#include "funclib.h"
#include <iostream>
using namespace std;

double add (double a, double b){return a+b;}
double sub (double a, double b){return a-b;}
double mul (double a, double b){return a*b;}
double divide (double a, double b){
	if (b == 0){
		cout << "Undefined " << endl ;
		return 0;
	}
	else return a/b;
}

