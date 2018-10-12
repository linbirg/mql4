
/**
 *
 * 数组的帮助类
*/

#property copyright "linbirg"
#property link "https://www.mql5.com"
#property strict

#include "array.mqh"

class SeriseArrayHelper
{
  private:
    /* data */
  public:
    SeriseArrayHelper(/* args */){};
    ~SeriseArrayHelper(){};

  public:
    void abs(TArraySerise<double> &dist, TArraySerise<double> &src)
    {
        // 计算序列的绝对值，并存入dist中。
        int size = src.size();
        for (int i = 0; i < size; i++)
        {
            dist.append(fabs(src[i]));
        }
    };
};

// SeriseArrayHelper::SeriseArrayHelper(/* args */)
// {
// }

// SeriseArrayHelper::~SeriseArrayHelper()
// {
// }

// 计算序列的绝对值，并存入dist中。
// void SeriseArrayHelper::abs(TArraySerise<T> &dist, const TArraySerise<T> &src)
// {
//     int size = src.size();
//     for (int i = 0; i < size; i++)
//     {
//         dist.append(fabs(src[i]));
//     }
// }