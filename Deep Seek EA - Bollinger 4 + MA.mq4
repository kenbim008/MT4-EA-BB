//+------------------------------------------------------------------+
//|                                                      BB_MA_EA.mq4|
//|                        Generated by MetaEditor                   |
//|                                                                  |
//+------------------------------------------------------------------+
#property strict

// Input parameters
input double LotSize = 0.1;                // Lot size
input int BBPeriod = 20;                   // Bollinger Bands period
input double BBDeviation = 2.0;            // Bollinger Bands deviation
input int FastMAPeriod = 10;               // Fast Moving Average period
input int SlowMAPeriod = 20;               // Slow Moving Average period
input int MagicNumber = 123456;            // Magic number for trades
input int Slippage = 3;                    // Slippage in points
input int StopLoss = 50;                   // Stop loss in points
input int TakeProfit = 100;                // Take profit in points
input long AllowedAccountNumber = 0;       // Allowed account number (0 = any account)
input int MaxTradesPerCandleBuy = 1;       // Maximum buy trades per candle
input int MaxTradesPerCandleSell = 1;      // Maximum sell trades per candle
input int BackTrack = 10;                  // How many candles to consider for average trend 

// Global variables
int LastCrossDirection = 0;                // 0 = No cross, 1 = Up, -1 = Down
datetime LastTradeTime = 0;                // Time of the last candle
int BuyTradesThisCandle = 0;               // Number of buy trades executed this candle
int SellTradesThisCandle = 0;              // Number of sell trades executed this candle
int wTradeDuration = 0;                    // Average time for a winning trade
int lTradeDuration = 0;                     // Average time for a Loosing trade
int numWinTrades = 0;                      // Total profitable trades made 
int numLosTrades = 0;                      // Total negative trades made 
bool timerStarted = false;

#define DEBUG  1

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Check if the EA is allowed to run on this account
    if (AllowedAccountNumber != 0 && AccountNumber() != AllowedAccountNumber)
      {
      Alert("EA is not allowed to run on this account. Allowed account: ", AllowedAccountNumber);
      return(INIT_FAILED);
      }
      if (DEBUG){
        CreateTradeDurationLabels();
      }
    return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Deinitialization code
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Check if the EA is allowed to run on this account
   if (AllowedAccountNumber != 0 && AccountNumber() != AllowedAccountNumber)
     {
      return; // Exit if the account number does not match
     }

   // Get the current candle time
   datetime CurrentCandleTime = iTime(NULL, 0, 0);

   // Reset trade counters if a new candle has started
   if (CurrentCandleTime != LastTradeTime)
     {
      BuyTradesThisCandle = 0;
      SellTradesThisCandle = 0;
      LastTradeTime = CurrentCandleTime;
     }

   // Get Bollinger Bands values
   double MiddleBand = iBands(NULL, 0, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_MAIN, 0);
   double UpperBand = iBands(NULL, 0, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double LowerBand = iBands(NULL, 0, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, 0);

   // Get Moving Average values
   double FastMA = iMA(NULL, 0, FastMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
   double SlowMA = iMA(NULL, 0, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);

   // Get current price
   double CurrentPrice = Close[0];

   // Check for Bollinger Bands cross conditions
   bool BB_BuySignal = (CurrentPrice > MiddleBand && LastCrossDirection != 1);
   bool BB_SellSignal = (CurrentPrice < MiddleBand && LastCrossDirection != -1);

   // Check for Moving Average crossover conditions
   bool MA_BuySignal = (FastMA > SlowMA);
   bool MA_SellSignal = (FastMA < SlowMA);

   // Execute trades only if both strategies agree
   if (BB_BuySignal && MA_BuySignal && BuyTradesThisCandle < MaxTradesPerCandleBuy && getTrend())
     {
      // Price crossed middle band going up and Fast MA is above Slow MA
      LastCrossDirection = 1;
      OpenTrade(OP_BUY);
      BuyTradesThisCandle++; // Increment buy trade counter
     }
   else if (BB_SellSignal && MA_SellSignal && SellTradesThisCandle < MaxTradesPerCandleSell && getTrend() == 0)
     {
      // Price crossed middle band going down and Fast MA is below Slow MA
      LastCrossDirection = -1;
      OpenTrade(OP_SELL);
      SellTradesThisCandle++; // Increment sell trade counter
     }
    if (numWinTrades + numLosTrades > OrdersHistoryTotal()){
      TradeTransaction();
    }
  }
//+------------------------------------------------------------------+
//| Function to open a trade                                         |
//+------------------------------------------------------------------+
void OpenTrade(int OrderType)
  {
   double SL = 0;
   double TP = 0;

   if (OrderType == OP_BUY)
     {
      SL = Bid - StopLoss * Point;
      TP = Bid + TakeProfit * Point;
     }
   else if (OrderType == OP_SELL)
     {
      SL = Ask + StopLoss * Point;
      TP = Ask - TakeProfit * Point;
     }

   int Ticket = OrderSend(Symbol(), OrderType, LotSize, (OrderType == OP_BUY ? Ask : Bid), Slippage, SL, TP, "BB_MA_EA", MagicNumber, 0, (OrderType == OP_BUY ? clrBlue : clrRed));

   if (Ticket < 0)
     {
      Print("Error opening order: ", GetLastError());
     }
  }
//+------------------------------------------------------------------+

int getTrend(){
  double middleBand[100];
  double average = 0;
  for (int i = 0; i<BackTrack; i++){
    middleBand[i] = iBands(NULL, 0, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_MAIN, i);
    average += middleBand[i];
  }
  average = average/BackTrack;
  if(average>middleBand[BackTrack-1])
    return 1;
  else return 0;
   
}

//+------------------------------------------------------------------+
//| Handles trade transactions                                       |
//+------------------------------------------------------------------+
void TradeTransaction()
{
  if (OrderSelect(OrdersHistoryTotal() - 1, SELECT_BY_POS, MODE_HISTORY))
  {
      if (OrderCloseTime() > 0)
      {
          Print("Trade closed. Ticket: ", OrderTicket());
          int duration = CalculateTradeDuration(OrderTicket());
          int tradeTime;
          if (OrderProfit() > 0){
              tradeTime = wTradeDuration * numWinTrades + duration;
              numWinTrades += 1;
              wTradeDuration = tradeTime / numWinTrades;
          }
          else{
              tradeTime = lTradeDuration * numLosTrades + duration;
              numLosTrades += 1;
              lTradeDuration = tradeTime / numLosTrades;
          }
          if (DEBUG)
          {
              UpdateTradeDurationDisplay();
          }
          if (!timerStarted && (numWinTrades + numLosTrades) >= 10)
          {
              Print("Starting Timer for ", wTradeDuration, " seconds");
              EventSetTimer(wTradeDuration);  // Start the timer
              timerStarted = true;
          }
      }
  }

}

//+------------------------------------------------------------------+
//| Function to calculate the time in seconds between open & close   |
//+------------------------------------------------------------------+
int CalculateTradeDuration(int ticket)
{
    // Select the order using the ticket number
    if (OrderSelect(ticket, SELECT_BY_TICKET))
    {
      datetime openTime = OrderOpenTime();
      datetime closeTime = OrderCloseTime();
      return (int)(closeTime - openTime);  // Calculate duration in seconds
    }
    else
    {
        Print("Error retrieving trade history for ticket: ", ticket);
        return 0;
    }
}

void CreateTradeDurationLabels()
{
    // Winning Trade Duration Label
    if (ObjectFind("WinDurationLabel") == -1) // Check if label exists
    {
        // Create the label if it doesn't exist
        ObjectCreate("WinDurationLabel", OBJ_LABEL, 0, 0, 0);
        
        // Set label properties
        ObjectSetInteger(0, "WinDurationLabel", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, "WinDurationLabel", OBJPROP_YDISTANCE, 20);
        ObjectSetInteger(0, "WinDurationLabel", OBJPROP_COLOR, clrGreen); // Green color for winning duration
        ObjectSetInteger(0, "WinDurationLabel", OBJPROP_FONTSIZE, 12);
        ObjectSetString(0, "WinDurationLabel", OBJPROP_TEXT, "Winning Trade Duration: 0 sec");
    }

    // Losing Trade Duration Label
    if (ObjectFind("LossDurationLabel") == -1) // Check if label exists
    {
        // Create the label if it doesn't exist
        ObjectCreate("LossDurationLabel", OBJ_LABEL, 0, 0, 0);
        
        // Set label properties
        ObjectSetInteger(0, "LossDurationLabel", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, "LossDurationLabel", OBJPROP_YDISTANCE, 40);
        ObjectSetInteger(0, "LossDurationLabel", OBJPROP_COLOR, clrRed); // clrRed color for losing duration
        ObjectSetInteger(0, "LossDurationLabel", OBJPROP_FONTSIZE, 12);
        ObjectSetString(0, "LossDurationLabel", OBJPROP_TEXT, "Losing Trade Duration: 0 sec");
    }
}


void UpdateTradeDurationDisplay()
{
    ObjectSetString(0, "WinDurationLabel", OBJPROP_TEXT, "Winning Trade Duration (AVG): " + IntegerToString(wTradeDuration) + " sec");
    ObjectSetString(0, "LossDurationLabel", OBJPROP_TEXT, "Losing Trade Duration (AVG): " + IntegerToString(lTradeDuration) + " sec");
}


//+------------------------------------------------------------------+
//| Close Loosing trades that have been open for "too long"          |
//+------------------------------------------------------------------+
void OnTimer()
{
    Print("Timer expired. Checking for long open trades...");

    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            datetime openTime = OrderOpenTime();
            int tradeAge = int(TimeCurrent() - openTime); // Explicitly cast the result to int (seconds)
            if (tradeAge > wTradeDuration*2) // Trade has been open longer than wTradeDuration
            {
                Print("Closing trade: ", OrderTicket(), " Open for: ", tradeAge, " seconds");
                CloseTrade(OrderTicket());
            }
        }
    }
    
    // Stop the timer to avoid repeated execution
    EventKillTimer();
    timerStarted = false;
}

// Function to close a trade based on its ticket number
void CloseTrade(int ticket)
{
    // Ensure the order is selected by ticket
    if (OrderSelect(ticket, SELECT_BY_TICKET)){
        double closePrice = 0;
        int slippage = 3;  // Adjust slippage as needed
        double lotSize = OrderLots();  // Get the order lot size
        if (OrderType() == OP_BUY){
            closePrice = Bid; 
        }
        else if (OrderType() == OP_SELL){
            closePrice = Ask; 
        }
        else {
            Print("Unknown order type, unable to close ticket: ", ticket);
            return;
        }
        bool result = OrderClose(ticket, lotSize, closePrice, slippage, clrNONE);
        if (result){
            Print("Trade closed successfully: ", ticket);
        }
        else{
            int errorCode = GetLastError();
            Print("Error closing trade: ", ticket, " Error code: ", errorCode);
        }
    }
    else
    {
        Print("Failed to select order with ticket: ", ticket, " Error code: ", GetLastError());
    }
}