#ifndef TRADE_VANTAGE_UTIL_H
#define TRADE_VANTAGE_UTIL_H

#define DEBUG 0
    
void RemoveIndicagtorsOnTester(){
    if (MQLInfoInteger(MQL_TESTER))
    {
        for (int i = 0; i < 100; i++)  // Remove all indicators from the chart
        {
            ChartIndicatorDelete(0, 0, (string)i);
        }
        if(DEBUG){
            Print("Indicators Removed");
        }
    }

}

#ifdef MA_1_EA_H

#define ACCOUNT_NUMBER 0
#define TIMER_INTERVAL 300

int TOTALBUY_trades = 0; 
int TOTALSELL_trades = 0; 
double  TOTALDAY_profit = 0;
double TOTALMONTH_profit = 0;
double TOTALWEEK_profit = 0;

int CURRENT_DAY = 0;
int CURRENT_MONTH = 0;
int CURRENT_WEEK = 0;




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
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_XDISTANCE, 0);  // Set X position to 0 (top-left)
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_YDISTANCE, 20);  // Set Y position to 0 (top-left)
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_XSIZE, 160);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_YSIZE, 200);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_COLOR, C'22,27,27');
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_BGCOLOR,C'22,27,27');
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, "Dashboard_Background", OBJPROP_STYLE, STYLE_SOLID);

    CreateLabel("Total Balance", 10, 30, COLOR_TEXT);
    CreateLabel("Total Equity", 10, 50, COLOR_TEXT);
    CreateLabel("Drawdown %", 10, 70, COLOR_TEXT);
    ObjectCreate(0, "Separator1", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "Separator1", OBJPROP_XDISTANCE, 0);  // Set X position to 0 (top-left)
    ObjectSetInteger(0, "Separator1", OBJPROP_YDISTANCE, 90);  // Set Y position to 0 (top-left)
    ObjectSetInteger(0, "Separator1", OBJPROP_XSIZE, 160);
    ObjectSetInteger(0, "Separator1", OBJPROP_YSIZE, 5);
    ObjectSetInteger(0, "Separator1", OBJPROP_COLOR, C'22,27,27');
    ObjectSetInteger(0, "Separator1", OBJPROP_BGCOLOR,C'22,27,27');
    ObjectSetInteger(0, "Separator1", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, "Separator1", OBJPROP_STYLE, STYLE_SOLID);
    CreateLabel("Total Buy Trades", 10, 100, COLOR_BUY);
    CreateLabel("Total Sell Trades", 10, 120, COLOR_SELL);
    ObjectCreate(0, "Separator2", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "Separator2", OBJPROP_XDISTANCE, 0);  // Set X position to 0 (top-left)
    ObjectSetInteger(0, "Separator2", OBJPROP_YDISTANCE, 140);  // Set Y position to 0 (top-left)
    ObjectSetInteger(0, "Separator2", OBJPROP_XSIZE, 160);
    ObjectSetInteger(0, "Separator2", OBJPROP_YSIZE, 5);
    ObjectSetInteger(0, "Separator2", OBJPROP_COLOR, C'22,27,27');
    ObjectSetInteger(0, "Separator2", OBJPROP_BGCOLOR,C'22,27,27');
    ObjectSetInteger(0, "Separator2", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, "Separator2", OBJPROP_STYLE, STYLE_SOLID);
    CreateLabel("This Day's Profit", 10, 150, COLOR_TEXT);
    CreateLabel("This Week's Profit", 10, 170, COLOR_TEXT);
    CreateLabel("This Month's Profit", 10, 190, COLOR_TEXT);


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
    

    string totalBalanceText = "Total Balance: " + StringFormat("%-20s", DoubleToString(balance, 2));
    string totalEquityText = "Total Equity: " + StringFormat("%-20s", DoubleToString(equity, 2));
    string drawdownText = "Drawdown: " + StringFormat("%-20s", DoubleToString(drawdown, 2) + "%");
    string totalBuyTradesText = "Total Buy Trades: " + StringFormat("%-20s", IntegerToString(TOTALBUY_trades));
    string totalSellTradesText = "Total Sell Trades: " + StringFormat("%-20s", IntegerToString(TOTALSELL_trades));
    string totalProfitText = "This Day's Profit: " + StringFormat("%-20s", DoubleToString(TOTALDAY_profit, 2));
    string totalProfitTextWeek = "This Week's Profit: " + StringFormat("%-20s", DoubleToString(TOTALWEEK_profit, 2));
    string totalProfitTextMonth = "This Month's Profit: " + StringFormat("%-20s", DoubleToString(TOTALMONTH_profit, 2));
    // Update each label
    UpdateLabel("Total Balance", totalBalanceText);
    UpdateLabel("Total Equity", totalEquityText);
    UpdateLabel("Drawdown %", drawdownText);
    UpdateLabel("Total Buy Trades", totalBuyTradesText);
    UpdateLabel("Total Sell Trades", totalSellTradesText);
    UpdateLabel("This Day's Profit", totalProfitText);
    UpdateLabel("This Week's Profit",totalProfitTextWeek);
    UpdateLabel("This Month's Profit", totalProfitTextMonth);
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

int countTotalProfits(){
    // Get the most recent closed trade from the history
    int totalOrders = OrdersHistoryTotal();
    
    if (totalOrders > 0)
    {
        // Select the most recent closed trade
        if (OrderSelect(totalOrders - 1, SELECT_BY_POS, MODE_HISTORY))
        {
            // Check if the order is a valid buy or sell trade
            if (OrderType() == OP_BUY || OrderType() == OP_SELL)
            {
                // Get the profit of the most recently closed trade
                double profit = OrderProfit();
                
                // Get the time of the most recent trade closure
                datetime closeTime = OrderCloseTime();
                
                MqlDateTime closeStruct;
                TimeToStruct(closeTime, closeStruct);
                
                int closeDay = closeStruct.day;
                int closeMonth = closeStruct.mon;
                int closeWeek = (closeStruct.day_of_year / 7) + 1;
                
                // Add profit to the respective day, month, or week
                if (closeDay == CURRENT_DAY) {
                    TOTALDAY_profit += profit;
                } else {
                    TOTALDAY_profit = profit; // Reset to today's profit
                }
                
                if (closeMonth == CURRENT_MONTH) {
                    TOTALMONTH_profit += profit;
                } else {
                    TOTALMONTH_profit = profit; // Reset to this month's profit
                }
                
                if (closeWeek == CURRENT_WEEK) {
                    TOTALWEEK_profit += profit;
                } else {
                    TOTALWEEK_profit = profit; // Reset to this week's profit
                }
                
            }
        }
    }
    
    return 0; 
}
void UpdateDateValues() {
    // Get the current time
    datetime currentTime = TimeCurrent();
    
    // Extract the day, month, and year from the current time
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    int currentDay = timeStruct.day;
    int currentMonth = timeStruct.mon;
    int currentWeek = (timeStruct.day_of_year / 7) + 1;

    // Check if the current day is different from the stored day
    if (currentDay != CURRENT_DAY) {
        CURRENT_DAY = currentDay;
        // Optionally reset the profit for the new day
        TOTALDAY_profit = 0;
    }

    // Check if the current month is different from the stored month
    if (currentMonth != CURRENT_MONTH) {
        CURRENT_MONTH = currentMonth;
        // Optionally reset the profit for the new month
        TOTALMONTH_profit = 0;
    }

    // Check if the current week is different from the stored week
    if (currentWeek != CURRENT_WEEK) {
        CURRENT_WEEK = currentWeek;
        // Optionally reset the profit for the new week
        TOTALWEEK_profit = 0;
    }
}



#endif  //MA_1_EA_H
#endif  //TRADE_VANTAGE_UTIL_H