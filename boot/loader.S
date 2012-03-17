;
; Boot loader for Bonk, stage two of boot process
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


; GDT indices
FLAT_CODE	equ     0x8
FLAT_DATA	equ     0x10


	
	
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
org     0x8000

start:	cli				;{0}

	;; GDT and segments and A20 assumed correct at this point
	
	mov	ax, 0x90		;Segment for boot blocks
	mov	es, ax			;{1A}

	xor	eax, eax		;Segment and LBN
	mov	ds, ax			;{1B}
					
	mov	ss, ax			;Temp. stack
	mov	sp, start


	;; Save the drive number from where we are booting
	mov	eax, [0x7c00 + 512 - 3]
	mov     [load_drive], al

	xor	eax, eax		; LBN
	

;; Read bootblock of this partition (we are floppy or part. bootblock)

	xor	edi, edi	
	inc	di			;Count of sectors
	call	read_sectors		;Read the boot block (ourselves) into 0x900

					; [0x8021]
;>  eax = 0
;>  edi = 1
;>  ds  = 0
;>  es  = 80

;---------------------------
; Read DIRECTORY into 0x9000
;---------------------------


	mov	bp, 0x900			;Point at partition boot block
	mov	bx, [bp+BB_res]			;Sectors before first FAT
	add	eax, ebx			;LBN of FAT
	push	eax				;Need to read the FAT later
	movzx	bx, [bp+BB_fats]		;Number of FATs
	imul	bx, [bp+BB_fat]			;Times size of FAT
	add	eax, ebx			;LBN of Root directory
	mov	di, [bp+BB_root]		;Root directory entries
	push	di				; used again later
	dec	di				;Convert to number of sectors
	shr	di, 4				;  16 directory entries per sector
	inc	di
	mov	es, bp				;Read directory at 0x9000
						; [0x8042]
	call	read_sectors
	add	eax, edi			;LBN of cluster 2
					

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

	lea	si, [NotFoundMsg]
	call	print
	jmp	short $


;>    [sp] = LBN of FAT
;>     eax = LBN of cluster 2
;>  es:edi = Pointer to end of name within directory entry
;>      bp = 800
;>      ds = 0
;>      es = 800

;------------------------------------------
; Ok, found. Read FAT into memory at 0x9000
;------------------------------------------

found:
	mov	bx, [es:edi+0xF]	;Starting cluster of file [0x806a]
	mov	di, [bp+BB_fat]		;Size of FAT (in sectors)
	xchg	eax, ebp		;ebp = LBN of cluster 2
	pop	eax			;LBN of FAT
	push	bx			;Starting cluster of file
					; [0x8077]
	call	read_sectors

	mov	bh, 0x40
	mov	es, bx			;es = 0x4000
	mov	edi, 0x100000-0x40000	;{1D}{4B} One megabyte minus ES base
.10:					;[0x8084]

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
	mov	al, [0x900+BB_clu]	;Size of each cluster
	mov	di, ax			;  (in sectors)
	mul	esi			;Times current cluster number
	add	eax, ebp		;Plus LBN of cluster 2	
					;[0x80a3]
	call	read_sectors		;Read that cluster
					
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
					; [0x80af]

;; ####################### HERE #####################


	jmp short .10			;Loop until end of file

;>     eax = 0
;>     ebx = 0000??00
;>      si = FF??
;>     ecx = 0

;------------------------
; File read, setup paging
;------------------------

eof:
	;; Shut of floppy motor in a fancy way

	mov	ecx, 4096
.loop	int	8
	loop	.loop

	cli				;{6}
					

	mov	eax, CR0		;Turn on paging and protected mode
	or	eax, 0x00000001
	mov	CR0, eax

	mov	cl, FLAT_DATA		;Setup ds and es
	push	cx			;{5}
	pop	ds
	mov	es, cx
					

	jmp     dword 0x0008:0x100000	;Jump to kernel


               
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



;        cmp     byte [load_drive], 0x80
;	jb	.fdd			; jump if less than.

; LBN -> CHS translation, harddrive specific...

;.hdd:
	; Have not quite tested this hdd code, hopefully it works (grin)
	
;	lds	si, [0x104]	       ;Hard drive 0 parameters
;	cdq			       ;edx = 0
;	movzx	ebx, byte [si+DP_sect]
;	div	ebx		       ;EAX=track ;EDX=sector-1
;	mov	bl, [si+DP_heads]
;	jmp	.indep

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

	mov	byte [retry_count], 50   ; Retry IO 4 times
.retry2
	sub	byte [retry_count], 1
	jz	disk_error
	pusha
				; [0x9012e]
	int	0x13
	jc near .retry
	jmp	.ok

.retry:				; Reset disk controller and retry
	mov	ax, 0
	mov	dx, [load_drive]
	int	0x13
	
	popa
	jmp     .retry2
	
.ok:	popa
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

;; Disk error message

disk_error:		
	lea	si, [DiskErrorMsg]
	call	print
	jmp	short $
	
; Printing subrotine
; Needs pointer to null terimnated string in si

print:	pusha
.loop	lodsb			; Load char into AL
	cmp	al, 0		; End of string?
	je	.end		; Yes! return
	mov	cx, 0x01
	mov	ah, 0x0e	; 0Eh = Teletype Putchar command for INT10
	mov	bx, 0x07	; Normal attribute
	int	0x10		; Print character
	jmp	.loop
	popa	
.end:	ret


	
LoadingMsg:	db  10, 13, "Loading...", 0

DiskErrorMsg:	db  10, 13, "Disk Error!", 0

NotFoundMsg:	db  10, 13, "File not found!", 0

	
; FAT name    12345678123
file_name db 'SYSTEM     '

; Retry count (for bios disk routines)
retry_count db 0

; Were are we loading from?
load_drive	db	0x0	

