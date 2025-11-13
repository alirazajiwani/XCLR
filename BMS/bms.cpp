#include <iostream>
using namespace std;


class Account{
	private:
		int accountNumber;
		double balance;

	protected:
		double getBalance() const { return  balance; }
		void setBalance(double newBalance) { balance = newBalance; }

	public:
		// Base Constructor
		Account (int accNum, double bal) : accountNumber(accNum) , balance(bal){}

		// Deposit 
		void deposit (double amount){
			balance += amount;
		}

		// Virtual Withdraw
		virtual void withdraw (double amount){
			balance -= amount;
		}

		// Display Account Balance
		void displayBalance (){
			cout << "Account Number(" << accountNumber << "): Balance =  " << balance << endl;
		}

		virtual ~Account() {}
};


class SavingsAccount : public Account {
	public:
		SavingsAccount (int accNum, double bal) : Account(accNum, bal) {}

		// Derived Withdraw
		void withdraw (double amount) override {
			if (amount <= getBalance()-1000) {
				setBalance(getBalance() - amount); 	  //Allows to hold atleats 1000RS in account
				cout << "Amount Withdrawn!" << endl;
			}
			else 
				cout << "Entered Amount Cannot Be Withdrawn!" << endl;
		}
};

class CurrentAccount : public Account {
	public: 
		CurrentAccount (int accNum, double balance) : Account (accNum, balance) {}

		// Derived Withdraw
		void withdraw (double amount) override {
			if (amount + 25.5  <= getBalance()){
				setBalance(getBalance() -  amount + 25.5);  //Service Charges
				cout << "Amount Withdrawn!" << endl;
			}
			else 
				cout << "Insufficient Balance!" << endl;
		}
};



int main (){
	Account* acc1 = new SavingsAccount(1, 2000);
	Account* acc2 = new SavingsAccount(2, 1000);
	Account* acc3 = new CurrentAccount(3, 1000);

	cout << "---------- BALANCE BEFORE -----------" << endl;
        acc1->displayBalance();
        acc2->displayBalance();
        acc3->displayBalance();


	cout << "---------- WITHDRAWAL TEST ----------" << endl;
	acc1->withdraw(500);
	acc2->withdraw(500);
	acc3->withdraw(500);
	

	cout << "----------- BALANCE AFTER -----------" << endl;
	acc1->displayBalance();
	acc2->displayBalance();
	acc3->displayBalance();


	cout << "-------------------------------------" << endl;
	acc2->deposit(1000);
	acc2->displayBalance();
	acc2->withdraw(1000);
	acc2->displayBalance();

	delete acc1;
	delete acc2;
	delete acc3;
}

