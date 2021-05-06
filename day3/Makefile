day3: day3.o
	gcc -no-pie -m64 -o day3 day3.o

day3.o: day3.asm
	nasm -g -felf64 day3.asm -l day3.lst

clean:
	rm -f day3 day3.o day3.lst


