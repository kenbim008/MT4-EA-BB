//+------------------------------------------------------------------+
//|                                    BB Dual Entry EA v1.13 (Revised) |
//|                    Bollinger Bands Entry with Per-Side Martingale |
//|                            (Removed any \"dual-entry\" mode)      |
//+------------------------------------------------------------------+
#property copyright "BB Dual Entry Strategy"
#property link      ""
#property version   "1.13r"
#property strict

//--- Input Parameters
input string    Section1 = "========== Bollinger Bands Settings ==========";
input int       BB_Period = 50;                    // BB Period
input double    BB_Deviation = 2.0;                // BB Deviation
input int       BB_AppliedPrice = PRICE_CLOSE;     // BB Applied Price (int for MQL4)

input string    Section2 = "========== Trading Settings ==========";
input double    LotSize = 0.1;                     // Initial Lot Size
input bool      UseMartingale = true;              // Use Martingale (kept for UI backwards compat)
input bool      MartingaleOnEntry = true;          // Apply martingale sizing on every BB-triggered entry
input double    MartingaleMultiplier = 1.2;        // Martingale Multiplier
input double    MaxLotSize = 5.0;                 // Maximum Lot Size
input int       MagicNumber = 12345;               // Magic Number
input int       Slippage = 3;                      // Slippage

input string    Section3 = "========== Exit Method Selection ==========";
enum EXIT_METHOD
{
   EXIT_TP_SL_TS,    // TP/SL/Trailing Stop
   EXIT_BB_TOUCH,    // BB Touch Exit
   EXIT_BB_CLOSE     // BB Close Exit
};
input EXIT_METHOD ExitMethod = EXIT_BB_CLOSE;      // Exit Method

input string    Section4 = "========== Exit Settings (TP/SL/TS Method) ==========";
input double    TakeProfit = 500;                  // Take Profit (points)
input double    StopLoss = 300;                    // Stop Loss (points)
input bool      UseTrailingStop = true;            // Use Trailing Stop
input double    TrailingStop = 200;                // Trailing Stop (points)
input double    TrailingStep = 50;                 // Trailing Step (points)

input string    Section5 = "========== Exit Settings (BB Touch Method) ==========";
input bool      UseSL_BBTouch = true;              // Use Stop Loss with BB Touch
input double    StopLoss_BBTouch = -1000000;            // Stop Loss for BB Touch Method (points)

input string    Section6 = "========== Exit Settings (BB Close Method) ==========";
input bool      UseSL_BBClose = true;              // Use Stop Loss with BB Close
input double    StopLoss_BBClose = -1000000;            // Stop Loss for BB Close Method (points)

input string    Section7 = "========== Trend Identification ==========";
input int       TrendMA_Period = 50;               // Trend MA Period
input int       TrendMA_Method = MODE_SMA;         // Trend MA Method (int for MQL4)
input int       TrendMA_AppliedPrice = PRICE_CLOSE;// Trend MA Applied Price
input double    SidewaysThreshold = 0.0005;        // Sideways Threshold (price range)
input int       TrendLookback = 10;                // Trend Lookback Bars

input string    Section8 = "========== Dashboard Settings ==========";
input bool      ShowDashboard = true;              // Show Dashboard
input int       Dashboard_X = 20;                  // Dashboard X Position
input int       Dashboard_Y = 30;                  // Dashboard Y Position
input color     Dashboard_Color = clrWhite;        // Dashboard Text Color
input color     Dashboard_TitleColor = clrYellow;  // Dashboard Title Color
input int       Dashboard_FontSize = 9;            // Dashboard Font Size
input string    Dashboard_Font = "Arial";          // Dashboard Font

//--- Global Variables
datetime lastBarTime = 0;
int totalBuyOrders = 0;
int totalSellOrders = 0;
double totalProfit = 0;
double totalLoss = 0;
string currentTrend = "Sideways";
double currentBuyLot = 0;   // Current lot size for buy orders
double currentSellLot = 0;  // Current lot size for sell orders

// Forward declarations
double CalculateLotSize(int orderType);
double NormalizeLot(double lot);
void CheckBBCloseExit();
void CheckBBTouchExit();
void ApplyTrailingStop();
string IdentifyTrend();
void CreateDashboard();
void UpdateDashboard();
void RemoveDashboard();
void OpenOrder(int orderType, string signal);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   currentBuyLot = LotSize;
   currentSellLot = LotSize;
   if(ShowDashboard) CreateDashboard();
   lastBarTime = Time[0];
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   RemoveDashboard();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Tick-level actions if same bar
   if(Time[0] == lastBarTime)
   {
      if(ExitMethod == EXIT_BB_TOUCH) CheckBBTouchExit();
      if(ExitMethod == EXIT_TP_SL_TS && UseTrailingStop) ApplyTrailingStop();
      if(ShowDashboard) UpdateDashboard();
      return;
   }

   // New bar
   lastBarTime = Time[0];

   double upperBB = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_AppliedPrice, MODE_UPPER, 1);
   double lowerBB = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_AppliedPrice, MODE_LOWER, 1);
   double closePrice = Close[1];

   currentTrend = IdentifyTrend();

   if(ExitMethod == EXIT_BB_CLOSE) CheckBBCloseExit();

   // Entry logic (single-side entries only):
   // SELL when the bar closed above upperBB
   if(closePrice > upperBB)
      OpenOrder(OP_SELL, "UpperBB");

   // BUY when the bar closed below lowerBB
   if(closePrice < lowerBB)
      OpenOrder(OP_BUY, "LowerBB");

   if(ShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Calculate Lot Size with Martingale applied on every BB entry    |
//+------------------------------------------------------------------+
double CalculateLotSize(int orderType)
{
   double newLot = LotSize;

   // Use MartingaleOnEntry when deciding to apply martingale on each BB entry
   bool applyMartingale = MartingaleOnEntry;

   // Find last closed order (history) of this type for this symbol and magic
   datetime lastCloseTime = 0;
   double lastClosedLot = 0;

   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == orderType)
         {
            if(OrderCloseTime() > lastCloseTime)
            {
               lastCloseTime = OrderCloseTime();
               lastClosedLot = OrderLots();
            }
         }
      }
   }

   if(lastCloseTime > 0)
   {
      if(applyMartingale)
         newLot = lastClosedLot * MartingaleMultiplier;
      else
         newLot = lastClosedLot;
   }
   else
   {
      // No historical same-side trades. Check open trades of same side and same magic.
      bool foundOpen = false;
      for(int j = OrdersTotal() - 1; j >= 0; j--)
      {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == orderType)
            {
               if(applyMartingale)
                  newLot = OrderLots() * MartingaleMultiplier;
               else
                  newLot = OrderLots();
               foundOpen = true;
               break;
            }
         }
      }
      if(!foundOpen)
      {
         // No history and no open orders. Use base lot (initial).
         newLot = LotSize;
      }
   }

   // Cap and normalize
   if(newLot > MaxLotSize) newLot = MaxLotSize;
   return NormalizeLot(newLot);
}

//+------------------------------------------------------------------+
//| Normalize Lot Size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;
   if(lotStep <= 0.0) return NormalizeDouble(lot,2);

   double steps = MathRound(lot / lotStep);
   lot = steps * lotStep;
   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;
   return NormalizeDouble(lot,2);
}

//+------------------------------------------------------------------+
//| Open Single Order (Buy or Sell)                                  |
//+------------------------------------------------------------------+
void OpenOrder(int orderType, string signal)
{
   double price = (orderType == OP_BUY) ? Ask : Bid;
   double point = Point;
   if(Point == 0.00001 || Point == 0.001) point = Point * 10;

   // Calculate lot size with martingale-per-entry control
   double lotSize = CalculateLotSize(orderType);

   double tp = 0;
   double sl = 0;

   if(ExitMethod == EXIT_TP_SL_TS)
   {
      if(orderType == OP_BUY)
      {
         tp = (TakeProfit > 0) ? price + TakeProfit * point : 0;
         sl = (StopLoss > 0)     ? price - StopLoss * point   : 0;
      }
      else
      {
         tp = (TakeProfit > 0) ? price - TakeProfit * point : 0;
         sl = (StopLoss > 0)     ? price + StopLoss * point   : 0;
      }
   }
   else if(ExitMethod == EXIT_BB_TOUCH)
   {
      tp = 0;
      if(orderType == OP_BUY)
         sl = (UseSL_BBTouch && StopLoss_BBTouch > 0) ? price - StopLoss_BBTouch * point : 0;
      else
         sl = (UseSL_BBTouch && StopLoss_BBTouch > 0) ? price + StopLoss_BBTouch * point : 0;
   }
   else if(ExitMethod == EXIT_BB_CLOSE)
   {
      tp = 0;
      if(orderType == OP_BUY)
         sl = (UseSL_BBClose && StopLoss_BBClose > 0) ? price - StopLoss_BBClose * point : 0;
      else
         sl = (UseSL_BBClose && StopLoss_BBClose > 0) ? price + StopLoss_BBClose * point : 0;
   }

   string orderTypeText = (orderType == OP_BUY) ? "Buy" : "Sell";
   color orderColor = (orderType == OP_BUY) ? clrBlue : clrRed;

   int ticket = OrderSend(Symbol(), orderType, lotSize, price, Slippage, sl, tp,
                          "BB " + orderTypeText + " " + signal, MagicNumber, 0, orderColor);

   if(ticket > 0)
   {
      Print(orderTypeText, " order opened: ", ticket, " Lot: ", DoubleToString(lotSize,2));
      if(orderType == OP_BUY) currentBuyLot = lotSize; else currentSellLot = lotSize;
   }
   else
   {
      int err = GetLastError();
      Print("Error opening ", orderTypeText, " order: ", err);
      ResetLastError();
   }
}

//+------------------------------------------------------------------+
//| Check for BB Touch Exit                                          |
//+------------------------------------------------------------------+
void CheckBBTouchExit()
{
   double upperBB = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_AppliedPrice, MODE_UPPER, 0);
   double lowerBB = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_AppliedPrice, MODE_LOWER, 0);

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(OrderType() == OP_BUY && Bid >= upperBB)
            {
               if(!OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrGreen))
                  Print("Error closing Buy order at Upper BB: ", GetLastError());
            }
            else if(OrderType() == OP_SELL && Ask <= lowerBB)
            {
               if(!OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrGreen))
                  Print("Error closing Sell order at Lower BB: ", GetLastError());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check for BB Close Exit (on bar close)                           |
//+------------------------------------------------------------------+
void CheckBBCloseExit()
{
   double upperBB = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_AppliedPrice, MODE_UPPER, 1);
   double lowerBB = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_AppliedPrice, MODE_LOWER, 1);
   double closePrice = Close[1];

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(OrderType() == OP_BUY && closePrice >= upperBB)
            {
               if(!OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrGreen))
                  Print("Error closing Buy order on BB close: ", GetLastError());
            }
            else if(OrderType() == OP_SELL && closePrice <= lowerBB)
            {
               if(!OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrGreen))
                  Print("Error closing Sell order on BB close: ", GetLastError());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop to open positions                            |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
   double point = Point;
   if(Point == 0.00001 || Point == 0.001) point = Point * 10;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(OrderType() == OP_BUY)
            {
               double newSL = Bid - TrailingStop * point;
               if((OrderStopLoss() == 0 || newSL > OrderStopLoss() + TrailingStep * point) && newSL > OrderStopLoss())
               {
                  if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrBlue))
                     Print("Failed modify Buy SL: ", GetLastError());
               }
            }
            else if(OrderType() == OP_SELL)
            {
               double newSL = Ask + TrailingStop * point;
               if((OrderStopLoss() == 0 || newSL < OrderStopLoss() - TrailingStep * point) && (OrderStopLoss() == 0 || newSL < OrderStopLoss()))
               {
                  if(!OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed))
                     Print("Failed modify Sell SL: ", GetLastError());
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Identify Market Trend                                            |
//+------------------------------------------------------------------+
string IdentifyTrend()
{
   double ma_current  = iMA(Symbol(), 0, TrendMA_Period, 0, TrendMA_Method, TrendMA_AppliedPrice, 0);
   double ma_previous = iMA(Symbol(), 0, TrendMA_Period, 0, TrendMA_Method, TrendMA_AppliedPrice, TrendLookback);

   double highestHigh = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, TrendMA_Period, 0));
   double lowestLow   = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, TrendMA_Period, 0));
   double priceRange = highestHigh - lowestLow;

   if(priceRange < SidewaysThreshold) return "Sideways";
   if(ma_current > ma_previous && Close[0] > ma_current) return "Up";
   if(ma_current < ma_previous && Close[0] < ma_current) return "Down";
   return "Sideways";
}

//+------------------------------------------------------------------+
//| Create Dashboard Objects                                         |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   string labels[] = {"Title", "ExitMethod", "Martingale", "Equity", "Balance", "BuyOrders", "SellOrders", "Profit", "Loss", "Trend"};

   for(int i = 0; i < ArraySize(labels); i++)
   {
      string objName = "Dashboard_" + labels[i];
      // Remove if exists
      if(ObjectFind(objName) != -1) ObjectDelete(objName);
      // Create label (time1/price1 not used for OBJ_LABEL)
      ObjectCreate(objName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(objName, OBJPROP_XDISTANCE, Dashboard_X);
      ObjectSet(objName, OBJPROP_YDISTANCE, Dashboard_Y + i * 18);
      ObjectSet(objName, OBJPROP_FONTSIZE, Dashboard_FontSize);
      // color set below via ObjectSetText since some builds ignore OBJPROP_COLOR for text labels
      ObjectSetText(objName, "", Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
      if(labels[i] == "Title")
         ObjectSet(objName, OBJPROP_COLOR, Dashboard_TitleColor);
      else
         ObjectSet(objName, OBJPROP_COLOR, Dashboard_Color);
   }
}

//+------------------------------------------------------------------+
//| Update Dashboard Information                                     |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   totalBuyOrders = 0; totalSellOrders = 0; totalProfit = 0; totalLoss = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(OrderType() == OP_BUY) totalBuyOrders++;
            else if(OrderType() == OP_SELL) totalSellOrders++;
            double pl = OrderProfit() + OrderSwap() + OrderCommission();
            if(pl > 0) totalProfit += pl; else totalLoss += pl;
         }
      }
   }

   string exitMethodText = (ExitMethod == EXIT_TP_SL_TS) ? "TP/SL/TS" : (ExitMethod == EXIT_BB_TOUCH ? "BB Touch" : "BB Close");
   string martingaleText = MartingaleOnEntry ? "ON (per-entry x" + DoubleToString(MartingaleMultiplier,2) + ")" : "OFF";

   // Update text. ObjectSetText handles color per-label.
   ObjectSetText("Dashboard_Title", "=== BB ENTRY DASHBOARD ===", Dashboard_FontSize, Dashboard_Font, Dashboard_TitleColor);
   ObjectSetText("Dashboard_ExitMethod", "Exit Method: " + exitMethodText, Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
   ObjectSetText("Dashboard_Martingale", "Martingale: " + martingaleText, Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
   ObjectSetText("Dashboard_Equity", "Equity: " + DoubleToString(AccountEquity(),2), Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
   ObjectSetText("Dashboard_Balance", "Balance: " + DoubleToString(AccountBalance(),2), Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
   ObjectSetText("Dashboard_BuyOrders", "Buy Orders: " + IntegerToString(totalBuyOrders), Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
   ObjectSetText("Dashboard_SellOrders", "Sell Orders: " + IntegerToString(totalSellOrders), Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
   ObjectSetText("Dashboard_Profit", "Profit: " + DoubleToString(totalProfit,2), Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
   ObjectSetText("Dashboard_Loss", "Loss: " + DoubleToString(totalLoss,2), Dashboard_FontSize, Dashboard_Font, Dashboard_Color);
   ObjectSetText("Dashboard_Trend", "Trend: " + currentTrend, Dashboard_FontSize, Dashboard_Font, Dashboard_Color);

   // Ensure trend color via OBJPROP_COLOR too (some builds respect it)
   color trendCol = clrYellow;
   if(currentTrend == "Up") trendCol = clrLime;
   else if(currentTrend == "Down") trendCol = clrRed;
   ObjectSet("Dashboard_Trend", OBJPROP_COLOR, trendCol);
}

//+------------------------------------------------------------------+
//| Remove Dashboard Objects                                         |
//+------------------------------------------------------------------+
void RemoveDashboard()
{
   string labels[] = {"Title","ExitMethod","Martingale","Equity","Balance","BuyOrders","SellOrders","Profit","Loss","Trend"};
   for(int i = 0; i < ArraySize(labels); i++)
   {
      string name = "Dashboard_" + labels[i];
      if(ObjectFind(name) != -1) ObjectDelete(name);
   }
}
//+------------------------------------------------------------------+
