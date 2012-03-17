;
; Functions for ioports
; (c) Jimmy Larsson 1998

GLOBAL out_b, in_b

align 16
out_b:
	mov	edx, [4+esp]
	mov	al,  [8+esp]
	out	dx, al
	ret

align 16
in_b:
	mov	edx, [4+esp]
	sub	eax, eax
	in	al, dx
	ret