day7: day7.o
	gcc -no-pie -m64 -o day7 day7.o

day7.o: day7.asm
	nasm -g -felf64 day7.asm -l day7.lst

clean:
	rm -f day7 day7.o day7.lst


