day10: day10.o
	gcc -no-pie -m64 -o day10 day10.o

day10.o: day10.asm
	nasm -g -felf64 day10.asm -l day10.lst

clean:
	rm -f day10 day10.o day10.lst


