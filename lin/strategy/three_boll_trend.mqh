//+------------------------------------------------------------------+
//|                                             three_boll_trend.mq4 |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "linbirg"
#property link "https://www.mql5.com"
#property version "1.00"
#property strict

#include "../util/util.mqh"
#include "../indicator/boll.mqh"
// #include "../orders/order_helper.mqh"
#include "../position/position_manager.mqh"
#include "../position/stop_manager.mqh"
#include "abstract_strategy.mqh"

input double TrailingStop = 280; // 移动止损

class ThreeBollTrendStrategy : public AbstractStrategy
{
private:
  Boll1MN m_boll1mn;
  Boll1W m_boll1W;
  Boll1D m_bollDay;
  Boll4H m_boll4H;
  Boll1H m_boll1H;
  Boll15M m_boll15M;
  Boll5M m_boll5M;

  // PositionManager m_positionManager;
  // StopManager m_stopManager;
  // Util m_util;

public:
  ThreeBollTrendStrategy(/* args */);
  ~ThreeBollTrendStrategy();

private:
  bool has_chance_for_long();
  bool has_chance_for_short();
  bool may_long();
  bool may_long_by_day();
  bool may_short();
  bool may_short_by_day();

  void do_every_tick();

  // public:
  //   void onTick();

  // public:
  //   void checkForOpen();  //开仓
  //   void checkForClose(); //平仓
  void checkForScale(); //加仓

public:
  void calcStopLoss(); //止损策略
  // private:
  //   bool has_chance_for_long();
  //   void open_long();
  //   bool has_chance_for_short();
  //   void open_short();
  //   bool has_long_position();
  //   bool has_short_position();
  //   bool may_long();
  //   bool may_short();

  //   void close_long();
  //   void close_short();

private:
  void flush_bolls();
  string print_market_state();
  string print_boll_state(Boll &boll, string name);
};

ThreeBollTrendStrategy::ThreeBollTrendStrategy(/* args */)
{
  m_stopManager.setTrailingStop(TrailingStop);
}

ThreeBollTrendStrategy::~ThreeBollTrendStrategy()
{
}

void ThreeBollTrendStrategy::checkForScale()
{

  if (m_bollDay.is_flat())
  {
    Print("checkForScale:日线没有趋势，不加仓。");
    return;
  }

  AbstractStrategy::checkForScale();
}

void ThreeBollTrendStrategy::do_every_tick()
{
  flush_bolls();
  string st_str = print_market_state();
  Print(st_str);
  Comment(st_str);
}

void ThreeBollTrendStrategy::flush_bolls()
{
  m_boll1mn.calc();
  m_boll1W.calc();
  m_bollDay.calc();
  m_boll4H.calc();
  m_boll1H.calc();
  m_boll15M.calc();
  m_boll5M.calc();
}
string ThreeBollTrendStrategy::print_boll_state(Boll &boll, string name)
{
  string desc = "none";
  if (boll.is_long())
  {
    desc = "long";
  }
  else if (boll.is_short())
  {
    desc = "short";
  }
  else if (boll.is_flat())
  {
    desc = "flat";
  }

  return name + " " + desc;
}

string ThreeBollTrendStrategy::print_market_state()
{
  string state_str = "state:";

  state_str += print_boll_state(m_boll1mn, "1MN");

  state_str += " ";
  state_str += print_boll_state(m_boll1W, "1W");

  state_str += " ";
  state_str += print_boll_state(m_bollDay, "D1");

  state_str += " ";
  state_str += print_boll_state(m_boll4H, "4H");

  state_str += " ";
  state_str += print_boll_state(m_boll1H, "1H");

  state_str += " ";
  state_str += print_boll_state(m_boll15M, "15M");

  state_str += " ";
  state_str += print_boll_state(m_boll5M, "5M");

  return state_str;
}

/**
 * 
 * 止损策略：以5M的上中线轨为基础，随时间推移逐步扩展到15M，1H，4H的上中下轨。
*/
void ThreeBollTrendStrategy::calcStopLoss()
{
  // m_stopManager.set_defual_stop();

  // if (m_boll1mn.is_flat() && m_boll1W.is_flat() && m_bollDay.is_flat())
  //   m_stopManager.set_stop_less_by_boll();
  m_stopManager.set_stop_less_by_step();
}

/**
 * 
 * 日线boll看多，4H看多，1H看多，根据5M线择机开多仓
*/
bool ThreeBollTrendStrategy::has_chance_for_long()
{
  // return m_boll1H.is_long() && (m_boll15M.is_long() || m_boll5M.is_long());
  return (m_boll4H.is_long() || m_bollDay.is_long() || m_boll1W.is_long() || m_boll1mn.is_long()) && // 顺序由4H到1MN
         m_boll1H.is_long() && (m_boll15M.is_long() || m_boll5M.is_long());
}

bool ThreeBollTrendStrategy::has_chance_for_short()
{
  //m_bollDay.is_short() &&m_boll4H.is_short() &&
  // return m_boll1H.is_short() && (m_boll15M.is_short() || m_boll5M.is_short());
  return (m_boll4H.is_short() || m_bollDay.is_short() || m_boll1W.is_short() || m_boll1mn.is_short()) &&
         m_boll1H.is_short() && (m_boll15M.is_short() || m_boll5M.is_short());
}

bool ThreeBollTrendStrategy::may_long()
{
  if (m_boll1W.is_short())
  {
    return false;
  }

  return may_long_by_day();
}

/*
* 用于判断空头反转。
* 如果日线不空，则只要1H不空为may long，如果日线为空，则以4H走多为反转。
*/
bool ThreeBollTrendStrategy::may_long_by_day()
{
  // 存在大趋势
  if (m_boll1W.is_short() || m_boll1mn.is_short())
  {
    return m_bollDay.is_long();
  }

  // 没有大趋势，看中趋势日线,如果日线没有走long，则只要4H线不走long
  if (!m_bollDay.is_long())
  {
    return m_boll4H.is_long();
  }

  return !m_boll1H.is_short();
}

bool ThreeBollTrendStrategy::may_short()
{
  if (m_boll1W.is_long())
  {
    return false;
  }

  return may_short_by_day();
}

/**
 * 用于判断多头的反转。
 * 如果日线多头，则以4H的反转为反转；如果日线不多，则以1H的不多为反转。
 * 
*/
bool ThreeBollTrendStrategy::may_short_by_day()
{
  // 存在大趋势
  if (m_boll1W.is_long() || m_boll1mn.is_long())
  {
    return m_bollDay.is_short();
  }

  // 没有大趋势，看中趋势日线,如果日线没有走long，则只要4H线不走long
  if (!m_bollDay.is_short())
  {
    return m_boll4H.is_short();
  }

  return !m_boll1H.is_long();
}
