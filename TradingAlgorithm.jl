import Pkg
println("--- 🔎 Verifying Libraries ---")
required_packages = ["HTTP", "JSON", "Dates", "DataFrames", "Statistics", "Random"]
for pkg in required_packages
    if !haskey(Pkg.project().dependencies, pkg)
        println("   + Installing $pkg...")
        Pkg.add(pkg)
    end
end
using HTTP, JSON, Dates, DataFrames, Statistics, Random
println("--- ✅ Libraries Ready ---\n")

# 🔴 PASTE YOUR KEYS HERE 🔴
const API_KEY = "YOUR ALPACA API KEY"        
const SECRET_KEY = "YOUR ALPACA SECRET KEY" 
const BASE_URL = "https://paper-api.alpaca.markets"

# ------------------------------------------------------------
# ⚙️ 2. CONFIGURATION
# ------------------------------------------------------------
const SYMBOL_TO_ANALYZE = "NVDA"
const CASH_RISK_PER_TRADE = 0.02     # 2% cash risk per trade
const MAX_POSITIONS = 26             # Max 26 concurrent positions

# --- THE DUAL FILTERS ---
const GROWTH_REQUIRED = 1.08         # 1. MUST be up 8% total over 2 years
const MK_TREND_THRESHOLD = 1.64      # 2. MUST have Z-Score > 1.64 (95% Confidence)

const BUY_DROP_THRESHOLD = 0.04      # Buy if intraday drop > 4%
const SELL_PROFIT_THRESHOLD = 0.015  # Sell if profit > 1.5%
const CRASH_THRESHOLD = -0.08        # -8% Market drop = Panic (Liquidate all)

# Memory Structure
mutable struct Position
    symbol::String
    entry_price::Float64
    shares::Float64 
end
active_positions = Dict{String, Position}()

# ------------------------------------------------------------
# 3. INTERNAL STOCK LIST 
# ------------------------------------------------------------

const SP500_CACHE = String[]

function get_sp500_full_list()
    if !isempty(SP500_CACHE); return SP500_CACHE; end
    println("🌐 Connecting to GitHub (Official 'datasets' repo)...")
    url = "https://raw.githubusercontent.com/datasets/s-and-p-500-companies/main/data/constituents.csv"
    
    # BACKUP LIST (In case of total internet failure)
    backup_list = [
        "AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "TSLA", "META", "BRK.B", "JPM", "V", 
        "JNJ", "WMT", "PG", "LLY", "MA", "UNH", "HD", "CVX", "MRK", "ABBV", 
        "KO", "PEP", "AVGO", "COST", "MCD", "TMO", "CSCO", "ACN", "ABT", "DHR", 
        "LIN", "NKE", "DIS", "ADBE", "TXN", "VZ", "PM", "UPS", "NEE", "RTX", 
        "HON", "AMGN", "LOW", "INTC", "IBM", "QCOM", "SPGI", "CAT", "GS", "GE", 
        "BA", "ISRG", "DE", "PLD", "BLK", "BKNG", "MDLZ", "AXP", "ADI", "NOW", 
        "ELV", "SYK", "LMT", "TJX", "ADP", "MMC", "C", "MD", "AMT", "CB", 
        "GILD", "AMAT", "REGN", "ZTS", "VRTX", "MO", "PGR", "TMUS", "SO", "BSX", 
        "CI", "BDX", "LRCX", "FISV", "TGT", "MU", "EOG", "ITW", "SLB", "CME", 
        "SHW", "CSX", "CL", "ETN", "AON", "NOC", "PYPL", "EQIX", "USB", "HUM", 
        "ICE", "APD", "FCX", "MPC", "WM", "KLAC", "HCA", "PNC", "DUK", "EMR", 
        "ORLY", "FDX", "MCO", "MCK", "PSX", "APH", "MAR", "TFC", "NXPI", "MSI", 
        "ROP", "DXCM", "MCHP", "AJG", "GM", "NSC", "GD", "TT", "AZO", "EW", 
        "SRE", "ADSK", "IDXX", "CARR", "OXY", "AEP", "TRV", "MET", "PCAR", "D", 
        "KMB", "PSA", "AIG", "ROST", "F", "VLO", "EXC", "HLT", "TEL", "MNST", 
        "CTAS", "STZ", "JCI", "PAYX", "TRGP", "PH", "KMI", "WMB", "AFL", "MSCI", 
        "O", "YUM", "ALL", "KHC", "ED", "IQV", "XEL", "GPN", "FAST", "ADM", 
        "DHI", "PEG", "RSG", "BK", "OTIS", "DFS", "AMP", "PCG", "MTD", "AME", 
        "CHTR", "ON", "KR", "CMI", "FIS", "NUE", "DOW", "CTSH", "VRSK", "WBA", 
        "AWK", "FANG", "BKR", "IT", "SYY", "VRSN", "KEYS", "CEG", "ODFL", "HSY", 
        "XYL", "HPQ", "VICI", "MPWR", "CBRE", "DVN", "GLW", "DLTR", "K", "ABC", 
        "EFX", "CDW", "HAL", "RMD", "WEC", "URI", "TSCO", "HES", "PPG", "FTV", 
        "HIG", "WELL", "GWW", "DAL", "IR", "ROK", "EIX", "AEE", "STT", "MTB", 
        "MKC", "VMC", "ZBH", "APTV", "DOV", "BIIB", "TROW", "ULTA", "EBAY", 
        "HPE", "STE", "ETR", "FE", "ES", "DLR", "PPL", "CMS", "CNP", "RF", 
        "LYB", "CAH", "GPC", "RJF", "PHM", "WAT", "TDG", "IRM", "NTRS", "MOH", 
        "AVY", "IFF", "LHX", "BLDR", "PFG", "EXR", "NDAQ", "CINF", "HOLX", 
        "OMC", "PKI", "BRO", "WAB", "TYL", "AMCR", "DRI", "ALB", "IEX", "FSLR", 
        "HBAN", "EXPD", "POOL", "ATO", "MAS", "TXT", "JBHT", "STX", "CNM", 
        "SNA", "BBY", "WST", "DGX", "CBOE", "LUV", "WRB", "NVR", "UAL", "GRMN", 
        "L", "ESS", "SWK", "MAA", "AKAM", "INCY", "LKQ", "CPT", "PKG", "NDSN", 
        "TER", "CAG", "HST", "IP", "EVRG", "JKHY", "PTC", "LDOS", "DPZ", "J", 
        "KMX", "TYL", "WYNN", "SJM", "BF.B", "CPB", "TAP", "TECH", "UDR", "AES", 
        "NRG", "ZBRA", "HRL", "REG", "NI", "MGM", "QRVO", "TPR", "IPG", "LNT", 
        "PNR", "CF", "NWSA", "FFIV", "AOS", "GL", "CDAY", "HAS", "BBWI", "ALLE", 
        "SEE", "CTRA", "FRT", "GNRC", "AIZ", "BWA", "XRAY", "IVZ", "NWL", "BEN", 
        "WHR", "PNW", "MHK", "RL", "DVA", "ALK", "DXC", "VNO", "PEAK", "LNC", 
        "BIO", "OGN"
    ]
    try
        headers = ["User-Agent" => "Mozilla/5.0"]
        r = HTTP.get(url, headers; readtimeout=30)
        raw_text = String(r.body)
        lines = split(raw_text, '\n')
        symbols = String[]
        for i in 2:length(lines)
            line = strip(lines[i])
            if isempty(line) continue end
            parts = split(line, ',')
            sym = replace(String(parts[1]), "\"" => "")
            final_sym = replace(sym, "-" => ".")
            push!(symbols, final_sym)
        end
        println("✅ CSV list downloaded: $(length(symbols)) companies.")
        append!(SP500_CACHE, symbols)
        return symbols
    catch e
        println("⚠️ Error downloading CSV. Using backup list.")
        return backup_list
    end
end

function get_dynamic_universe(limit::Int=40)
    full_list = get_sp500_full_list()
    return first(shuffle(full_list), limit)
end

# ------------------------------------------------------------
# 4. CONNECTION AND DATA
# ------------------------------------------------------------

function get_headers()
    return ["APCA-API-KEY-ID" => API_KEY, "APCA-API-SECRET-KEY" => SECRET_KEY, "Content-Type" => "application/json"]
end

function get_account_data()
    try
        r = HTTP.get(string(BASE_URL, "/v2/account"), get_headers())
        return JSON.parse(String(r.body))
    catch e
        println("⚠️ Error reading account: $e")
        return nothing
    end
end

function get_account_cash()
    data = get_account_data()
    if isnothing(data) return 0.0 end
    return parse(Float64, data["cash"])
end

function get_equity()
    data = get_account_data()
    if isnothing(data) return 0.0 end
    return parse(Float64, data["equity"]) 
end

function sync_positions()
    try
        r = HTTP.get(string(BASE_URL, "/v2/positions"), get_headers())
        positions_data = JSON.parse(String(r.body))
        empty!(active_positions)
        for p in positions_data
            sym = p["symbol"]
            qty = parse(Float64, p["qty"]) 
            entry = parse(Float64, p["avg_entry_price"])
            active_positions[sym] = Position(sym, entry, qty)
        end
    catch e
        println("❌ Error syncing positions: $e")
    end
end

function get_current_price(symbol::String)
    try
        r = HTTP.get("https://data.alpaca.markets/v2/stocks/$symbol/trades/latest", get_headers())
        data = JSON.parse(String(r.body))
        return Float64(data["trade"]["p"])
    catch
        try
            url_backup = "https://data.alpaca.markets/v2/stocks/$symbol/bars?timeframe=1Min&limit=1"
            r = HTTP.get(url_backup, get_headers())
            data = JSON.parse(String(r.body))
            if haskey(data, "bars") && length(data["bars"]) > 0
                return Float64(data["bars"][1]["c"])
            end
            return nothing
        catch; return nothing; end
    end
end

function get_yesterday_close(symbol::String)
    try
        url = "https://data.alpaca.markets/v2/stocks/$symbol/bars?timeframe=1Day&limit=2"
        r = HTTP.get(url, get_headers())
        data = JSON.parse(String(r.body))
        if haskey(data, "bars") && length(data["bars"]) >= 1
            return Float64(data["bars"][1]["c"])
        end
    catch e; return nothing; end
    return nothing
end

function get_hourly_history(symbol::String)
    start_date = Dates.format(now() - Day(7), "yyyy-mm-dd")
    url = "https://data.alpaca.markets/v2/stocks/$symbol/bars?timeframe=1Hour&limit=50&start=$start_date"
    try
        r = HTTP.get(url, get_headers())
        data = JSON.parse(String(r.body))
        if !haskey(data, "bars") || isnothing(data["bars"]); return Float64[]; end
        return [Float64(bar["c"]) for bar in data["bars"]]
    catch e; return Float64[]; end
end

function get_long_term_history(symbol::String)
    start_date = Dates.format(now() - Year(2), "yyyy-mm-dd")
    url = "https://data.alpaca.markets/v2/stocks/$symbol/bars?timeframe=1Day&limit=600&start=$start_date"
    try
        r = HTTP.get(url, get_headers())
        data = JSON.parse(String(r.body))
        if !haskey(data, "bars") || isnothing(data["bars"]); return Float64[]; end
        return [Float64(bar["c"]) for bar in data["bars"]]
    catch e; return Float64[]; end
end

# ------------------------------------------------------------
# 5. MATHEMATICS & ALGORITHMS (MANN-KENDALL)
# ------------------------------------------------------------

function calculate_mann_kendall(prices::Vector{Float64})
    n = length(prices)
    if n < 10 return 0.0 end 
    S = 0
    for i in 1:n-1
        for j in i+1:n
            S += sign(prices[j] - prices[i])
        end
    end
    var_s = (n * (n - 1) * (2n + 5)) / 18
    if S > 0; z = (S - 1) / sqrt(var_s)
    elseif S < 0; z = (S + 1) / sqrt(var_s)
    else; z = 0.0; end
    return z
end

# ------------------------------------------------------------
# 6. ORDERS AND MANAGEMENT
# ------------------------------------------------------------

function place_order(symbol::String, amount_or_qty::Float64, side::String)
    url = string(BASE_URL, "/v2/orders")
    body = Dict("symbol" => symbol, "side" => side, "type" => "market", "time_in_force" => "day")
    if side == "buy"; body["notional"] = string(round(amount_or_qty, digits=2))
    else; body["qty"] = string(amount_or_qty); end

    try
        HTTP.post(url, get_headers(), JSON.json(body))
        return true
    catch e
        println("❌ Order Failed ($side $symbol). Possible PDT block? Error: $e")
        return false
    end
end

function close_position(symbol::String)
    url = string(BASE_URL, "/v2/positions/$symbol")
    try; HTTP.delete(url, get_headers()); return true
    catch e; println("❌ Error closing position $symbol: $e"); return false; end
end

function panic_sell_all()
    println("\n🔥🔥🔥 PANIC MODE! ACTIVATING NUCLEAR OPTION 🔥🔥🔥")
    url = string(BASE_URL, "/v2/positions?cancel_orders=true")
    try
        HTTP.delete(url, get_headers())
        println("✅ SIGNAL RECEIVED. Closing everything.")
        exit()
    catch e
        println("❌ Error in Nuclear Option: $e"); exit()
    end
end

function print_portfolio_status()
    if isempty(active_positions)
        println("💼 PORTFOLIO: [ Empty ]"); return
    end
    println("\n💼 --- CURRENT PORTFOLIO ---")
    println("   SYM      | INVESTED | VALUE TODAY | PROFIT(\$) |     %")
    
    total_invested = 0.0
    for (sym, pos) in active_positions
        curr = get_current_price(sym)
        if isnothing(curr) 
            println("   $sym     | ...        | ...        | ...          | (Wait)"); continue 
        end
        invested = pos.entry_price * pos.shares
        market_val = curr * pos.shares
        profit_dollars = market_val - invested
        pl_pct = (curr - pos.entry_price) / pos.entry_price
        
        icon = pl_pct >= 0 ? "🟢" : "🔴"
        sign = profit_dollars >= 0 ? "+" : ""
        s_invested = "\$$(round(invested, digits=2))"
        s_val = "\$$(round(market_val, digits=2))"
        s_profit = "$(sign)\$$(round(profit_dollars, digits=2))"
        s_pct = "$(round(pl_pct*100, digits=2))%"
        println("   $icon $sym | $s_invested    | $s_val    | $s_profit       | $s_pct")
    end
    println("   -------------------------------------------------------")
end

function run_diagnostic(symbol::String)
    println("\n🔬 --- INITIAL DIAGNOSTIC: $symbol ---")
    price = get_current_price(symbol)
    if isnothing(price) println("❌ Price error."); return end
    println("📍 Current Price: \$$price")

    long_history = get_long_term_history(symbol) 
    if length(long_history) < 300; println("⚠️ Not enough historical data."); return; end

    # --- HYBRID DIAGNOSTIC CHECK ---
    
    # 1. GROWTH CHECK
    price_2y = long_history[1]
    growth_ok = price >= (price_2y * GROWTH_REQUIRED)

    # 2. MK CHECK
    mk_score = calculate_mann_kendall(long_history[end-100:end])
    is_mk_ok = mk_score > MK_TREND_THRESHOLD
    
    sma_50 = mean(long_history[end-49:end])
    is_above_sma = price > sma_50

    println("1. 8% Growth (2yr): $(round(price_2y, digits=2)) -> $(round(price_2y * GROWTH_REQUIRED, digits=2))")
    println("   Pass?          $(growth_ok ? "YES ✅" : "NO ❌")")
    
    println("2. Trend Score:     $mk_score (Needs > $MK_TREND_THRESHOLD)")
    println("   Pass?          $(is_mk_ok ? "YES ✅" : "NO ❌")")

    println("3. Above SMA 50?    $(is_above_sma ? "YES ✅" : "NO ❌")")
    println("----------------------------------------------\n")
end

# ------------------------------------------------------------
# 7. MAIN STRATEGY
# ------------------------------------------------------------

function check_market_health()
    indices = ["SPY", "QQQ"] 
    for index in indices
        current = get_current_price(index)
        prev = get_yesterday_close(index)
        if !isnothing(current) && !isnothing(prev)
            change_pct = (current - prev) / prev
            println("📊 Market Status ($index): $(round(change_pct*100, digits=2))%")
            if change_pct <= CRASH_THRESHOLD; panic_sell_all(); end
            return 
        end
    end
end

function run_strategy(current_symbols::Vector{String})
    check_market_health()
    equity_total = get_equity()
    cash_available = get_account_cash()
    
    if equity_total == 0.0 && cash_available == 0.0
        println("⚠️ ALERT: 0 Balance detected. Check credentials."); return
    end

    println("💰 CASH: \$$(round(cash_available, digits=2)) | TOTAL EQUITY: \$$(round(equity_total, digits=2))")
    print_portfolio_status() 
    sync_positions()

    # --- SELLS ---
    for (sym, pos) in active_positions
        price = get_current_price(sym)
        if !isnothing(price)
            target = pos.entry_price * (1 + SELL_PROFIT_THRESHOLD)
            if price >= target
                println("✨ SELL (TP Hit)! Closing $sym...")
                if close_position(sym); delete!(active_positions, sym); end
            end
        end
    end

    # --- BUYS ---
    if length(active_positions) >= MAX_POSITIONS
        println("✋ Position limit reached. Only watching for sells."); return 
    end

    println("🕒 Scanning opportunities in batch of $(length(current_symbols)) stocks...")
    
    for sym in current_symbols
        if haskey(active_positions, sym) continue end 
        
        history_long = get_long_term_history(sym)
        if length(history_long) < 400 continue end 

        current_price = history_long[end]
        price_2y = history_long[1] # Approx 2 years ago (start of buffer)

        # --- FILTER 1: GROWTH (MAGNITUDE) ---
        # "Is it actually worth more than it was 2 years ago?"
        if current_price < (price_2y * GROWTH_REQUIRED)
             continue 
        end
        
        # --- FILTER 2: MANN-KENDALL (CONSISTENCY) ---
        # "Is the move upward steady and reliable?"
        trend_score = calculate_mann_kendall(history_long[end-100:end])
        if trend_score < MK_TREND_THRESHOLD
            continue 
        end

        # --- FILTER 3: SMA 50 (MOMENTUM) ---
        sma_50 = mean(history_long[end-49:end])
        if current_price < sma_50 continue end
        
        # --- FILTER 4: INTRADAY DIP (ENTRY) ---
        history_hourly = get_hourly_history(sym)
        if length(history_hourly) < 10 continue end 

        recent_high = maximum(history_hourly)
        drop_percentage = (recent_high - current_price) / recent_high
        
        if drop_percentage > 0.005
             print("   $sym: -$(round(drop_percentage*100, digits=2))% (MK:$(round(trend_score,digits=2))) | ")
        end

        if drop_percentage >= BUY_DROP_THRESHOLD
            println("\n -> 🎯 OPPORTUNITY CONFIRMED! $sym")
            
            allocation = equity_total * CASH_RISK_PER_TRADE
            if allocation > cash_available; allocation = cash_available - 5.0; end

            if allocation >= 5.0 
                if place_order(sym, allocation, "buy")
                        println("       🚀 ORDER SENT: \$$allocation of $sym")
                        cash_available -= allocation
                end
            end
        end
    end
    println("")
end

# ------------------------------------------------------------
# 8. BOT EXECUTION
# ------------------------------------------------------------
println("🤖 BOT PRO v9.5: HYBRID EDITION (MK + 8% GROWTH)")
test_cash = get_account_cash()
println("🔌 Alpaca connection test... Balance detected: \$$test_cash")

if test_cash == 0.0
    println("🛑 CRITICAL ERROR: Balance is 0. Reset Paper account and update keys.")
    exit()
end

sync_positions() 
run_diagnostic(SYMBOL_TO_ANALYZE)

ticks = 0
println("🏁 Starting secure trading loop...")
while true
    try
        global ticks
        ticks += 1
        if ticks % 5 == 0; sync_positions(); end 
        cycle_symbols = get_dynamic_universe(500) 
        run_strategy(cycle_symbols)
    catch e
        println("⚠️ Main loop error: $e")
        sleep(5)
    end
    println("💤 Waiting 60s...")
    sleep(60) 
end
