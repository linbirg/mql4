//+------------------------------------------------------------------+
//|                                                           ma.mqh |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

#include "indicator_grp.mqh"
#include "abstract_indicator.mqh"

// bool isMaUp(int ma_period, double minMAUpStep, int period_count)
// {
//       double Ma0, Ma1, Ma2;
//       //均뿯纽뿯厽뿯劽뿯殽뿯붿慢붿뿯暽뿯施뿯厽两个
//       Ma0 = iMA(NULL, ma_period, period_count, 0, MODE_LWMA, PRICE_CLOSE, 0);
//       Ma1 = iMA(NULL, ma_period, period_count, 0, MODE_LWMA, PRICE_CLOSE, 1);
//       Ma2 = iMA(NULL, ma_period, period_count, 0, MODE_LWMA, PRICE_CLOSE, 2);

//       bool isUp = false;

//       if (Ma0 > Ma1)
//       {
//             if ((Ma0 - Ma1) > minMAUpStep * Point)
//             {
//                   //Print("isMaUp:Ma0-Ma1   ",(Ma0-Ma1)/Point,"  step  ",minMAUpStep,"   Period   ",ma_period,"  count ",period_count);
//                   isUp = true;
//                   return isUp;
//             }
//             if (Ma1 > Ma2 && (Ma0 - Ma2) > 1.5 * minMAUpStep * Point)
//             {
//                   //Print("isMaUp:Ma0-Ma2   ",(Ma0-Ma2)/Point,"  step  ",minMAUpStep,"   Period   ",ma_period,"  count ",period_count);
//                   isUp = true;
//                   return isUp;
//             }
//       }

//       return isUp;
// }

// bool isMaDown(int ma_period, double minMaDownStep, int period_count)
// {
//       double Ma0, Ma1, Ma2;
//       //均뿯纽뿯厽뿯劽뿯殽뿯붿慢붿뿯暽뿯施뿯厽两个
//       Ma0 = iMA(NULL, ma_period, period_count, 0, MODE_LWMA, PRICE_CLOSE, 0);
//       Ma1 = iMA(NULL, ma_period, period_count, 0, MODE_LWMA, PRICE_CLOSE, 1);
//       Ma2 = iMA(NULL, ma_period, period_count, 0, MODE_LWMA, PRICE_CLOSE, 2);

//       bool isDown = false;

//       if (Ma0 < Ma1)
//       {
//             if ((Ma1 - Ma0) > minMaDownStep * Point)
//             {
//                   isDown = true;
//                   //Print("isMaDown: Ma1-Ma0  ",(Ma1-Ma0)/Point,"   step  ",minMaDownStep,"   Period   ",ma_period,"  count ",period_count);

//                   return isDown;
//             }
//             if (Ma2 > Ma1 && (Ma2 - Ma0) > 1.5 * minMaDownStep * Point)
//             {
//                   //Print("isMaDown:Ma2-Ma0 ",(Ma2-Ma0)/Point,"  step  ",minMaDownStep,"   Period   ",ma_period,"  count ",period_count);
//                   isDown = true;
//                   return isDown;
//             }
//       }

//       return isDown;
// }

// //H4 开뿯亽붿뿯붿看13붿26,60三根均뿯纽뿯施向一뿯붿。
// bool isMa4HUpForOpen()
// {
//       return isMaUp(PERIOD_H4, MAOpenLevel, MATrendPeriodFast / 2) && isMaUp(PERIOD_H4, MAOpenLevel, MATrendPeriodFast); //&&isMaUp(Timeframes,MAOpenLevel,MATrendPeriod);
// }

// bool isMa4HDownForOpen()
// {
//       return isMaDown(PERIOD_H4, MAOpenLevel, MATrendPeriodFast / 2) && isMaDown(PERIOD_H4, MAOpenLevel, MATrendPeriodFast); //&&isMaDown(Timeframes,MAOpenLevel,MATrendPeriod);
// }

// bool isMa4HUpForClose()
// {
//       return isMaUp(PERIOD_H4, MACloseLevel, MATrendPeriodFast);
// }

// bool isMa4HDownForClose()
// {
//       return isMaDown(PERIOD_H4, MACloseLevel, MATrendPeriodFast);
// }

// bool isFarAway(int ma_timeframe, int ma_period_count)
// {
//       double ma = iMA(NULL, ma_timeframe, ma_period_count, 0, MODE_LWMA, PRICE_CLOSE, 0);
//       double open = iOpen(NULL, ma_timeframe, 0);
//       double close = iClose(NULL, ma_timeframe, 0);

//       if (open > ma && close > ma && close > open)
//             return true;

//       if (open < ma && close < ma && close < open)
//             return true;

//       return false;
// }

// bool isApproaching(int ma_timeframe, int ma_period_count)
// {
//       double ma = iMA(NULL, ma_timeframe, ma_period_count, 0, MODE_LWMA, PRICE_CLOSE, 0);
//       double open = iOpen(NULL, ma_timeframe, 0);
//       double close = iClose(NULL, ma_timeframe, 0);

//       if (open > ma && close > ma && close < open)
//             return true;

//       if (open < ma && close < ma && close > open)
//             return true;

//       return false;
// }

// /**
// *开뿯皽뿯亽在均뿯纽붿近delta个Point即뿯箽在붿近
// */
// bool isNearBy(int ma_timeframe, int ma_period_count, int delta)
// {
//       double ma = iMA(NULL, ma_timeframe, ma_period_count, 0, MODE_LWMA, PRICE_CLOSE, 0);
//       double open = iOpen(NULL, ma_timeframe, 0);

//       if (MathAbs(ma - open) < delta * Point)
//       {
//             //Print("isNearBy:true ma_period_count   ",ma_period_count,"  ma_timeframe   ",ma_timeframe,"  MathAbs(ma-open)/Point  ",MathAbs(ma-open)/Point);
//             return true;
//       }

//       return false;
// }

// // 붿过判뿯施两条均뿯纽뿯皽뿯嶽值来判뿯施是否存在붿붿붿뿯悽。
// bool isConsolidation(int ma_timeframe, int ma_period_one, int ma_period_other, int ravistor)
// {
//       double Ma, MaDB;
//       //int count = 0;

//       Ma = iMA(NULL, ma_timeframe, ma_period_one, 0, MODE_LWMA, PRICE_CLOSE, 0);
//       MaDB = iMA(NULL, ma_timeframe, ma_period_other, 0, MODE_LWMA, PRICE_CLOSE, 0);

//       //Print("isConsolidation:delta:",MathAbs(Ma-MaDB)/Point,"  Ma ",Ma,"   MaDB  ",MaDB,"   ma_timeframe   ",ma_timeframe,"  ma_period_one  ",ma_period_one,"  ma_period_other   ",ma_period_other);

//       if (MathAbs(Ma - MaDB) >= ravistor * Point)
//             return false;

//       return true;
// }

/**
 * 
 * 均线指标
*/
class MA : public Abstractindicator
{
    private:
      // int m_timeframe;
      int m_maPeriods;
      // datetime m_start_time;

    public:
      MA(/* args */);
      ~MA();

    public:
      void setMaPeriods(int periods) { m_maPeriods = periods; };
      void setTimeFrame(int frame) { m_frame = frame; };

    public:
      // bool is_long();
      // bool is_short();
      // bool is_flat();
      // void calc();
      void do_calc(int shift);
};

MA::MA(/* args */)
{
      setBufferSize(1000);
}

MA::~MA()
{
}

// void MA::calc()
// {
//       datetime now = iTime(NULL, m_frame, 0);
//       int count = (now - m_start_time) / (60 * m_frame);

//       for (int i = 0; i < count; i++)
//       {
//             double ma = iMA(NULL, m_timeframe, m_maPeriods, 0, MODE_LWMA, PRICE_CLOSE, 0);
//             m_indicator.append(ma);
//       }
//       m_start_time = now;
// }

void MA::do_calc(int shift)
{
      double ma = iMA(NULL, m_frame, m_maPeriods, 0, MODE_LWMA, PRICE_CLOSE, shift);
      m_indicator.append(ma);
}

class DoubleMA : public Abstractindicator
{
    private:
      MA m_fast;
      MA m_slow;
      int m_timeframe;

    public:
      DoubleMA(/* args */);
      ~DoubleMA();

    public:
      void setTimeFrame(int frame);
      void setBufferSize(int size);

    public:
      void do_calc(int shift);

    public:
      bool is_long();
      bool is_short();
      string format_to_str();
};

DoubleMA::DoubleMA(/* args */)
{
      setTimeFrame(PERIOD_M15);
      m_fast.setMaPeriods(20);
      m_slow.setMaPeriods(60);
}

DoubleMA::~DoubleMA()
{
}

void DoubleMA::setTimeFrame(int frame)
{
      m_fast.setTimeFrame(frame);
      m_slow.setTimeFrame(frame);
}

void DoubleMA::setBufferSize(int size)
{
      m_fast.setBufferSize(size);
      m_slow.setBufferSize(size);
}

void DoubleMA::do_calc(int shift)
{
      m_fast.do_calc(shift);
      m_slow.do_calc(shift);
}

bool DoubleMA::is_long()
{
      return m_fast.is_long() && m_slow.is_long();
}

bool DoubleMA::is_short()
{
      return m_fast.is_short() && m_slow.is_short();
}

string DoubleMA::format_to_str()
{
      return "ma:fast:is_long:" + m_fast.is_long() +
             " is_short:" + m_fast.is_short() +
             " slow:is_long:" + m_slow.is_long() +
             " is_short:" + m_slow.is_short();
}

class DoubleMA5M : public DoubleMA
{
    private:
      /* data */
    public:
      DoubleMA5M(/* args */);
      ~DoubleMA5M();
};

DoubleMA5M::DoubleMA5M(/* args */)
{
      setTimeFrame(PERIOD_M5);
}

DoubleMA5M::~DoubleMA5M()
{
}

class DoubleMa1H : public DoubleMA
{
    private:
      /* data */
    public:
      DoubleMa1H(/* args */);
      ~DoubleMa1H();
};

DoubleMa1H::DoubleMa1H(/* args */)
{
      setTimeFrame(PERIOD_H1);
}

DoubleMa1H::~DoubleMa1H()
{
}

class DoubleMA4H : public DoubleMA
{
    private:
      /* data */
    public:
      DoubleMA4H(/* args */);
      ~DoubleMA4H();
};

DoubleMA4H::DoubleMA4H(/* args */)
{
      setTimeFrame(PERIOD_H4);
}

DoubleMA4H::~DoubleMA4H()
{
}

class DoubleMA1D : public DoubleMA
{
    private:
      /* data */
    public:
      DoubleMA1D(/* args */);
      ~DoubleMA1D();
};

DoubleMA1D::DoubleMA1D(/* args */)
{
      setTimeFrame(PERIOD_D1);
}

DoubleMA1D::~DoubleMA1D()
{
}

class DoubleMA1W : public DoubleMA
{
    private:
      /* data */
    public:
      DoubleMA1W(/* args */);
      ~DoubleMA1W();
};

DoubleMA1W::DoubleMA1W(/* args */)
{
      setTimeFrame(PERIOD_W1);
}

DoubleMA1W::~DoubleMA1W()
{
}

class DoubleMA1MN : public DoubleMA
{
    private:
      /* data */
    public:
      DoubleMA1MN(/* args */);
      ~DoubleMA1MN();
};

DoubleMA1MN::DoubleMA1MN(/* args */)
{
      setTimeFrame(PERIOD_MN1);
      setBufferSize(100);
}

DoubleMA1MN::~DoubleMA1MN()
{
}
