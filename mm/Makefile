#
# Memeory management Makefile 
# (c) Jimmy Larsson 1998
#



AR	=ar
NASM	=nasm -f elf
CC	=gcc
CFLAGS	=-Wall -O2 -nostdinc -m486
CPP	=gcc -E -nostdinc
RANLIB	=ranlib

MM_OBJS = pages.o


.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

.S.o:
	$(NASM) -o $*.o $<


all:	mm

mm:	$(MM_OBJS)
	$(AR) rs libmm.a $(MM_OBJS)
	$(RANLIB) libmm.a


clean:
	rm -f *~ *.o $(MM_OBJS) entry.o tmp_make libmm.a

dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in *.c;do echo -n `echo $$i | sed 's,\.c,\.s,'`" "; \
		$(CPP) -M $$i;done) >> tmp_make
	cp tmp_make Makefile
	rm -f tmp_make

### Dependencies:
pages.s pages.o: pages.c pages.h
