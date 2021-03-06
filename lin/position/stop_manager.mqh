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

input double MAX_STOPS = 2000;
input double MAX_DEP_STOP_PRICE = 1500;

class StopManager
{
private:
  int m_MATrendPeriod;
  int m_MATrendPeriodFast;
  double m_TrailingStop;
  Util m_util;
  int m_periods[5];
  int m_MASwitchStep;
  int m_MASwitchCount;
  OrderHelper m_orderHelper;
  int m_max_stops_by_step;     // 止损超过此值之后就不再按照步进的方式增加止损，改为设在总盈利的1/3处。
  int m_max_dep_stop_by_price; // 止损距离价格的最远距离，超过则按步长移动止损。

public:
  StopManager()
  {
    m_MATrendPeriod = 60;
    m_MATrendPeriodFast = 26;

    m_MASwitchStep = 2;
    m_MASwitchCount = 16;

    m_max_stops_by_step = MAX_STOPS;
    m_max_dep_stop_by_price = MAX_DEP_STOP_PRICE;

    init();
  };

  void CalcStopLoss();
  void set_stop_less_by_boll();

  void set_stop_less_by_step(); //运行一定距离后，设置部分止损

  void set_stop_loss_greed_by_step(); // 尽快移动到开仓价后再步进止损。

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
  void move_stop_per_step();
  bool is_stop_between_step_max();
  bool is_stop_between_step_(double max_stop);
  bool is_stop_by_new_price_between_(double dep);
  void set_trailing_3_1();
  void set_trailing_quator_1(int quator);

  bool select_latest_order();

private:
  bool is_stop_minus();

  void move_stop_to_open_plus_one_point();
  bool is_dep_btw_stop_and_price_in_3_stop();
  bool is_dep_btw_stop_and_price_beyond_3_stop();
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
  Print("set_defual_stop");

  if (OrdersTotal() <= 0)
    return;

  if (m_orderHelper.get_curr_orders() <= 0)
  {
    Print("set_defual_stop：当前没有持仓。");
    return;
  }

  if (!m_orderHelper.select_trade_latest_order())
  {
    Print("set_defual_stop:无法选中最新订单。");
    return;
  }

  if (m_util.double_equal(OrderStopLoss(), 0))
  {
    Print("set_defual_stop:设置默认止损。");
    double stop = min_atr_trailing();

    if (OrderType() == OP_BUY)
    {
      Print("set_defual_stop:buy:OrderOpenPrice:" + OrderOpenPrice() + " min_atr_trailing:" + stop + " new stop:" + (OrderOpenPrice() - stop));
      m_orderHelper.modify_stop_lost_for_long(OrderOpenPrice() - stop);
    }
    else if (OrderType() == OP_SELL)
    {
      m_orderHelper.modify_stop_lost_for_short(OrderOpenPrice() + stop);
    }
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

  m_orderHelper.modify_stop_lost_for_short(stopLost);
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

  m_orderHelper.modify_stop_lost_for_long(stopLost);

  //if(OrderStopLoss()<stopLost)ModifyStopLost(stopLost);
}

double StopManager::min_atr_trailing()
{
  double atr = iATR(NULL, PERIOD_D1, 60, 0); //1.5倍的atr。
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
    if (m_orderHelper.modify_stop_lost_for_long(Bid - stop))
      return true;
  }

  return false;
}

bool StopManager::trailingStopForShort()
{
  double stop = min_atr_trailing();

  if (OrderStopLoss() - stop > Ask)
  {
    if (m_orderHelper.modify_stop_lost_for_short(Ask + stop))
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
    maxLostAmount = m_orderHelper.maxLostAmount();

  for (cnt = 0; cnt < total; cnt++)
  {
    if (!m_orderHelper.select_trade_by_index(cnt))
      continue;

    if (OrderStopLoss() == 0)
    {
      set_defual_stop();
    }

    double stop_lost_profit = m_orderHelper.calc_profit_stop_lost_btw_middle();
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
    maxLostAmount = m_orderHelper.maxLostAmount();

  for (cnt = 0; cnt < total; cnt++)
  {
    if (!m_orderHelper.select_trade_by_index(cnt))
      continue;

    if (m_util.double_equal(OrderStopLoss(), 0))
    {
      set_defual_stop();
    }

    double stop_lost_profit = m_orderHelper.calc_profit_stop_lost_btw_middle();
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
    m_orderHelper.modify_stop_lost_for_long(stopLost);
    return;
  }

  double price = OrderOpenPrice();

  if (OrderOpenPrice() > OrderStopLoss())
  {
    price = OrderStopLoss();
  }

  stopLost = min_boll_val_above(price);
  m_orderHelper.modify_stop_lost_for_long(stopLost);
}

void StopManager::set_short_stop_less_by_boll()
{
  double stopLost = 0;

  if (m_util.double_equal(OrderStopLoss(), 0))
  {
    stopLost = Ask + calcATR();
    if (stopLost > Ask + m_TrailingStop * Point)
      stopLost = Ask + m_TrailingStop * Point;
    m_orderHelper.modify_stop_lost_for_short(stopLost);
    return;
  }

  double price = OrderOpenPrice();
  if (OrderOpenPrice() < OrderStopLoss())
  {
    price = OrderStopLoss();
  }

  stopLost = max_boll_val_below(price);
  m_orderHelper.modify_stop_lost_for_short(stopLost);
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
  // if (OrdersBuyOrSell() == OP_BUY)
  // ;

  if (!m_orderHelper.select_trade_latest_order())
  {
    Print("is_stop_cover_trailing_profit：无法选中最新订单");
    return false;
  }

  double latest_stop = OrderStopLoss();
  double latest_open_price = OrderOpenPrice();

  if (OrderType() == OP_BUY)
  {
    if (latest_stop > latest_open_price + min_atr_trailing())
      return true;
  }

  //卖
  if (OrderType() == OP_SELL)
  {
    if (latest_stop < latest_open_price - min_atr_trailing())
    {
      return true;
    }
  }

  return false;
}

/**
 * 选中最新开仓的订单。
*/
bool StopManager::select_latest_order()
{
  int cnt = OrdersTotal();

  if (cnt <= 0)
    return false;

  if (m_orderHelper.get_curr_orders() <= 0)
  {
    Print("select_latest_order:没有持仓。");
    return false;
  }

  // Print("set_stop_less_by_step");

  if (!m_orderHelper.select_trade_latest_order())
  {
    Print("select_latest_order:无法选中最新订单。");
    return false;
  };

  return true;
}

//
/**
 * 
 * 运行一定距离后，设置部分止损
*/
void StopManager::set_stop_less_by_step()
{
  // int cnt = OrdersTotal();

  // if (cnt <= 0)
  //   return;

  // if (m_orderHelper.get_curr_orders() <= 0)
  // {
  //   Print("set_stop_less_by_step:没有持仓。");
  //   return;
  // }

  // // Print("set_stop_less_by_step");

  // if (!m_orderHelper.select_trade_latest_order())
  // {
  //   Print("set_stop_less_by_step:无法选中最新订单。");
  //   return;
  // };

  if (!select_latest_order())
  {
    Print("set_stop_less_by_step:未能选中最新的订单。");
    return;
  }

  double latest_stop = OrderStopLoss();
  if (m_util.double_equal(latest_stop, 0))
  {
    set_defual_stop();
    return;
  }

  if (is_stop_between_step_max())
  {
    move_stop_per_step();
    return;
  }

  //1/3的盈利处。
  Print("set_stop_less_by_step：执行1/3移动止损策略。");
  set_trailing_3_1();
}

void StopManager::set_trailing_3_1()
{
  Print("set_trailing_3_1");
  set_trailing_quator_1(3);
}

void StopManager::set_trailing_quator_1(int quator)
{
  double open_price = OrderOpenPrice();
  if (OrderType() == OP_BUY)
  {
    double dep = (Ask - open_price) / quator;
    m_orderHelper.modify_stop_lost_for_long(open_price + dep);
    return;
  }

  if (OrderType() == OP_SELL)
  {
    double dep = (open_price - Bid) / quator;
    m_orderHelper.modify_stop_lost_for_short(open_price - dep);
  }
}

bool StopManager::is_stop_between_step_max()
{
  // double latest_stop = OrderStopLoss();
  // double open_price = OrderOpenPrice();
  // if (OrderType() == OP_BUY)
  // {
  //   // Print("is_stop_between_step_max:latest_stop:" + latest_stop + " open_price:" + open_price + " dep:" + (latest_stop - open_price) + " max_step:" + m_max_stops_by_step * Point());
  //   bool between = (latest_stop - open_price) < m_max_stops_by_step * Point();
  //   Print("is_stop_between_step_max:" + between);
  //   return between;
  // }

  // if (OrderType() == OP_SELL)
  // {
  //   // Print("is_stop_between_step_max:latest_stop:" + latest_stop + " open_price:" + open_price + " dep:" + (open_price - latest_stop) + " max_step:" + m_max_stops_by_step * Point());
  //   bool between = (open_price - latest_stop) < m_max_stops_by_step * Point();
  //   Print("is_stop_between_step_max:" + between);
  //   return between;
  // }

  // Print("is_stop_between_step_max:异常的订单类型:" + OrderType());
  // return false;
  Print("is_stop_between_step_max:max_step:" + m_max_stops_by_step);
  return is_stop_between_step_(m_max_stops_by_step * Point());
}

/**
 * 
 * 判断止损与最新价价差是否在制定的范围内（不超过）。
*/
bool StopManager::is_stop_between_step_(double max_stop)
{
  double latest_stop = OrderStopLoss();
  double open_price = OrderOpenPrice();
  if (OrderType() == OP_BUY)
  {
    bool between = (latest_stop - open_price) < max_stop;
    Print("is_stop_between_step_:" + between + " max_stop:" + max_stop+" latest_stop-open_price:" + (latest_stop-open_price));
    return between;
  }

  if (OrderType() == OP_SELL)
  {
    bool between = (open_price - latest_stop) < max_stop;
    Print("is_stop_between_step_:" + between + " max_stop:" + max_stop+" open_price - latest_stop:" + (open_price - latest_stop));
    return between;
  }

  // bool between = fabs(cur_price - latest_stop) < max_stop;
  // Print("is_stop_between_step_:" + between + " max_stop:" + max_stop+" fabs(cur_price - latest_stop):" + fabs(cur_price - latest_stop));
  // return between;

  Print("is_stop_between_step_:异常的订单类型:" + OrderType());
  return false;
}

bool StopManager::is_stop_by_new_price_between_(double dep)
{
  double latest_stop = OrderStopLoss();
  double cur_price = Close[0];
  bool between = fabs(cur_price - latest_stop) < dep;
  Print("is_stop_by_new_price_between_:" + between + " max_stop:" + dep+" fabs(cur_price - latest_stop):" + fabs(cur_price - latest_stop));
  return between;
}

/**
 * 当最新价与止损差距在4倍min_atr_trailing的时候，增加一次min_atr_trailing止损
 * 
*/
void StopManager::move_stop_per_step()
{
  Print("move_stop_per_step");
  double latest_stop = OrderStopLoss();
  //买
  if (OrderType() == OP_BUY)
  {
    if ((Ask - latest_stop) > (m_max_dep_stop_by_price * Point()))
    {
      // Print("move_stop_per_step:" + " ask:" + Ask + " latest_stop:" + latest_stop + " Ask - latest_stop:" + (Ask - latest_stop) + " m_max_dep_stop_by_price:" + m_max_dep_stop_by_price * Point());
      double step = min_atr_trailing();
      Print("move_stop_per_step：执行止损。latest_stop：" + latest_stop + " new stop:" + (latest_stop + step));
      m_orderHelper.modify_stop_lost_for_long(latest_stop + step);
      return;
    }
    Print("move_stop_per_step:没有走出一段大行情，不增加止损。");
    return;
  }

  //卖
  if (OrderType() == OP_SELL)
  {
    // Print("set_stop_less_by_step:step:" + step + " latest_stop:" + latest_stop + " ask:" + Ask + " latest_stop - 4 * step:" + (latest_stop - 4 * step));
    if ((latest_stop - Bid) > (m_max_dep_stop_by_price * Point()))
    {
      // Print("move_stop_per_step:" + " Bid:" + Bid + " latest_stop:" + latest_stop + " latest_stop - Bid:" + (latest_stop - Bid) + " m_max_dep_stop_by_price:" + m_max_dep_stop_by_price * Point());
      double step = min_atr_trailing();
      Print("move_stop_per_step：执行止损。latest_stop：" + latest_stop + " new stop:" + (latest_stop - step));
      m_orderHelper.modify_stop_lost_for_short(latest_stop - step);
    }
    Print("move_stop_per_step:没有走出一段大行情，不增加止损。");
  }
}

/**
 * 
 * 止损是负值。
*/
bool StopManager::is_stop_minus()
{
  double stop_lost_profit = m_orderHelper.calc_profit_stop_lost_btw_middle();
  return stop_lost_profit < 0;
}

bool StopManager::is_dep_btw_stop_and_price_in_3_stop()
{
  double stop = min_atr_trailing();
  Print("is_dep_btw_stop_and_price_in_3_stop:stop:" + stop);
  return is_stop_by_new_price_between_(3 * stop);
}

bool StopManager::is_dep_btw_stop_and_price_beyond_3_stop()
{
  bool is_beyond = !is_dep_btw_stop_and_price_in_3_stop();
  Print("is_dep_btw_stop_and_price_beyond_3_stop:" + is_beyond);
  return is_beyond;
}

void StopManager::move_stop_to_open_plus_one_point()
{
  Print("move_stop_to_open_plus_one_point");
  double open_price = OrderOpenPrice();
  if (OrderType() == OP_BUY)
  {
    m_orderHelper.modify_stop_lost_for_long(open_price+Point());
    return;
  }

  //卖
  if (OrderType() == OP_SELL)
  {
    m_orderHelper.modify_stop_lost_for_short(open_price-Point());
    return;
  }
}

/**
 * 止损策略采用，尽快将止损移动到开仓价的位置。再采用步进移动止损的策略。
*/
void StopManager::set_stop_loss_greed_by_step()
{
  if (!select_latest_order())
  {
    Print("set_stop_loss_greed_by_step:未能选中最新的订单。");
    return;
  }

  double latest_stop = OrderStopLoss();
  if (m_util.double_equal(latest_stop, 0))
  {
    set_defual_stop();
    return;
  }

  if (is_stop_minus() && is_dep_btw_stop_and_price_beyond_3_stop())
  {
    move_stop_to_open_plus_one_point();
    return;
  }

  if (is_stop_between_step_max())
  {
    move_stop_per_step();
    return;
  }

  //1/3的盈利处。
  Print("set_stop_loss_greed_by_step：执行1/3移动止损策略。");
  set_trailing_3_1();
}