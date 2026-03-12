# 🤖 AUTOMATIZED MATHEMATICAL TRADING ALGORITHM  | Quantitative Trading Core

![Julia](https://img.shields.io/badge/Core-Julia_1.10+-9558B2?style=for-the-badge&logo=julia)
![Python](https://img.shields.io/badge/Telemetry-Python_3.9+-3776AB?style=for-the-badge&logo=python)
![Broker](https://img.shields.io/badge/Broker-Alpaca_API-F5C518?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-success?style=for-the-badge)

Welcome to **Algo Engine Pro**, a high-performance algorithmic trading system built for the US Equities market (S&P 500). 

This project uses a **Dual-Engine Architecture**:
1. **The Brain (Julia):** A highly optimized execution engine that handles market data streaming, mathematical trend analysis, and order routing via the Alpaca API.
2. **The Dashboard (Python/Streamlit):** A real-time, zero-latency web interface that reads live telemetry from the Julia engine via a lightweight SQLite database.

---

## 🧮 Mathematical Background & Logic

The trading logic is built on a multi-layered quantitative approach, ensuring that capital is only deployed when statistical, momentum, and mean-reversion alignments occur.

### 1. The Mann-Kendall Trend Test (Statistical Confidence)
Instead of relying purely on simple moving averages, the bot evaluates the historical price action using the Mann-Kendall (MK) test. This is a non-parametric test used to identify monotonic trends over time.

First, the algorithm calculates the $S$ statistic by comparing all pairs of data points in the last 100 days:
$$S = \sum_{i=1}^{n-1} \sum_{j=i+1}^{n} \text{sgn}(x_j - x_i)$$

Then, it computes the variance of $S$:
$$Var(S) = \frac{n(n-1)(2n+5)}{18}$$

Finally, the standard normal test statistic (Z-score) is calculated (assuming $S > 0$ for uptrends):
$$Z = \frac{S - 1}{\sqrt{Var(S)}}$$

**Implementation:** The bot requires a Z-score of **> 1.64**. In a one-sided test, a Z-score of 1.64 corresponds to a **95% statistical confidence** that the asset is in a reliable upward trend.

### 2. Momentum & Baseline Growth
Alongside the statistical confidence, the asset must pass structural growth checks:
* **2-Year Growth Requirement:** The current price must be mathematically strictly greater than 110% of its price two years ago ($P_{current} \ge P_{t-2yrs} \times 1.10$).
* **50-Day Momentum:** The current price must be trading above its 50-day Simple Moving Average (SMA), calculated as:
$$\text{SMA}_{50} = \frac{1}{50} \sum_{i=1}^{50} P_i$$

### 3. Mean Reversion Trigger (Intraday Drop)
If a stock passes the macro trend and momentum filters, the bot waits for a localized mean-reversion opportunity. It measures the intraday percentage drop from the daily high ($P_{high}$):
$$\text{Drop \%} = \frac{P_{high} - P_{current}}{P_{high}}$$
The bot executes a buy order only when the drop exceeds **4%** (0.04), securing a favorable statistical entry point within a macro uptrend.

---

### 📈 Strategy Execution & Risk Management

### The Entry Setup
Before deploying capital (5% risk per trade), a stock must pass **all** the mathematical conditions outlined above: 10% macro growth, 95% MK Trend Confidence, > 50 SMA, and > 4% intraday drop.

### The Exit Logic
* **Standard Take Profit:** Sells automatically when the position reaches **+1.5%** profit from the entry price.
* **🦘 Bounce Recovery:** If the stock drops below the entry price, the bot tracks the new local bottom. If it then bounces **1.5%** from that bottom, the bot dynamically closes the position to mitigate further downside risk.
* **☢️ The Nuclear Option (Market Crash):** If the broader market (SPY/QQQ) drops by **8%** in a single day, the bot triggers a total portfolio liquidation, canceling all pending orders and selling all active positions to cash.

---

### 🏗️ Architecture & Telemetry

The system avoids heavy inter-process communication (IPC) overhead by using **SQLite** as a shared, real-time memory state.

* **bot.jl (Julia)** scans the market, executes trades, and constantly updates `bot_data.sqlite` with the portfolio state and active positions.
* **dashboard.py (Python/Streamlit)** independently queries `bot_data.sqlite` every 5 seconds to render a live, Bloomberg-style terminal UI.

---

### 🚀 Setup & Installation

### Prerequisites
* **Julia** (v1.10 or higher)
* **Python** (v3.9 or higher)
* An **Alpaca Markets** Paper Trading Account (API Key & Secret)

### Step 1: Clone the Repository
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
    cd YOUR_REPO_NAME

### Step 2: Configure API Keys
Open `bot.jl` and replace the placeholder keys with your actual Alpaca **Paper Trading** keys.
(⚠️ CRITICAL: Never commit your actual API keys to GitHub. Keep them secure!)
    
    const API_KEY = "YOUR_API_KEY_HERE"      
    const SECRET_KEY = "YOUR_SECRET_KEY_HERE" 

### Step 3: Start the Julia Execution Core
Open your terminal, navigate to the project folder, and run:
    
    julia bot.jl

(Note: On the first run, Julia will automatically install the required dependencies: HTTP, JSON, DataFrames, SQLite, etc.)

### Step 4: Launch the Live Dashboard
Open a **second** terminal window, navigate to the exact same project folder, install the Python requirements, and start Streamlit:
    
    pip install streamlit pandas plotly
    python -m streamlit run dashboard.py

The dashboard will open automatically in your browser at http://localhost:8501.

---

### ⚠️ Disclaimer
**Not Financial Advice.** This software is for educational and research purposes only. Do not use this algorithm with real money (live trading) without thoroughly backtesting and understanding the risks involved. The author is not responsible for any financial losses incurred. Use the Alpaca **Paper Trading** environment to test it safely.
