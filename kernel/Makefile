#
# Kernel Makefile 
# (c) Jimmy Larsson 1998
#

#
# The entry.S lies outside of the libkernel.a, 
# because I can't get ld to link only libraries...
#

AR	=ar
NASM	=nasm -f elf
CC	=gcc
CFLAGS	=-Wall -O2 -nostdinc -m486
CPP	=gcc -E -nostdinc
RANLIB	=ranlib

KERNEL_OBJS = stack.o start.o printk.o port_io.o 8259.o idt.o idt_s.o interrupt.o panic.o switching.o task_test.o syscall.o

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

.S.o:
	$(NASM) -o $*.o $<


all:	kernel

kernel: $(KERNEL_OBJS)
	$(AR) rs libkernel.a $(KERNEL_OBJS)
	$(RANLIB) libkernel.a

entry:  entry.S
	$(NASM) -o entry.o entry.S

clean:
	rm -f *~ *.o $(KERNEL_OBJS) entry.o tmp_make libkernel.a

dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in *.c;do echo -n `echo $$i | sed 's,\.c,\.s,'`" "; \
		$(CPP) -M $$i;done) >> tmp_make
	cp tmp_make Makefile
	rm -f tmp_make

### Dependencies:
8259.s 8259.o: 8259.c config.h debug_messages.h printk.h 8259.h port_io.h
idt.s idt.o: idt.c config.h debug_messages.h printk.h types.h idt.h gdt.h \
 8259.h panic.h stack.h
interrupt.s interrupt.o: interrupt.c types.h panic.h debug_messages.h config.h \
 printk.h interrupt.h idt.h 8259.h
panic.s panic.o: panic.c panic.h printk.h config.h
printk.s printk.o: printk.c printk.h config.h
stack.s stack.o: stack.c config.h stack.h
start.s start.o: start.c types.h config.h printk.h interrupt.h switching.h \
 task_test.h panic.h
switching.s switching.o: switching.c types.h config.h gdt.h idt.h switching.h \
 debug_messages.h printk.h
syscall.s syscall.o: syscall.c types.h config.h gdt.h printk.h syscall.h \
 switching.h task_test.h
task_test.s task_test.o: task_test.c config.h types.h printk.h switching.h \
 interrupt.h port_io.h 8259.h task_test.h idt.h syscall.h
