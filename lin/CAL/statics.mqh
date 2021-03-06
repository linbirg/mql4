//+------------------------------------------------------------------+
//|                                                  statics.mqh.mq4 |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "linbirg"
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include "../orders/order_helper.mqh"

class Metrix
{
    public:
      Metrix()
      {
            m_id = 0;
            m_result = 0;
            m_MFE = 0;
            m_MAE = 0;
            m_MFE_Index = 0;
            m_MAE_Index = 0;

            m_kin = 0;
            m_kout = 0;
            m_totalbars = 1;
            m_profitbars = 0;
            m_lossbars = 0;
            m_delta = 0;
            m_kComfort = 1;
      };

      Metrix(const Metrix &other);

      string format();
      void calc();
      Metrix operator=(const Metrix &other);
      int getID();

    private:
      long countTotalM1();
      void calcTotalBars();
      void calcProfitAndLossBars();

      void calcMFEAndMAE();
      void calcKinKout();

      int countHighBelow(double price);
      int countLowAbove(double price);

    private:
      int m_id;

      double m_result;
      double m_MFE;
      int m_MFE_Index;
      double m_MAE;
      int m_MAE_Index;

      double m_kin;
      double m_kout;

      double m_totalbars;
      double m_delta;

      double m_profitbars;
      double m_lossbars;

      double m_kComfort;

      string m_symbol;
};

Metrix::Metrix(const Metrix &other)
{
      this.m_delta = other.m_delta;
      this.m_id = other.m_id;
      this.m_kComfort = other.m_kComfort;
      this.m_kin = other.m_kin;
      this.m_kout = other.m_kout;

      this.m_MAE = other.m_MAE;
      this.m_MAE_Index = other.m_MAE_Index;
      this.m_MFE = other.m_MFE;
      this.m_MFE_Index = other.m_MFE_Index;

      this.m_lossbars = other.m_lossbars;
      this.m_profitbars = other.m_profitbars;
      this.m_totalbars = other.m_totalbars;

      this.m_result = other.m_result;

      this.m_symbol = other.m_symbol;
}

string Metrix::format(void)
{
      return "ID:" + m_id +
             " Result:" + DoubleToString(m_result, 3) +
             " MFE:" + DoubleToString(m_MFE, 3) + " Index:" + m_MFE_Index +
             " MAE:" + DoubleToString(m_MAE, 3) + " Index:" + m_MAE_Index +
             " K(In):" + DoubleToString(m_kin, 3) +
             " K(Out):" + DoubleToString(m_kout, 3) +
             " K(Deal):" + DoubleToString(m_kin + m_kout, 3) +
             " K(Comfort):" + DoubleToString(m_kComfort, 3) +
             " profitbars:" + m_profitbars +
             " lossbars:" + m_lossbars +
             " totalbars:" + m_totalbars +
             " delta " + m_delta +
             " " + m_symbol;
}

void Metrix::calc(void)
{
      m_id = OrderTicket();

      calcTotalBars();
      calcProfitAndLossBars();

      calcMFEAndMAE();
      calcKinKout();

      m_symbol = ChartSymbol();
}

void Metrix::calcKinKout()
{
      if (MathAbs(m_result) < 0.00000001)
      {
            m_kin = 0;
      }
      else
      {
            m_kin = 1 / (1 + MathAbs(m_MAE / m_result));
      }

      if (m_MFE < 0.000000001)
      {
            m_kout = 0;
      }
      else
      {
            m_kout = m_result / m_MFE;
      }
}

void Metrix::calcMFEAndMAE()
{
      double price = Ask;
      if (OrderType() == OP_BUY)
            price = Bid;

      double profit = calc_profit_at_by_direct(price); //OrderProfit();
      // Print("close:" + iClose(NULL, 0, 0) + " profit:" + profit + " open pirce:" + OrderOpenPrice() + " ask:" + Ask + " Bid:" + Bid);
      m_result = profit;
      if (profit > m_MFE)
      {
            m_MFE = profit;
            m_MFE_Index = m_totalbars;
      }

      if (profit < m_MAE)
      {
            m_MAE = profit;
            m_MAE_Index = m_totalbars;
      }
}

void Metrix::calcTotalBars()
{
      int total = countTotalM1();
      if (total > m_totalbars)
      {
            m_delta = total - m_totalbars;
            m_totalbars = total;
      }
      else
      {
            m_delta = 0;
      }

      if (m_totalbars == 0)
      {
            m_kComfort = 1;
      }
      else
      {
            m_kComfort = m_profitbars / m_totalbars - m_lossbars / m_totalbars;
      }
}

long Metrix::countTotalM1(void)
{
      datetime open_time = OrderOpenTime();
      datetime now = iTime(NULL, PERIOD_M1, 0);
      long delta = now - open_time;
      return delta / 60;
}

void Metrix::calcProfitAndLossBars(void)
{
      int buy_type = OrderType();
      if (buy_type == OP_BUY)
      {
            m_lossbars = m_lossbars + countHighBelow(OrderOpenPrice());
            m_profitbars = m_profitbars + countLowAbove(OrderOpenPrice());
      }
      else
      {
            m_lossbars = m_lossbars + countLowAbove(OrderOpenPrice());
            m_profitbars = m_profitbars + countHighBelow(OrderOpenPrice());
      }
}

int Metrix::countHighBelow(double price)
{
      int cnt = 0;
      for (int i = m_delta; i > 0; i--)
      {
            if (iHigh(NULL, PERIOD_M1, i) < price)
                  cnt++;
      }

      return cnt;
}

int Metrix::countLowAbove(double price)
{
      int cnt = 0;
      for (int i = m_delta; i > 0; i--)
      {
            if (iLow(NULL, PERIOD_M1, i) > price)
                  cnt++;
      }

      return cnt;
}

Metrix Metrix::operator=(const Metrix &other)
{
      this.m_delta = other.m_delta;
      this.m_id = other.m_id;
      this.m_kComfort = other.m_kComfort;
      this.m_kin = other.m_kin;
      this.m_kout = other.m_kout;

      this.m_MAE = other.m_MAE;
      this.m_MAE_Index = other.m_MAE_Index;
      this.m_MFE = other.m_MFE;
      this.m_MFE_Index = other.m_MFE_Index;

      this.m_lossbars = other.m_lossbars;
      this.m_profitbars = other.m_profitbars;
      this.m_totalbars = other.m_totalbars;

      this.m_result = other.m_result;

      this.m_symbol = other.m_symbol;
      return this;
}

int Metrix::getID()
{
      return m_id;
}

class MetrixManager
{
    public:
      MetrixManager(){};
      void flush(void);
      string formatoStr(void);

    private:
      void append(Metrix &one[], const Metrix &another);
      void resizeArray(Metrix &one[], int len);
      void arrayCopy(Metrix &dist[], const Metrix &src[], int count = -1);
      Metrix *findByID(int id);
      void clearByTickets();

    private:
      Metrix m_mtrxs[];
      int m_orders[];
      int m_order_cnt;
};

void MetrixManager::flush(void)
{
      int total = OrdersTotal();
      ArrayResize(m_orders, total);
      m_order_cnt = 0;
      for (int i = 0; i < total; i++)
      {
            if (SelectTradeOrderByPos(i) && OrderSymbol() == Symbol())
            {
                  Metrix *pmtrx = findByID(OrderTicket());
                  if (pmtrx == NULL)
                  {
                        Metrix mtrx;
                        mtrx.calc();
                        append(m_mtrxs, GetPointer(mtrx));
                  }
                  else
                  {
                        (*pmtrx).calc();
                  }
                  m_orders[m_order_cnt++] = OrderTicket();
            }
      }
      clearByTickets();
}

string MetrixManager::formatoStr(void)
{
      int size = ArraySize(m_mtrxs);
      string ret_str = "";
      for (int i = 0; i < size; i++)
      {
            ret_str += m_mtrxs[i].format() + "\t\n";
      }

      return ret_str;
}

// 从0开始拷贝。count必须不能大于最小者的长度。如果count<0，以最小长度拷贝。
void MetrixManager::arrayCopy(Metrix &dist[], const Metrix &src[], int count = -1)
{
      if (count < 0)
      {
            count = ArraySize(dist);
            int size_src = ArraySize(src);

            if (count > size_src)
            {
                  count = size_src;
            }
      }

      for (int i = 0; i < count; i++)
      {
            dist[i] = src[i];
      }
}

// 对数组重新调整大小，保留数组len的数据不变。
void MetrixManager::resizeArray(Metrix &one[], int len)
{
      Metrix temp[];
      ArrayResize(temp, len);
      // Print("resizeArray:1 " + "temp:" + ArraySize(temp) + " m_mtrxs:" + ArraySize(m_mtrxs));
      arrayCopy(temp, m_mtrxs);

      ArrayResize(one, len);
      // Print("resizeArray:2 " + "m_mtrxs:" + ArraySize(m_mtrxs) + " temp:" + ArraySize(temp));
      arrayCopy(m_mtrxs, temp);
      ArrayFree(temp);
}

Metrix *MetrixManager::findByID(int id)
{
      int size = ArraySize(m_mtrxs);
      if (size == 0)
            return NULL;

      for (int i = 0; i < size; i++)
      {
            if (m_mtrxs[i].getID() == id)
            {
                  return GetPointer(m_mtrxs[i]);
            }
      }

      return NULL;
}

void MetrixManager::append(Metrix &one[], const Metrix &another)
{
      int size = ArraySize(one);
      Metrix temp[];
      ArrayResize(temp, size);
      // Print("append:1 " + "temp:" + ArraySize(temp) + " one:" + ArraySize(one));
      arrayCopy(temp, one);
      ArrayResize(one, size + 1);
      // Print("append:2 " + "one:" + ArraySize(one) + " temp:" + ArraySize(temp) + " size:" + size);
      arrayCopy(one, temp, size);
      one[size] = another;
      ArrayFree(temp);
}

void MetrixManager::clearByTickets()
{
      if (m_order_cnt == 0)
            ArrayFree(m_mtrxs);

      Metrix temp[];
      ArrayResize(temp, m_order_cnt);

      for (int i = 0; i < m_order_cnt; i++)
      {
            Metrix *pmtrx = findByID(m_orders[i]);
            temp[i] = *pmtrx;
      }
      arrayCopy(m_mtrxs, temp, m_order_cnt);
}
