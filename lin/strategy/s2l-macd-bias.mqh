/**
 * 
 * 重构s2l-macd-bias.mqh linbirg@2018/10/16.
 * 改为面向对象编程，以便后续重构和逻辑调整。
 * 
*/
//+------------------------------------------------------------------+
// Changelog:
// 1.增加macd的快慢参数配置功能。
// 2.均线以慢参数为参考
// 3.移除了第三个信号与macd必须拉开一定距离的判断
// Changelog:
// 1.修改均线为MATrendPeriod*2
// 2.修改判断方向的均线由两个变为三个，但是条件放松到只要不是反方向就行
// Changelog:
// 1.修改均线为MATrendPeriod，两个均线判断方向。
// Changelog:
// 1.增加盘整行情的判断，如果没有检测到金叉或者死叉时，存在盘整行情，可以开仓。
// Changelog:2015.06.12
// 1.判断均线向上或者向下的时候，均线相等时返回false。即向下必须Ma0<Ma1，向上必须Ma0>Ma1。
// 2.用参数Lots来控制下单数量。
// ChangeLog:2015.06.16
// 1.代码进行了重构，将主程序逻辑改为三步：检查开仓、检查平仓、移动止损
// 2.平仓的逻辑改为只看均线。
// ChangeLog:2015.06.23
// 1.修改平仓的均线判断，改为判断M1和M2，如果用M0会导致随着行情波动，在一个周期内会多次开平仓的bug。
// ChangeLog:2015.07.02
// 增加了对平仓均线的变化幅度的判断，从而过滤短期波动的影响。坏处是减少了平仓的灵活性，增加了响应时间，使潜在风险增大。
// ChangeLog:2015.07.03
// 1.增加记录开仓和平仓时间，一个周期内只判断一次开平仓。

// Changelog.2015.07.16
// 1.增加连续2单亏损停止一段时间的逻辑。
// 2.增加震荡行情不开仓的逻辑。
// 3.增加加仓逻辑和加仓后如果总收益要亏损，平掉所有头寸的逻辑。
// 4.将平仓逻辑改为不是原来的方向就平，从而减少了回撤时的损失，但是增加了方向判断正确而被回撤打掉单子的概率，从而会减少收益，但是相比风险来说，风险更重要。

// Changelog.2015.07.23
// 1.重构了止损的函数。引入atr的方式计算移动止损，移动止损为开仓方向上atr、ma、2*ma中离价格最远者。
//

// Changelog.2015.08.04
// 1.增加周五最后一刻钟不开仓,如果有持仓,强制平仓的逻辑

// Changelog.2015.08.04
// 1.修改了判断isLastLostAndPassed的逻辑，函数默认返回false，只有在亏损次数小于制定值或者时间过去足够久才返回true
// Changelog.2015.08.07
// 1.参数化亏损后暂停的时期数

// Changelog.2015.08.11.v1.0
// 1.修改止损策略，当价格大于一定幅度之后，将止损设置为开盘价，以保证不亏损。
// 2.引入4小时周期，开盘必须4小时周期均线看多或者看空，不再开于4小时均线向反的仓。
// 3.平仓策略改为看4小时图的均线。
// 4.移动止损，改为参考15分钟的60均线，4小时图的13均线，26均线和52均线。
// 5.4小时均线以26周期为参考。

// Changelog.2015.08.24
// 1修改了isScaledIn函数的判断逻辑，增加对symbol的判断，这样可以不同图标的策略分开。

// Changelog.2015.08.27
// 1.增加乖离率的概念，才用价格偏离26日均线的点数作为乖离率的值，偏离大于MAXBIAS点时，采用ATR作为止损，从而起到保护的作用。
// 2.增加短线转长线的逻辑，当止损采用的均线大于4小时的26日均线或者大于60日均线或者120均线时，采用相应均线作为判断均线是否转向的依据。

// Changelog.2015.09.23
// 1.重构了代码结构，分模块重构代码
// 2.增加开仓时，持仓判断，如果有持仓，只按持仓方向加仓。没有持仓则看均线和多空的方向。

// Changelog.2015.10.02
// 1.增加如果连续亏损多次则长时间内不开仓的逻辑
// 2.增加开仓时通过5分钟短线，判断是否远离均线来寻找进入的机会。

// Changelog.2015.10.23
// 1.增加逻辑：如果日线三线同向，则向长期转。如果三线不同向，则可能存在风险，以短期为主，4小时26均线掉头则平仓

// Changelog.2018.09.11
// 增加衡量保单好坏的指标k(in),k(out),k(comfort)以及最大盈利、最大亏损等的统计信息。

// #include "lin/util/util.mqh"
// #include "lin/orders/order_helper.mqh"
// #include "lin/position/position_manager.mqh"
// #include "lin/position/stop_manager.mqh"

// #include "lin/indicator/ma.mqh"
// #include "lin/indicator/macd.mqh"
// #include "lin/indicator/atr.mqh"
// #include "lin/indicator/bias.mqh"
// #include "lin/indicator/boll.mqh"

// #include "lin/CAL/statics.mqh"

// input double TakeProfit = 20000;

// input double TrailingStop = 150;

// input double MAOpenLevel = 2;
// input double MACloseLevel = 1;
// input int MATrendPeriod = 60;
// input int MATrendPeriodFast = 26;
// //input double MaximumRisk   =0.08;
// //input int DecreaseFactor=3;

// input double Ravistor = 20; //两条均线的差值，用于判断是否是震荡行情。

// input int Timeframes = 240;

// input int DeltaOfNearBy = 20;

// //input int digits=2;//下单手数的最小单位，即小数点后面几位小数.number of digits after point

// StopManager stopManager;
// MetrixManager metrixManger;
// Boll boll;

// //判断从第i个行情之前的一段时间内存在盘整行情
// //盘整行情的定义：行情波动不大
// bool hasConsolidation(int i)
// {
//     double macd, ma;
//     double maArr[], delta[];
//     double total, avg;
//     int count, j;

//     ArrayResize(maArr, 2 * CheckPeriod);
//     ArrayResize(delta, 2 * CheckPeriod);

//     for (j = 0; j < 2 * CheckPeriod; j++)
//     {
//         ma = iMA(NULL, 0, MATrendPeriod, 0, MODE_EMA, PRICE_CLOSE, i + j);
//         maArr[j] = ma;
//     }
//     total = 0;
//     for (j = 0; j < 2 * CheckPeriod; j++)
//     {
//         total += maArr[j];
//     }

//     avg = total / (2 * CheckPeriod);
//     //Print("hasConsolidation: ma avg:",avg);
//     for (j = 0; j < 2 * CheckPeriod; j++)
//     {
//         delta[j] = avg - maArr[j];
//     }

//     count = 0;
//     for (j = 0; j < 2 * CheckPeriod; j++)
//     {
//         //Comment("j:",j,"delta[j]:", MathAbs(delta[j]));
//         //Print("j:",j,"delta[j]:", MathAbs(delta[j]),"3*MACDOpenLevel*Point:",10*MACDOpenLevel*Point);
//         if (MathAbs(delta[j]) <= (10 * MACDOpenLevel * Point))
//         {
//             count = count + 1;
//             Print("count:", count);
//             if (count >= CheckPeriod)
//             {
//                 Print("hasConsolidation:存在盘整行情");
//                 return true;
//             }
//         }
//         else
//             count = 0;
//     }

//     return false;
// }

// double Macd0, Macd1, Macd2;
// double Signal0, Signal1, Signal2;
// double Ma0, Ma1, Ma2;
// double MACDAVGLevel;
// // 看前三个macd值和signal,都是向上的，并且均线向上
// bool CheckForLong()
// {

//     if (!isLong())
//         return false;

//     //如果是底背离，均线向上，买
//     //if(isBullishDivergence())return true;

//     //如果是0轴上的第一个金叉，且离0轴不远，均线向上，买

//     //如果是0轴下的金叉，（且离0轴很远），均线向上，买

//     //如果没有金叉（或者金叉离0轴很远），判断是盘整行情，均线向上，买

//     if (!CheckForGoldInHour())
//     {
//         Print("CheckForLong:有效时间内没有检测到0轴下的金叉");
//         if (hasConsolidation(0))
//         {
//             Print("CheckForLong:检测到盘整行情，现在已经确定走势，可以开仓。");
//             return true;
//         }
//         return false;
//     }

//     return true;
// }

// //只要一个条件不满足Long的条件就返回true。
// bool isLong()
// {
//     Macd0 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_MAIN, 0);
//     Macd1 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_MAIN, 1);
//     Macd2 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_MAIN, 2);

//     Signal0 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
//     Signal1 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_SIGNAL, 1);
//     Signal2 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_SIGNAL, 2);

//     if (Macd1 >= Macd0 || Macd2 >= Macd1 || Signal1 >= Signal0 || Signal2 >= Signal1)
//     {
//         Print("isLong:macd或者signal不是向上");
//         return false;
//     }

//     //取差值的均值
//     MACDAVGLevel = (Macd0 + Macd1 + Macd2 - Signal0 - Signal1 - Signal2) / 3;
//     if (MACDAVGLevel < MACDOpenLevel * Point)
//     {
//         Print("isLong:macd高于Signal的量太小");
//         Print("isLong:相差", MACDAVGLevel / Point, "个Point");
//         return false;
//     }

//     //均线变动比较慢，暂时取两个
//     //Ma0=iMA(NULL,0,MATrendPeriod,0,MODE_LWMA,PRICE_CLOSE,0);
//     //Ma1=iMA(NULL,0,MATrendPeriod,0,MODE_LWMA,PRICE_CLOSE,1);
//     //Ma2=iMA(NULL,0,MATrendPeriod,0,MODE_EMA,PRICE_CLOSE,2);
//     //均线没有向上
//     if (!isMaUpForOpen()) //Ma0<=Ma1)//)//|| Ma1<Ma2)
//     {
//         Print("isLong:均线没有向上");
//         return false;
//     }

//     //上面条件都不满足，可以确定为多。
//     return true;
// }

// bool isShort()
// {

//     Macd0 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_MAIN, 0);
//     Macd1 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_MAIN, 1);
//     Macd2 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_MAIN, 2);

//     Signal0 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
//     Signal1 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_SIGNAL, 1);
//     Signal2 = iMACD(NULL, 0, MATrendPeriodFast, MATrendPeriod, 9, PRICE_CLOSE, MODE_SIGNAL, 2);

//     if (Macd0 >= Macd1 || Macd1 >= Macd2 || Signal0 >= Signal1 || Signal1 >= Signal2)
//     {
//         Print("isShort:macd或者signal不是向下");
//         return false;
//     }

//     MACDAVGLevel = (Signal0 + Signal1 + Signal2 - Macd0 - Macd1 - Macd2) / 3;

//     if (MACDAVGLevel < MACDOpenLevel * Point)
//     {
//         Print("isShort:macd低于信号的量不够。");
//         Print("isShort:相差", MACDAVGLevel / Point, "个Point");
//         return false;
//     }

//     //均线变动比较慢，暂时取两个
//     //Ma0=iMA(NULL,0,MATrendPeriod,0,MODE_LWMA,PRICE_CLOSE,0);
//     //Ma1=iMA(NULL,0,MATrendPeriod,0,MODE_LWMA,PRICE_CLOSE,1);
//     if (!isMaDownForOpen()) //Ma0>=Ma1)//)
//     {
//         Print("isShort:均线没有向下");
//         return false;
//     }

//     //上面条件都不满足，可判断为空
//     return true;
// }

// //+------------------------------------------------------------------+
// //|                                                                  |
// //+------------------------------------------------------------------+
// bool CheckForShort()
// {

//     if (!isShort())
//         return false;

//     //如果是顶背离，均线向下，卖
//     //如果是0轴下的死叉，且离0轴比较金，卖。
//     //如果是0轴上的死叉（切离0轴很远），均线向下，卖
//     //如果没有死叉，判断盘整行情，均线向下，卖。

//     if (!CheckForDeathInHour())
//     {
//         Print("CheckForShort:有效时间内没有检测到0轴上的死叉");
//         if (hasConsolidation(0))
//         {
//             Print("CheckForShort:检测到盘整行情，现在已经确定走势，可以开仓。");
//             return true;
//         }
//         return false;
//     }

//     return true;
// }

// int CurrentStop2MA()
// {
//     double stopLost = OrderStopLoss();
//     double MA = 0;
//     int maTrendPeriod = MATrendPeriod;
//     for (int cnt = 1; cnt < MASwitchCount; cnt++)
//     {
//         MA = iMA(NULL, 0, MATrendPeriod * MASwitchStep * cnt, 0, MODE_LWMA, PRICE_CLOSE, 0);
//         if (OrderType() == OP_BUY)
//         {
//             if (stopLost >= MA)
//                 maTrendPeriod = MATrendPeriod * MASwitchStep * cnt;
//             if (stopLost < MA)
//             {
//                 Print("CurrentStop2MA:maTrendPeriod   ", maTrendPeriod);
//                 return maTrendPeriod;
//             }
//         }

//         if (OrderType() == OP_SELL)
//         {
//             if (stopLost <= MA)
//                 maTrendPeriod = MATrendPeriod * MASwitchStep * cnt;
//             if (stopLost > MA)
//             {
//                 Print("CurrentStop2MA:maTrendPeriod   ", maTrendPeriod);
//                 return maTrendPeriod;
//             }
//         }
//     }
//     return maTrendPeriod;
// }

// // 通过判断两条均线的差值来判断是否存在震荡行情。
// bool isM15Consolidation()
// {
//     return isConsolidation(PERIOD_M15, MATrendPeriod, MATrendPeriod / 2, Ravistor);
// }

// bool is4HConsolidation()
// {
//     return isConsolidation(PERIOD_H4, MATrendPeriod, MATrendPeriod / 2, 5 * Ravistor);
// }

// bool isNearByMAAndFarAway()
// {
//     if (isNearBy(PERIOD_M5, MATrendPeriodFast / 2, DeltaOfNearBy) && isFarAway(PERIOD_M5, MATrendPeriodFast / 2))
//     {
//         Print("远离13均线");
//         return true;
//     }
//     if (isNearBy(PERIOD_M5, MATrendPeriodFast, DeltaOfNearBy) && isFarAway(PERIOD_M5, MATrendPeriodFast))
//     {
//         Print("远离26均线");
//         return true;
//     }

//     if (isNearBy(PERIOD_M5, MATrendPeriod, DeltaOfNearBy) && isFarAway(PERIOD_M5, MATrendPeriod))
//     {
//         Print("远离60均线");
//         return true;
//     }

//     if (isNearBy(PERIOD_M5, MATrendPeriod * 2, DeltaOfNearBy) && isFarAway(PERIOD_M5, MATrendPeriod * 2))
//     {
//         Print("远离120均线");
//         return true;
//     }
//     Print("isNearByMAAndFarAway:没有靠近均线或者靠近没有远离");
//     return false;
// }

// int getNearByMa()
// {
//     if (isNearBy(PERIOD_M5, MATrendPeriodFast / 2, DeltaOfNearBy) && isFarAway(PERIOD_M5, MATrendPeriodFast / 2))
//     {
//         //Print("远离13均线");
//         return MATrendPeriodFast / 2;
//     }
//     if (isNearBy(PERIOD_M5, MATrendPeriodFast, DeltaOfNearBy) && isFarAway(PERIOD_M5, MATrendPeriodFast))
//     {
//         //Print("远离26均线");
//         return MATrendPeriodFast;
//     }

//     if (isNearBy(PERIOD_M5, MATrendPeriod, DeltaOfNearBy) && isFarAway(PERIOD_M5, MATrendPeriod))
//     {
//         //Print("远离60均线");
//         return MATrendPeriod;
//     }

//     if (isNearBy(PERIOD_M5, MATrendPeriod * 2, DeltaOfNearBy) && isFarAway(PERIOD_M5, MATrendPeriod * 2))
//     {
//         //Print("远离120均线");
//         return MATrendPeriod * 2;
//     }
//     Print("isNearByMAAndFarAway:没有靠近均线或者靠近没有远离");
//     return 0;
// }

// bool has_chance_for_long()
// {
//     if (isNearByMAAndFarAway() && isMaUp(PERIOD_M5, MAOpenLevel, getNearByMa()))
//     {
//         Print("has_chance_for_long:true");
//         return true;
//     }

//     Print("has_chance_for_long:false");
//     return false;
// }

// bool has_chance_for_short()
// {
//     if (isNearByMAAndFarAway() && isMaDown(PERIOD_M5, MAOpenLevel, getNearByMa()))
//     {
//         Print("has_chance_for_short:true");
//         return true;
//     }

//     Print("has_chance_for_short:false");
//     return false;
// }

// datetime openTime = __DATETIME__;

// void CheckForOpen()
// {
//     int ticket;
//     //--- no opened orders identified
//     if (AccountFreeMargin() < (1000 * Lots))
//     {
//         Print("We have no money. Free Margin = ", AccountFreeMargin());
//         return;
//     }

//     if (isFridayLastFifteen())
//     {
//         return;
//     }

//     Print("openTime:", TimeToString(openTime, TIME_DATE | TIME_SECONDS));
//     if (openTime == Time[0])
//     {
//         Print("CheckForOpen:当前周期已经开过仓。");
//         return;
//     }

//     if (is4HConsolidation())
//     {
//         Print("CheckForOpen：4H震荡行情，不开仓。");
//         return;
//     }

//     if (isM15Consolidation())
//     {
//         Print("CheckForOpen：15分钟震荡行情，不开仓。");
//         return;
//     }

//     if (!isLastLostAndPassed())
//     {
//         Print("CheckForOpen：上笔订单亏损，一段时间内不再开仓交易。");
//         return;
//     }

//     bool longPosition = false;
//     bool shortPosition = false;

//     if (CalculateCurrentOrders() > 0)
//         longPosition = true;
//     if (CalculateCurrentOrders() < 0)
//         shortPosition = true;

//     //如果没有持仓，双向都可以开仓，取决于此刻的均线
//     if (CalculateCurrentOrders() == 0)
//     {
//         longPosition = true;
//         shortPosition = true;
//     }

//     //--- check for long position (BUY) possibility
//     if (longPosition && isMa4HUpForOpen() && isMacd4HLong() && CheckForLong() && has_chance_for_long())
//     {
//         RefreshRates();
//         ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(), Ask, 5, 0, Ask + TakeProfit * Point, "macd sample", 16384, 0, Green);
//         if (ticket > 0)
//         {
//             if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
//                 Print("BUY order opened : ", OrderOpenPrice());
//             openTime = Time[0];
//         }
//         else
//             Print("Error opening BUY order : ", GetLastError());
//         return;
//     }

//     //--- check for short position (SELL) possibility
//     if (shortPosition && isMa4HDownForOpen() && isMacd4HShort() && CheckForShort() && has_chance_for_short()) //&& MaCurrent<MaPrevious)
//     {
//         ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(), Bid, 5, 0, Bid - TakeProfit * Point, "macd sample", 16384, 0, Red);
//         if (ticket > 0)
//         {
//             if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
//                 Print("SELL order opened : ", OrderOpenPrice());
//             openTime = Time[0];
//         }
//         else
//             Print("Error opening SELL order : ", GetLastError());
//         return;
//     }
// }

// //获取订单的最低止损位
// double lowestStop()
// {
//     double lowestStop = 0;

//     int buy_or_sell = OrdersBuyOrSell();

//     for (int i = 0; i < OrdersTotal(); i++)
//     {
//         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
//             break;
//         if (OrderSymbol() == Symbol())
//         {
//             if (lowestStop == 0)
//                 lowestStop = OrderStopLoss();

//             if (buy_or_sell == OP_BUY && lowestStop > OrderStopLoss())
//             {
//                 lowestStop = OrderStopLoss();
//             }

//             if (buy_or_sell == OP_SELL && lowestStop < OrderStopLoss())
//             {
//                 lowestStop = OrderStopLoss();
//             }
//         }
//     }
//     return lowestStop;
// }

// //获取最新订单的开仓价格
// double latestOpenPrice()
// {
//     /*for(int i=OrdersTotal()-1;i>=0;i--)
//    {
//       if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
//       if(OrderSymbol()!=Symbol())continue;

//       //OrderPrint();

//       return OrderOpenPrice();
//    }

//    return 0;*/
//     for (int i = 0; i < OrdersTotal(); i++)
//     {
//         if (SelectTradeOrderByPos(i))
//             return OrderOpenPrice();
//     }

//     return 0;
// }

// //所有订单的总收益
// double totalProfit()
// {
//     double totalProfit = 0;
//     for (int i = 0; i < OrdersTotal(); i++)
//     {
//         //if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
//         //if(OrderSymbol()==Symbol())
//         if (SelectTradeOrderByPos(i))
//         {
//             totalProfit = totalProfit + OrderProfit();
//         }
//     }

//     return totalProfit;
// }

// bool stopLossCoveredlatestOpenPrice()
// {
//     //Print("latestOpenPrice()-TrailingStop*Point",latestOpenPrice()-TrailingStop*Point);
//     //买
//     if (OrdersBuyOrSell() == OP_BUY)
//     {
//         //
//         if (lowestStop() > latestOpenPrice() + TrailingStop * Point)
//             return true; //+TrailingStop*Point
//         return false;
//     }

//     //卖
//     if (OrdersBuyOrSell() == OP_SELL)
//     {
//         if (lowestStop() < latestOpenPrice() - TrailingStop * Point) //-TrailingStop*Point
//         {
//             Print("stopLossCoveredlatestOpenPrice:卖单，止损已经低于开仓价", TrailingStop, "个基点 lowestStop:", lowestStop(), " latestOpenPrice()-TrailingStop*Point:", latestOpenPrice() - TrailingStop * Point);
//             return true;
//         }
//         return false;
//     }
//     return false;
// }

// double calcHighest()
// {
//     double high = 0;
//     for (int i = 1; i < CheckPeriod / 2; i++)
//     {
//         if (high == 0)
//             high = Close[i];

//         if (high < Close[i])
//             high = Close[i];
//     }

//     Print("calcHighest:前期最高收盘价 ", high);
//     return high;
// }

// double calcLowest()
// {
//     double low = 0;

//     for (int i = 1; i < CheckPeriod / 2; i++)
//     {
//         if (low == 0)
//             low = Close[i];

//         if (low > Close[i])
//             low = Close[i];
//     }
//     Print("calcLowest:前期最低收盘价  ", low);
//     return low;
// }

// bool CheckBreakForLong()
// {
//     if (Close[0] > calcHighest())
//     {
//         Print("CheckBreakForLong:收盘价突破前期低点。 Close[0] ", Close[0], " calcHighest   ", calcHighest());
//         return true;
//     }
//     return false;
// }

// bool CheckBreakForShort()
// {
//     if (Close[0] < calcLowest())
//     {
//         Print("CheckBreakForShort:收盘价突破前期低点。 Close[0]   ", Close[0], " calcLowest ", calcLowest());
//         return true;
//     }
//     return false;
// }

// bool CheckForBreak()
// {
//     if (OrdersBuyOrSell() == OP_BUY)
//         return CheckBreakForLong();

//     if (OrdersBuyOrSell() == OP_SELL)
//         return CheckBreakForShort();

//     return false;
// }

// void CheckForScaleIn()
// {
//     int ticket;

//     if (CalculateCurrentOrders() == 0)
//     {
//         Print("CheckForScaleIn:当前没有持仓");
//         return;
//     }

//     if (openTime == Time[0])
//     {
//         Print("CheckForScaleIn:当前周期已经开过仓位");
//         return;
//     }

//     if (AccountFreeMargin() < (1000 * Lots))
//     {
//         Print("We have no money. Free Margin = ", AccountFreeMargin());
//         return;
//     }

//     Print("CheckForScaleIn:lowestStop:", lowestStop(), " latestOpenPrice:", latestOpenPrice());
//     if (!stopLossCoveredlatestOpenPrice())
//     {
//         Print("CheckForScaleIn:止损位没有覆盖最新开仓的价格");
//         return;
//     }

//     CheckForOpen();
// }

// bool isMaUpForOpen()
// {
//     return isMaUp(PERIOD_CURRENT, MAOpenLevel, MATrendPeriod);
// }

// bool isMaDownForOpen()
// {
//     return isMaDown(PERIOD_CURRENT, MAOpenLevel, MATrendPeriod);
// }

// int chooseMa4HPeriod()
// {
//     int MAPeriod = MATrendPeriodFast;
//     int currStopMA = CurrentStop2MA();
//     if (currStopMA > MATrendPeriodFast * 16)
//         MAPeriod = MATrendPeriod;
//     if (currStopMA > MATrendPeriod * 16)
//         MAPeriod = 2 * MATrendPeriod;

//     Print("chooseMa4HPeriod:   MAPeriod ", MAPeriod);
//     return MAPeriod;
// }

// //这样做的意思是，如果短期均线MATrendPeriodFast已经掉头了，那就转向长期MATrendPeriod或者更长期MATrendPeriod*2。
// bool isMaUpForClose()
// {
//     if (isMaUp(PERIOD_H4, MACloseLevel, MATrendPeriodFast))
//     {
//         Print("isMaUpForClose:", "均线向上 ", MATrendPeriodFast);
//         return true;
//     }

//     if (!is_all_day_ma_up())
//     {
//         Print("日线上三均线不是同像上，不往长期转");
//         return false;
//     }

//     Print("日线上三均线同像上，查看60或者120均线");

//     if (isMaUp(PERIOD_H4, MACloseLevel, MATrendPeriod))
//     {
//         Print("isMaUpForClose:", "均线向上 ", MATrendPeriod);
//         return true;
//     }

//     if (isMaUp(PERIOD_H4, MACloseLevel, MATrendPeriod * 2))
//     {
//         Print("isMaUpForClose:", "均线向上 ", MATrendPeriod * 2);
//         return true;
//     }

//     Print("isMaUpForClose:", "所有均线都没有向上");
//     return false;
// }

// bool isMaDownForClose()
// {
//     if (isMaDown(PERIOD_H4, MACloseLevel, MATrendPeriodFast))
//     {
//         Print("isMaDownForClose:", "均线向下 ", MATrendPeriodFast);
//         return true;
//     }

//     if (!is_all_day_ma_down())
//     {
//         Print("日线上三均线不是同像下，不往长期转");
//         return false;
//     }

//     Print("日线上三均线同像下，查看60或者120均线");

//     //如果日线上三线同向，则长期持有；如果日线上三线有分歧，则只看4小时的26均线
//     if (isMaDown(PERIOD_H4, MACloseLevel, MATrendPeriod))
//     {
//         Print("isMaDownForClose:", "均线向下 ", MATrendPeriod);
//         return true;
//     }

//     if (isMaDown(PERIOD_H4, MACloseLevel, MATrendPeriod * 2))
//     {
//         Print("isMaDownForClose:", "均线向下 ", MATrendPeriod * 2);
//         return true;
//     }

//     Print("isMaDownForClose:", "所有均线都没有向下");
//     return false;
// }

// bool is_all_day_ma_down()
// {
//     return isMaDown(PERIOD_D1, MACloseLevel, MATrendPeriodFast) && isMaDown(PERIOD_D1, MACloseLevel, MATrendPeriod) && isMaDown(PERIOD_D1, MACloseLevel, MATrendPeriod * 2);
// }

// bool is_all_day_ma_up()
// {
//     return isMaUp(PERIOD_D1, MACloseLevel, MATrendPeriodFast) && isMaUp(PERIOD_D1, MACloseLevel, MATrendPeriod) && isMaUp(PERIOD_D1, MACloseLevel, MATrendPeriod * 2);
// }

// bool isScaledIn()
// {
//     return MathAbs(CalculateCurrentOrders()) > 1; //订单数2个以上认为是加过仓的。
// }

// void ForceCloseAll()
// {
//     int cnt;

//     for (cnt = 0; cnt < OrdersTotal(); cnt++)
//     {
//         if (SelectTradeOrderByPos(0))
//         {
//             if (OrderType() == OP_BUY)
//             {
//                 if (OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet))
//                 {
//                     closeTime = Time[0];
//                     Print("OrderClose:已经平仓.   closeTime   ", TimeToString(closeTime, TIME_DATE | TIME_SECONDS));
//                     cnt--;
//                 }
//                 else
//                 {
//                     Print("ForceCloseAll:OrderClose error ", GetLastError());
//                 }
//             }
//             else // go to short position
//             {
//                 if (OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet))
//                 {
//                     closeTime = Time[0];
//                     Print("OrderClose:已经平仓，closeTime   ", TimeToString(closeTime, TIME_DATE | TIME_SECONDS));
//                     cnt--;
//                 }
//                 else
//                 {
//                     Print("ForceCloseAll:OrderClose error ", GetLastError());
//                 }
//             }
//         }
//     }
// }

// datetime closeTime = __DATETIME__;
// void CheckForClose()
// {
//     int cnt, ticket, total;
//     double Ma0, Ma1, Ma2;

//     /*if(isFridayLastFifteen())
//    {
//       ForceCloseAll();
//       return;
//    }*/

//     if (isScaledIn() && totalProfit() <= 0)
//     {
//         Print("加仓后总收益即将亏损，强制平掉所有的仓位");
//         ForceCloseAll();
//         return;
//     }

//     Print("CheckForClose:isScaledIn  ", isScaledIn(), " totalProfit   ", totalProfit());

//     Print("CheckForClose: closeTime  ", TimeToString(closeTime, TIME_DATE | TIME_SECONDS));
//     if (closeTime == Time[0])
//     {
//         Print("CheckForClose:当前周期已经平仓了。");
//         return;
//     }

//     //均线变动比较慢，暂时取两个
//     //Ma0=iMA(NULL,0,MATrendPeriod,0,MODE_LWMA,PRICE_CLOSE,0);
//     //Ma1=iMA(NULL,0,MATrendPeriod,0,MODE_LWMA,PRICE_CLOSE,1);
//     //Ma2=iMA(NULL,0,MATrendPeriod,0,MODE_LWMA,PRICE_CLOSE,2);

//     //total=OrdersTotal();
//     //--- it is important to enter the market correctly, but it is more important to exit it correctly...
//     for (cnt = 0; cnt < OrdersTotal(); cnt++)
//     {
//         if (!SelectTradeOrderByPos(cnt))
//             continue;

//         //--- long position is opened
//         //Print("Ma1:",Ma1,"Ma2:",Ma2,"Delta/Point:",(Ma1-Ma2)/Point);
//         if (OrderType() == OP_BUY)
//         {
//             //--- should it be closed?
//             if (!isMaUpForClose())
//             {
//                 //--- close order and exit
//                 Print("均线没有向上，平仓");
//                 if (OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet))
//                 {
//                     closeTime = Time[0];
//                     Print("OrderClose:已经平仓，closeTime:", TimeToString(closeTime, TIME_DATE | TIME_SECONDS));
//                     cnt--;
//                 }
//                 else
//                 {
//                     Print("OrderClose:OrderClose error ", GetLastError());
//                 }
//             }
//             else
//                 Print("CheckForClose: 均线向上，不用平仓");
//             continue;
//         }
//         if (OrderType() == OP_SELL) // go to short position
//         {
//             //--- should it be closed?
//             if (!isMaDownForClose())
//             {
//                 //--- close order and exit
//                 //Print("CheckForClose: 均线没有向下，平仓");
//                 if (OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet))
//                 {
//                     closeTime = Time[0];
//                     Print("OrderClose:已经平仓，closeTime ", TimeToString(closeTime, TIME_DATE | TIME_SECONDS));
//                     cnt--;
//                 }
//                 else
//                 {
//                     Print("CheckForClose:OrderClose error ", GetLastError());
//                 }
//             }
//             else
//                 Print("CheckForClose:均线向下，不用平仓");
//         }
//     }
// }

// #include "../util/time_util.mqh"
// #include "../position/position_manager.mqh"
// #include "../position/stop_manager.mqh"

#include "abstract_strategy.mqh"
#include "../indicator/ma.mqh"

class S2LMacdBiasStragy : public AbstractStrategy
{
  private:
    DoubleMA4H m_maH4;
    DoubleMA15M m_mam15;

  public:
    S2LMacdBiasStragy(/* args */);
    ~S2LMacdBiasStragy();

  private:
    // bool has_long_chance();
    // bool has_short_chance();
    bool has_chance_for_long();
    bool has_chance_for_short();
    bool may_long();
    bool may_short();
};

S2LMacdBiasStragy::S2LMacdBiasStragy(/* args */)
{
    m_stopManager.setTrailingStop(300);
}

S2LMacdBiasStragy::~S2LMacdBiasStragy()
{
}

bool S2LMacdBiasStragy::has_chance_for_long()
{
    if (m_mam15.is_consolidation())
    {
        Print("has_chance_for_long：15分钟震荡行情。");
    }

    if (m_maH4.is_consolidation())
    {
        Print("has_chance_for_long：4H震荡行情。");
    }

    //     if (longPosition && isMa4HUpForOpen() && isMacd4HLong() && CheckForLong() && has_chance_for_long())
    return false;
}
bool S2LMacdBiasStragy::has_chance_for_short()
{
    if (m_mam15.is_consolidation())
    {
        Print("has_chance_for_long：15分钟震荡行情。");
    }

    if (m_maH4.is_consolidation())
    {
        Print("has_chance_for_long：4H震荡行情。");
    }
    //     if (shortPosition && isMa4HDownForOpen() && isMacd4HShort() && CheckForShort() && has_chance_for_short()) //&& MaCurrent<MaPrevious)
    return false;
}
bool S2LMacdBiasStragy::may_long()
{
    return false;
}

bool S2LMacdBiasStragy::may_short()
{
    return false;
}
