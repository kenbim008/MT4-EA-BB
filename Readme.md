# BB_MA_EA - Bollinger Bands & Moving Average Expert Advisor

## Overview
BB_MA_EA is an **Expert Advisor (EA) for MetaTrader 4 (MT4)** that implements a trading strategy based on **Bollinger Bands** and **Moving Average crossovers**. The EA determines trade signals using Bollinger Bands and Moving Average strategies and manages trade execution with risk management settings.

## Things to do
1. 
2. 
3. 

## Features
- Uses **Bollinger Bands** to identify price breakouts.
- Implements a **Fast & Slow Moving Average crossover strategy**.
- Configurable **lot size, stop loss, and take profit**.
- Allows **account-specific execution**.
- Limits the **number of trades per candle** to prevent overtrading.
- Implements **trend filtering** using Bollinger Band averages over past candles.

## Parameters
| Parameter                  | Description                                      | Default Value |
|----------------------------|--------------------------------------------------|--------------|
| LotSize                    | Lot size for trades                              | 0.1          |
| BBPeriod                   | Bollinger Bands period                           | 20           |
| BBDeviation                | Bollinger Bands deviation                        | 2.0          |
| FastMAPeriod               | Fast Moving Average period                       | 10           |
| SlowMAPeriod               | Slow Moving Average period                       | 20           |
| MagicNumber                | Unique identifier for trades                     | 123456       |
| Slippage                   | Allowed slippage in points                       | 3            |
| StopLoss                   | Stop loss in points                              | 50           |
| TakeProfit                 | Take profit in points                            | 100          |
| AllowedAccountNumber       | Restrict EA to a specific account (0 = any)      | 0            |
| MaxTradesPerCandleBuy      | Maximum buy trades per candle                    | 1            |
| MaxTradesPerCandleSell     | Maximum sell trades per candle                   | 1            |
| BackTrack                  | Number of past candles for trend analysis        | 10           |

## Trading Logic
### Entry Conditions
- **Buy Signal**:
  - Price crosses **above** the Bollinger Bands middle band.
  - Fast MA crosses **above** Slow MA.
  - Trend filter confirms **uptrend**.
  - Number of buy trades for the candle **is within limit**.

- **Sell Signal**:
  - Price crosses **below** the Bollinger Bands middle band.
  - Fast MA crosses **below** Slow MA.
  - Trend filter confirms **downtrend**.
  - Number of sell trades for the candle **is within limit**.

### Trade Execution
- The EA opens trades using the **OrderSend()** function.
- Trades are placed with a **stop loss and take profit**.
- Buy orders use the **Bid price**, and Sell orders use the **Ask price**.
- The EA prevents overtrading by limiting trades per candle.

### Trend Detection
- Uses the **getTrend()** function to analyze the middle Bollinger Band over the last `BackTrack` candles.
- If the **current middle band** is above the **average of past bands**, the trend is **up**.
- Otherwise, the trend is **down**.

## Installation & Usage
1. Copy the **BB_MA_EA.mq4** file to `MQL4/Experts/` in your MetaTrader 4 directory.
2. Restart MetaTrader 4 or refresh the **Navigator** panel.
3. Attach **BB_MA_EA** to a chart.
4. Configure the input parameters as needed.
5. Enable **AutoTrading** to allow trade execution.

## Notes
- The EA checks if it is running on the allowed account before executing trades.
- If an order fails, the error is printed in the **Expert Logs**.
- The EA does **not** use martingale or grid strategies—each trade is independent.

## Disclaimer
This EA is for **educational purposes**. Use at your own risk. Always test on a **demo account** before using real funds.

---
**Developed with MetaEditor**

