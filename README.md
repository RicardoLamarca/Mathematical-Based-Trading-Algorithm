# Mathematical-Based-Trading-Algorithm

![Julia](https://img.shields.io/badge/Made%20with-Julia-9558B2?style=flat&logo=julia)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active-success)

A high-performance algorithmic trading bot written in **Julia**. This system automates the analysis, selection, and execution of trades using the **Alpaca Paper Trading API**.

The bot utilizes a **Hybrid Statistical Strategy**, combining **absolute magnitude** (Minimum Growth) with **statistical consistency** (Mann-Kendall Trend Test) to identify high-probability "dip buying" opportunities within the S&P 500.

## 🚀 Key Features

* **Hybrid Trend Engine:** Uses a dual-layer filter (Magnitude + Consistency) to separate luck from true performance.
* **Dynamic Universe:** Automatically downloads, parses, and shuffles the S&P 500 constituents list.
* **Risk Management:** Strict position sizing (default 2% equity per trade) and portfolio limits (Max 26 positions).
* **Market "Circuit Breaker":** Automatically liquidates all positions if the broad market (SPY/QQQ) crashes significantly.
* **High Performance:** Leveraging Julia's speed for real-time statistical analysis and decision making.

---

## 🧠 Mathematical Logic & Strategy

The bot operates on a "Buy the Dip, Sell the Rip" philosophy, but with strict safety filters. A trade is only executed if a stock passes **all** of the following mathematical conditions simultaneously:

### 1. Magnitude Filter (The "8% Rule")
First, the bot checks if the asset has actually gained value over the long term. It compares the current price ($P_{t}$) against the price from 2 years ago ($P_{t-2y}$).

$$P_{t} \geq P_{t-2y} \times 1.08$$

* **Logic:** The stock must have grown at least **8%** over the last two years. This filters out stocks that are volatile but ultimately stagnant or declining.

### 2. Consistency Filter (Mann-Kendall Trend Test)
To ensure the growth isn't just a random spike, the bot performs a non-parametric **Mann-Kendall Test** on the last 100 days of data. It calculates a Z-Score ($Z_{MK}$) to quantify the probability of a consistent uptrend.

$$S = \sum_{i=1}^{n-1} \sum_{j=i+1}^{n} \text{sgn}(P_j - P_i)$$

$$Z_{MK} = \frac{S - 1}{\sqrt{\frac{n(n-1)(2n+5)}{18}}}$$

$$Condition: Z_{MK} > 1.64$$

* **Logic:** A Z-Score $> 1.64$ indicates a **95% statistical confidence** that the uptrend is non-random. This filters out "choppy" stocks that are dangerous to trade.

### 3. Momentum Filter (SMA 50)
The bot calculates the 50-Day Simple Moving Average (SMA) to determine the medium-term market sentiment.

$$Condition: P_{t} > SMA_{50}$$

* **Logic:** The current price must be **above** its 50-day average. We want to buy dips in verified uptrends, not catch falling knives.

### 4. Mean Reversion Entry (Intraday Dip)
The bot analyzes the last 50 trading hours to find the recent high ($P_{high}$). It calculates the percentage drop ($\Delta \%$) to the current price.

$$\Delta \% = \frac{P_{high} - P_{current}}{P_{high}}$$

$$Condition: \Delta \% \ge 0.04$$

* **Logic:** We only buy if the stock has dropped **4% or more** from its recent hourly high, betting on a short-term statistical reversion to the mean.

### 5. Exit Strategy
Once a position is open, the bot monitors it continuously.

$$P_{current} \ge P_{entry} \times (1 + 0.015)$$

* **Logic:** Secure profits immediately once the asset rises **1.5%** above the entry price.

---

## 🛠️ Configuration

You can adjust the strategy parameters in the `Configuration` section of the code:

| Constant | Default | Description |
| :--- | :--- | :--- |
| `CASH_RISK_PER_TRADE` | `0.02` | Allocates 2% of total equity per trade. |
| `MAX_POSITIONS` | `26` | Maximum number of concurrent open positions. |
| `GROWTH_REQUIRED` | `1.08` | Requires 8% total price growth over 2 years. |
| `MK_TREND_THRESHOLD` | `1.64` | **New:** Requires 95% confidence in trend consistency. |
| `BUY_DROP_THRESHOLD` | `0.04` | Buys when price drops 4% from recent high. |
| `SELL_PROFIT_THRESHOLD` | `0.015` | Sells when profit hits 1.5%. |
| `CRASH_THRESHOLD` | `-0.08` | **Nuclear Option:** Liquidates everything if market drops 8%. |

---

## 📦 Installation & Usage

### 1. Prerequisites
* **Install Julia:** Download it from [julialang.org](https://julialang.org/downloads/).
* **Alpaca Account:** Sign up at [Alpaca Markets](https://alpaca.markets/) and generate **Paper Trading API Keys**.

### 2. Setup
Clone the repository:
```bash
git clone [https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git)
cd YOUR_REPO_NAME
