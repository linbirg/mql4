

interface IIndicator
{
    bool is_long();  //多
    bool is_short(); //空
    bool is_flat();  //走平

    void calc();

    string format_to_str();

    void setTimeFrame(int frame);
    void setBufferSize(int size);
};