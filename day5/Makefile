day5: day5.o
	gcc -no-pie -m64 -o day5 day5.o

day5.o: day5.asm
	nasm -g -felf64 day5.asm -l day5.lst

clean:
	rm -f day5 day5.o day5.lst


