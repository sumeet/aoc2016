day1: day1.o
	gcc -no-pie -m64 -o day1 day1.o

day1.o: day1.asm
	nasm -g -felf64 day1.asm -l day1.lst

clean:
	rm -f day1 day1.o day1.lst


