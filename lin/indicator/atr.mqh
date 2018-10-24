//+------------------------------------------------------------------+
//|                                                          atr.mqh |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

double MultipleATR = 5;

int ATRPeriod = 14;

double calcATR()
{
    return MultipleATR * iATR(NULL, 0, ATRPeriod, 0);
}
