#property copyright "linbirg"
#property link "http://www.mql4.com"

#include "lin/strategy/s2l-macd-bias.mqh"

S2LMacdBiasStragy macdStragy;

void OnInit()
{
  // stopManager.setMATrendPeriod(MATrendPeriod);
  // stopManager.setMATrendPeriodFast(MATrendPeriodFast);
  // stopManager.setTrailingStop(TrailingStop);
  // Print("OnInit:初始化完成");
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
{
  if (Bars < 100)
  {
    Print("bars less than 100");
    return;
  }

  macdStragy.onTick();

  //isLastLostAndPassed();
  //isConsolidation();
  // if (CalculateCurrentOrders() == 0)
  //   CheckForOpen();
  // else
  // {
  //   CheckForScaleIn();
  //   CheckForClose();
  // }

  // //移动止损
  // stopManager.CalcStopLoss();
  // metrixManger.flush();
  // Comment(metrixManger.formatoStr());
  // boll.calc();
  // Comment(metrixManger.formatoStr() + "\n" + boll.format_to_str());
}
//+------------------------------------------------------------------+
