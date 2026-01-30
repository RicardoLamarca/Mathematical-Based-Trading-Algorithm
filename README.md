# Mathematical-Based-Trading-Algorithm

![Julia](https://img.shields.io/badge/Made%20with-Julia-9558B2?style=flat&logo=julia)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active-success)

A high-performance algorithmic trading bot written in **Julia**. This system automates the analysis, selection, and execution of trades using the **Alpaca Paper Trading API**. It focuses on the S&P 500 universe, utilizing a mean-reversion strategy backed by long-term trend confirmation.

## 🚀 Key Features

* **Dynamic Universe:** Automatically downloads, parses, and shuffles the S&P 500 constituents list.
* **Risk Management:** Strict position sizing (default 2% equity per trade) and portfolio limits (Max 25 positions).
* **Market "Circuit Breaker":** Automatically liquidates all positions if the broad market (SPY/QQQ) crashes significantly (Nuclear Option).
* **High Performance:** Leveraging Julia's speed for real-time data processing and decision making.

---

## 🧠 Mathematical Logic & Strategy

The bot operates on a "Buy the Dip, Sell the Rip" philosophy, but with strict safety filters. A trade is only executed if a stock passes **all** of the following mathematical conditions simultaneously:

### 1. Long-Term Growth Filter (Trend Confirmation)
To ensure capital is only deployed into fundamentally strong assets, the bot compares the current price ($P_{t}$) against the price from 2 years ago ($P_{t-2y}$).

$$P_{t} \geq P_{t-2y} \times 1.08$$

* **Logic:** The stock must have retained value and grown at least **8%** over the last two years. This filters out stocks in a long-term downtrend.

### 2. Moving Average Trend (Momentum)
The bot calculates the 50-Day Simple Moving Average (SMA) to determine the medium-term market sentiment.

$$SMA_{50} = \frac{1}{50} \sum_{i=0}^{49} P_{t-i}$$

$$Condition: P_{t} > SMA_{50}$$

* **Logic:** The current price must be **above** its 50-day average. This ensures we are buying a "dip" in an uptrend, rather than catching a falling knife.

### 3. Intraday "Dip" Detection (Mean Reversion)
The bot analyzes the last 50 trading hours to find the recent high ($P_{high}$). It calculates the percentage drop ($\Delta \%$) to the current price ($P_{current}$).

$$\Delta \% = \frac{P_{high} - P_{current}}{P_{high}}$$

$$Condition: \Delta \% \ge 0.04$$

* **Logic:** We only buy if the stock has dropped **4% or more** from its recent hourly high, betting on a short-term statistical reversion to the mean.

### 4. Profit Taking (Exit Strategy)
Once a position is open, the bot monitors it continuously.

$$P_{current} \ge P_{entry} \times (1 + 0.015)$$

* **Logic:** Secure profits immediately once the asset rises **1.5%** above the entry price.

---

## 🛠️ Configuration

You can adjust the strategy parameters in the `Configuration` section of the code to fit your risk tolerance:

| Constant | Default | Description |
| :--- | :--- | :--- |
| `CASH_RISK_PER_TRADE` | `0.02` | Allocates 2% of total equity per trade. |
| `MAX_POSITIONS` | `25` | Maximum number of concurrent open positions. |
| `GROWTH_REQUIRED` | `1.08` | Requires 108% price retention (8% growth) over 2 years. |
| `BUY_DROP_THRESHOLD` | `0.04` | Buys when price drops 4% from recent high. |
| `SELL_PROFIT_THRESHOLD` | `0.015` | Sells when profit hits 1.5%. |
| `CRASH_THRESHOLD` | `-0.08` | **Nuclear Option:** Sells everything if market drops 8%. |

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
