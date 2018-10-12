#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

#include "../util/util.mqh"
#include "chart_helper.mqh"

/**
 * 
 * 线段
*/
class TrendLine
{
  private:
    ChartHelper m_helper;
    string m_name;
    double m_x1;
    double m_y1;
    double m_x2;
    double m_y2;
    color m_color;
    int m_width;

  public:
    TrendLine(/* args */);
    ~TrendLine();

    TrendLine(string name, double x1, double y1, double x2, double y2, color colorVal = Red, int width = 1);

  public:
    void draw();

  public:
    void setName(string name);
    void setWidth(int width);
    void setStart(double x, double y);
    void setEnd(double x, double y);
    void setColor(color val);
};

TrendLine::TrendLine(/* args */)
{
    m_name = "trend_line";
    m_width = 1;
    m_color = Black;
}

TrendLine::~TrendLine()
{
    ObjectDelete(m_name);
}

TrendLine::TrendLine(string name, double x1, double y1, double x2, double y2, color colorVal = Red, int width = 1)
{
    m_name = name;
    m_x1 = x1;
    m_y1 = y1;
    m_x2 = x2;
    m_y2 = y2;
    m_color = colorVal;
    m_width = width;
}

void TrendLine::draw()
{
    m_helper.create_trend_line(m_name, m_x1, m_y1, m_x2, m_y2, m_color, m_width);
}

void TrendLine::setName(string name)
{
    m_name = name;
}

void TrendLine::setWidth(int width)
{
    m_width = width;
}

void TrendLine::setStart(double x, double y)
{
    m_x1 = x;
    m_y1 = y;
}
void TrendLine::setEnd(double x, double y)
{
    m_x2 = x;
    m_y2 = y;
}

void TrendLine::setColor(color val)
{
    m_color = val;
}

/**
 * 
 * 坐标轴
*/
class Axias : public TrendLine
{
  private:
    /* data */
  public:
    Axias(/* args */);
    ~Axias();
    Axias(double x1, double y1, double x2, double y2, string name = "axias", color colorVal = Black, int width = 2);
};

Axias::Axias(/* args */)
{
    setName("axias");
    setWidth(2);
}

Axias::~Axias()
{
}

Axias::Axias(double x1, double y1, double x2, double y2, string name = "axias", color colorVal = Black, int width = 2)
{
    setStart(x1, y1);
    setEnd(x2, y2);
    setName(name);
    setWidth(width);
    setColor(colorVal);
}

/**
 * 
 * x轴。
 * x为时间轴，只需要确定y和长度。类会做将长度换算为坐标。
*/
class Xaxis : public Axias
{
  private:
    double m_y;
    long m_x;
    int m_length;

  public:
    Xaxis(/* args */);
    ~Xaxis();
    Xaxis(long x, double y, int len);

  public:
    void setZero(long x, double y);
    void setLength(int len);
    int getLen();

  private:
    void relocate();
};

Xaxis::Xaxis(/* args */)
{
    setName("xaxis");
}

Xaxis::~Xaxis()
{
}

Xaxis::Xaxis(long x, double y, int len)
{
    m_x = x;
    m_y = y;
    m_length = len;
    relocate();
    setName("xaxis");
}

void Xaxis::setZero(long x, double y)
{
    m_x = x;
    m_y = y;
    relocate();
}
void Xaxis::setLength(int len)
{
    m_length = len;
    relocate();
}

int Xaxis::getLen()
{
    return m_length;
}

void Xaxis::relocate()
{
    setStart(m_x, m_y);
    setEnd(m_x + Period() * 60 * m_length, m_y);
}

/**
 * 
 * Yaxis
*/
class Yaxis : public Axias
{
  private:
    double m_y1;
    double m_y2;
    long m_x;

  public:
    Yaxis(/* args */);
    ~Yaxis();

  public:
    void setX(long x);
    void setY1(double y);
    void setY2(double y);

    long getX();
    double getY1();
    double getY2();

  private:
    void relocate();
};

Yaxis::Yaxis(/* args */)
{
    setName("yaxis");
}

Yaxis::~Yaxis()
{
}

void Yaxis::relocate()
{
    setStart(m_x, m_y1);
    setEnd(m_x, m_y2);
}

void Yaxis::setX(long x)
{
    m_x = x;
    relocate();
}
void Yaxis::setY1(double y)
{
    m_y1 = y;
    relocate();
}
void Yaxis::setY2(double y)
{
    m_y2 = y;
    relocate();
}

long Yaxis::getX()
{
    return m_x;
}

double Yaxis::getY1()
{
    return m_y1;
}

double Yaxis::getY2()
{
    return m_y2;
}

/**
 * 
 * Histogram
*/
class HistogramChart
{
  private:
    Xaxis m_xaxis;
    Yaxis m_yaxis;
    int m_zero_x; // 以时间偏移为计量的x坐标
    double m_zero_y;
    double m_y2;
    int m_x_len;

    double m_chart_max;
    double m_chart_min;
    double m_data[];
    double m_step[];

    ChartHelper m_helper;
    Util m_util;

    int m_pad_top; //上边留白
    int m_pad_rl;  //左右的留白

  public:
    HistogramChart(/* args */);
    ~HistogramChart();

  public:
    void draw();
    void redraw();

  public:
    void setZero(int x, double y);
    void setY2(double y);
    void setData(const double &data[]);
    void setStep(const double &data[]);
    void relocate();

  private:
    void init();
    void draw_rects();

  private:
    double find_max();
};

HistogramChart::HistogramChart(/* args */)
{
    init();
}

HistogramChart::~HistogramChart()
{
    ObjectsDeleteAll();
}

void HistogramChart::setZero(int x, double y)
{
    m_zero_x = x;
    m_zero_y = y;
}

void HistogramChart::setY2(double y)
{
    m_y2 = y;
}

void HistogramChart::relocate()
{
    m_xaxis.setLength(m_x_len);
    m_xaxis.setZero(Time[m_zero_x], m_zero_y);

    m_yaxis.setX(Time[m_zero_x]);
    m_yaxis.setY1(m_zero_y);
    m_yaxis.setY2(m_y2);
}

void HistogramChart::setData(const double &data[])
{
    // if (ArraySize(data) > 0)
    // {
    //     ArrayResize(m_data, ArraySize(data));
    //     ArrayCopy(m_data, data);
    // }
    m_util.copy(m_data, data, ArraySize(data));
}

void HistogramChart::setStep(const double &data[])
{
    // if (ArraySize(data) > 0)
    // {
    //     ArrayResize(m_step, ArraySize(data));
    //     ArrayCopy(m_step, data);
    // }
    m_util.copy(m_step, data, ArraySize(data));
}

void HistogramChart::draw()
{
    m_xaxis.draw();
    m_yaxis.draw();

    draw_rects();
}

void HistogramChart::init()
{
    // 起始在20个柱子的位置，图表的中间。
    m_chart_max = ChartGetDouble(0, CHART_PRICE_MAX);
    m_chart_min = ChartGetDouble(0, CHART_PRICE_MIN);

    m_zero_y = m_chart_min + (m_chart_max - m_chart_min) / 2;
    m_zero_x = 20;
    m_x_len = 80;
    m_y2 = m_chart_max - 20 * Point();

    m_xaxis.setLength(m_x_len);
    m_xaxis.setZero(Time[m_zero_x], m_zero_y);

    m_yaxis.setX(Time[m_zero_x]);
    m_yaxis.setY1(m_zero_y);
    m_yaxis.setY2(m_y2);

    m_pad_top = 20; // 上顶离坐标顶20个点差
    m_pad_rl = 6;
}

void HistogramChart::redraw()
{
    relocate();
    draw();
}

double HistogramChart::find_max()
{
    int cnt = ArraySize(m_data);

    if (cnt <= 0)
    {
        Print("EmptyArrayError:" + "数组为空");
        return 0;
    }

    double max = m_data[0];
    for (int i = 0; i < cnt; i++)
    {
        if (m_data[i] > max)
        {
            max = m_data[i];
        }
    }

    return max;
}

void HistogramChart::draw_rects()
{
    int cnt = ArraySize(m_data);

    if (cnt <= 0)
    {
        return;
    }

    long rec_width = Period() * 60 * (m_xaxis.getLen() - m_pad_rl) / cnt;
    long rec_white = 60 * Period() * m_pad_rl / cnt;
    double max = find_max();

    for (int i = 0; i < cnt; i++)
    {
        double x1 = Time[m_zero_x] + i * (rec_white + rec_width) + rec_white;
        double x2 = x1 + rec_width;
        double y2 = m_yaxis.getY1() + (m_yaxis.getY2() - m_yaxis.getY1() - m_pad_top * Point()) * m_data[i] / max;
        m_helper.create_rect("rect" + i, x1, m_yaxis.getY1(), x2, y2);
        m_helper.set_obj_hit("rect" + i, "p:" + m_data[i] + " s:" + m_step[i]);
        // m_helper.set_obj_hit("rect" + i, "" + m_step[i]);
    }
}
