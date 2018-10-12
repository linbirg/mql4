//+------------------------------------------------------------------+
//|                                                    TemplTest.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
//+------------------------------------------------------------------+
//| 声明一个模板类                                                     |
//+------------------------------------------------------------------+
template <typename T>
class TArray
{
  protected:
    T m_data[];

  protected:
    bool resize()
    {
        int new_size = ArraySize(m_data) + 1;
        int reserve = (new_size / 2 + 15) & ~15;
        // Print("reserve:" + reserve + " new size:" + new_size);
        //---
        if (ArrayResize(m_data, new_size, reserve) != new_size)
            return false;

        return true;
    };

  public:
    bool append(T item)
    {

        if (!resize())
            return false;
        //---
        int new_size = ArraySize(m_data);
        m_data[new_size - 1] = item;
        return true;
    };

    T operator[](int index) const
    {
        static T invalid_index;
        //---
        if (index < 0 || index >= ArraySize(m_data))
            return (invalid_index);
        //---
        return (m_data[index]);
    };

    int size() const
    {
        return ArraySize(m_data);
    };

    // T* get_buf() const
    // {
    //     return GetPointer(m_data);
    // }
};

//+------------------------------------------------------------------+
//| 指针数组的模板类。在析构函数中，它删除                                 |
//| 对象，数组中存储指针的对象。                                         |
//|                                                                  |
//| 请注意继承TArray 模板类                                            |
//+------------------------------------------------------------------+
template <typename T>
class TArrayPtr : public TArray<T *>
{
  public:
    void ~TArrayPtr()
    {
        for (int n = 0, count = ArraySize(m_data); n < count; n++)
            if (CheckPointer(m_data[n]) == POINTER_DYNAMIC)
                delete m_data[n];
    }
};

/**
 * 序列化数组。append在数组最后，重载访问函数，改为重后往前访问。
 * 
*/
template <typename T>
class TArraySerise : public TArray<T>
{
  private:
    int m_max_size; //

  public:
    bool shift_left()
    {
        // 向左移动，位于头部的数据被丢弃。
        // int size_of = sizeof(m_data);
        int size = ArraySize(m_data);
        int drop = (size / 2 + 15) & ~15;
        // Print("size_of:" + size_of + " size:" + size + " drop:" + drop + " new size:" + (size - drop));

        if (size < drop)
        {
            // 没有足够移动的数据（理论上不存在）。
            return false;
        }

        int new_size = size - drop;

        if (drop == 0)
        {
            return true;
        }

        int cnt = ArrayCopy(m_data, m_data, 0, drop, new_size);

        if (cnt != new_size)
        {
            return false;
        }

        ArrayResize(m_data, new_size, 2 * drop);
        return true;
    };

  public:
    TArraySerise()
    {
        m_max_size = 2000;
    };

    void set_max_size(int max_size)
    {
        m_max_size = max_size;
    };

    int get_max_size()
    {
        return m_max_size;
    };

    bool append(T item)
    {
        // 丢弃掉部分数据，并重新resize。
        if (size() >= m_max_size)
        {
            shift_left();
        }

        return TArray<T>::append(item);
    };

  public:
    T operator[](int index)
    {
        static T invalid_index;
        //---
        int size = ArraySize(m_data);
        if (index < 0 || index >= size)
            return (invalid_index);
        //---
        return (m_data[size - 1 - index]);
    };
};