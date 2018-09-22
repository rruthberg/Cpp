//+------------------------------------------------------------------+
//|                                                         TANN.mq4 |
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
#property strict
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 1
#property indicator_plots   1
//--- plot Levels
#property indicator_level1     50.0
#property indicator_level2     55.0
#property indicator_level3     45.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
//--- plot Signal
#property indicator_label1  "Signal"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input double   _W1   =0.25;
input double   _W2   =0.25;
input double   _W3   =0.25;
input double   _W4   =0.25;
input int      _PER  =14;
//--- indicator buffers (Signal and for calculation)
double         SignalBuffer[];
//double ExtPosBuffer[];
//double ExtNegBuffer[];

//--- variables

ENUM_APPLIED_PRICE _app, _app1, _app2, _app3, _app4;
ENUM_TIMEFRAMES _tf, _tf1, _tf2, _tf3, _tf4;
int _per, _per1, _per2, _per3, _per4;
string _sym, _sym1, _sym2, _sym3, _sym4;
double w1[], w2[], b1[], b2[], imin[],imax[], imean[];
int ls_1 = 5; //input neurons
int ls_2 = 1; //output neuron





//+------------------------------------------------------------------+
//| Custom defined functions for use later                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//Sigmoid array function. Takes return-, weight-, input/(indicator)
//and bias arrays as input. Also the number of neurons in the layer.
//Need to be run once for each layer, output subsequently used as 
//input to other layers.
//https://en.wikipedia.org/wiki/Sigmoid_function 


//HEADER:
double f_sigmoid(double w1, double w2, double w3, double w4, double w5,
                 double i1, double i2, double i3, double i4, double i5,
                 double bias
                 );
                 
void f_sigmoidArray(double & retArr[], double & wArr[], double & iArr[], double & biArr[], int neurons=5);

void f_csvToArray (string filename, double & arr[], string subdir = "Data");

//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   string short_name;
   _app = PRICE_CLOSE;
   _per = _PER;
   _sym = Symbol();
   _tf = 0;
   ArrayResize(w1,25);
   ArrayResize(w2,5);
   ArrayResize(b1,5);
   ArrayResize(b2,1);
   ArrayResize(imin,5);
   ArrayResize(imax,5);
   
//--- indicator buffers mapping
   SetIndexBuffer(0,SignalBuffer);
   SetIndexStyle(0,DRAW_LINE);
   
//--- read input files to arrays
   f_csvToArray("TANN_Weights_Layer_1.csv", w1);
   f_csvToArray("TANN_Weights_Layer_2.csv", w2);
   f_csvToArray("TANN_Bias_Layer_1.csv", b1);
   f_csvToArray("TANN_Bias_Layer_2.csv", b2);
   f_csvToArray("TANN_Normalizations_Min.csv", imin);
   f_csvToArray("TANN_Normalizations_Max.csv", imax);
   
   
//--- 2 additional buffers are used for counting.
   //IndicatorBuffers(3);
   //SetIndexBuffer(1,ExtPosBuffer);
   //SetIndexBuffer(2,ExtNegBuffer);
//--- indicator line
   
//--- name for DataWindow and indicator subwindow label
   short_name="TANNI ("+string(_PER)+ ")" + " ("+string(_W1)+"|"+string(_W2)+"|"+string(_W3)+"|"+string(_W4)+"|" + ")" + "Pt val * 1000: " + string(Point*1000);
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);
//--- check for input
   if(_PER<2)
     {
      Print("Incorrect value for period input variable _PER = ",_PER);
      return(INIT_FAILED);
     }
//---
   SetIndexDrawBegin(0,_PER);
  
   
//--- initialization done

   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//--- initialize variables for calcs
   int    k,pos;
   int shift;
   
   double sig1, sig2;
   double i1, i2, i3, i4, i5;
   double tm1,tm2,tm3,tm4,tm5;
   double sigmoid;
  
//--- determine what happens if the data is less than period chosen
   if(Bars<=_PER || _PER<2)
      return(0);
//--- counting from 0 to rates_total
   ArraySetAsSeries(SignalBuffer,false);
   //ArraySetAsSeries(ExtPosBuffer,false);
   //ArraySetAsSeries(ExtNegBuffer,false);
   ArraySetAsSeries(volume,false); //applied on close price
   //ArraySetAsSeries(volume,false);
//--- preliminary calculations
   pos=prev_calculated-1;
   
   if(pos<=_PER)
     {
      //--- first values of the indicator are not calculated
      SignalBuffer[0]=50.0;
      //ExtPosBuffer[0]=0.0;
      //ExtNegBuffer[0]=0.0;
      for(k=1; k<=_PER; k++)
        {
         SignalBuffer[k]=50.0;
         //ExtPosBuffer[i]=0.0;
         //ExtNegBuffer[i]=0.0;
         //diff=close[i]-close[i-1];
        }
      //--- prepare the position value for main calculation
      pos=_PER+1;
     }
     //double ind[], sig_1[], sig_2[];
     
     
//--- the main loop of calculations
   for(k=pos; k<rates_total && !IsStopped(); k++)
     {
      double ind[], sig_1[], sig_2[];
      ArrayResize(ind,5); //resize according to # inputs
      ArrayResize(sig_1,5);
      //ArrayResize(sig_2,1);
      
      shift = rates_total - k;
      //Normalize inputs according to data analysis:
      //TODO: order of indicators is reversed when saved using pandas shit..
      //ind[4] = (Volume[0]-imin[4])/imax[4];
      //ind[3] = (iRSI(_sym, _tf, _per, _app, shift) - imin[3])/imax[3];
      //ind[2] = (iCCI(_sym, _tf, _per, _app, shift) - imin[2])/imax[2];
      //ind[1] = (iADX(_sym, _tf, _per, _app, 0, shift) -imin[1])/imax[1];
      //ind[0] = (iATR(_sym, _tf, _per, shift) - imin[0])/imax[0];
      
      
      i5 = (Volume[k]-imin[0])/imax[0];
      i4 = (iRSI(_sym, _tf, _per, _app, shift) - imin[1])/imax[1];
      i3 = (iCCI(_sym, _tf, _per, _app, shift) - imin[2])/imax[2];
      i2 = (iADX(_sym, _tf, _per, _app, 0, shift) -imin[3])/imax[3];
      i1 = (iATR(_sym, _tf, _per, shift) - imin[4])/imax[4];
      
      //ind[4] = (Volume[0]-imin[0])/imax[0];
      //ind[3] = (iRSI(_sym, _tf, _per, _app, shift) - imin[1])/imax[1];
      //ind[2] = (iCCI(_sym, _tf, _per, _app, shift) - imin[2])/imax[2];
      //ind[1] = (iADX(_sym, _tf, _per, _app, 0, shift) -imin[3])/imax[3];
      //ind[0] = (iATR(_sym, _tf, _per, shift) - imin[4])/imax[4];
      
      //tm1 = f_sigmoid(w1[0],w1[1],w1[2],w1[3],w1[4],i1,i2,i3,i4,i5);
      
      //f_sigmoidArray(sig_1,w1,ind,b1,ls_1);
      //f_sigmoidArray(sig_2,w2,sig_1,b2,ls_2);
      //sigmoid = f_sigmoid(_W1, _W2, _W3, _W4, i1, i2, i3, i4);
      shift = rates_total - k;
      //i1 = iRSI(_sym, _tf, _per, _app, shift)/100;
      //i2 = iCCI(_sym, _tf, _per, _app, shift)/100;
      //i3 = iADX(_sym, _tf, _per, _app, 0, shift)/100;
      //i4 = iATR(_sym, _tf, _per, shift)*1000;
      tm1 = f_sigmoid(w1[0],w1[1],w1[2],w1[3],w1[4], i5, i4, i3, i2, i1,b1[0]);
      tm2 = f_sigmoid(w1[5],w1[6],w1[7],w1[8],w1[9], i5, i4, i3, i2, i1,b1[1]);
      tm3 = f_sigmoid(w1[10],w1[11],w1[12],w1[13],w1[14], i5, i4, i3, i2, i1,b1[2]);
      tm4 = f_sigmoid(w1[15],w1[16],w1[17],w1[18],w1[19], i5, i4, i3, i2, i1,b1[3]);
      tm5 = f_sigmoid(w1[20],w1[21],w1[22],w1[23],w1[24], i5, i4, i3, i2, i1,b1[4]);
      
      sigmoid = f_sigmoid(w2[0],w2[1],w2[2],w2[3],w2[4],tm1,tm2,tm3,tm4,tm5,b2[0]);
      SignalBuffer[k] = sigmoid*100;
      
      
      //SignalBuffer[k] = 100*i1;
     }  
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//FUNCTIONS:

//Sigmoid function for input params
double f_sigmoid(double w1, double w2, double w3, double w4, double w5,
                 double i1, double i2, double i3, double i4, double i5,
                 double bias
                 ) 
{
   double wsum, esum;
   wsum = w1*i1 + w2*i2 + w3*i3 + w4*i4 + w5*i5;
   esum = exp(-wsum);
   //esum = exp(-wsum-bias);
   if(1+esum == 0) return 0;
   else return 1-1/(1+esum);
}

//Sigmoid for array
void f_sigmoidArray(double & retArr[], double & wArr[], double & iArr[], double & biArr[], int neurons=6) 
{  
   int x = 0;
   int y;
   double wsum, esum, check;
   ArrayResize(retArr,neurons);
   check = ArraySize(wArr)/ArraySize(iArr); //if the inputs does not match weight count, something is wrong.
   
   for(x;x<neurons && !IsStopped();x++)
   {
      y = 0;
      if(check < (double) neurons || check > (double) neurons)
      {
         Print("Invalid weight or input array size vs. neuron count. Aborting.");
         ArrayInitialize(retArr,0);
      }
      wsum = 0;
      esum = 0;
      for(y;y<neurons && !IsStopped();y++) 
      {
         wsum += wArr[x+y]*iArr[x];
      } 
      esum = exp(-wsum-biArr[x]);
      if(1+esum == 0) retArr[x] = 1;
      else retArr[x] = 1/(1+esum);
      
      //Print(DoubleToStr(retArr[i]));
   }
}


//Function that reads csv files with weights/biases into an array
void f_csvToArray (string filename, double & arr[], string subdir = "Data")
{
   ResetLastError();
   //--- open the file for reading and only read if it was successful 
   int file_handle=FileOpen(subdir+"//"+filename,FILE_READ|FILE_CSV,',');
   int i = 0;
   if(file_handle!=INVALID_HANDLE)
     {
      Print("Reading file " + filename);
      while(!FileIsEnding(file_handle))
      {
         if(i+1>ArraySize(arr))
         {
            //--- resize the array if it was too small, and we are able to
            if(ArrayIsDynamic(arr))
            {
               ArrayResize(arr,i+1);
               //Print("Array too small, resized.");
            }
            else
            {
               Print("Array is too small and could not resize, aborting...");
               break;
            }
         }
         arr[i] = (double) FileReadNumber(file_handle); //cast to double
         //Print("Added number " + DoubleToStr(arr[i],20) + " to array at index " + IntegerToString(i)); 
         i++;
      }
      //--- close the file to prevent issues
      FileClose(file_handle);
     }
   else
      PrintFormat("Error, code = %d",GetLastError());
}