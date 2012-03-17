#
# Makefile for Bonk
#

AR	=ar
NASM	=nasm -f elf
AS	=as
LD	=ld

# The kernel is loaded at 0x100000, so we'll link for that
LDFLAGS	=-s -x -Ttext 0x100000 -e system_entry

CC	=g++
CFLAGS	=-Wall -O2 -fstrength-reduce -fomit-frame-pointer -nostdinc
CPP	=gcc -E -nostdinc
OBJDUMP =objdump
OBJCOPY =objcopy

# Objects of the system
SYSTEM_OBJS = kernel/entry.o kernel/libkernel.a mm/libmm.a

# All subdirs
SUBDIRS = kernel mm


all:	system

system:	$(SYSTEM_OBJS)
	$(LD) $(LDFLAGS) -o system.elf $(SYSTEM_OBJS)
	$(OBJCOPY) --remove-section=.note --remove-section=.comment --output-target=binary system.elf system.bin
	rm -f system.elf


# The kernel code
kernel/libkernel.a:
	(cd kernel; make dep; make)


# Memory management
mm/libmm.a:
	(cd mm; make dep; make)


# The system entry code
kernel/entry.o:
	(cd kernel; make entry;)



clean:
	for i in $(SUBDIRS); do (cd $$i && make clean); done;
	(cd boot;make clean; cd ..)
	rm -f core system.elf system.bin *~ tmp_make

dep:
	for i in $(SUBDIRS); do (cd $$i && make dep); done;

     
bochs:
	(make clean;make;mount /mnt/hos.floppy;cp -f system.bin /mnt/hos.floppy/system;umount /mnt/hos.floppy;bochs)



