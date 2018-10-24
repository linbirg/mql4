#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

#include "../util/util.mqh"
#include "serise_metrix.mqh"
#include "../core/array.mqh"

// class Config
// {
//   public:
//     double m_mid_low;
//     double m_mid_high;

//   public:
//     Config(/* args */) : m_mid_low(0), m_mid_high(0){};
//     ~Config(){};

//     Config(const Config &other) : m_mid_high(other.m_mid_high), m_mid_low(other.m_mid_low){};

//     void operator=(const Config &other)
//     {
//         // Config one;
//         // one.m_mid_high = other.m_mid_high;
//         // one.m_mid_low = other.m_mid_low;
//         // return one;
//         m_mid_high = other.m_mid_high;
//         m_mid_low = other.m_mid_low;
//     };

//     string format_to_str()
//     {
//         return " m_mid_low:" + m_mid_low + " m_mid_high:" + m_mid_high;
//     };
// };

// class IndConfig
// {
//   public:
//     IndConfig(){};
//     ~IndConfig(){};
//     IndConfig(const IndConfig &other);

//     void operator=(const IndConfig &other)
//     {
//         // IndConfig one;
//         // one.m_ind = other.m_ind;
//         // one.m_ind_ma = other.m_ind_ma;
//         // one.m_ind_std = other.m_ind_std;
//         // return one;
//         m_ind = other.m_ind;
//         m_ind_ma = other.m_ind_ma;
//         m_ind_std = other.m_ind_std;
//     };

//     string format_to_str()
//     {
//         return " m_ind:" + m_ind.format_to_str() + " m_ind_ma:" + m_ind_ma.format_to_str() + " m_ind_std:" + m_ind_std.format_to_str();
//     };

//   public:
//     Config m_ind;
//     Config m_ind_ma;
//     Config m_ind_std;
// };

// IndConfig::IndConfig(const IndConfig &other)
// {
//     m_ind = other.m_ind;
//     m_ind_ma = other.m_ind_ma;
//     m_ind_std = other.m_ind_std;
// };

// class IndiGrpConfig
// {
//   public:
//     IndiGrpConfig(){};
//     ~IndiGrpConfig(){};
//     IndiGrpConfig(const IndiGrpConfig &other);

//     void operator=(const IndiGrpConfig &other);

//     string format_to_str()
//     {
//         return " m_indicator:" + m_indicator.format_to_str() + " m_speed:" + m_speed.format_to_str() + " m_acc:" + m_acc.format_to_str();
//     };

//   public:
//     IndConfig m_indicator;
//     IndConfig m_speed;
//     IndConfig m_acc;
// };

// IndiGrpConfig::IndiGrpConfig(const IndiGrpConfig &other)
// {
//     m_indicator = other.m_indicator;
//     m_speed = other.m_speed;
//     m_acc = other.m_acc;
// };

// void IndiGrpConfig::operator=(const IndiGrpConfig &other)
// {
//     // IndiGrpConfig one;
//     // one.m_indicator = other.m_indicator;
//     // one.m_speed = other.m_speed;
//     // one.m_acc = other.m_acc;
//     // return one;
//     m_indicator = other.m_indicator;
//     m_speed = other.m_speed;
//     m_acc = other.m_acc;
// }

/**
 * 
 * 一个IndicatorArrayGroup，包含数组本身，ma，delta，速度，加速度
*/
class IndicatorArrayGroup
{
  public:
    IndicatorArrayGroup()
    {
        m_buffer_size = 0;
        m_period = 20;

        init_buffer();
    };

    void resize(int size);

    // bool setValue(int index, double val);
    void setPeriod(int period);

    double calc_ma_with_period(int period);
    double calc_std_with_period(int period);

    double calc_speed();
    double calc_speed_ma();
    double calc_speed_std();

    double calc_acceleration();
    double calc_acceleration_ma();
    double calc_acceleration_std();

    double calc_20ma();
    double calc_ma();
    double calc_20std();
    double calc_std();

    // void calc();
    bool append(double val);

  public:
    double getValue(int index);
    double getMa(int index);
    double getStd(int index);
    double getSpeed(int index);
    double getSpeedMa(int index);
    double getSpeedStd(int index);
    double getAcceleration(int index);
    double getAccelerationMa(int index);
    double getAccelerationStd(int index);

    string format_to_str();

  public:
    bool is_acc_up();
    // bool is_smooth();
    bool is_acc_down();
    bool is_in_middle();
    bool is_in_low();
    bool is_in_high();

    bool is_up();
    bool is_down();
    bool is_acc();
    bool is_dece();

    bool is_multi_up(int cnt = 3);   // 连续cnt次都为up。
    bool is_multi_down(int cnt = 3); // 连续cnt次都为down。

    bool is_flat();
    bool is_acc_in_low();
    bool is_speed_in_low();

    //   public:
    //     void getIndicator(double &dist[]) { m_util.copy(dist, m_indicator, m_buffer_size); };
    //     void getIndicatorMa(double &dist[]) { m_util.copy(dist, m_indicator_ma, m_buffer_size); };

    //     void getIndicatorStd(double &dist[]) { m_util.copy(dist, m_indicator_std, m_buffer_size); };

    //     void getSpeed(double &dist[]) { m_util.copy(dist, m_speed, m_buffer_size); };
    //     void getSpeedMa(double &dist[]) { m_util.copy(dist, m_speed_ma, m_buffer_size); };
    //     void getSpeedStd(double &dist[]) { m_util.copy(dist, m_speed_std, m_buffer_size); };

    //     void getAcc(double &dist[]) { m_util.copy(dist, m_acceleration, m_buffer_size); };
    //     void getAccMa(double &dist[]) { m_util.copy(dist, m_acceleration_ma, m_buffer_size); };
    //     void getAccStd(double &dist[]) { m_util.copy(dist, m_acceleration_std, m_buffer_size); };

  private:
    void init_buffer();

  private:
    // double sum_to(const TArraySerise<double> &serise, int from, int to);
    double calc_serise_ma_with_period(const TArraySerise<double> &serise, int period);
    double calc_serise_std_with_period(const TArraySerise<double> &src, const TArraySerise<double> &ma, int period);

  private:
    TArraySerise<double> m_indicator;
    TArraySerise<double> m_indicator_ma;
    TArraySerise<double> m_indicator_std;

    TArraySerise<double> m_speed;
    TArraySerise<double> m_speed_ma;
    TArraySerise<double> m_speed_std;

    TArraySerise<double> m_acceleration;
    TArraySerise<double> m_acceleration_ma;
    TArraySerise<double> m_acceleration_std;

    int m_buffer_size;
    int m_period;

    SeriseMetrix m_metrx;
    Util m_util;

    //   private:
    //     IndiGrpConfig m_config;

    //   public:
    // IndiGrpConfig getConfig() { return m_config; };
    // void setConfig(IndiGrpConfig &conf)
    // {
    //     m_config = conf;
    // };
    // string format_conf_to_str() { return m_config.format_to_str(); };
};

void IndicatorArrayGroup::init_buffer()
{
    // ArrayResize(m_indicator, m_buffer_size);
    int max_size = m_buffer_size * 2;

    m_indicator.set_max_size(max_size);
    m_indicator_ma.set_max_size(max_size);
    m_indicator_std.set_max_size(max_size);

    m_speed.set_max_size(max_size);
    m_speed_ma.set_max_size(max_size);
    m_speed_std.set_max_size(max_size);

    m_acceleration.set_max_size(max_size);
    m_acceleration_ma.set_max_size(max_size);
    m_acceleration_std.set_max_size(max_size);
}

void IndicatorArrayGroup::resize(int size)
{
    m_buffer_size = size;
    init_buffer();
    m_metrx.reset();
}

// bool IndicatorArrayGroup::setValue(int index, double val)
// {
//     if (index >= m_buffer_size)
//         return false;

//     m_indicator[index] = val;
//     return true;
// }

bool IndicatorArrayGroup::append(double val)
{
    m_indicator.append(val);

    double ma = calc_ma();
    m_indicator_ma.append(ma);
    double std = calc_std();
    m_indicator_std.append(std);

    double speed = calc_speed();
    m_speed.append(speed);
    double speed_ma = calc_speed_ma();
    m_speed_ma.append(speed_ma);
    double speed_std = calc_speed_std();
    m_speed_std.append(speed_std);

    double acce = calc_acceleration();
    m_acceleration.append(acce);
    double acce_ma = calc_acceleration_ma();
    m_acceleration_ma.append(acce_ma);
    double acce_std = calc_acceleration_std();
    m_acceleration_std.append(acce_std);

    return true;
}

double IndicatorArrayGroup::getValue(int index)
{
    // 应该要界值校验
    return m_indicator[index];
}

double IndicatorArrayGroup::getMa(int index)
{
    // 应该要界值校验
    return m_indicator_ma[index];
}

double IndicatorArrayGroup::getStd(int index)
{
    // 应该要界值校验
    return m_indicator_std[index];
}

double IndicatorArrayGroup::getSpeed(int index)
{
    return m_speed[index];
}

double IndicatorArrayGroup::getSpeedMa(int index)
{
    return m_speed_ma[index];
}

double IndicatorArrayGroup::getSpeedStd(int index)
{
    return m_speed_std[index];
}

double IndicatorArrayGroup::getAcceleration(int index)
{
    return m_acceleration[index];
}

double IndicatorArrayGroup::getAccelerationMa(int index)
{
    return m_acceleration_ma[index];
}

double IndicatorArrayGroup::getAccelerationStd(int index)
{
    return m_acceleration_std[index];
}

// void IndicatorArrayGroup::getIndicator(double &dist[])
// {
//     ArrayResize(dist, m_buffer_size);
//     ArrayCopy(dist, m_indicator);
// }

void IndicatorArrayGroup::setPeriod(int period)
{
    m_period = period;
}

// double IndicatorArrayGroup::sum_to(const TArraySerise<double> &serise, int from, int to);
// {
//     double total = 0;

//     for (int i = from; i < to; i++)
//     {
//         total += data[i];
//     }

//     return total;
// }

double IndicatorArrayGroup::calc_ma_with_period(int period)
{
    // if (period <= 0 || m_indicator.size() <= 0)
    // {
    //     Print("PeriodError:周期数不能小于零或者缓冲区大小不能为零。");
    //     return 0;
    // }

    // int size = m_indicator.size();
    // int cnt = period;
    // if (size < period)
    // {
    //     cnt = size;
    // }

    // double total = 0;
    // for (int i = 0; i < cnt; i++)
    // {
    //     total += m_indicator[i];
    // }

    // return total / cnt;

    return calc_serise_ma_with_period(m_indicator, period);
}

double IndicatorArrayGroup::calc_serise_ma_with_period(const TArraySerise<double> &buf, int period)
{
    if (period <= 0 || buf.size() <= 0)
    {
        Print("PeriodError:周期数不能小于零。");
        return 0;
    }

    int size = buf.size();
    int cnt = fmin(size, period);

    // double total = sum_to(buf, 0, cnt);
    double total = 0;
    for (int i = 0; i < cnt; i++)
    {
        total += buf[i];
    }

    return total / cnt;
}

double IndicatorArrayGroup::calc_serise_std_with_period(const TArraySerise<double> &src, const TArraySerise<double> &ma, int period)
{
    if (period <= 0 || src.size() < 0 || ma.size() < 0)
    {
        Print("PeriodError:周期数、缓冲区大小不能小于零。");
        return 0;
    }

    int ind_size = src.size();
    int ma_size = ma.size();
    int cnt = fmin(ind_size, ma_size);
    cnt = fmin(cnt, period);

    double total = 0;
    for (int i = 0; i < cnt; i++)
    {
        double delta = src[i] - ma[i];
        double sqrt = delta * delta;
        total += sqrt;
    }

    double std = MathSqrt(total / cnt);

    return std;
    // if (period <= 0)
    // {
    //     Print("PeriodError:周期数不能小于零。");
    //     return;
    // }

    // for (int i = size - 1; i >= 0; i--)
    // {
    //     int cnt = size - i;

    //     if (cnt > period)
    //     {
    //         cnt = period;
    //     }

    //     double total = 0;
    //     for (int j = 0; j < cnt; j++)
    //     {
    //         double delta = src[i + j] - ma[i + j];
    //         double sqrt = delta * delta;
    //         total += sqrt;
    //     }

    //     targ[i] = MathSqrt(total / cnt);
    // }
}

// 计算标准差之前，必须完成均值的计算。
double IndicatorArrayGroup::calc_std_with_period(int period)
{
    // if (period <= 0 || m_indicator.size() < 0 || m_indicator_ma.size() < 0)
    // {
    //     Print("PeriodError:周期数、缓冲区大小不能小于零。");
    //     return 0;
    // }

    // int ind_size = m_indicator.size();
    // int ma_size = m_indicator_ma.size();
    // int cnt = fmin(ind_size, ma_size);
    // cnt = fmin(cnt, period);

    // double total = 0;
    // for (int i = 0; i < cnt; i++)
    // {
    //     double delta = m_indicator[i] - m_indicator_ma[i];
    //     double sqrt = delta * delta;
    //     total += sqrt;
    // }
    // double std = MathSqrt(total / cnt);

    // return std;

    return calc_serise_std_with_period(m_indicator, m_indicator_ma, period);
}

double IndicatorArrayGroup::calc_speed()
{
    if (m_indicator.size() < 2)
    {
        return 0; //一个数据的速度为0
    }

    return m_indicator[0] - m_indicator[1];
}

double IndicatorArrayGroup::calc_acceleration()
{
    if (m_speed.size() < 2)
    {
        return 0;
    }

    return m_speed[0] - m_speed[1];

    // m_acceleration[m_buffer_size - 1] = 0;

    // for (int i = m_buffer_size - 2; i >= 0; i--)
    // {
    //     m_acceleration[i] = m_speed[i] - m_speed[i + 1];
    // }
}

double IndicatorArrayGroup::calc_20ma()
{
    return calc_ma_with_period(20);
}

double IndicatorArrayGroup::calc_ma()
{
    return calc_ma_with_period(m_period);
}

double IndicatorArrayGroup::calc_20std()
{
    return calc_std_with_period(20);
}

double IndicatorArrayGroup::calc_std()
{
    return calc_std_with_period(m_period);
}

// void IndicatorArrayGroup::calc()
// {
//     calc_ma();
//     calc_std();

//     calc_speed();
//     calc_speed_ma();
//     calc_speed_std();

//     calc_acceleration();
//     calc_acceleration_ma();
//     calc_acceleration_std();
// }

double IndicatorArrayGroup::calc_speed_ma()
{
    return calc_serise_ma_with_period(m_speed, m_period);
}

double IndicatorArrayGroup::calc_speed_std()
{
    return calc_serise_std_with_period(m_speed, m_speed_ma, m_period);
}

double IndicatorArrayGroup::calc_acceleration_ma()
{
    return calc_serise_ma_with_period(m_acceleration, m_period);
}

double IndicatorArrayGroup::calc_acceleration_std()
{
    return calc_serise_std_with_period(m_acceleration, m_acceleration_ma, m_period);
}

string IndicatorArrayGroup::format_to_str()
{
    return " m_indicator:" + DoubleToString(getValue(0), 6) +
           " m_indicator_ma:" + DoubleToString(getMa(0), 6) +
           " m_indicator_std:" + DoubleToString(getStd(0), 6) +
           " m_speed:" + DoubleToString(getSpeed(0), 6) +
           " m_speed_ma:" + DoubleToString(getSpeedMa(0), 6) +
           " m_speed_std:" + DoubleToString(getSpeedStd(0), 6) +
           " m_acc:" + DoubleToString(getAcceleration(0), 6) +
           " m_acc_ma:" + DoubleToString(getAccelerationMa(0), 6) +
           " m_acc_std:" + DoubleToString(getAccelerationStd(0), 6);
}

/**
 * 速度向上，并且幅度不能太小(也不能太大)
*/
bool IndicatorArrayGroup::is_up()
{
    if (m_speed[0] <= 0)
    {
        return false;
    }

    m_metrx.reset();
    m_metrx.computeAbs(m_speed);

    bool is_up = m_speed[0] > 0 && m_metrx.is_middle_area(m_speed[0]);
    // bool is_up = m_speed[0] > m_config.m_speed.m_ind.m_mid_low;
    return is_up;
}

/**
 * 速度向下，并且幅度不能太小
*/
bool IndicatorArrayGroup::is_down()
{
    if (m_speed[0] >= 0)
    {
        return false;
    }

    m_metrx.reset();
    m_metrx.computeAbs(m_speed);

    bool is_down = m_speed[0] < 0 && m_metrx.is_middle_area(-m_speed[0]);
    // bool is_down = m_speed[0] < -m_config.m_speed.m_ind.m_mid_low;
    return is_down;
}

// 连续cnt次都为up。
bool IndicatorArrayGroup::is_multi_up(int cnt = 3)
{
    //判断所有数值>0
    for (int i = 0; i < cnt; i++)
    {
        if (m_speed[i] <= 0)
        {
            return false;
        }
    }

    m_metrx.reset();
    m_metrx.computeAbs(m_speed);

    // 所有速度都必须在mid区域，不能太小或者太大。(暂时只考虑不能太小)
    for (int i = 0; i < cnt; i++)
    {
        // Print("m_speed[i]:"+m_speed[i]);
        if (m_metrx.is_low_area(m_speed[i]))
        {
            return false;
        }
    }

    return true;
}

// 连续cnt次都为down。
bool IndicatorArrayGroup::is_multi_down(int cnt = 3)
{
    //判断所有数值>0
    for (int i = 0; i < cnt; i++)
    {
        if (m_speed[i] >= 0)
        {
            return false;
        }
    }

    m_metrx.reset();
    m_metrx.computeAbs(m_speed);

    // 所有速度都必须在mid区域，不能太小或者太大。
    for (int i = 0; i < cnt; i++)
    {
        if (m_metrx.is_low_area(-m_speed[i]))
        {
            return false;
        }
    }

    return true;
}

/**
 * 加速度增加，并且幅度不能太小
*/
bool IndicatorArrayGroup::is_acc()
{

    if (m_acceleration[0] <= 0)
    {
        return false;
    }

    m_metrx.reset();
    m_metrx.computeAbs(m_acceleration);

    bool is_acc = m_acceleration[0] > 0 && m_metrx.is_middle_area(m_acceleration[0], 90);
    // bool is_acc = m_acceleration[0] > m_config.m_acc.m_ind.m_mid_low;
    return is_acc;
}

/**
 * 加速度向下，并且幅度不能太小
*/
bool IndicatorArrayGroup::is_dece()
{

    if (m_acceleration[0] >= 0)
    {
        return false;
    }

    m_metrx.reset();
    m_metrx.computeAbs(m_acceleration);

    bool is_dece = m_acceleration[0] < 0 && m_metrx.is_middle_area(-m_acceleration[0], 90);
    // bool is_dece = m_acceleration[0] < -m_config.m_acc.m_ind.m_mid_low;

    return is_dece;
}

/**
 * 值与均值都向上，加速度增大。
*/
bool IndicatorArrayGroup::is_acc_up()
{
    return is_up() && is_acc();
}

/**
 * 最近几次（3）的方差差别不大。
*/
// bool IndicatorArrayGroup::is_smooth()
// {
//     // m_metrx.reset();
//     // m_metrx.compute(m_indicator_std, m_buffer_size);
//     // Print("is_smooth:m_indicator_std[0]:" + m_indicator_std[0] + " index:" + m_metrx.calc_index(m_indicator_std[0]));
//     // return m_metrx.is_low_area(m_indicator_std[0]) && m_metrx.is_low_area(m_indicator_std[1]) && m_metrx.is_low_area(m_indicator_std[2]);
//     // return m_indicator_std[0] < m_config.m_indicator.m_ind_std.m_mid_low &&
//     //        m_indicator_std[1] < m_config.m_indicator.m_ind_std.m_mid_low &&
//     //        m_indicator_std[2] < m_config.m_indicator.m_ind_std.m_mid_low;
// }

/**
 * 值与均值都向下，加速度向下。
*/
bool IndicatorArrayGroup::is_acc_down()
{
    return is_down() && is_dece();
}

/**
 * 值分布在中间区域内且占比较大（70%）。
*/
bool IndicatorArrayGroup::is_in_middle()
{
    m_metrx.reset();
    m_metrx.compute(m_indicator);
    // Print("is_in_middle:" + m_metrx.format_to_str());
    return m_metrx.is_middle_area(m_indicator[0]);
    // return fabs(m_indicator[0]) > m_config.m_indicator.m_ind.m_mid_low &&
    //        fabs(m_indicator[0]) < m_config.m_indicator.m_ind.m_mid_high;
}

/**
 * 值分布在较低区域内且占比较小（30%）。
*/
bool IndicatorArrayGroup::is_in_low()
{
    m_metrx.reset();
    m_metrx.compute(m_indicator);

    return m_metrx.is_low_area(m_indicator[0]);
    // return fabs(m_indicator[0]) < m_config.m_indicator.m_ind.m_mid_low;
}

/**
 * 值分布在较高区域内且占比较小（20%）。
*/
bool IndicatorArrayGroup::is_in_high()
{
    m_metrx.reset();
    m_metrx.compute(m_indicator);
    // Print("is_in_high:" + m_metrx.format_to_str());
    return m_metrx.is_high_area(m_indicator[0]);
    // return fabs(m_indicator[0]) > m_config.m_indicator.m_ind.m_mid_high;
}

bool IndicatorArrayGroup::is_speed_in_low()
{
    m_metrx.reset();
    m_metrx.computeAbs(m_speed);
    // Print("is_speed_in_low:" + m_metrx.format_to_str());

    return m_metrx.is_low_area(fabs(m_speed[0]));
    // return fabs(m_speed[0]) < m_config.m_speed.m_ind.m_mid_low;
}

bool IndicatorArrayGroup::is_acc_in_low()
{
    m_metrx.reset();
    m_metrx.computeAbs(m_acceleration);

    return m_metrx.is_low_area(fabs(m_acceleration[0]));
    // return fabs(m_acceleration[0]) < m_config.m_acc.m_ind.m_mid_low;
}

//走平（速度和加速度都很小，甚至为很小的负数）
//@deprecated
bool IndicatorArrayGroup::is_flat()
{
    return is_speed_in_low() && is_acc_in_low();
}
