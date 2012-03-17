#
# Makefile for HOS, Human operating system, 
# boot parts...
# (c) Jimmy Larsson 1998
#

NASM86	=nasm -f bin

all:    boot loader


# Boot stage 1, bootblock
boot:	boot.S
	$(NASM86) -o boot.b boot.S


# Boot stage 2
loader:	loader.S
	$(NASM86) -o loader loader.S

loader_bochs:	loader
		mount /mnt/hos.floppy
		cp -f loader /mnt/hos.floppy/loader
		umount /mnt/hos.floppy
		bochs

clean:
	rm -f boot.b *~ loader

install: boot
	(dd if=boot.b of=/dev/fd0 bs=1 count=3 ; dd if=boot.b of=/dev/fd0 bs=1 seek=62 skip=62)
