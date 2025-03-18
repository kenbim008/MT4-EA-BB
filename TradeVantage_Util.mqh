#ifndef MY_HEADER_MQH
#define MY_HEADER_MQH

#define  DEBUG 1
void RemoveIndicagtorsOnTester(){
    if (MQLInfoInteger(MQL_TESTER))
    {
        for (int i = 0; i < 100; i++)  // Remove all indicators from the chart
        {
            ChartIndicatorDelete(0, 0, i);
        }
        if(DEBUG){
            Print("Indicators Removed");
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
    long userAccountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
    if(userAccountNumber != ACCOUNT_NUMBER && ACCOUNT_NUMBER != 0){
        Print("This EA is not authorized to run on this account. Please contact the Adminsitrator.");
        return(INIT_FAILED);
    }
    EventSetTimer(TIMER_INTERVAL);
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

#endif  