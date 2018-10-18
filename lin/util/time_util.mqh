
class TimeUtil
{
  private:
    /* data */
  public:
    TimeUtil(/* args */);
    ~TimeUtil();

  public:
    bool is_friday_last_fifteen();
};

TimeUtil::TimeUtil(/* args */)
{
}

TimeUtil::~TimeUtil()
{
}

/**
 * 
 * 判断是否是周五的最后15分钟
*/
bool TimeUtil::is_friday_last_fifteen()
{
    if (DayOfWeek() != 5)
    {
        return false;
    }

    if (TimeHour(Time[0]) < 23 || TimeMinute(Time[0]) < 45)
    {
        return false;
    }

    return true;
}