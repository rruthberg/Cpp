#include "MQL_Trade.h"
#include <string>
#include <vector>
#include <iostream>
using namespace std;
//Central functions:
void SymbolInit(Symbol arr[]){
    for(int x=0;x<=4;x++){
        arr[x].ask = 100;
        arr[x].bid = 90;
        arr[x].symbol = (symbolType)x;
    }
}

Price Symbol::getLastTick(){
    tick.ask = ask;
    tick.bid = bid;
    return tick;
}



void SymbolList::pushSymbol(symbolType pType, Symbol pSym){
    // NEW WAY OF CHECKING EXISTENCE
    //if(symbolMap.find(pType) == symbolMap.end() && pSym.symbol == pType){
    if(symbolMap.count(pType) == 0 && pSym.symbol == pType){
            //GOOD TO GO
            symbolMap[pType] = pSym; //Should this be a pointer? NO
    } else {
        //ERROR
        std::cout << "Symbol already exists or inconsistent type set."<< endl;
    }
}

Symbol* SymbolList::popSymbol(symbolType pType){
    if(symbolMap.find(pType) == symbolMap.end()){
            //ERROR
            return 0; //Return a null pointer if the symbol does not exist in the list
    } else {
        return &symbolMap[pType] ;
    }
}

void SymbolList::removeSymbol(symbolType pType){
    if(symbolMap.find(pType) == symbolMap.end()){
            //ERROR
    } else {
        symbolMap.erase(pType);
    }
}

Price SymbolList::getSymPrice(symbolType pType){
    // NEW WAY OF CHECKING EXISTENCE
    //if(symbolMap.find(pType) == symbolMap.end()){
    if(symbolMap.count(pType) == 0){
            //ERROR
    } else {
        return (symbolMap[pType]).getLastTick();
    }
}

/*
SymbolList::SymbolList(Symbol arr[]){
    //Modify the 4 to length of arr
    for(int i=0;i<=4;i++){
        pushSymbol(arr[i].symbol, arr[i]);
    }
}
*/

//Order class functions:
//TODO:

void Order::refreshPrice(symbolType pSymbol){
    //Function should communicate with the specified symbol and get latest price data
    //This should trigger checks on pending orders as well
    currprice = symptr->getSymPrice(pSymbol);
}

int Order::OrderSend(Ticket pTicket){
    //This will be used slightly different from the platform
    //CHECKS on ticket! done here really? yes, this is where the communication is with the symbol.
    //Need to check with Symbol that price is OK
    return bookptr->addTicket(pTicket);
}

bool Order::Open(symbolType pSymbol, tradeType pType, double pPrice, double pLot, double pSL, double pTP, int pMag) {
    refreshPrice(pSymbol); //This could be removed if refresPrices() is used or the like. IMPROVEMENT
    double _currprice;

    bool _oksl      = true;
    bool _oktp      = true;
    bool _okpr      = true;
    bool _oksym     = true;
    bool _oktype    = true;
    bool _oklot     = true;

    std::string _buysell = "BUY";

    int _onum;

    switch(pType){
        case BUY:
        case BUY_STOP:
        case BUY_TAKE_PROFIT:
        case BUY_LIMIT:
            _currprice = currprice.ask;
            if(pPrice == 0) price = _currprice;
            else price = pPrice;
            if(price >= _currprice) _okpr = false;
            if(pSL > price-deviation*point) _oksl = false;
            if(pTP < price+deviation*point) _oktp = false;
            if(pType == BUY_LIMIT) {
                    state   = PENDING;
                    limit   = price;
            }
            break;
        case SELL:
        case SELL_STOP:
        case SELL_TAKE_PROFIT:
        case SELL_LIMIT:
            _currprice = currprice.bid;
            if(pPrice == 0) price = _currprice;
            else price = pPrice;
            if(price <= _currprice) _okpr = false;
            if(pSL < price+deviation*point) _oksl = false;
            if(pTP > price-deviation*point) _oktp = false;
            if(pType == SELL_LIMIT) {
                    state   = PENDING;
                    limit   = price;
            }
            _buysell = "SELL"; //Temporary, used for printing TODO
            break;
        default:
            _oktype = false;
            break;
    }

    if(pLot>0) lots = pLot;
    if(pSL > 0 && _oksl == true) sl = pSL;
    if(pTP > 0 && _oktp == true) tp = pTP;
    if(symptr->popSymbol(pSymbol) == 0) _oksym = false; //Check if symbol name is in the symbollist, else false

    magic = pMag;

    if(_oksl == false || _oktp == false || _okpr == false || _oksym == false|| _oktype == false || _oklot == false ) {
        //std::cout << "Trade could not be placed. Please check input and retry." << endl;
        return false;
    } else {
        populateTicket();
        _onum = OrderSend(orderticket);
        if (_onum==-1) return false;
        ticket = _onum;
        //std::cout << "Trade placed: " << endl << "Type = " << _buysell << endl;
        return true;
    }
}

bool Order::Modify(double tp, double sl, double lp) {
    //USe try catch - return true
    tp = tp;
    sl = sl;
    limit = lp;
    //comment = cmt;
    return true;
}

bool Order::Close(double pClose) {
    close = pClose;
    state = CLOSED;
    calcPnl();
    return true;
}

bool Order::Delete() {
    //Can this be used here?
    return true;
}

void Order::calcPnl() {
    switch(state){
    case OPEN:
        if(type==BUY || type == BUY_STOP || type == BUY_TAKE_PROFIT) {
            pnl = price-currprice.ask;
        } else {
            pnl = currprice.bid-price;
        }
    case PENDING:
            pnl = 0;
    case CLOSED:
        if(type==BUY || type == BUY_STOP || type == BUY_TAKE_PROFIT) {
            pnl = price-close;
        } else {
            pnl = close-price;
        }
    }
}

double Order::getPrice() {
    return price;
}

void Order::setCurrPrice(Price pCurrprice){
    currprice.ask = pCurrprice.ask;
    currprice.bid = pCurrprice.bid;
}

void Order::populateTicket(){
        orderticket.ticket=ticket;
        orderticket.symbol=symbol;
        orderticket.price=price;
        orderticket.lots=lots;
        orderticket.close=close;
        orderticket.currprice=currprice;
        orderticket.pnl=pnl;
        orderticket.type=type;
        orderticket.tp=tp;
        orderticket.sl=sl;
        orderticket.limit=limit; //remove
        orderticket.magic=magic;
        orderticket.point=point;
        orderticket.deviation=deviation;
        //std::string comment;
        orderticket.state=state;
}

int OrderBook::addTicket(Ticket pTicket){
    ordervec.push_back(pTicket);
    booksize=ordervec.size();
    ordervec[booksize-1].ticket = booksize;
    return booksize;
}

Ticket* OrderBook::getTicket(int pTnum){
    Ticket* _tptr = &ordervec[pTnum-1];
    return _tptr;
}


/* IS THIS NEEDED?
int OrderSend(  symbolType pSymbol, tradeType pTradetype, double pLot, double pPrice, int pSlip,
                double pTP, double pSL, double pLimit, int pMagic, double pExpiration) {
    //Symbol _symbol = sym_array[(int)pSymbol];
    return 0;
}
*/
