//+------------------------------------------------------------------+
//|                                                      TANN_EA.mq4 |
//|                                 Copyright 2017, Richard Ruthberg |
//|                                                  ruthberg@kth.se |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Richard Ruthberg"
#property link      "ruthberg@kth.se"
#property version   "1.00"
#property strict
//--- general input parameters
input int      _SL=200;
input int      _TP=0;
input double   _LOT=0.1;
input int      _TRAIL=200;
//--- input parameters for weights and TA period
input double   _W1   =0.25;
input double   _W2   =0.25;
input double   _W3   =0.25;
input double   _W4   =0.25;
input int      _PER  =14;
//--- input thresholds
input double  _TUP = 60;
input double _TLOW = 50;  
//Magic 
#define MAGICMA 20171220

//+------------------------------------------------------------------+
//| Calculate open positions tied to the EA and check trailstops     |
//+------------------------------------------------------------------+
int CalcOrderTrail(string symbol)
  {
   int buys=0,sells=0;
//--- assumes unidirectional trades
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)
         {  
            buys++;
            if(OrderStopLoss() < Bid-Point*_TRAIL)
            {
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Bid-Point*_TRAIL,Digits),OrderTakeProfit(),0,Blue))
                  Print("OrderModify error ",GetLastError());
            } 
         }
         if(OrderType()==OP_SELL)
         {
            sells++;
            if(OrderStopLoss() > Ask + Point*_TRAIL)
            {
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Ask+Point*_TRAIL,Digits),OrderTakeProfit(),0,Blue))
                  Print("OrderModify error ",GetLastError());
            } 
         }
        }
     }
//--- return orders volume, buys or sells
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double tann, tp, sl;
   int    res;
   tp = 0;
   sl = 0;
   
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get TANN
   //ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   tann = iCustom(NULL,0,"TANN",_W1, _W2, _W3, _W4, _PER, 0,0);
//--- sell conditions
   if(tann < _TLOW)
     {
      //SL and TP levels should use the Ask for SELL orders since we ¨
      //will buy the position at the Ask
      if(_SL>0) sl = Ask + Point*_SL;
      if(_TP>0) tp = Ask - Point*_TP;
      
      res=OrderSend(Symbol(),OP_SELL,_LOT,Bid,3,sl,tp,"",MAGICMA,0,Red);
      return;
     }
//--- buy conditions
   if(tann > _TUP)
     {
      //SL and TP levels should use the Bid for BUY orders since we 
      //will sell the position at the Bid
      if(_SL>0) sl = Bid - Point*_SL;
      if(_TP>0) tp = Bid + Point*_TP;
      res=OrderSend(Symbol(),OP_BUY,_LOT,Ask,3,sl,tp,"",MAGICMA,0,Blue);
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double tann;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get TANN 
   //ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   tann = iCustom(NULL,0,"TANN",_W1, _W2, _W3, _W4, _PER, 0,0);
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(tann < _TUP)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(tann > _TLOW)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }












//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalcOrderTrail(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
//---
  }
//+------------------------------------------------------------------+
