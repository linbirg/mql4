//+------------------------------------------------------------------+
//|                                               tre_boll_trend.mq4 |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "linbirg"
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include "lin/core/array.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- create timer
    EventSetTimer(60);

    //---
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- destroy timer
    EventKillTimer();
}

TArraySerise<double> d_s_arr;

void test_arr_ser_shift()
{
    d_s_arr.set_max_size(100);
    Print("append befroe size:" + d_s_arr.size());
    for (int i = 0; i < 100; i++)
    {
        d_s_arr.append(i);
    }

    Print("append after size:" + d_s_arr.size());

    for (int i = 0; i < d_s_arr.size(); i++)
    {
        Print("index:" + i + " d_arr:" + d_s_arr[i]);
    }
}
// TArray<double> d_arr;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    test_arr_ser_shift();
    // d_arr.append(1);
    // Print("append befroe size:" + d_arr.size());
    // long tick = GetTickCount();
    // for (int i = 0; i < 100000; i++)
    // {
    //     d_arr.append(i);
    // }
    // tick = GetTickCount() - tick;
    // Print("TArray tick:" + tick);

    // tick = GetTickCount();
    // for (int i = 0; i < 100; i++)
    // {
    //     d_s_arr.append(i);
    // }
    // // tick = GetTickCount() - tick;
    // // Print("d_s_arr tick:" + tick);
    // // Print("d_s_arr[0]:" + d_s_arr[0]);

    // int size = d_s_arr.size();
    // Print("append after size:" + size);
    // for (int i = 99; i >= 0; i--)
    // {
    //     Print("index:" + (size - 1 - i) + " d_arr:" + d_s_arr[size - 1 - i]);
    // }
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    //---
}
//+------------------------------------------------------------------+
