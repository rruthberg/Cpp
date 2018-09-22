//+------------------------------------------------------------------+
//|                                                     ReadTest.mq4 |
//|                                 Copyright 2017, Richard Ruthberg |
//|                                                  ruthberg@kth.se |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Richard Ruthberg"
#property link      "ruthberg@kth.se"
#property version   "1.00"
#property strict
input int ls_1 = 6; //number of input neurons
input int ls_2 = 1; //number of output neurons
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+


//Function declarations:
void f_csvToArray (string filename, double &arr[], string subdir = "Data"); //Reading csv file to array
double f_sigmoid(double & wArr[], double & iArr[], double bias); //Simple sigmoid function
void f_sigmoidArray(double &retArr[], double &wArr[], double &iArr[], double &biArr[], int neurons=1); //reading sigmoid using arrays
bool ArrFun(int & arr[]); //Test function

//Main script function
void OnStart()
  {
//---
   
   //Initialize variables
   double w1[], w2[], ind[], b1[], b2[], sig_1[];

   double s[]; //sigmoid values as one vector
   
   //Read NN weights for each layer along with biases
   f_csvToArray("TANN_Weights_Layer_1.csv", w1); 
   f_csvToArray("TANN_Weights_Layer_2.csv", w2);
   f_csvToArray("TANN_Bias_Layer_1.csv", b1);
   f_csvToArray("TANN_Bias_Layer_2.csv", b2);
   
   //Resize 
   ArrayResize(ind,ls_1);
   ArrayInitialize(ind,1);
   
   f_sigmoidArray(s,w1,ind,b1,ls_1);
   
   for(int i=0;i<ArraySize(s);i++) Print("Sigmoid val = " + DoubleToStr(s[i]));
   Print("Array size is: " + IntegerToString(ArraySize(w1)));
   Print("Array size is: " + IntegerToString(ArraySize(w2)));
   Print("Array size is: " + IntegerToString(ArraySize(b1)));
   Print("Array size is: " + IntegerToString(ArraySize(b2)));
   Print("Array size is: " + IntegerToString(ArraySize(ind)));
   Print("Array size is: " + IntegerToString(ArraySize(s)));
   
   Print("First is : " + DoubleToString(s[0]));
   
   
   
   /*
   string InpFileName="TANN_Weights_Layer_1.csv";    // file name
   string InpDirectoryName="Data";   // directory name
   int    InpEncodingType=FILE_UNICODE; // ANSI=32 or UNICODE=64
   //--- print the path to the file we are going to use
   //PrintFormat("Working %s\\Files\\ folder",TerminalInfoString(TERMINAL_DATA_PATH));
   //--- reset the error value
   ResetLastError();
   //--- open the file for reading (if the file does not exist, the error will occur
   int file_handle=FileOpen(InpDirectoryName+"//"+InpFileName,FILE_READ|FILE_CSV,',');
   //int file_handle=FileOpen(InpFileName,FILE_READ|FILE_CSV,',');
  
   if(file_handle!=INVALID_HANDLE)
     {
      //--- print the file contents
      while(!FileIsEnding(file_handle))
         Print(DoubleToStr(FileReadNumber(file_handle),8));
      //--- close the file
      FileClose(file_handle);
     }
   else
      PrintFormat("Error, code = %d",GetLastError());
   
   
   Print(TerminalInfoString(TERMINAL_DATA_PATH));
   */
   
  }
//+------------------------------------------------------------------+


//FUNCTIONS:


//Read csv file to a C++ array:
void f_csvToArray (string filename, double &arr[], string subdir = "Data")
{
   ResetLastError();
   //--- open the file for reading (if the file does not exist, the error will occur
   int file_handle=FileOpen(subdir+"//"+filename,FILE_READ|FILE_CSV,',');
   //int file_handle=FileOpen(InpFileName,FILE_READ|FILE_CSV,',');
   int i = 0;
   if(file_handle!=INVALID_HANDLE)
     {
      Print("Reading file " + filename);
      //--- print the file contents
      while(!FileIsEnding(file_handle))
      {
         if(i+1>ArraySize(arr))
         {
            if(ArrayIsDynamic(arr))
            {
               ArrayResize(arr,i+1);
               Print("Array too small, resized.");
            }
            else
            {
               Print("Array is too small and could not resize, aborting...");
               break;
            }
         }
         arr[i] = (double) FileReadNumber(file_handle);
         Print("Added number " + DoubleToStr(arr[i],20) + " to array"); 
         i++;
      }
      //--- close the file
      FileClose(file_handle);
     }
   else
      PrintFormat("Error, code = %d",GetLastError());
}

//Sigmoid function
double f_sigmoid(double & wArr[], double & iArr[], double bias) 
{
   double wsum, esum;
   int i, wLen;
   wsum = 0;
   wLen = ArraySize(wArr);
   for(i;i<wLen;i++) 
   {
      wsum += wArr[i]*iArr[i];
      Print(wsum);
   } 
   esum = exp(-wsum-bias);
   if(1+esum == 0) return 1;
   else return 1/(1+esum);
}

//Sigmoid array function
//TODO: is the sigmoid calculation correct? Weighted sum using i+j but should be (i*neurons + j)?
void f_sigmoidArray(double &retArr[], double &wArr[], double &iArr[], double &biArr[], int neurons=1) 
{  
   int i = 0;
   double wsum, esum, check;
   ArrayResize(retArr,neurons);
   check = ArraySize(wArr)/ArraySize(iArr);
   
   for(i;i<neurons;i++)
   {
      int j = 0;
      if(check != (double) neurons)
      {
         Print("Invalid weight or input array size vs. neuron count. Aborting.");
         ArrayInitialize(retArr,0);
      }
      wsum = 0;
      esum = 0;
      for(j;j<neurons;j++) 
      {
         wsum += wArr[i*neurons+j]*iArr[j]; //TODO: possibly incorrect calc... should be better now
      } 
      esum = exp(-wsum-biArr[i]);
      if(1+esum == 0) retArr[i] = 1;
      else retArr[i] = 1/(1+esum);
      
      Print(DoubleToStr(retArr[i]));
      Print("Current it: " + IntegerToString(i) + " -- Sum is: " + DoubleToStr(wsum) + " and bias: " + DoubleToStr(biArr[i]));
   }
}

//Test function
bool ArrFun(int & arr[])
{
   for(int i; i < ArraySize(arr); i++)
   {
      Print("New: " + IntegerToString(arr[i]) + " and " + IntegerToString(i));
   }
   
   return true;
}