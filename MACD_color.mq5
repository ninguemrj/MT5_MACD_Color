//+------------------------------------------------------------------+
//|                 Changes By Ricardo José Alves Júnior on MACD.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009-2017, MetaQuotes Software Corp. / Changes By Ricardo José Alves Júnior"
#property link      "ricardo.junior@gmail.com"
#property version   "1.00"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_type2   DRAW_LINE
#property indicator_color1  Green,Red
#property indicator_color2  Red
#property indicator_width1  1
#property indicator_width2  2
#property indicator_label1  "MACD"
#property indicator_label2  "Signal"

//--- input parameters
input int                InpFastEMA=26;               // Fast EMA period
input int                InpSlowEMA=55;               // Slow EMA period
input int                InpSignalSMA=13;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
//--- indicator buffers
double                   ExtMacdBuffer[];
double                   ExtSignalBuffer[];
double                   ExtFastMaBuffer[];
double                   ExtSlowMaBuffer[];
// color buffer
double ColorBuffer[];

//--- MA handles
int                      ExtFastMaHandle;
int                      ExtSlowMaHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);
   
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpSignalSMA-1);
//--- name for Dindicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD("+string(InpFastEMA)+","+string(InpSlowEMA)+","+string(InpSignalSMA)+")");
//--- get MA handles
   ExtFastMaHandle=iMA(NULL,0,InpFastEMA,0,MODE_EMA,InpAppliedPrice);
   ExtSlowMaHandle=iMA(NULL,0,InpSlowEMA,0,MODE_EMA,InpAppliedPrice);
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- check for data
   if(rates_total<InpSignalSMA)
      return(0);
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtFastMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtFastMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
   calculated=BarsCalculated(ExtSlowMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtSlowMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//--- get Fast EMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtFastMaHandle,0,0,to_copy,ExtFastMaBuffer)<=0)
     {
      Print("Getting fast EMA is failed! Error",GetLastError());
      return(0);
     }
//--- get SlowSMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtSlowMaHandle,0,0,to_copy,ExtSlowMaBuffer)<=0)
     {
      Print("Getting slow SMA is failed! Error",GetLastError());
      return(0);
     }
//---
   int limit;
   if(prev_calculated==0)
      limit=0;
   else limit=prev_calculated-1;
//--- calculate MACD
   for(int i=limit;i<rates_total && !IsStopped();i++)
   {
      ExtMacdBuffer[i]=ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
      if (ExtMacdBuffer[i]>=0)
      {
         ColorBuffer[i] = 0.0;
      } 
      else
      {
         ColorBuffer[i] = 1.0;
      }
   }
     
//--- calculate Signal
   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSignalSMA,ExtMacdBuffer,ExtSignalBuffer);
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
