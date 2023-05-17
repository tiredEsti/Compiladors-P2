CC=gcc
CFLAGS=-g -Wall -I.

syn: syn.tab.o lex.yy.o symtab.o
	$(CC) -o $@ $^ -lm

syn.tab.o: syn.tab.c
	$(CC) $(CFLAGS) -c $<

syn.tab.c: syn.y
	bison -d $<

lex.yy.o: lex.yy.c
	$(CC) $(CFLAGS) -c $<

lex.yy.c: lex.l
	flex $<

symtab.o: symtab.c
	$(CC) $(CFLAGS) -c $<


.PHONY: clean
clean:
	rm -f syn syn.tab.c syn.tab.h lex.yy.c *.o log.txt

