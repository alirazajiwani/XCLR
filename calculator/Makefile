all: program

program: main.o func.o
	g++ main.o func.o -o program

main.o: main.cpp funclib.h
	g++ -c main.cpp


	g++ -c func.cpp

clean:
	rm -f *.o program

