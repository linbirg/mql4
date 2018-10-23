//+------------------------------------------------------------------+
//|                                                 stop_manager.mqh |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//Changelog
//2016.09.13 增加移动止损的逻辑：如果存在亏损，且订单盈利未覆盖亏损，执行移到止损，尽快回复资金。如果已经覆盖，转为按照正常止损策略

#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

#include "../indicator/atr.mqh"
#include "../indicator/bias.mqh"

#include "../orders/order_helper.mqh"
#include "../util/util.mqh"

class StopManager
{
public:
  StopManager()
  {
    m_MATrendPeriod = 60;
    m_MATrendPeriodFast = 26;

    m_MASwitchStep = 2;
    m_MASwitchCount = 16;

    init();
  };

  void CalcStopLoss();
  void set_stop_less_by_boll();

public:
  void set_defual_stop();
  void trailingStop();

private:
  double maxStopLostBelow(double openPrice);
  double minStopLostAbove(double openPrice);

  void calcStopLossForShort();
  void calcStopLossForLong();

  bool trailingStopForLong();
  bool trailingStopForShort();

  void set_long_stop_less_by_boll();
  void set_short_stop_less_by_boll();

  double min_boll_val_above(double price);
  double max_boll_val_below(double price);
  double min_atr_trailing();

public:
  bool is_stop_cover_trailing_profit();

public:
  void setMATrendPeriod(int period) { m_MATrendPeriod = period; };
  void setMATrendPeriodFast(int periodFast) { m_MATrendPeriodFast = periodFast; };
  void setTrailingStop(double trailingStop) { m_TrailingStop = trailingStop; };

private:
  void init();

private:
  int m_MATrendPeriod;
  int m_MATrendPeriodFast;
  double m_TrailingStop;
  Util m_util;
  int m_periods[5];
  int m_MASwitchStep;
  int m_MASwitchCount;
  OrderHelper m_orderHelper;
};

void StopManager::init()
{
  // m_periods[0] = 5;
  // m_periods[1] = 15;
  // m_periods[2] = 30;
  m_periods[0] = 60;
  m_periods[1] = 240;
  m_periods[2] = 1440;
  m_periods[3] = PERIOD_W1;
  m_periods[4] = PERIOD_MN1;
};

double
StopManager::maxStopLostBelow(double openPrice)
{
  double stopLost = OrderStopLoss();
  double ATR = Ask + calcATR();

  //价格偏离均线太远
  if (isTooFar(m_MATrendPeriodFast))
  {
    Print("maxStopLostBelow:价格偏离均线太远");
    return ATR;
  }

  double ma = 0;

  if (ATR < openPrice)
    stopLost = ATR;

  ma = iMA(NULL, 0, m_MATrendPeriodFast, 0, MODE_LWMA, PRICE_CLOSE, 0);
  if (ma < openPrice && ma > stopLost)
    stopLost = ma;

  ma = iMA(NULL, 0, m_MATrendPeriod, 0, MODE_LWMA, PRICE_CLOSE, 0);
  if (ma < openPrice && ma > stopLost)
    stopLost = ma;

  for (int cnt = 1; cnt < m_MASwitchCount; cnt++)
  {
    ma = iMA(NULL, 0, m_MATrendPeriod * m_MASwitchStep * cnt, 0, MODE_LWMA, PRICE_CLOSE, 0);
    if (ma < openPrice && ma > stopLost)
      stopLost = ma;
  }

  return stopLost;
}

double StopManager::minStopLostAbove(double openPrice)
{
  double stopLost = OrderStopLoss();
  double ATR = Bid - calcATR();

  //价格偏离均线太远
  if (isTooFar(this.m_MATrendPeriodFast))
  {
    Print("maxStopLostBelow:价格偏离均线太远");
    return ATR;
  }

  double ma = 0;

  if (ATR > openPrice)
    stopLost = ATR;

  ma = iMA(NULL, 0, m_MATrendPeriodFast, 0, MODE_LWMA, PRICE_CLOSE, 0);
  if (ma > openPrice && ma < stopLost)
    stopLost = ma;

  ma = iMA(NULL, 0, m_MATrendPeriod, 0, MODE_LWMA, PRICE_CLOSE, 0);
  if (ma > openPrice && ma < stopLost)
    stopLost = ma;

  for (int cnt = 1; cnt < m_MASwitchCount; cnt++)
  {
    ma = iMA(NULL, 0, m_MATrendPeriod * m_MASwitchStep * cnt, 0, MODE_LWMA, PRICE_CLOSE, 0);
    if (ma > openPrice && ma < stopLost)
      stopLost = ma;
  }

  return stopLost;
}

void StopManager::set_defual_stop()
{
  double stop = min_atr_trailing();

  if (OrderType() == OP_BUY)
  {
    modify_stop_lost_for_long(Bid - stop);
  }
  else if (OrderType() == OP_SELL)
  {
    modify_stop_lost_for_short(Ask + stop);
  }
}

void StopManager::calcStopLossForShort()
{
  double stopLost = 0;

  if (OrderStopLoss() == 0)
  {
    set_defual_stop();
    return;
  }

  if (OrderOpenPrice() < OrderStopLoss())
  {
    stopLost = maxStopLostBelow(OrderStopLoss());
  }
  else
  {
    stopLost = maxStopLostBelow(OrderOpenPrice());
  }

  modify_stop_lost_for_short(stopLost);
  //if(OrderStopLoss()>stopLost)ModifyStopLost(stopLost);
}

void StopManager::calcStopLossForLong()
{
  double stopLost = 0;

  if (OrderStopLoss() == 0)
  {
    set_defual_stop();
    return;
  }

  //if(OrderOpenPrice()+m_TrailingStop*Point<Bid && OrderOpenPrice()>OrderStopLoss())ModifyStopLost(OrderOpenPrice());
  if (OrderOpenPrice() > OrderStopLoss())
  {
    stopLost = minStopLostAbove(OrderStopLoss());
  }
  else
  {
    stopLost = minStopLostAbove(OrderOpenPrice());
  }

  modify_stop_lost_for_long(stopLost);

  //if(OrderStopLoss()<stopLost)ModifyStopLost(stopLost);
}

double StopManager::min_atr_trailing()
{
  double atr = iATR(NULL, PERIOD_H4, 60, 0); //1.5倍的atr。
  double trailing = m_TrailingStop * Point;
  double stop = MathMin(atr, trailing);
  Print("min_atr_trailing:atr:" + atr + " trailing:" + trailing + " stop:" + stop);
  return stop;
}

void StopManager::trailingStop()
{
  if (OrderType() == OP_BUY)
    trailingStopForLong();
  if (OrderType() == OP_SELL)
    trailingStopForShort();
}

bool StopManager::trailingStopForLong()
{
  double stop = min_atr_trailing();
  if (OrderStopLoss() + stop < Bid)
  {
    if (modify_stop_lost_for_long(Bid - stop))
      return true;
  }

  return false;
}

bool StopManager::trailingStopForShort()
{
  double stop = min_atr_trailing();

  if (OrderStopLoss() - stop > Ask)
  {
    if (modify_stop_lost_for_short(Ask + stop))
      return true;
  }

  return false;
}

void StopManager::CalcStopLoss()
{
  int cnt, total;
  double maxLostAmount = 0;

  total = OrdersTotal();

  if (total > 0)
    maxLostAmount = maxLostAmount();

  for (cnt = 0; cnt < total; cnt++)
  {
    if (!SelectTradeOrderByPos(cnt))
      continue;

    if (OrderStopLoss() == 0)
    {
      set_defual_stop();
    }

    double stop_lost_profit = calc_profit_stop_lost_btw_middle();
    Print("maxLostAmount:", maxLostAmount, " OrderProfit:", OrderProfit(), " OrderStopLoss profit ", stop_lost_profit);
    if (stop_lost_profit < 0 || (maxLostAmount > 0 && (OrderProfit() < maxLostAmount || stop_lost_profit < maxLostAmount)))
    {
      Print("止损为负或者存在亏损且止损未覆盖亏损，执行追踪止损策略");

      // if (OrderType() == OP_BUY)
      //   trailingStopForLong();
      // if (OrderType() == OP_SELL)
      //   trailingStopForShort();

      trailingStop();
      continue;
    }

    //Print("不存在亏损或者止损已经覆盖亏损，执行正常止损策略");

    //--- long position is opened
    if (OrderType() == OP_BUY)
    {
      calcStopLossForLong();
    }
    if (OrderType() == OP_SELL)
    {
      //--- check for trailing stop
      calcStopLossForShort();
    }
  }
}

void StopManager::set_stop_less_by_boll()
{
  int cnt, total;
  double maxLostAmount = 0;

  total = OrdersTotal();

  if (total > 0)
    maxLostAmount = maxLostAmount();

  for (cnt = 0; cnt < total; cnt++)
  {
    if (!SelectTradeOrderByPos(cnt))
      continue;

    if (m_util.double_equal(OrderStopLoss(), 0))
    {
      set_defual_stop();
    }

    double stop_lost_profit = calc_profit_stop_lost_btw_middle();
    Print("maxLostAmount:", maxLostAmount, " OrderProfit:", OrderProfit(), " OrderStopLoss profit ", stop_lost_profit);
    if (stop_lost_profit < 0 || (maxLostAmount > 0 && (OrderProfit() < maxLostAmount || stop_lost_profit < maxLostAmount)))
    {
      Print("存在亏损且止损未覆盖亏损，执行追踪止损策略");
      // if (OrderType() == OP_BUY)
      //   trailingStopForLong();

      // if (OrderType() == OP_SELL)
      //   trailingStopForShort();
      trailingStop();

      continue;
    }

    Print("不存在亏损或者止损已经覆盖亏损，执行正常止损策略");
    if (OrderType() == OP_BUY)
    {
      set_long_stop_less_by_boll();
    }
    if (OrderType() == OP_SELL)
    {
      //--- check for trailing stop
      set_short_stop_less_by_boll();
    }
  }
}

void StopManager::set_long_stop_less_by_boll()
{
  double stopLost = 0;

  if (m_util.double_equal(OrderStopLoss(), 0))
  {
    stopLost = Bid - calcATR();
    if (stopLost < Bid - m_TrailingStop * Point)
      stopLost = Bid - m_TrailingStop * Point;
    modify_stop_lost_for_long(stopLost);
    return;
  }

  double price = OrderOpenPrice();

  if (OrderOpenPrice() > OrderStopLoss())
  {
    price = OrderStopLoss();
  }

  stopLost = min_boll_val_above(price);
  modify_stop_lost_for_long(stopLost);
}

void StopManager::set_short_stop_less_by_boll()
{
  double stopLost = 0;

  if (m_util.double_equal(OrderStopLoss(), 0))
  {
    stopLost = Ask + calcATR();
    if (stopLost > Ask + m_TrailingStop * Point)
      stopLost = Ask + m_TrailingStop * Point;
    modify_stop_lost_for_short(stopLost);
    return;
  }

  double price = OrderOpenPrice();
  if (OrderOpenPrice() < OrderStopLoss())
  {
    price = OrderStopLoss();
  }

  stopLost = max_boll_val_below(price);
  modify_stop_lost_for_short(stopLost);
}

double StopManager::min_boll_val_above(double price)
{
  double min = iBands(NULL, PERIOD_H1, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);

  double mid = iBands(NULL, PERIOD_H1, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, 0);
  double low = iBands(NULL, PERIOD_H1, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);
  int period = m_periods[0];
  int i = 0;
  while (mid > price && low > price && i < 5)
  {
    mid = iBands(NULL, m_periods[i], 20, 2, 0, PRICE_CLOSE, MODE_MAIN, 0);
    low = iBands(NULL, m_periods[i], 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 0);

    if (mid < min && mid > price)
    {
      min = mid;
    }

    if (low < min && low > price)
    {
      min = low;
    }
    period = m_periods[i];

    i = i + 1;
  }

  Print("min_boll_val_above:period:" + period + " min:" + min);
  return min;
}

double StopManager::max_boll_val_below(double price)
{
  double max = iBands(NULL, PERIOD_H1, 20, 2, 0, PRICE_CLOSE, MODE_MAIN, 0);

  double mid = max;
  double upper = iBands(NULL, PERIOD_H1, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
  int period = m_periods[0];
  int i = 0;

  while (mid < price && upper < price && i < 5)
  {
    mid = iBands(NULL, m_periods[i], 20, 2, 0, PRICE_CLOSE, MODE_MAIN, 0);
    upper = iBands(NULL, m_periods[i], 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);

    if (mid > max && mid > price)
    {
      max = mid;
    }

    if (upper > max && upper > price)
    {
      max = upper;
    }
    period = m_periods[i];

    i = i + 1;
  }

  Print("max_boll_val_below:period:" + period + " min:" + max);
  return max;
}

bool StopManager::is_stop_cover_trailing_profit()
{
  //买
  if (OrdersBuyOrSell() == OP_BUY)
  {
    if (m_orderHelper.get_latest_stop() > m_orderHelper.get_latest_open_price() + min_atr_trailing())
      return true;
  }

  //卖
  if (OrdersBuyOrSell() == OP_SELL)
  {
    if (m_orderHelper.get_latest_stop() < m_orderHelper.get_latest_open_price() - min_atr_trailing())
    {
      return true;
    }
  }

  return false;
}
