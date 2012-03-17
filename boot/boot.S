;
; Boot block for Bonk
; (c) Jimmy Larsson 1998
;
;-----------------------------------------------------------------------
;
; For now this loads a file in root of a FAT-16 filesys,
; file should be called 'system'
;
;----------------------------------------------------------------------
;
; Loads image to 0x100000 (1MB) and sets up paging/protected mode
; then jumps to 0x100000
;
;-----------------------------------------------------------------------
;
; 980719 - It's now possible to boot all drives without reassembling.
;          Just change byte in end of the file with some poking tool...
;
; 980913 - Added retries to sector-read code seemed to bomb on real
;          machinery when only read once. (hdd boot code removed for now)
;
;
;-----------------------------------------------------------------------
;
; This bootblock only works with FAT-16, will not use FAT later anyway.. =)
;
; To make FAT16 floppy in linux -> "mkfs.msdos -v -F 16 /dev/fd0"
; To mount it in Linux          -> "mount -t msdos -o fat=16 /dev/fd0 /mnt/floppy"
;
; IT HAS TO BE MOUNTED WITH THE fat=16 OPTION OR LINUX WILL MESS UP THE FLOPPY
; (Shit... pulled my hair for some time before I found out this)
;
;-----------------------------------------------------------------------

; Floppy parameters (1.44)
SECTORS_1_44	equ	18
HEADS_1_44	equ	2
CYLINDERS_1_44	equ	160

; Addresses
LOAD_SEG	equ	0x800
LOAD_ADDR	equ	0x8000
	

struc	DISK_PARM	;BIOS hard disk parameters
		DP_cyl		resw	1
		DP_heads	resb	1
				resb	5	;Obsolete
		DP_ctrl		resb	1
				resb	5	;Obsolete
		DP_sect		resb	1
				resb	1
endstruc

struc	PT_ENT		;Partition table entry
		BootFlag	resb	1
		BeginHead       resb	1
		BeginSector     resb	1
		BeginCyl        resb	1
		SystemID        resb	1
		EndHead         resb	1
		EndSector       resb	1
		EndCyl          resb	1
		RelSectorLow    resw	1
		RelSectorHigh   resw	1
		NumSectorsLow   resw	1
		NumSectorsHigh  resw	1
endstruc

struc	BB		;Partition Boot block (FAT Specific)
				resb	0xD	;Things we ignore
		BB_clu		resb	1	;Sectors per cluster
		BB_res		resw	1	;Reserved sectors
		BB_fats		resb	1	;Number of FATs
		BB_root		resw	1	;Root directory entries
				resb	3	;Things we ignore
		BB_fat		resw	1	;Sectors per fat
endstruc

	
max_xfer	equ	0x78	;Maximum number of sectors to transfer at once
				;Must be divisible by 8

;-----------------------------------------------------------------------
; The code
;

section .text use 16
org     0x7c00

	jmp short start			;Standard start of boot sector
	nop
	resb	0x3B			;Skip over parameters (set by format)

start:	cli				;{0}
	lgdt	[cs:gdt]		;Load GDT


	mov	ecx, CR0		;Switch to protected mode
	inc	cx
	mov	CR0, ecx

.5:	in	al, 0x64		;Enable A20 {4A} {5}
	test	al, 2
	jnz	.5
	mov	al, 0xD1
	out	0x64, al
.6:	in	al, 0x64
	test	al, 2
	jnz	.6
	mov	al, 0xDF
	out	0x60, al

	mov	ax, flat_data		;Selector for 4Gb data seg
	mov	ds, ax			;{2} Extend limit for ds
	mov	es, ax			;Extend limit for es
	dec	cx			;Switch back to real mode
	mov	CR0, ecx


	mov	al, 0x80		;Segment for boot blocks
	mov	es, ax			;{1A}

	xor	eax, eax		;Segment and LBN
	mov	ds, ax			;{1B}
	mov	ss, ax
	mov	sp, start

;; Read bootblock of this partition (we are floppy or part. bootblobk)

	xor	edi, edi	
	inc	di			;Count of sectors
	call	read_sectors		;Read the boot block (ourselves)
					; [0x7c80]

;>  eax = 0
;>  edi = 1
;>  ds  = 0
;>  es  = 80

;	mov	si, 0x9BE-PT_ENT_size	;Point at partition table
;.10:	add	si, byte PT_ENT_size
;	cmp	[si+BootFlag], al	;Active?
;	je	.10			;No
;	jg	boot_error
;	mov	eax, [si+RelSectorLow]	;LBN sector number of partition
;	call	read_sectors		;Read partition boot block

;>  eax = LBN of partition
;>  ebx = 0000????
;>  edi = 0000????
;>   ds = 0

;--------------------------
; Read DIRECTORY into 0x800
;--------------------------


	mov	bp, 0x800		;Point at partition boot block
	mov	bx, [bp+BB_res]		;Sectors before first FAT
	add	eax, ebx		;LBN of FAT
	push	eax			;Need to read the FAT later
	movzx	bx, [bp+BB_fats]	;Number of FATs
	imul	bx, [bp+BB_fat]		;Times size of FAT
	add	eax, ebx		;LBN of Root directory
	mov	di, [bp+BB_root]	;Root directory entries
	push	di			; used again later
	dec	di			;Convert to number of sectors
	shr	di, 4			;  16 directory entries per sector
	inc	di
	mov	es, bp		;Read directory at 800:0
	call	read_sectors
	add	eax, edi		;LBN of cluster 2
					;[0x7ca7]

;>> [sp+2] = LBN of FAT
;>    [sp] = Number of root directory entries
;>>    eax = LBN of cluster 2
;>     edi = 0000????
;>>     bp = 800
;>      ds = 0
;>      es = 800

;----------------------------------
; Search the directory for filename
;----------------------------------

	pop	bx			;Root directory entries
	xor	di, di			;Point at directory {1C}
.20:	mov	si, file_name		;Name of file we want
	xor	ecx, ecx
	mov	cl, 11
	a32 rep cmpsb			;Found the file?
	je	found			;Yes
	add	cl, 21			;Offset to next directory entry
	add	edi, ecx		;Advance to next entry
	dec	bx			;Loop through all entries
	jnz	.20

	;Couldn't find file in directory
boot_error:
disk_error:	
	mov	ax, 0xE07		;{3}
	int	10h
	jmp short $

;>    [sp] = LBN of FAT
;>     eax = LBN of cluster 2
;>  es:edi = Pointer to end of name within directory entry
;>      bp = 800
;>      ds = 0
;>      es = 800

;------------------------------------------
; Ok, found. Read FAT into memory at 0x8000
;------------------------------------------

found:
	mov	bx, [es:edi+0xF]	;Starting cluster of file
	mov	di, [bp+BB_fat]		;Size of FAT (in sectors)
	xchg	eax, ebp		;ebp = LBN of cluster 2
	pop	eax			;LBN of FAT
	push	bx			;Starting cluster of file
	call	read_sectors

	mov	bh, 0x40
	mov	es, bx			;es = 0x4000
	mov	edi, LOAD_ADDR-0x40000	;{1D}{4B} One megabyte minus ES base
.10:					;[0x7ce1]

;>    [sp] = Next cluster of file
;>     esi = 0000????
;>  es:edi = Destination address
;>     ebp = LBN of cluster 2
;>      ds = 0

;--------------------------------------------------------
; Follow linked list in FAT and load all clusters of file
;--------------------------------------------------------

	xor	eax, eax
	pop	si			;Next cluster of file
	dec	si
	dec	si

	cmp	si, byte 0xFFFFFFEE 	;Valid cluster? (was: 0xFFFFFFEE)
	jae	eof			;No: assume end of file

	push word [esi*2+0x8004]	;Cluster after it
	push	di			;Save destination address {7}
	mov	al, [0x800+BB_clu]	;Size of each cluster
	mov	di, ax			;  (in sectors)
	mul	esi			;Times current cluster number
	add	eax, ebp		;Plus LBN of cluster 2	
	call	read_sectors		;Read that cluster
					;[0x7d03]
;>>    ebx = 0000??00
;>      di = Clustersize in sectors
;>     esi = 0
;>>    ebp = LBN of cluster 2
;>    [sp] = Bottom 16-bits of destination address {7}
;>  [sp+2] = Following cluster
;>>     ds = 0
;>      es = 4000

	mov	cx, di			;Cluster size in sectors
	xchg	ch, cl			;Cluster size in words
	pop	di			;Restore destination address {7}
	es a32 rep movsw
	jmp short .10			;Loop until end of file
					;[0x7d0e]
;>     eax = 0
;>     ebx = 0000??00
;>      si = FF??
;>     ecx = 0

;---------------------------
; File read, jump to stage 2
;---------------------------

eof:
	mov	ecx, 4096
.loop	int	8
	loop	.loop
				; [0x7d18]
	cli

	mov	eax, [load_drive] ; Parameter for stage 2 (the boot drive)
	push    eax

	jmp     LOAD_SEG:0 ; Go to loader stage 2


               
read_sectors:
; Input:
;	EAX = LBN
;	DI  = sector count
;	ES = segment
; Output:
;	BL = low byte of ES
;	EBX high half cleared
;	DL = 0x80
;	EDX high half cleared
;	ESI = 0
; Clobbered:
;	BH, CX, DH

	push	eax
	push	di
	push	es

.10:	push	eax		;LBN

	push	ds



        cmp     byte [load_drive], 0x80
	jb	.fdd			; jump if less than.

; LBN -> CHS translation, harddrive specific...

.hdd:
	; Have not quite tested this hdd code, hopefully it works (grin)
	
	lds	si, [0x104]	       ;Hard drive 0 parameters
	cdq			       ;edx = 0
	movzx	ebx, byte [si+DP_sect]
	div	ebx		       ;EAX=track ;EDX=sector-1
	mov	bl, [si+DP_heads]
	jmp	.indep

; LBN -> CHS, the floppy way....

.fdd:
	cdq			     ;edx = 0
	mov	ebx, SECTORS_1_44
	div	ebx		     ;EAX=track ;EDX=sector-1
	mov	bl, byte HEADS_1_44


; Independent code of translation...

.indep:
	mov	cx, dx		;CL=sector-1 ;CH=0
	inc	cx		;CL=Sector number

	xor	dx, dx
	pop	ds
	div	ebx

	mov	dh, dl		;Head
	mov	dl, [load_drive]	;Select drive 
	xchg	ch, al		;CH=Low 8 bits of cylinder number; AL=0
	shr	ax, 2		;AL[6:7]=High two bits of cylinder; AH=0
	or	cl, al		;CX = Cylinder and sector
	mov	al, max_xfer	;AX = Maximum sectors to xfer
	cmp	ax, di		;Total is larger?
	jb	.20		;Yes: transfer maximum
	xchg	ax, di		;No:  AX=total ;DI=maximum
.20:	mov	ah, 2		;Read
	xor	bx, bx

	mov	byte [retry_count], 5   ; Retry IO 4 times
.retry:
	sub	byte [retry_count], 1
	jz	near disk_error
	int	13h
	jc near .retry


	mov	bx, es
	add	bh, max_xfer>>3	;Advance segment
	mov	es, bx

	pop	eax
	add	eax, byte max_xfer
	sub	di, byte max_xfer
	ja	.10

	pop	es
	pop	di
	pop	eax
	xor	esi, esi
	ret
	
; FAT name    12345678123
file_name db 'LOADER     '

; Retry count (for bios disk routines)
retry_count db 0

; GDT indices
flat_code    equ      0x8
flat_data    equ      0x10



; Global Descriptor Table
gdt:
	dw	0x18		; gdt limit=2048, 256 GDT entries
	dw	null_seg,0x0    ; gdt base

null_seg:							
	dw	0,0,0,0		; dummy

flat_code_seg:
	dw	0xFFFF		; 4Gb - limit
	dw	0x0000		; base address=0
	dw	0x9A00		; code read/exec
	dw	0x00CF		; granularity=4096, 386

flat_data_seg:
	dw	0xFFFF		; 4Gb - limit
	dw	0x0000		; base address=0
	dw	0x9200		; data read/write
	dw	0x00CF		; granularity=4096, 386


	resb 0x1FD+$$-$

; Drive number (0 = fd-0, 0x80 = hd-1...)
load_drive	db	0x0	

		db	0x55, 0xAA		;Standard end of boot sector


















