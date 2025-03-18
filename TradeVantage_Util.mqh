#ifndef MY_HEADER_MQH
#define MY_HEADER_MQH

void RemoveIndicagtorsOnTester(){
    if (MQLInfoInteger(MQL_TESTER))
    {
        for (int i = 0; i < 100; i++)  // Remove all indicators from the chart
        {
            ChartIndicatorDelete(0, 0, i);
        }
    }
}

//--- EA 1 MA Dashboard 
//+------------------------------------------------------------------+
//| Dashboard Display for Trading Statistics                        |
//+------------------------------------------------------------------+
#property indicator_chart_window

// Define Colors
#define COLOR_BACKGROUND clrBlack
#define COLOR_TEXT clrWhite
#define COLOR_BUY clrLime
#define COLOR_SELL clrRed

//+------------------------------------------------------------------+
//| Function to Update Labels                                       |
//+------------------------------------------------------------------+
void UpdateLabel(string name, string text)
{
    ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
//| Custom Indicator Initialization                                 |
//+------------------------------------------------------------------+
int EA1_MA_OnInit()
{
    // Set the background
    ObjectCreate(0, "Dashboard_Background", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_XSIZE, 200);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_YSIZE, 150);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_COLOR, COLOR_BACKGROUND);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_STYLE, STYLE_SOLID);

    CreateLabel("Total Balance", 10, 10, COLOR_TEXT);
    CreateLabel("Total Equity", 10, 30, COLOR_TEXT);
    CreateLabel("Drawdown %", 10, 50, COLOR_TEXT);
    CreateLabel("Total Buy Trades", 10, 80, COLOR_BUY);
    CreateLabel("Total Sell Trades", 10, 100, COLOR_SELL);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnTick Function to Update Values                                |
//+------------------------------------------------------------------+
void EA1_MA_OnTickDashboard()
{
    double balance = AccountBalance();
    double equity = AccountEquity();
    double drawdown = 100.0 * (balance - equity) / balance;
    int buyTrades = CountTradesInPosition(OP_BUY);
    int sellTrades = CountTradesInPosition(OP_SELL);

    UpdateLabel("Total Balance", "Total Balance: " + DoubleToString(balance, 2));
    UpdateLabel("Total Equity", "Total Equity: " + DoubleToString(equity, 2));
    UpdateLabel("Drawdown %", "Drawdown: " + DoubleToString(drawdown, 2) + "%");
    UpdateLabel("Total Buy Trades", "Total Buy Trades: " + IntegerToString(buyTrades));
    UpdateLabel("Total Sell Trades", "Total Sell Trades: " + IntegerToString(sellTrades));
}

//+------------------------------------------------------------------+
//| Function to Create Labels                                       |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, color textColor)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
}

int CountTradesInPosition(int type)
{
    int count = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS) && OrderType() == type)
        {
            count++;
        }
    }
    return count;
}
//--- EA 1 MA Dashboard 

//--- EA 15Min R3 No Lines Revise Helper Functions 

//+------------------------------------------------------------------+
//| Get Trend Direction                                              |
//+------------------------------------------------------------------+
string GetTrendDirection()
  {
   double ma = iMA(NULL, 0, MovingPeriod, MovingShift, MODE_SMA, PRICE_CLOSE, 0);
   if(Close[1] > ma) return "Bullish";
   if(Close[1] < ma) return "Bearish";
   return "Neutral";
  }

//+------------------------------------------------------------------+
//| Update Profit Calculations                                       |
//+------------------------------------------------------------------+
void UpdateProfitCalculations()
  {
   datetime currentTime = TimeCurrent();
   if(lastDailyUpdate == 0 || TimeDay(currentTime) != TimeDay(lastDailyUpdate))
     {
      dailyProfit = 0.0;
      lastDailyUpdate = currentTime;
     }
   if(lastWeeklyUpdate == 0 || TimeDayOfWeek(currentTime) < TimeDayOfWeek(lastWeeklyUpdate))
     {
      weeklyProfit = 0.0;
      lastWeeklyUpdate = currentTime;
     }
   if(lastMonthlyUpdate == 0 || TimeMonth(currentTime) != TimeMonth(lastMonthlyUpdate))
     {
      monthlyProfit = 0.0;
      lastMonthlyUpdate = currentTime;
     }

   double profit = AccountBalance() - AccountCredit();
   dailyProfit += profit;
   weeklyProfit += profit;
   monthlyProfit += profit;
  }

//+------------------------------------------------------------------+
//| Trailing Stop Management                                         |
//+------------------------------------------------------------------+
void TrailingStopManagement()
  {
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(Bid-OrderOpenPrice()>TrailingStop*Point)
           {
            if(OrderStopLoss()<Bid-(TrailingStop+TrailingStep)*Point)
              {
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailingStop*Point,OrderTakeProfit(),0,clrNONE))
                  Print("OrderModify error ",GetLastError());
              }
           }
        }
      if(OrderType()==OP_SELL)
        {
         if(OrderOpenPrice()-Ask>TrailingStop*Point)
           {
            if(OrderStopLoss()>Ask+(TrailingStop+TrailingStep)*Point || OrderStopLoss()==0)
              {
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailingStop*Point,OrderTakeProfit(),0,clrNONE))
                  Print("OrderModify error ",GetLastError());
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Update lot size based on trade outcome                           |
//+------------------------------------------------------------------+
void UpdateLotSize(double profit)
  {
   if(profit < 0)
     {
      lossCount++;
      currentLots *= LotMultiplier;
     }
   else
     {
      lossCount = 0;
      currentLots = Lots;
     }
  }

//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void EAR3_CheckForClose()
  {
   double ma;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         // Close Buy trade if price is lower than previous low and multiplier is active
         if(lossCount > 0 && Bid < previousLow)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
            else
               UpdateLotSize(OrderProfit());
           }
         // Close Buy trade based on MA crossover
         else if(Open[1]>ma && Close[1]<ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
            else
               UpdateLotSize(OrderProfit());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         // Close Sell trade if price is higher than previous high and multiplier is active
         if(lossCount > 0 && Ask > previousHigh)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
            else
               UpdateLotSize(OrderProfit());
           }
         // Close Sell trade based on MA crossover
         else if(Open[1]<ma && Close[1]>ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
            else
               UpdateLotSize(OrderProfit());
           }
         break;
        }
     }
  }

void EAR3_CheckForOpen()
  {
   double ma;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell conditions
   if(Open[1]>ma && Close[1]<ma)
     {
      res=OrderSend(Symbol(),OP_SELL,currentLots,Bid,3,0,0,"",MAGICMA,0,Red);
      if(res<0)
         Print("Error opening SELL order: ",GetLastError());
      else
         previousHigh = High[1]; // Set previous high for Sell trade
      return;
     }
//--- buy conditions
   if(Open[1]<ma && Close[1]>ma)
     {
      res=OrderSend(Symbol(),OP_BUY,currentLots,Ask,3,0,0,"",MAGICMA,0,Blue);
      if(res<0)
         Print("Error opening BUY order: ",GetLastError());
      else
         previousLow = Low[1]; // Set previous low for Buy trade
      return;
     }
  }

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double EAR3_LotsOptimized()
  {
   double lot=currentLots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }

//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int EAR3_CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
#endif  