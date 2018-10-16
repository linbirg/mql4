//+------------------------------------------------------------------+
//|                                                          boll.mqh |
//|                                                          linbirg |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

#include "indicator_grp.mqh"
#include "../core/indicator_interface.mqh"

/**
 * 基于Boll指标的自定义指标，除了boll指标本身，还存储boll上线轨的速度、加速度等指标。 
 * 
 * 
*/
class Boll : public IIndicator
{
  public:
    Boll()
    {
        m_frame = PERIOD_M15; // 主周期，15m
        m_period = 20;        // 周期
        m_num_std = 2;        // 标准差个数

        m_buffer_size = 1000;
        reset_buf();
        //init_config();

        m_start_time = iTime(NULL, m_frame, m_buffer_size);
    };

  public:
    void setTimeFrame(int frame);
    void setBufferSize(int size);

  public:
    bool is_long();  //多
    bool is_short(); //空
    bool is_flat();  //走平

    void calc();

    string format_to_str();

  public:
    IndicatorArrayGroup *getUpperIndicator()
    {
        return GetPointer(m_upperIndicator);
    };

    IndicatorArrayGroup *getMainIndicator()
    {
        return GetPointer(m_mainIndicator);
    };

    IndicatorArrayGroup *getLowerIndicator()
    {
        return GetPointer(m_lowerIndicator);
    };

    IndicatorArrayGroup *getBandIndicator()
    {
        return GetPointer(m_bandIndicator);
    };

    //   public:
    // void setMainIndConfig(IndiGrpConfig &config) { m_mainIndicator.setConfig(config); };
    // void setUpperIndConfig(IndiGrpConfig &config) { m_upperIndicator.setConfig(config); };
    // void setLowerIndConfig(IndiGrpConfig &config) { m_lowerIndicator.setConfig(config); };
    // void setBandIndConfig(IndiGrpConfig &config) { m_bandIndicator.setConfig(config); };

  private:
    // void calc_main_ma_delta();
    // void calc_upper();
    void calc_band();
    void reset_buf();
    void nec_calc_band();

  private:
    // double calc_array_ma(const double &data[]);
    // double calc_array_std(const double &data[]);

    //   protected:
    // void init_main_conf(){};
    // void init_upper_conf(){};
    // void init_lower_conf(){};
    // void init_band_conf(){};

    // void init_config()
    // {
    //     init_main_conf();
    //     init_upper_conf();
    //     init_lower_conf();
    //     init_band_conf();
    // };

  private:
    int m_frame; // 主周期，15m

    int m_period;  // 周期
    int m_num_std; // 标准差个数

    datetime m_start_time; // 开始计算的时间。

  private:
    IndicatorArrayGroup m_mainIndicator;
    IndicatorArrayGroup m_upperIndicator;
    IndicatorArrayGroup m_lowerIndicator;

    IndicatorArrayGroup m_bandIndicator; //上下轨的宽度

    int m_buffer_size;
};

void Boll::setTimeFrame(int frame)
{
    m_frame = frame;
}

void Boll::setBufferSize(int size)
{
    m_buffer_size = size;
    reset_buf();
}

void Boll::reset_buf()
{
    m_upperIndicator.resize(m_buffer_size);
    m_mainIndicator.resize(m_buffer_size);
    m_lowerIndicator.resize(m_buffer_size);
    m_bandIndicator.resize(m_buffer_size);
}

string Boll::format_to_str()
{
    return "upper:" + m_upperIndicator.format_to_str() + "\n" + "mian:" + m_mainIndicator.format_to_str() + "\n" + "lower:" + m_lowerIndicator.format_to_str();
}

void Boll::calc()
{
    nec_calc_band();

    // m_upperIndicator.calc();
    // m_mainIndicator.calc();
    // m_lowerIndicator.calc();
}

/**
 * 
 * 以增量方式计算boll的上中下轨道的值以及band宽度的值。
*/
void Boll::nec_calc_band()
{
    datetime now = iTime(NULL, m_frame, 0);
    int count = (now - m_start_time) / (60 * m_frame);

    for (int i = 0; i < count; i++)
    {
        m_mainIndicator.append(iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_MAIN, i));
        m_upperIndicator.append(iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_UPPER, i));
        m_lowerIndicator.append(iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_LOWER, i));
        m_bandIndicator.append(iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_UPPER, i) -
                               iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_LOWER, i));
    }

    m_start_time = now;
}

// void Boll::calc_band()
// {
//     for (int i = m_buffer_size - 1; i >= 0; i--)
//     {
//         m_mainIndicator.setValue(i, iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_MAIN, i));
//         m_upperIndicator.setValue(i, iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_UPPER, i));
//         m_lowerIndicator.setValue(i, iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_LOWER, i));
//         m_bandIndicator.setValue(i, iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_UPPER, i) -
//                                         iBands(NULL, m_frame, m_period, m_num_std, 0, PRICE_CLOSE, MODE_LOWER, i));
//     }
// }

// void Boll::calc_upper()
// {
//     // m_upperIndicator.calc();
// }

// double Boll::calc_array_ma(const double &data[])
// {
//     return iMAOnArray(data, 0, m_period, 0, MODE_EMA, 0);
// }

// double Boll::calc_array_std(const double &data[])
// {
//     return iStdDevOnArray(data, 0, m_period, 0, MODE_EMA, 0);
// }

/**
 * 中上轨加速向上，三轨平稳，波动不大，三轨差值扩大但处于范围的中间分布。
*/
bool Boll::is_long()
{
    // bool is_upper_acc_up = m_upperIndicator.is_acc_up();
    bool is_main_multi_up = m_mainIndicator.is_multi_up();
    bool is_band_in_mid = m_bandIndicator.is_in_middle();

    // bool is_upper_smooth = m_upperIndicator.is_smooth();
    // bool is_main_smooth = m_mainIndicator.is_smooth();
    // bool is_lower_smooth = m_lowerIndicator.is_smooth();

    // Print("Boll::is_long:" +
    //       " period:" + m_frame +
    //       //   " is_upper_acc_up:" + is_upper_acc_up +
    //       " is_main_multi_up:" + is_main_multi_up +
    //       " is_band_in_mid:" + is_band_in_mid);

    // return (is_upper_acc_up && is_main_acc_up) && (is_band_in_mid);
    return (is_main_multi_up) && (is_band_in_mid); // && m_bandIndicator.is_acc_up()
}
/**
 * 中下轨加速向下，三轨平稳，波动不大，三轨差值扩大但处于范围的中间分布。
*/
bool Boll::is_short()
{
    // return (m_lowerIndicator.is_acc_down() && m_mainIndicator.is_acc_down()) && (m_bandIndicator.is_in_middle());
    bool is_main_multi_down = m_mainIndicator.is_multi_down();
    bool is_band_in_mid = m_bandIndicator.is_in_middle();
    // Print("Boll::is_short:" +
    //       " period:" + m_frame +
    //       " is_main_multi_down:" + is_main_multi_down +
    //       " is_band_in_mid:" + is_band_in_mid);
    return (is_main_multi_down) && (is_band_in_mid);
    //   &&m_bandIndicator.is_acc_up();
}

/**
 * 三轨差值很小， 三轨走平（速度和加速度都很小，甚至为很小的负数），波动不大（三轨方差缩小且处于较小范围）。
*/
bool Boll::is_flat()
{
    return !is_long() && !is_short();
}

/**
 * 
 * Boll5M
*/
class Boll5M : public Boll
{
  public:
    Boll5M(/* args */);
    ~Boll5M();

  private:
    void init();
};

Boll5M::Boll5M(/* args */)
{
    init();
}

Boll5M::~Boll5M()
{
}

void Boll5M::init()
{
    setTimeFrame(5);
}

/**
 * 
 * Boll15M
*/
class Boll15M : public Boll
{
  public:
    Boll15M(/* args */);
    ~Boll15M();

  private:
    void init();
};

Boll15M::Boll15M(/* args */)
{
    init();
}

Boll15M::~Boll15M()
{
}

void Boll15M::init()
{
    setTimeFrame(15);
}

/**
 * 
 * Boll1H
*/
/**
 * 
 * Boll15M
*/
class Boll1H : public Boll
{
  public:
    Boll1H(/* args */);
    ~Boll1H();

  private:
    void init();
};

Boll1H::Boll1H(/* args */)
{
    init();
}

Boll1H::~Boll1H()
{
}

void Boll1H::init()
{
    setTimeFrame(60);
}

/**
 * 
 * Boll4H
*/
class Boll4H : public Boll
{
  public:
    Boll4H(/* args */);
    ~Boll4H();

  private:
    void init();
};

Boll4H::Boll4H(/* args */)
{
    init();
}

Boll4H::~Boll4H()
{
}

void Boll4H::init()
{
    setTimeFrame(240);
}

/**
 * 
 * Boll1D
*/
class Boll1D : public Boll
{
  public:
    Boll1D(/* args */);
    ~Boll1D();

  private:
    void init();
};

Boll1D::Boll1D(/* args */)
{
    init();
}

Boll1D::~Boll1D()
{
}

void Boll1D::init()
{
    setTimeFrame(1440);
}
