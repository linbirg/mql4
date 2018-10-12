#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

/**
 * 
 * 画图的工具类，以类的方式写，便于代码管理和阅读，另外会有一些默认设置可以作为私有变量使用。
*/
class ChartHelper
{
  private:
    int m_chart_index;

  public:
    ChartHelper(/* args */);
    ~ChartHelper();

  public:
    void create_trend_line(string name, double x1, double y1, double x2, double y2, color colorVal = Red, int width = 1);
    void create_rect(string name, double x1, double y1, double x2, double y2, color colorValue = Red);
    void set_obj_hit(string name, string hit);
};

ChartHelper::ChartHelper(/* args */)
{
    m_chart_index = 0;
}

ChartHelper::~ChartHelper()
{
}

/**
 * 
 * 先删除元素，再创建。
*/
void ChartHelper::create_trend_line(string name, double x1, double y1, double x2, double y2, color colorVal = Red, int width = 1)
{
    ObjectDelete(name);
    ObjectCreate(name, OBJ_TREND, m_chart_index, x1, y1, x2, y2);
    ObjectSet(name, OBJPROP_COLOR, colorVal);
    ObjectSet(name, OBJPROP_WIDTH, width);
    ObjectSet(name, OBJPROP_STYLE, 0);
    ObjectSet(name, OBJPROP_RAY, false);
}

void ChartHelper::create_rect(string name, double x1, double y1, double x2, double y2, color colorValue = Red)
{
    ObjectDelete(name);
    //    // Time[3]: left of rect.   startValue: top of rect.   Time[0]: right of rect.    endValue: bottom of rect;
    ObjectCreate(name, OBJ_RECTANGLE, m_chart_index, x1, y1, x2, y2);
    ObjectSet(name, OBJPROP_COLOR, colorValue);
    ObjectSet(name, OBJPROP_WIDTH, 1);
    ObjectSet(name, OBJPROP_STYLE, 0);
    ObjectSet(name, OBJPROP_BACK, false);
};

void ChartHelper::set_obj_hit(string name, string hit)
{
    ObjectSetString(m_chart_index, name, OBJPROP_TEXT, hit);
}
