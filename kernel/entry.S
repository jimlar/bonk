;
; entry.S
; ------------------------------
; System entry point for Bonk
; (c) Jimmy Larsson 1998
;

GLOBAL   system_entry, _gdt
EXTERN   kernel_stacktop, system_start, init_paging

	
system_entry:

	lgdt	[gdt_ptr]		;  Load with our descriptors

	;; Set segment registers

	mov	ax, flat_data
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax

	;; Set code segment with a jump
	jmp	0x8:next

next:		
	push	ds			; Set stack-segment to DS
	pop	ss		
	mov	esp, kernel_stacktop	; Setup stack pointer

	;; Setup paging
	push    long 0			; Detected memory (not used now)
	call	init_paging
	add	esp, 4

	;; Go C

	call    system_start		; Jump to 'start.c'
	
	;; Halt if system_start returns
	jmp	$

;------------------------------------------------------
; The GDT. Should not be dependant of bootblock anymore
;------------------------------------------------------

	
	;; GDT indices

flat_code  equ  0x08
flat_data  equ  0x10


	;; Global Descriptor Table
	
	ALIGN	2
	dw	0	

gdt_ptr:
	dw	8 * 256    	; gdt limit
	dd	null_seg	; gdt base

_gdt:	
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

tss_seg:
	dw	0,0,0,0		; Filled in later

        times 252 dw 0,0,0,0	;  Reserve space for more descriptors (total of 256)

