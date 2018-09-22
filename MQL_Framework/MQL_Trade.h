#ifndef MQL_TRADE_H_INCLUDED
#define MQL_TRADE_H_INCLUDED
#include <string>
#include <vector>
#include <map>
//MQL trade structure goes here
//Class variables:                 lowercase letters
//Class functions, order:          OrderFunction
//Class functions, non-order:      camelCase
//Function parameters:             pParam
//Function variables:              _variable

//ENUMERATIONS:
enum tradeType {
    BUY,
    SELL,
    BUY_STOP,
    SELL_STOP,
    BUY_TAKE_PROFIT,
    SELL_TAKE_PROFIT,
    BUY_LIMIT,
    SELL_LIMIT
};

enum opTradeType {
    OP_BUY,
    OP_SELL,
    OP_BUYSTOP,
    OP_SELLSTOP,
    OP_BUYTAKEPROFIT,
    OP_SELLTAKEPROFIT,
    OP_BUYLIMIT,
    OP_SELLLIMIT
};

enum symbolType {
    EURUSD,
    EURGBP,
    GBPUSD,
    USDSEK,
    EURSEK
};

enum candleTime {
    M1,
    M5,
    M10,
    M15,
    M30,
    H1,
    H4,
    H12,
    D1,
    D30,
    D180,
    Y1
};

enum orderState {
    OPEN,
    PENDING,
    CLOSED
};

//STRUCTS:
struct Price {
    double ask;
    double bid;
};

struct Ticket {
    int ticket;
    symbolType symbol;
    double price;
    double lots;
    double close;
    Price currprice;
    double pnl;
    tradeType type;
    double tp;
    double sl;
    double limit; //remove
    int magic;
    double point;
    int deviation;
    //std::string comment;
    orderState state;
};

//SYMBOLS & CANDLES:
class Symbol {
    public:
        symbolType symbol;
        double bid;
        double ask; //create an array/vector
        int slippage;
        double volume;
        double bidvec;
        double askvec;
        double volvec;
        Price tick;
    //public:
        Symbol(symbolType pSymb = EURGBP,
               double pBid = 90,
               double pAsk = 100) : symbol(pSymb),bid(pBid),ask(pAsk) {};

        //~Symbol();
        Price getLastTick();
        getLastVol();
        pushTick(Price pTick); //pushes latest tick data
        pushAsk(double pAsk); //pushed latest ask price and adds to the vector
        pushBid(double pBid); //pushes latest bid price and adds to the vector
        pushVol(double pVol); //pushes latest volume and adds to the vector
        randData(int pLen, int pModel);

};

class SymbolList{
    //SHOULD USE a MAP i think
    //Shoult the symbols be pointers to symbols instead? NEED to do it. Depends on how its used. <map> creates a copy it seems -> THIS IS BEST
    public:
        int index; //represents the enumerations
        std::map <symbolType,Symbol> symbolMap;
        void pushSymbol(symbolType pType, Symbol pSym); //IMPROVEMENT: only push the pSym and use its symbol type?
        Symbol* popSymbol(symbolType pType);
        void removeSymbol(symbolType pType);
        SymbolList(){};
        Price getSymPrice(symbolType pType); //Get functions all need to be created in the symbollist!
        void updateSymbol(symbolType pType, Price pTick, double pVol = 0);
};

class Candle : public Symbol {
    //Should be like symbol ut open high low close data
};


//ORDER BOOK CLASS
class OrderBook{
    public:
        std::vector<Ticket> ordervec;
        int booksize; //Also specifies the last ticket number
        //Tickets will be copied to the vector it seems. Is this intended? Seems unnecessary to copy rather than just store the same order.
        //Maybe this is better. Using an abstract order to be re-sent and stored, so the copied order will be re-used. That would make sense.
        //This is probably the only way to do it because I dont want to create several variables or ANOTHER vector to store that... so yeah, makes sense
        Ticket* getTicket(int pTnum); //Gives back the address of a stored order in the orderbook.
        SymbolList* symptr;
        int addTicket(Ticket pTicket);
        //void removeTicket(int pTnum); unnecessary

        double totPnl(); //Wait with this
        void refreshPrices(); //Wait with this
        OrderBook(SymbolList* pSymPtr): booksize(0), symptr(pSymPtr){};
};


//ORDER CLASS:
class Order {
    //protected:
    //Need input of an orderbook to be able to communicate with it.
    public:
        int ticket;
        symbolType symbol;
        double price;
        double lots;
        double close;
        Price currprice;
        double pnl;
        tradeType type;
        double tp;
        double sl;
        double limit; //remove
        int magic;
        double point;
        int deviation;
        //std::string comment;
        orderState state;
        Ticket orderticket; //to be sent to the order book
        SymbolList* symptr;
        OrderBook* bookptr;

    //public:
        Order(OrderBook* pOrderBookPtr):
            ticket(-1), point(0.001), deviation(10), bookptr(pOrderBookPtr), state(OPEN) {};
        //~Order();
        int OrderSend(Ticket pTicket); //function that sends an order to the order book where it is copied and stored. Also checks the order viability and communicatess with the symbol
                     //This also populates a ticket and gets back a ticket number which is the index in the order book
        bool Open(symbolType pSymbol, tradeType pType, double pPrice = 0, double pLot = 0.1, double pSL = 0, double pTP = 0, int pMag = 1);
        bool Modify(double tp, double sl, double lp);
        bool Close(double pClose);
        bool Delete();
        void calcPnl();
        double getPrice();
        void setCurrPrice(Price pCurrprice);
        void populateTicket();
        bool checkTicket(Ticket pTicket);
        void refreshPrice(symbolType pSymbol);

};




//CENTRAL FUNCTIONS AND CLASSES:
void SymbolInit(Symbol arr[]);

int OrderSend(  symbolType pSymbol, tradeType pTradetype, double pLot, double pPrice, int pSlip,
                double pTP, double pSL, double pLimit, int pMagic, double pExpiration);


#endif // MQL_TRADE_H_INCLUDED
