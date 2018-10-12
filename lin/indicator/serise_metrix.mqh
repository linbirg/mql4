#property copyright "linbirg"

// #include "../util/util.mqh"
#include "indicator_metrix.mqh"
#include "../core/array.mqh"
#include "../core/array_helper.mqh"

/**
 * 一些统计数据,目前统计包括占比。
 * 基于TArraySerise实现,采用增量push的方式统计。
 * 
*/

class SeriseMetrix : public IndicatorMetrix
{
  private:
    SeriseArrayHelper m_serise_helper;

  public:
    SeriseMetrix(/* args */){};
    ~SeriseMetrix(){};

  public:
    void compute(TArraySerise<double> &serise);
    void computeAbs(TArraySerise<double> &serise);

  protected:
    void count_occpy(TArraySerise<double> &serise);
    void calc_min_max(TArraySerise<double> &serise);
};

void SeriseMetrix::compute(TArraySerise<double> &serise)
{
    calc_min_max(serise);
    count_step();
    count_occpy(serise);
}

void SeriseMetrix::calc_min_max(TArraySerise<double> &serise)
{
    // 应该用全局或者静态常量
    const double DEFUALT_MAX = 999999999;
    const double DEFUALT_MIN = -999999999;

    m_total = serise.size();

    double min = DEFUALT_MAX;
    double max = DEFUALT_MIN;

    for (int i = 0; i < m_total; i++)
    {

        if (serise[i] < min)
        {
            min = serise[i];
        }

        if (serise[i] > max)
        {
            max = serise[i];
        }
    }

    if (min < DEFUALT_MAX)
    {
        m_min = min;
    }

    if (max > DEFUALT_MIN)
    {
        m_max = max;
    }
}

void SeriseMetrix::count_occpy(TArraySerise<double> &serise)
{
    double delta = (m_max - m_min) / (m_step_size - 1);

    if (m_util.double_equal(delta, 0))
    {
        Print("ErrorDivZero:" + delta + " m_max:" + m_max + " m_min:" + m_min);
        return;
    }

    for (int i = 0; i < serise.size(); i++)
    {
        int index = (serise[i] - m_min) / delta;
        // Print("index:" + index);
        m_occupy[index] += 1;
    }
}

void SeriseMetrix::computeAbs(TArraySerise<double> &serise)
{
    TArraySerise<double> dist;
    m_serise_helper.abs(dist, serise);
    compute(dist);
}
