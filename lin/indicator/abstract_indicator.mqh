#include "../core/indicator_interface.mqh"
#include "indicator_grp.mqh"

class Abstractindicator : public IIndicator
{
  protected:
    IndicatorArrayGroup m_indicator;
    int m_buffer_size;
    datetime m_start_time;
    int m_frame;

  public:
    Abstractindicator(/* args */);
    ~Abstractindicator();

  public:
    virtual bool is_long();  //多
    virtual bool is_short(); //空
    virtual bool is_flat();  //走平

    virtual void calc();
    virtual void do_calc(int shift) = NULL;

    virtual string format_to_str() { return ""; };

    virtual void setTimeFrame(int frame) { m_frame = frame; };
    virtual void setBufferSize(int size);
};

Abstractindicator::Abstractindicator(/* args */)
{
    m_frame = PERIOD_M15;
    m_buffer_size = 1000;
    m_start_time = iTime(NULL, m_frame, m_buffer_size);
}

Abstractindicator::~Abstractindicator()
{
}

void Abstractindicator::setBufferSize(int size)
{
    if (size < 0)
    {
        Print("BufferSizeZeroError:缓冲区大小必须为正整数。");
        return;
    }

    m_buffer_size = size;
    m_indicator.resize(m_buffer_size);
}

bool Abstractindicator::is_long()
{
    return m_indicator.is_multi_up();
} //多
bool Abstractindicator::is_short()
{
    return m_indicator.is_multi_down();
} //空
bool Abstractindicator::is_flat()
{
    return !is_long() && !is_short();
} //走平

void Abstractindicator::calc()
{
    datetime now = iTime(NULL, m_frame, 0);
    int count = (now - m_start_time) / (60 * m_frame);

    for (int i = count - 1; i >= 0; i--)
    {
        do_calc(i);
    }

    m_start_time = now;
}
