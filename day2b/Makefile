day2: day2.o
	gcc -no-pie -m64 -o day2 day2.o

day2.o: day2.asm
	nasm -g -felf64 day2.asm -l day2.lst

clean:
	rm -f day2 day2.o day2.lst


