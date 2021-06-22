day9: day9.o
	gcc -no-pie -m64 -o day9 day9.o

day9.o: day9.asm
	nasm -g -felf64 day9.asm -l day9.lst

clean:
	rm -f day9 day9.o day9.lst


