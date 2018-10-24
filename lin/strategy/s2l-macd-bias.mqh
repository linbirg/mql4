/**
 * 
 * 重构s2l-macd-bias.mqh linbirg@2018/10/16.
 * 改为面向对象编程，以便后续重构和逻辑调整。
 * 
*/
//+------------------------------------------------------------------+
// Changelog:
// 1.增加macd的快慢参数配置功能。
// 2.均线以慢参数为参考
// 3.移除了第三个信号与macd必须拉开一定距离的判断
// Changelog:
// 1.修改均线为MATrendPeriod*2
// 2.修改判断方向的均线由两个变为三个，但是条件放松到只要不是反方向就行
// Changelog:
// 1.修改均线为MATrendPeriod，两个均线判断方向。
// Changelog:
// 1.增加盘整行情的判断，如果没有检测到金叉或者死叉时，存在盘整行情，可以开仓。
// Changelog:2015.06.12
// 1.判断均线向上或者向下的时候，均线相等时返回false。即向下必须Ma0<Ma1，向上必须Ma0>Ma1。
// 2.用参数Lots来控制下单数量。
// ChangeLog:2015.06.16
// 1.代码进行了重构，将主程序逻辑改为三步：检查开仓、检查平仓、移动止损
// 2.平仓的逻辑改为只看均线。
// ChangeLog:2015.06.23
// 1.修改平仓的均线判断，改为判断M1和M2，如果用M0会导致随着行情波动，在一个周期内会多次开平仓的bug。
// ChangeLog:2015.07.02
// 增加了对平仓均线的变化幅度的判断，从而过滤短期波动的影响。坏处是减少了平仓的灵活性，增加了响应时间，使潜在风险增大。
// ChangeLog:2015.07.03
// 1.增加记录开仓和平仓时间，一个周期内只判断一次开平仓。

// Changelog.2015.07.16
// 1.增加连续2单亏损停止一段时间的逻辑。
// 2.增加震荡行情不开仓的逻辑。
// 3.增加加仓逻辑和加仓后如果总收益要亏损，平掉所有头寸的逻辑。
// 4.将平仓逻辑改为不是原来的方向就平，从而减少了回撤时的损失，但是增加了方向判断正确而被回撤打掉单子的概率，从而会减少收益，但是相比风险来说，风险更重要。

// Changelog.2015.07.23
// 1.重构了止损的函数。引入atr的方式计算移动止损，移动止损为开仓方向上atr、ma、2*ma中离价格最远者。
//

// Changelog.2015.08.04
// 1.增加周五最后一刻钟不开仓,如果有持仓,强制平仓的逻辑

// Changelog.2015.08.04
// 1.修改了判断isLastLostAndPassed的逻辑，函数默认返回false，只有在亏损次数小于制定值或者时间过去足够久才返回true
// Changelog.2015.08.07
// 1.参数化亏损后暂停的时期数

// Changelog.2015.08.11.v1.0
// 1.修改止损策略，当价格大于一定幅度之后，将止损设置为开盘价，以保证不亏损。
// 2.引入4小时周期，开盘必须4小时周期均线看多或者看空，不再开于4小时均线向反的仓。
// 3.平仓策略改为看4小时图的均线。
// 4.移动止损，改为参考15分钟的60均线，4小时图的13均线，26均线和52均线。
// 5.4小时均线以26周期为参考。

// Changelog.2015.08.24
// 1修改了isScaledIn函数的判断逻辑，增加对symbol的判断，这样可以不同图标的策略分开。

// Changelog.2015.08.27
// 1.增加乖离率的概念，才用价格偏离26日均线的点数作为乖离率的值，偏离大于MAXBIAS点时，采用ATR作为止损，从而起到保护的作用。
// 2.增加短线转长线的逻辑，当止损采用的均线大于4小时的26日均线或者大于60日均线或者120均线时，采用相应均线作为判断均线是否转向的依据。

// Changelog.2015.09.23
// 1.重构了代码结构，分模块重构代码
// 2.增加开仓时，持仓判断，如果有持仓，只按持仓方向加仓。没有持仓则看均线和多空的方向。

// Changelog.2015.10.02
// 1.增加如果连续亏损多次则长时间内不开仓的逻辑
// 2.增加开仓时通过5分钟短线，判断是否远离均线来寻找进入的机会。

// Changelog.2015.10.23
// 1.增加逻辑：如果日线三线同向，则向长期转。如果三线不同向，则可能存在风险，以短期为主，4小时26均线掉头则平仓

// Changelog.2018.09.11
// 增加衡量保单好坏的指标k(in),k(out),k(comfort)以及最大盈利、最大亏损等的统计信息。

// changelog.2018.10.24
// 完成面向对象编程的重构。

// #include "../util/time_util.mqh"
// #include "../position/position_manager.mqh"
// #include "../position/stop_manager.mqh"

#include "abstract_strategy.mqh"
#include "../indicator/ma.mqh"
#include "../indicator/macd.mqh"

class S2LMacdBiasStragy : public AbstractStrategy
{
  private:
    DoubleMA4H m_maH4;
    DoubleMA15M m_mam15;
    Macd m_macd15;
    Macd4H m_macd4h;

  public:
    S2LMacdBiasStragy(/* args */);
    ~S2LMacdBiasStragy();

  private:
    bool has_chance_for_long();
    bool has_chance_for_short();
    bool may_long();
    bool may_short();

  private:
    // 重构s2l-macd
    bool check_for_long();
    bool check_for_short();
};

S2LMacdBiasStragy::S2LMacdBiasStragy(/* args */)
{
    m_stopManager.setTrailingStop(300);
}

S2LMacdBiasStragy::~S2LMacdBiasStragy()
{
}

bool S2LMacdBiasStragy::has_chance_for_long()
{
    if (m_mam15.is_consolidation())
    {
        Print("has_chance_for_long：15分钟震荡行情。");
    }

    if (m_maH4.is_consolidation())
    {
        Print("has_chance_for_long：4H震荡行情。");
    }
    //m_maH4.is_ma_up() && m_macd4h.is_long() &&
    return m_mam15.is_ma_up() && check_for_long() && m_mam15.is_near_by_fast() && m_mam15.is_far_away_fast();
}
bool S2LMacdBiasStragy::has_chance_for_short()
{
    if (m_mam15.is_consolidation())
    {
        Print("has_chance_for_long：15分钟震荡行情。");
    }

    if (m_maH4.is_consolidation())
    {
        Print("has_chance_for_long：4H震荡行情。");
    }
    //m_maH4.is_ma_down() && m_macd4h.is_short() &&
    return m_mam15.is_ma_down() && check_for_short() && m_mam15.is_near_by_fast() && m_mam15.is_far_away_fast();
}

/**
 * 
 * 持空仓，看是否可能走多。
*/
bool S2LMacdBiasStragy::may_long()
{
    return m_maH4.is_ma_up();
}

/**
 * 
 * 持多仓，看是否可能走空
*/
bool S2LMacdBiasStragy::may_short()
{
    return m_maH4.is_ma_down();
}

bool S2LMacdBiasStragy::check_for_long()
{
    if (!m_macd15.is_up())
        return false;

    //如果是0轴上的第一个金叉，且离0轴不远，均线向上，买

    //如果是0轴下的金叉，（且离0轴很远），均线向上，买

    //如果没有金叉（或者金叉离0轴很远），判断是盘整行情，均线向上，买
    //     if (isNearByMAAndFarAway() && isMaUp(PERIOD_M5, MAOpenLevel, getNearByMa()))
    //     {
    //         Print("has_chance_for_long:true");
    //         return true;
    //     }

    int i = m_macd15.find_first_gold();

    if (i > 24)
    { //24周期内，没有金叉
        if (m_mam15.is_consolidation())
        {
            Print("CheckForLong:检测到盘整行情，现在已经确定走势，可以开仓。");
            return true;
        }

        return false;
    }

    return true;
}

bool S2LMacdBiasStragy::check_for_short()
{
    if (!m_macd15.is_down())
        return false;

    //如果是0轴上的第一个金叉，且离0轴不远，均线向上，买

    //如果是0轴下的金叉，（且离0轴很远），均线向上，买

    //如果没有金叉（或者金叉离0轴很远），判断是盘整行情，均线向上，买

    int i = m_macd15.find_first_death();

    if (i > 24)
    { //24周期内，没有死叉
        if (m_mam15.is_consolidation())
        {
            Print("CheckForLong:检测到盘整行情，现在已经确定走势，可以开仓。");
            return true;
        }

        return false;
    }

    return true;
}
