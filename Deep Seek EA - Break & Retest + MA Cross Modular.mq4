//+------------------------------------------------------------------+
//|                                                      ModularEA.mq4 |
//|                        Generated by Deepseek-V3                   |
//|                                                                  |
//+------------------------------------------------------------------+
#property strict

// Include necessary libraries
#include <TradeVantage_Util.mqh>

// Input parameters for Module 1 (BreakRetestEA)
input double LotSize1 = 0.1;          // Lot size for Module 1
input int StopLossPips1 = 20;         // Stop loss in pips for Module 1
input int TakeProfit1_1 = 30;         // Take Profit 1 in pips (30%) for Module 1
input int TakeProfit2_1 = 50;         // Take Profit 2 in pips (50%) for Module 1
input int TakeProfit3_1 = 100;        // Take Profit 3 in pips (100%) for Module 1
input int MaxDailyLoss1 = 3;          // Max consecutive losses before stopping for Module 1
input double MaxDailyGain1 = 10.0;    // Max daily gain percentage for Module 1
input double MaxWeeklyGain1 = 30.0;   // Max weekly gain percentage for Module 1
input int Slippage1 = 3;              // Slippage in pips for Module 1
input int MagicNumber1 = 123456;      // Magic number for Module 1

// Input parameters for Module 2 (MA_Cross_EA)
input int MAPeriod2 = 12;             // MA Period for Module 2
input int MAShift2 = 6;               // MA Shift for Module 2
input double LotSize2 = 0.01;         // Lot Size for Module 2
input double EntryDistance2 = 1.0;    // Parameter 1 for Module 2
input double ExitDistance2 = 1.0;     // Distance for trade exit (in $) for Module 2
input int MagicNumber2 = 654321;      // Magic Number for Module 2
input double MULT2 = 1.5;             // Multiplier for lot size for Module 2

// Global variables
int ConsecutiveLosses1 = 0;
double DailyProfit1 = 0;
double WeeklyProfit1 = 0;
datetime LastTradeTime1 = 0;
datetime LastCandleTime1 = 0;

double currentLotsize2 = LotSize2;
int previoursBars2 = 0;

#define ACCOUNT_NUMBER 123456  // Replace with your account number
#define START_DATE  D'2024.03.01'  // YYYY.MM.DD
#define END_DATE    D'2024.03.31'  // YYYY.MM.DD
#define START_HOUR  9    // Start time (24-hour format)
#define END_HOUR    13   // End time (4-hour window after start)
#define START_MIN   0    // Start minute
#define END_MIN     0    // End minute
#define TIMER_INTERVAL 300

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Check account number for security
    long userAccountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
    if(userAccountNumber != ACCOUNT_NUMBER && ACCOUNT_NUMBER != 0){
        Print("This EA is not authorized to run on this account. Please contact the Administrator.");
        return(INIT_FAILED);
    }

    // Initialize modules
    Module1_OnInit();
    Module2_OnInit();

    EventSetTimer(TIMER_INTERVAL);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if trading is allowed
    if (!IsTradingAllowed()) return;

    // Check for ranging market
    if (IsRangingMarket()) return;

    // Execute Module 1 logic
    Module1_OnTick();

    // Execute Module 2 logic
    Module2_OnTick();
}

//+------------------------------------------------------------------+
//| Module 1 Initialization                                          |
//+------------------------------------------------------------------+
void Module1_OnInit()
{
    // Initialization code for Module 1
}

//+------------------------------------------------------------------+
//| Module 1 Tick Function                                           |
//+------------------------------------------------------------------+
void Module1_OnTick()
{
    // Check for new candle formation
    if (!IsNewCandle1()) return;

    // Calculate daily and weekly profit
    CalculateProfit1();

    // Check for max drawdown or profit limits
    if (ConsecutiveLosses1 >= MaxDailyLoss1 || DailyProfit1 >= MaxDailyGain1 || WeeklyProfit1 >= MaxWeeklyGain1)
        return;

    // Get indicator values
    double MA50 = iMA(NULL, PERIOD_D1, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
    double MA4 = iMA(NULL, PERIOD_H1, 4, 0, MODE_SMA, PRICE_CLOSE, 0);
    double MA10 = iMA(NULL, PERIOD_H1, 10, 0, MODE_SMA, PRICE_CLOSE, 0);

    // Determine trend bias
    bool BullishBias = (iClose(NULL, PERIOD_D1, 1) > MA50);
    bool BearishBias = (iClose(NULL, PERIOD_D1, 1) < MA50);

    // Check entry conditions
    if (BullishBias && CheckBuyConditions1())
        OpenTrade1(OP_BUY);
    else if (BearishBias && CheckSellConditions1())
        OpenTrade1(OP_SELL);
}

//+------------------------------------------------------------------+
//| Module 2 Initialization                                          |
//+------------------------------------------------------------------+
void Module2_OnInit()
{
    // Initialization code for Module 2
    currentLotsize2 = LotSize2;
}

//+------------------------------------------------------------------+
//| Module 2 Tick Function                                           |
//+------------------------------------------------------------------+
void Module2_OnTick()
{
    // Calculate MA value
    double MA_Value = iMA(NULL, 0, MAPeriod2, MAShift2, MODE_SMA, PRICE_CLOSE, 0);

    // Check for Buy entry condition
    if (Close[1] > MA_Value + EntryDistance2 && Open[1] < MA_Value && CountTrades2(OP_BUY) == 0 && previoursBars2 != Bars)
    {
        previoursBars2 = Bars;
        CloseAllTrades2(OP_SELL); // Close any Sell trades before opening a Buy
        OpenTrade2(OP_BUY);
    }

    // Check for Sell entry condition
    if (Close[1] < MA_Value - EntryDistance2 && Open[1] > MA_Value && CountTrades2(OP_SELL) == 0 && previoursBars2 != Bars)
    {
        previoursBars2 = Bars;
        CloseAllTrades2(OP_BUY); // Close any Buy trades before opening a Sell
        OpenTrade2(OP_SELL);
    }

    // Check for Buy exit condition
    if (Close[1] < MA_Value - ExitDistance2 && CountTrades2(OP_BUY) > 0)
    {
        CloseAllTrades2(OP_BUY);
    }

    // Check for Sell exit condition
    if (Close[1] > MA_Value + ExitDistance2 && CountTrades2(OP_SELL) > 0)
    {
        CloseAllTrades2(OP_SELL);
    }
}

//+------------------------------------------------------------------+
//| Check if Trading is Allowed                                      |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
    // Check for trading hours, market open, etc.
    return true;
}

//+------------------------------------------------------------------+
//| Check for Ranging Market                                         |
//+------------------------------------------------------------------+
bool IsRangingMarket()
{
    // Implement your ranging market detection logic here
    // Example: Use ATR or Bollinger Bands to detect ranging markets
    return false; // Placeholder, replace with actual logic
}

//+------------------------------------------------------------------+
//| Check for New Candle Formation (Module 1)                        |
//+------------------------------------------------------------------+
bool IsNewCandle1()
{
    static datetime LastCandleTime1 = 0;
    datetime CurrentCandleTime = iTime(NULL, PERIOD_H1, 0); // Change timeframe if needed

    if (LastCandleTime1 != CurrentCandleTime)
    {
        LastCandleTime1 = CurrentCandleTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Calculate Daily and Weekly Profit (Module 1)                     |
//+------------------------------------------------------------------+
void CalculateProfit1()
{
    // Reset daily profit at the start of a new day
    if (TimeDay(TimeCurrent()) != TimeDay(LastTradeTime1))
    {
        DailyProfit1 = 0;
        LastTradeTime1 = TimeCurrent();
    }

    // Calculate daily and weekly profit
    DailyProfit1 += AccountProfit() - DailyProfit1;
    WeeklyProfit1 += AccountProfit() - WeeklyProfit1;
}

//+------------------------------------------------------------------+
//| Check Buy Conditions (Module 1)                                  |
//+------------------------------------------------------------------+
bool CheckBuyConditions1()
{
    // Check 4H higher highs
    if (iHigh(NULL, PERIOD_H4, 1) <= iHigh(NULL, PERIOD_H4, 2))
        return false;

    // Check 1H bullish continuation
    if (iClose(NULL, PERIOD_H1, 1) <= iOpen(NULL, PERIOD_H1, 1))
        return false;

    // Check MA cross (MA4 > MA10 > MA50)
    double MA4 = iMA(NULL, PERIOD_H1, 4, 0, MODE_SMA, PRICE_CLOSE, 0);
    double MA10 = iMA(NULL, PERIOD_H1, 10, 0, MODE_SMA, PRICE_CLOSE, 0);
    double MA50 = iMA(NULL, PERIOD_H1, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
    if (MA4 <= MA10 || MA10 <= MA50)
        return false;

    return true;
}

//+------------------------------------------------------------------+
//| Check Sell Conditions (Module 1)                                 |
//+------------------------------------------------------------------+
bool CheckSellConditions1()
{
    // Check 4H lower lows
    if (iLow(NULL, PERIOD_H4, 1) >= iLow(NULL, PERIOD_H4, 2))
        return false;

    // Check 1H bearish continuation
    if (iClose(NULL, PERIOD_H1, 1) >= iOpen(NULL, PERIOD_H1, 1))
        return false;

    // Check MA cross (MA4 < MA10 < MA50)
    double MA4 = iMA(NULL, PERIOD_H1, 4, 0, MODE_SMA, PRICE_CLOSE, 0);
    double MA10 = iMA(NULL, PERIOD_H1, 10, 0, MODE_SMA, PRICE_CLOSE, 0);
    double MA50 = iMA(NULL, PERIOD_H1, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
    if (MA4 >= MA10 || MA10 >= MA50)
        return false;

    return true;
}

//+------------------------------------------------------------------+
//| Open Trade (Module 1)                                            |
//+------------------------------------------------------------------+
void OpenTrade1(int OrderType)
{
    double SL = 0, TP1 = 0, TP2 = 0, TP3 = 0;
    double Price = (OrderType == OP_BUY) ? Ask : Bid;

    // Calculate stop loss and take profit levels
    if (OrderType == OP_BUY)
    {
        SL = Price - StopLossPips1 * Point;
        TP1 = Price + TakeProfit1_1 * Point;
        TP2 = Price + TakeProfit2_1 * Point;
        TP3 = Price + TakeProfit3_1 * Point;
    }
    else if (OrderType == OP_SELL)
    {
        SL = Price + StopLossPips1 * Point;
        TP1 = Price - TakeProfit1_1 * Point;
        TP2 = Price - TakeProfit2_1 * Point;
        TP3 = Price - TakeProfit3_1 * Point;
    }

    // Open the order
    int Ticket = OrderSend(Symbol(), OrderType, LotSize1, Price, Slippage1, SL, TP1, "BreakRetestEA", MagicNumber1, 0, clrNONE);

    if (Ticket > 0)
    {
        // Modify order to add additional take profit levels
        if (OrderSelect(Ticket, SELECT_BY_TICKET))
        {
            OrderModify(Ticket, OrderOpenPrice(), SL, TP2, 0, clrNONE);
            OrderModify(Ticket, OrderOpenPrice(), SL, TP3, 0, clrNONE);
        }
    }
}

//+------------------------------------------------------------------+
//| Open Trade (Module 2)                                            |
//+------------------------------------------------------------------+
void OpenTrade2(int cmd)
{
    int ticket = OrderSend(Symbol(), cmd, currentLotsize2, cmd == OP_BUY ? Ask : Bid, 3, 0, 0, "", MagicNumber2, 0, clrNONE);
    if (ticket < 0)
    {
        Print("Error opening trade: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Close All Trades (Module 2)                                      |
//+------------------------------------------------------------------+
void CloseAllTrades2(int cmd)
{
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == MagicNumber2 && OrderSymbol() == Symbol())
        {
            if (OrderType() == cmd)
            {
                double profit     = OrderProfit(); // Built-in function to check trade profit/loss
                OrderClose(OrderTicket(), OrderLots(), OrderType() == OP_BUY ? Bid : Ask, 3, clrNONE);
                                
                if(profit > 0) {
                    currentLotsize2 = LotSize2;
                } else if(profit < 0) {
                    currentLotsize2 *= MULT2;
                } else {
                    Print("Trade closed at break-even.");
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Count Trades (Module 2)                                          |
//+------------------------------------------------------------------+
int CountTrades2(int cmd)
{
    int count = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == MagicNumber2 && OrderSymbol() == Symbol())
        {
            if (OrderType() == cmd)
            {
                count++;
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Timer Function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    datetime currentTime = TimeCurrent();  // Get current server time
    int currentHour = Hour();
    int currentMinute = Minute();

    // Check if the current date is within range
    if (currentTime < START_DATE || currentTime > END_DATE)
    {
        Print("EA Has Expired. Stopping EA...");
        ExpertRemove();  // Quit EA
        return;
    }

    // Check if the current time is outside the allowed timeframe
    if (currentHour < START_HOUR || (currentHour == START_HOUR && currentMinute < START_MIN) ||
        currentHour > END_HOUR || (currentHour == END_HOUR && currentMinute >= END_MIN))
    {
        Print("EA Has Expired. Stopping EA...");
        ExpertRemove();  // Quit EA
        return;
    }
    
    // EA runs normally if within time range
    Print("EA is running. Current Time: ", TimeToString(currentTime, TIME_SECONDS));
    EventSetTimer(TIMER_INTERVAL);
}