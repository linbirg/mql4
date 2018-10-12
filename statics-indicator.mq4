//+------------------------------------------------------------------+
//|                                               tre_boll_trend.mq4 |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "linbirg"
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include "lin/chart/chart.mqh"
#include "lin/indicator/boll.mqh"

HistogramChart chart;
Boll5M boll5m;
Boll15M boll15m;
Boll1H boll1h;
Boll4H boll4h;
Boll1D boll1d;

// Boll *p_boll = NULL;

IndicatorMetrix mtrx;

input int period = 15;
input int indicator = 1; // 1 up 2 mid 3 low 4 band
input int statics = 1;   // 1 indicator 2 ma 3 std 4 speed 5 speed ma 6 speed std 7 acc 8 acc ma 9 acc std
input int x = 10;
input double y_min = 0;
input double y_max = 0;
// input int len = 50;
input bool flag = false; //true to use manual set.

void set_chart()
{
    chart.setZero(x, y_min);
    chart.setY2(y_max);
}

IndicatorArrayGroup *get_indicator()
{
    IndicatorArrayGroup *pInd = NULL;
    Boll *p_boll = get_boll_by_period();

    if (indicator == 1)
    {
        pInd = p_boll.getUpperIndicator();
    }
    else if (indicator == 2)
    {
        pInd = p_boll.getMainIndicator();
    }
    else if (indicator == 3)
    {
        pInd = p_boll.getLowerIndicator();
    }
    else
    {
        pInd = p_boll.getBandIndicator();
    }

    return pInd;
}

void get_indicator_data(IndicatorArrayGroup *const pInd, double &dist[])
{
    switch (statics)
    {
    case 1:
        (*pInd).getIndicator(dist);
        break;
    case 2:
        (*pInd).getIndicatorMa(dist);
        break;
    case 3:
        (*pInd).getIndicatorStd(dist);
        break;
    case 4:
        (*pInd).getSpeed(dist);
        break;
    case 5:
        (*pInd).getSpeedMa(dist);
        break;
    case 6:
        (*pInd).getSpeedStd(dist);
        break;
    case 7:
        (*pInd).getAcc(dist);
        break;
    case 8:
        (*pInd).getAccMa(dist);
        break;
    case 9:
        (*pInd).getAccStd(dist);
        break;
    default:
        (*pInd).getIndicator(dist);
        break;
    }
}

string print_indicator_2str(IndicatorArrayGroup *const pInd)
{

    if (pInd == NULL)
    {
        return "Error:NUll PTR.";
    }

    string ret = "";
    ret += " is_up:" + (*pInd).is_up() +
           " is_down:" + (*pInd).is_down() +
           " is_acc:" + (*pInd).is_acc() +
           " is_dece:" + (*pInd).is_dece() +
           " is_acc_up:" + (*pInd).is_acc_up() +
           " is_acc_down:" + (*pInd).is_acc_down() +
           " is_acc_in_low:" + (*pInd).is_acc_in_low() +
           " is_speed_in_low:" + (*pInd).is_speed_in_low() +
           " is_in_high:" + (*pInd).is_in_high() +
           " is_in_low:" + (*pInd).is_in_low() +
           " is_in_middle:" + (*pInd).is_in_middle();
    return ret;
}

Boll *get_boll_by_period()
{
    int period = Period();

    if (period == 5)
    {
        return GetPointer(boll5m);
    }
    else if (period == 15)
    {
        return GetPointer(boll15m);
    }
    else if (period == 60)
    {
        return GetPointer(boll1h);
    }
    else if (period == 240)
    {
        return GetPointer(boll4h);
    }
    else if (period == 1440)
    {
        return GetPointer(boll1d);
    }
    return NULL;
}

void get_boll_data()
{
    Boll *p_boll = get_boll_by_period();
    (*p_boll).calc();

    IndicatorArrayGroup *pInd = get_indicator();

    if (pInd == NULL)
    {
        return;
    }

    (*pInd).calc();
    double dist[];

    get_indicator_data(pInd, dist);

    int size = ArraySize(dist);
    mtrx.reset();
    mtrx.computeAbs(dist, size);

    Comment(print_indicator_2str(pInd) + " cur val:" + dist[0] + " index:" + mtrx.calc_index(fabs(dist[0])));
    // Print((*pInd).format_conf_to_str());
    // Print(mtrx.format_to_str());
}

void init_boll()
{
    boll5m.setBufferSize(2000);
    boll15m.setBufferSize(1000);
    boll1h.setBufferSize(1000);
    boll4h.setBufferSize(1000);
    boll1d.setBufferSize(1000);
}
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- create timer
    EventSetTimer(60);
    // boll.setTimeFrame(period);
    // boll.setBufferSize(1000);
    init_boll();

    double data[] = {0};
    get_boll_data();
    mtrx.get_occpy(data);
    chart.setData(data);
    mtrx.get_step(data);
    chart.setStep(data);

    if (flag)
    {
        set_chart();
    }
    chart.draw();
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
    ObjectsDeleteAll();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if (Bars < 100)
    {
        Print("bars less than 100");
        return;
    }

    double data[10] = {0};
    get_boll_data();
    mtrx.get_occpy(data);
    chart.setData(data);

    if (flag)
    {
        set_chart();
    }

    chart.redraw();
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    //---
}
//+------------------------------------------------------------------+
