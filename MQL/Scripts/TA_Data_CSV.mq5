//+------------------------------------------------------------------+
//|                                           IndicatorDataSaver.mq5 |
//|                                 Copyright 2017, Richard Ruthberg |
//|                                                  ruthberg@kth.se |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Richard Ruthberg"
#property link      "ruthberg@kth.se"
#property version   "1.00"
#property script_show_inputs
//--- input parameters
input string file_name_marker = "20171104.csv"; //File name ends with this and starts with the current symbol.
input ENUM_TIMEFRAMES per = PERIOD_M1; //Timeframe to base data on.
input int len = 10000; //Lenght of data series, counting backwards in time from the current bar.
input string symbol = "Current"; //Symbol name.
input bool time_series = true; //Set output as time series (current to last)
//--- Indicator inputs. Be consistent in the period usage. Room for improvement.
input int ind_period_main = 20; //Custom indicator period. Main one used.
input int ind_period_2 = 15; //Custom indicator period, secondary.
input int ind_period_3 = 10; //Custom indicator period, tertiary.
input int ind_shift = 0; //Custom shift relative to prices.
input double ind_std = 1.96; //Standard deviation for indicators using it (e.g. Bollinger)
input ENUM_APPLIED_PRICE ind_app_price = PRICE_CLOSE; //Price to be applied, e.g. : PRICE_OPEN, PRICE_CLOSE, PRICE_HIGH, PRICE_LOW.

//TO DO:
// 1) custom input parameters to the indicators?
// 2) normalisation/decision thresholds -> output for each indicator should be BUY/HOLD/SELL (?) or at least normalised
// 3) grouping of the indicators (in line with above), currently not all components of the oscillators go through


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---Goal: create a script that does some calculation on the current series and saves it down in a csv.
   MqlRates price[];
   ArraySetAsSeries(price,time_series);
   int copy;
   string filename,symbol_name,period;
   if(symbol == "Current") symbol_name = Symbol();
   else symbol_name = symbol;
   
   period = EnumToString(per);
   //period = StringReplace(temp_period, "PERIOD_","");
   
   filename = symbol_name + "_" + period + "_" + file_name_marker;
   
   copy = CopyRates(symbol_name,per,0,len,price);
   
   //---Define indicator buffers:
   //Trend:
   double   ind_sma_buffer[],
            ind_ema_buffer[],
            ind_bollup_buffer[],
            ind_bolldo_buffer[];
   //Oscillators
   double   ind_macd_buffer[],
            ind_rsi_buffer[],
            ind_stoc_buffer[];
   //Set buffers as time series
   ArraySetAsSeries(ind_sma_buffer,time_series);
   ArraySetAsSeries(ind_ema_buffer,time_series);
   ArraySetAsSeries(ind_bollup_buffer,time_series);
   ArraySetAsSeries(ind_bolldo_buffer,time_series);
   ArraySetAsSeries(ind_macd_buffer,time_series);
   ArraySetAsSeries(ind_rsi_buffer,time_series);
   ArraySetAsSeries(ind_stoc_buffer,time_series);
   
   //Define indicator handles
   int ind_sma_handle   = iMA(symbol_name, per, ind_period_main, ind_shift, MODE_SMA, ind_app_price);
   if (ind_sma_handle < 0){Print("SMA handle error = ", GetLastError());}
   int ind_ema_handle   = iMA(symbol_name, per, ind_period_main, ind_shift, MODE_EMA, ind_app_price);
   if (ind_ema_handle < 0){Print("EMA handle error = ", GetLastError());}
   int ind_boll_handle  = iBands(symbol_name, per, ind_period_main, ind_shift, ind_std,ind_app_price);
   if (ind_boll_handle < 0){Print("Bollinger handle error = ", GetLastError());}
   int ind_macd_handle  = iMACD(symbol_name, per, ind_period_3, ind_period_main, ind_period_2, ind_app_price);
   if (ind_macd_handle < 0){Print("MACD handle error = ", GetLastError());}
   int ind_rsi_handle   = iRSI(symbol_name, per, ind_period_main, ind_app_price);
   if (ind_rsi_handle < 0){Print("RSI handle error = ", GetLastError());}
   int ind_stoc_handle  = iStochastic(symbol_name, per, ind_period_main, ind_period_2, 2, MODE_SMA, STO_LOWHIGH);
   if (ind_stoc_handle < 0){Print("Stochastic handle error = ", GetLastError());}
   
   
   //Copy indicator data to the buffers:
   if (CopyBuffer(ind_sma_handle,0,0,len,ind_sma_buffer) < 0){Print("CopyBufferSMA error =",GetLastError());}
   if (CopyBuffer(ind_ema_handle,0,0,len,ind_ema_buffer) < 0){Print("CopyBufferEMA error =",GetLastError());}
   if (CopyBuffer(ind_boll_handle,1,0,len,ind_bollup_buffer) < 0){Print("CopyBufferBollUP error =",GetLastError());}
   if (CopyBuffer(ind_boll_handle,2,0,len,ind_bolldo_buffer) < 0){Print("CopyBufferBollDOWN error =",GetLastError());}
   if (CopyBuffer(ind_macd_handle,0,0,len,ind_macd_buffer) < 0){Print("CopyBufferMACD error =",GetLastError());}
   if (CopyBuffer(ind_rsi_handle,0,0,len,ind_rsi_buffer) < 0){Print("CopyBufferRSI error =",GetLastError());}
   if (CopyBuffer(ind_stoc_handle,0,0,len,ind_stoc_buffer) < 0){Print("CopyBufferStochastic error =",GetLastError());}
   
   
   if (copy > 0) {
      Alert((string)copy + " data points saved. Symbol = " + symbol_name + ". Type = " + period + ".");
      int size = 10;
      
      //Format the output
      string out = "Index, Symbol, BarTimeframe, Time, Open, High, Low, Close, Volume, SMA, EMA, BollUp, BollDown, MACD, RSI, STOC";
      string format = " %G, %G, %G, %G, %d, %G, %G, %G, %G, %G, %G, %G"; 
      
      int ofile;
      ofile = FileOpen(filename,FILE_READ|FILE_WRITE);
      
      if(ofile != INVALID_HANDLE){
         FileWrite(ofile,out);
         FileFlush(ofile);
         
         for (int i=0; i < copy; i++) {
         
         out = (string) i + ", " + symbol_name +", " + period +", " + TimeToString(price[i].time);
         out = out + ", " + StringFormat(format,
                                          price[i].open,
                                          price[i].high,
                                          price[i].low,
                                          price[i].close,
                                          price[i].tick_volume,
                                          ind_sma_buffer[i],
                                          ind_ema_buffer[i],
                                          ind_bollup_buffer[i],
                                          ind_bolldo_buffer[i],
                                          ind_macd_buffer[i]*1000,
                                          ind_rsi_buffer[i],
                                          ind_stoc_buffer[i]);
         
         FileWrite(ofile,out);
         FileFlush(ofile);
         }
      } 
   if (ofile < 0) Alert("File opening failed.");
   FileClose(ofile);
   }
   else MessageBox("Failed to copy data on symbol ", symbol_name);
   

   
   
   
   
   
  }
//+------------------------------------------------------------------+
