day4: day4.o
	gcc -no-pie -m64 -o day4 day4.o

day4.o: day4.asm
	nasm -g -felf64 day4.asm -l day4.lst

clean:
	rm -f day4 day4.o day4.lst


