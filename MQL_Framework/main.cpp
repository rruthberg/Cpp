#include <iostream>
#include "MQL_Trade.h"
#include "Trade.h"
#include <vector>
#include <map>

//Program is very vulnerable. Switch statements need else case as well...?
//Create a map for the orders for searchability

/*
I want:
-central order book that is initialized. Is connected to the symbols, and points to all orders
    ~Uses a map for searchability of orders
    ~
-symbol handling and management of tick data
    ~symbol has the tick data and timestamps (equally distanced to begin with, such as each second)
    ~symbol book found by reference to the enumeration
-order class that communicates with the central order book through OrderSend. Also contains methods for trading
    ~should be on same format as a real MQL program
-a library of cuda functions that can be used in this framework for quick calculations of large amounts of data

*/

using namespace std;

//Order* orders[1000];
//int orderCount = 0;
//Symbol eurgbp, eurusd, eursek, usdsek, gbpusd;



int main()
{
    /*TEST STUFF
    Symbol* sym_array = new Symbol[5];
    SymbolInit(sym_array);
    SymbolList sym_list(sym_array);
    //sym_list.pushSymbol(sym_array[0].symbol,sym_array);
    Symbol* test = sym_list.popSymbol(EURGBP);
    cout << "Popped symbol: "<< test->ask << endl;
    test->ask = 980;
    cout << "Original symbol: " << sym_array[0].ask << endl;
    Symbol* test2 = sym_list.popSymbol(EURGBP);
    cout << "Popped new: " << test2->ask << endl;
    cout << "Popped first new: " << test->ask << endl;

    Ticket orderbook[10]; //Refine this to a vector and class usage
    Order o1(sym_array,orderbook);
    o1.price = 100;
    double pr = o1.getPrice();
    cout << "Price is: " << pr << endl;
    delete[] sym_array;
    Ticket t1;
    Ticket t2;
    t1.price = 1221;
    t2.price = 9999;
    map <symbolType,Symbol> maptest;
    maptest[EURUSD] = sym_array[1];
    //maptest["kalle"] = 939;
    cout << "Map stuff: " << maptest[EURUSD].ask << endl;
    */
    Symbol symTest;
    SymbolList symList;
    OrderBook o_book(&symList);

    symTest.ask = 100;
    symTest.bid = 95;

    symTest.symbol=EURGBP;

    symList.pushSymbol(symTest.symbol, symTest);

    Ticket t1;
    t1.price = 99;
    t1.symbol = EURGBP;

    int t1_num, t2_num;


    t1_num = o_book.addTicket(t1);

    cout << "This > " << o_book.getTicket(t1_num)->price << " vs  ___" << endl;
    cout << " size: " << o_book.booksize << endl;
    cout << "-------------------------" << endl;

    Order order(&o_book);
    //bool check;
    //check = order.Open(EURGBP,BUY,111,0.1,88,122,1337);
    //TODO SOME ERROR READING FROM THE SYMBOL MAP!! FIX THIS
    //Symbol outSym;
    //outSym = symList.symbolMap[EURGBP];

    //cout << "A1: " << symList.symbolMap.count(EURGBP) << endl; //<< "A2: " <<  symList.symbolMap[EURGBP].std::map::end() << endl;


    return 0;
}
