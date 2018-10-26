/**
 * 
 * 对策略的抽象类，包含了基本几个函数的实现。
*/
#include "../util/time_util.mqh"
#include "../position/position_manager.mqh"
#include "../position/stop_manager.mqh"

class AbstractStrategy
{
  protected:
    PositionManager m_positionManager;
    StopManager m_stopManager;
    TimeUtil m_timeUtil;

  public:
    AbstractStrategy(/* args */);
    ~AbstractStrategy();

  public:
    virtual void onTick();

  public:
    virtual void checkForOpen();  // 开仓
    virtual void checkForClose(); // 平仓
    virtual void checkForScale(); // 加仓
    virtual void calcStopLoss();  // 止损

    virtual void do_every_tick(){};

  protected:
    virtual void open_long();
    virtual void open_short();
    virtual bool has_long_position();
    virtual bool has_short_position();

    virtual void close_long();
    virtual void close_short();

  protected:
    virtual bool has_chance_for_long() = NULL;
    virtual bool has_chance_for_short() = NULL;
    virtual bool may_long() = NULL;
    virtual bool may_short() = NULL;
};

AbstractStrategy::AbstractStrategy(/* args */)
{
}

AbstractStrategy::~AbstractStrategy()
{
}

void AbstractStrategy::onTick()
{
    do_every_tick();
    if (m_positionManager.get_curr_orders() == 0)
    {
        checkForOpen();
    }
    else
    {
        checkForScale();
        checkForClose();
    }

    calcStopLoss();
}

/**
 * 开仓
*/
void AbstractStrategy::checkForOpen()
{
    if (m_timeUtil.is_friday_last_fifteen())
    {
        Print("checkForOpen:周五晚上的最后一刻钟，不开仓。");
        return;
    }

    // if (!m_positionManager.is_hisorder_pass_break())
    // {
    //     Print("checkForOpen：上笔才过去，一段时间内不再开仓。");
    //     return;
    // }

    // if (!m_positionManager.is_last_lost_and_passed())
    // {
    //     Print("checkForOpen：上笔订单亏损，一段时间内不再开仓交易。");
    //     return;
    // }

    // if (has_chance_for_long())
    // {
    //     open_long();
    // }

    // if (has_chance_for_short())
    // {
    //     open_short();
    // }
    if (!m_positionManager.is_hisorder_pass_break())
    {
        Print("checkForOpen：上笔才过去，一段时间内不再开仓。");
        return;
    }

    if (!m_positionManager.is_last_lost_and_passed())
    {
        Print("checkForOpen：上笔订单亏损，一段时间内不再开仓交易。");
        return;
    }

    if (has_chance_for_long())
    {
        open_long();
    }

    if (has_chance_for_short())
    {
        open_short();
    }
}

/**
 * 平仓
*/
void AbstractStrategy::checkForClose()
{
    if (has_long_position() && may_short())
    {
        close_long();
    }

    if (has_short_position() && may_long())
    {
        close_short();
    }
}

/**
 * 加仓
*/
void AbstractStrategy::checkForScale()
{
    if (m_positionManager.get_curr_orders() == 0)
    {
        return;
    }

    if (m_positionManager.is_current_opened())
    {
        Print("CheckForScaleIn:当前周期已经开过仓位");
        return;
    }

    if (!m_stopManager.is_stop_cover_trailing_profit())
    {
        Print("checkForScale:止损位没有覆盖开仓后的移动止损价格.");
        return;
    }

    checkForOpen();
}

/**
 * 止损
*/
void AbstractStrategy::calcStopLoss()
{
    m_stopManager.set_stop_less_by_boll();
}

void AbstractStrategy::open_long()
{
    m_positionManager.open_long();
}
void AbstractStrategy::open_short()
{
    m_positionManager.open_short();
}

bool AbstractStrategy::has_long_position()
{
    return m_positionManager.get_curr_long_positions() > 0;
}
bool AbstractStrategy::has_short_position()
{
    return m_positionManager.get_curr_short_positions() > 0;
}

void AbstractStrategy::close_long()
{
    m_positionManager.close_all_long_positions();
}

void AbstractStrategy::close_short()
{
    m_positionManager.close_all_short_positions();
}
