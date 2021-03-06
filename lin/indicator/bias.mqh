//+------------------------------------------------------------------+
//|                                                         bias.mqh |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

int MAXBIAS = 1000; //当价格距离均线1000点以上时，认为价格偏离均线太远。

double calcBias(int base_ma_period)
{
    double ma = iMA(NULL, 0, base_ma_period, 0, MODE_LWMA, PRICE_CLOSE, 0);
    double delta = MathAbs(Close[0] - ma);
    double bias = delta / Point;
    Print("calcBias:bias ", bias, " delta ", delta, "   delta/Point ", delta / Point);
    return bias;
}

//通过比较价格与26均线的比率，既乖离率来判断是否偏离均线太远
//base_ma_period 作为基准的均线
bool isTooFar(int base_ma_period)
{
    int curBias = (int)calcBias(base_ma_period);

    Print("isTooFar:curBias ", curBias);
    if (curBias > MAXBIAS)
        return true;

    return false;
}
