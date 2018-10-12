#property copyright "linbirg"

#include "../util/util.mqh"

/**
 * 一些统计数据,目前统计包括占比。
 * 
*/
class IndicatorMetrix
{
  protected:
    int m_total;
    double m_max;
    double m_min;

    int m_step_size;
    double m_step[];   //分阶 0-min 9-max
    double m_occupy[]; //占比

    Util m_util;

  public:
    IndicatorMetrix(/* args */);
    ~IndicatorMetrix();
    IndicatorMetrix(const double &src[], int size);

  public:
    void reset();
    void compute(const double &src[], int size);
    void computeAbs(const double &src[], int size);

    double get_upper_occpy_bigger(int occpy);
    double get_lower_occpy_bigger(int occpy);

    double get_min_by_occpy_bigger(int occpy);
    double get_max_by_occpy_bigger(int occpy);

    string format_to_str();

    int calc_occpy_bigger(double val);  // 统计val所在区间及以上的占比。
    int calc_occpy_smaller(double val); // 统计val所在区间及以下的占比。

    bool is_middle_area(double val, int occupy = 70); // 判断val是否在中间区域（默认70%）。
    bool is_low_area(double val, int occupy = 30);    // 判断val是否在低区域（默认占比30%）。
    bool is_high_area(double val, int occupy = 20);   // 判断val是否在高区域（默认占比20%）。

    int calc_index(double val);

  public:
    void get_occpy(double &dist[]);
    void get_step(double &dist[]);

  protected:
    void calc_min_max(const double &src[], int size);
    void count_occpy(const double &src[], int size);
    void count_step();
    void calc_band_occpy_bigger(int occpy);
    int find_minest_occpy_btw(int max, int min);
    void sorted_occupy();
};

IndicatorMetrix::IndicatorMetrix(/* args */)
{
    reset();
}

IndicatorMetrix::IndicatorMetrix(const double &src[], int size)
{
    reset();
    compute(src, size);
}

IndicatorMetrix::~IndicatorMetrix()
{
}

string IndicatorMetrix::format_to_str()
{
    string ret = "";

    for (int i = 0; i < m_step_size; i++)
    {
        ret += " step" + i + ": " + m_step[i] + " occupy:" + m_occupy[i];
    }

    return ret;
}

void IndicatorMetrix::reset()
{
    m_total = 0;
    m_step_size = 80;
    ArrayResize(m_step, m_step_size);
    ArrayResize(m_occupy, m_step_size);
    ArrayFill(m_step, 0, m_step_size, 0);
    ArrayFill(m_occupy, 0, m_step_size, 0);
}

void IndicatorMetrix::compute(const double &src[], int size)
{
    m_total = size;
    calc_min_max(src, size);
    count_step();
    count_occpy(src, size);
}

void IndicatorMetrix::computeAbs(const double &src[], int size)
{
    m_total = size;
    double absSrc[];
    ArrayResize(absSrc, size);

    m_util.abs(absSrc, src, size);
    calc_min_max(absSrc, size);
    count_step();
    count_occpy(absSrc, size);
}

void IndicatorMetrix::calc_min_max(const double &src[], int size)
{
    const double DEFUALT_MAX = 999999999;
    const double DEFUALT_MIN = -999999999;

    m_total = size;
    double min = DEFUALT_MAX;
    double max = DEFUALT_MIN;

    for (int i = 0; i < m_total; i++)
    {

        if (src[i] < min)
        {
            min = src[i];
        }

        if (src[i] > max)
        {
            max = src[i];
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

void IndicatorMetrix::count_occpy(const double &src[], int size)
{
    double delta = (m_max - m_min) / (m_step_size - 1);

    if (m_util.double_equal(delta, 0))
    {
        Print("ErrorDivZero:" + delta + " m_max:" + m_max + " m_min:" + m_min);
        return;
    }

    for (int i = 0; i < size; i++)
    {
        int index = (src[i] - m_min) / delta;
        // Print("index:" + index);
        m_occupy[index] += 1;
    }
}

void IndicatorMetrix::count_step()
{
    double delta = (m_max - m_min) / (m_step_size - 1);

    for (int i = 0; i < m_step_size; i++)
    {
        m_step[i] = m_min + i * delta;
    }
}

int IndicatorMetrix::calc_index(double val)
{
    double delta = (m_max - m_min) / (m_step_size - 1);

    if (MathAbs(delta) < 0.000000001)
    {
        Print("ErrorDivZero:" + delta + " m_max:" + m_max + " m_min:" + m_min);
        return -1;
    }

    int index = (val - m_min) / delta;

    if (index < 0 || index > (m_step_size - 1))
    {
        Print("IndexError:index:" + index + " delta:" + delta + " m_max:" + m_max + " m_min:" + m_min + " val:" + val);
        return -1;
    }

    return index;
}

// 统计val所在区间及以上的占比。
int IndicatorMetrix::calc_occpy_bigger(double val)
{
    // double delta = (m_max - m_min) / (m_step_size - 1);

    // if (MathAbs(delta) < 0.000000001)
    // {
    //     Print("ErrorDivZero:" + delta + " m_max:" + m_max + " m_min:" + m_min);
    //     return 0;
    // }

    // int index = (val - m_min) / delta;

    // if (index < 0 || index > (m_step_size - 1))
    // {
    //     Print("IndexError:index:" + index + " delta:" + delta + " m_max:" + m_max + " m_min:" + m_min + " val:" + val);
    //     return 0;
    // }

    int index = calc_index(val);

    if (index < 0)
    {
        Print("IndexError:index:" + index);
        return 0;
    }

    int total = m_util.sum_to(m_occupy, index, m_step_size);

    if (m_total == 0)
    {
        Print("ErrorTotalZero:m_total:" + m_total);
        return 0;
    }

    int ocpy = (100 * total / m_total);
    return ocpy;
}

// 统计val所在区间及以下的占比。
int IndicatorMetrix::calc_occpy_smaller(double val)
{
    // double delta = (m_max - m_min) / (m_step_size - 1);

    // if (MathAbs(delta) < 0.000000001)
    // {
    //     Print("ErrorDivZero:" + delta + " m_max:" + m_max + " m_min:" + m_min);
    //     return 0;
    // }

    // int index = (val - m_min) / delta;

    // if (index < 0 || index > (m_step_size - 1))
    // {
    //     Print("IndexError:index:" + index + " delta:" + delta + " m_max:" + m_max + " m_min:" + m_min + " val:" + val);
    //     return 0;
    // }

    int index = calc_index(val);

    if (index < 0)
    {
        Print("IndexError:index:" + index);
        return 0;
    }
    int total = m_util.sum_to(m_occupy, 0, index + 1);
    // for (int i = 0; i < index; i++)
    // {
    //     total += m_occupy[i];
    // }

    if (m_total == 0)
    {
        Print("ErrorTotalZero:m_total:" + m_total);
        return 0;
    }

    int ocpy = 100 * total / m_total;
    return ocpy;
}

// 判断val是否在中间区域（70%）。
bool IndicatorMetrix::is_middle_area(double val, int occupy = 70)
{
    int ocpy_bigger = calc_occpy_bigger(val);
    int occpy_smaller = calc_occpy_smaller(val);
    int half_opy = (100 - occupy) / 2;
    return ocpy_bigger > half_opy && occpy_smaller > half_opy;
}

// 判断val是否在低区域（默认占比30%）。
bool IndicatorMetrix::is_low_area(double val, int occupy = 30)
{
    int occpy_smaller = calc_occpy_smaller(val);
    // Print("is_low_area:" + occpy_smaller + " val:" + val + " index:" + calc_index(val));
    return occpy_smaller < occupy;
}

// 判断val是否在高区域（默认占比20%）。
bool IndicatorMetrix::is_high_area(double val, int occupy = 20)
{
    int ocpy_bigger = calc_occpy_bigger(val);
    return ocpy_bigger < occupy;
}

/**
 * 从大往小，计算累计占比>occpy的最小值，如果找不到则返回最小值。
*/
double IndicatorMetrix::get_min_by_occpy_bigger(int occpy)
{
    int total = m_total * occpy / 100;
    int count = 0;
    for (int i = m_step_size - 1; i >= 0; i--)
    {
        count += m_occupy[i];

        if (count > total)
        {
            return m_step[i];
        }
    }

    return m_step[0];
}

/**
 * 从小往大，计算累计占比>occpy的最大值，如果找不到则返回最大值。
*/
double IndicatorMetrix::get_max_by_occpy_bigger(int occpy)
{
    int total = m_total * occpy / 100;
    int count = 0;
    for (int i = 0; i < m_step_size; i++)
    {
        count += m_occupy[i];

        if (count > total)
        {
            return m_step[i];
        }
    }

    return m_step[0];
}

/**
 * 在m_occpy中查找>min&&<max的最小值的索引。
*/
int IndicatorMetrix::find_minest_occpy_btw(int max, int min)
{
    int minest = max;
    int index = -1;
    for (int i = 0; i < m_step_size; i++)
    {
        if (m_occupy[i] < minest && m_occupy[i] > min)
        {
            index = i;
        }
    }

    return index;
}

void IndicatorMetrix::get_occpy(double &dist[])
{
    m_util.copy(dist, m_occupy, m_step_size);
}
void IndicatorMetrix::get_step(double &dist[])
{
    m_util.copy(dist, m_step, m_step_size);
}