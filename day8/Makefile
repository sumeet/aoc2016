day8: day8.o
	gcc -no-pie -m64 -o day8 day8.o

day8.o: day8.asm
	nasm -g -felf64 day8.asm -l day8.lst

clean:
	rm -f day8 day8.o day8.lst


