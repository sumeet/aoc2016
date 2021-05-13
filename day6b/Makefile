day6: day6.o
	gcc -no-pie -m64 -o day6 day6.o

day6.o: day6.asm
	nasm -g -felf64 day6.asm -l day6.lst

clean:
	rm -f day6 day6.o day6.lst


