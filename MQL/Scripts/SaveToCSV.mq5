//+------------------------------------------------------------------+
//|                                                  ScriptToCSV.mq4 |
//|                                 Copyright 2017, Richard Ruthberg |
//|                                                  ruthberg@kth.se |
//+------------------------------------------------------------------+
//| Styleguide:      _CAPS       inputs
//|                  CAPS        constants
//|                  noncap      function parameters and variables
//|                  f_name      custom function declarations
//|                  _noncap     global variables
//|                  
//|

#property copyright "Copyright 2017, Richard Ruthberg"
#property link      "ruthberg@kth.se"
#property version   "1.00"
#property script_show_inputs
//--- input parameters
input string file_name_marker = "20180101.csv"; //File name ends with:
input ENUM_TIMEFRAMES per = PERIOD_M1; //Timeframe to store.
input int len = 10000; //Lenght of data series.
input string symbol = "Current"; //Symbol name
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---Goal: create a script that does some calculation on the current series and saves it down in a csv.
   MqlRates price[];
   ArraySetAsSeries(price,true);
   int copy;
   string filename,symbol_name,period;
   if(symbol == "Current") symbol_name = Symbol();
   else symbol_name = symbol;
   
   period = EnumToString(per);
   period = StringReplace(period, "PERIOD_","");
   
   filename = symbol_name + "_" + period + "_" + file_name_marker;
   
   copy = CopyRates(symbol_name,per,0,len,price);
   
   if (copy > 0) {
      Alert((string)copy + " data points saved. Symbol = " + symbol_name + ". Type = " + period + ".");
      int size = 10;
      string out = "Index, Symbol, Period, Time, Open, High, Low, Close, Volume";
      string format = " %G, %G, %G, %G, %d";
      
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
                                          price[i].tick_volume);
         
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
