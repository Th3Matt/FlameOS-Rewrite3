[ BITS 32 ]

InitVGAH:	; NAME='Init_VGA_'
	mov dx, 0x3DA
	in al, dx

	.3C4:
		mov dx, 0x3C4
		mov al, 1
		out dx, al

		inc dx

		in al, dx
		or al, 00100000b	; Disabling screen.
		out dx, al

		dec dx

		mov al, 0
		out dx, al

		inc dx

		in al, dx
		or al, 00000001b	; Activating "Sychnronous Reset".
		out dx, al

		dec dx

		mov al, 3
		out dx, al

		inc dx

		in al, dx
		and al, 11000000b	; Carefully clearing "Character Map Select Register".
		out dx, al

		dec dx

		mov al, 4
		out dx, al

		inc dx

		in al, dx
		or al, 00000010b 	; Enabling buffer sizes of 64KB and 256KB.
		and al, 11110011b 	; Disabling "Chain4" and "Even/Odd Memory Addressing".
		out dx, al

	.3C2:
		mov dx, 0x3CC
		in al, dx

		mov dx, 0x3C2
		or al, 11100011b	; Setting HSync and VSync polarities to negative, high page, enabling RAM buffer.
		out dx, al

	.3C0:
		mov dx, 0x3C0
		mov al, 0x30
		out dx, al

		inc dx

		in al, dx

		dec dx

		and al, 00010000b 	;
		or al, 00000001b
		push ax
		mov al, 0x30
		out dx, al
		pop ax
		out dx, al

		mov al, 0x31
		out dx, al

		mov al, 0
		out dx, al

		mov al, 0x32
		out dx, al

		inc dx

		in al, dx

		dec dx

		or al, 00001111b
		push ax
		mov al, 0x32
		out dx, al
		pop ax
		out dx, al

		mov al, 0x33
		out dx, al

		inc dx

		in al, dx

		dec dx

		and al, 11110000b
		push ax
		mov al, 0x33
		out dx, al
		pop ax
		out dx, al

		mov al, 0x34
		out dx, al

		inc dx

		in al, dx

		dec dx

		and al, 11110000b
		push ax
		mov al, 0x34
		out dx, al
		pop ax
		out dx, al

	.3CE:
		mov dx, 0x3CE
		mov al, 5
		out dx, al

		inc dx

		in al, dx
		and al, 10000100b
		push ax
		mov al, 5
		out dx, al
		pop ax
		out dx, al

		dec dx

		mov al, 6
		out dx, al

		inc dx

		in al, dx
		and al, 11110000b
		or al, 00000101b
		push ax
		mov al, 6
		out dx, al
		pop ax
		out dx, al

	.3D4:
		mov dx, 0x3D4
		mov al, 0x11
		out dx, al

		inc dx

		in al, dx
		and al, 01111111b
		out dx, al

		dec dx

		mov al, 0
		out dx, al

		inc dx

		mov al, 0x5F
		out dx, al

		dec dx

		mov al, 1
		out dx, al

		inc dx

		mov al, 0x4F
		out dx, al

		dec dx

		mov al, 2
		out dx, al

		inc dx

		mov al, 0x50
		out dx, al

		dec dx

		mov al, 3
		out dx, al

		inc dx

		mov al, 0x82
		out dx, al

		dec dx

		mov al, 4
		out dx, al

		inc dx

		mov al, 0x54
		out dx, al

		dec dx

		mov al, 5
		out dx, al

		inc dx

		mov al, 0x80
		out dx, al

		dec dx

		mov al, 6
		out dx, al

		inc dx

		mov al, 0x0B
		out dx, al

		dec dx

		mov al, 7
		out dx, al

		inc dx

		mov al, 0x3E
		out dx, al

		dec dx

		mov al, 8
		out dx, al

		inc dx

		mov al, 0x00
		out dx, al

		dec dx

		mov al, 9
		out dx, al

		inc dx

		mov al, 0x40
		out dx, al

		dec dx

		mov al, 0x10
		out dx, al

		inc dx

		mov al, 0xEA
		out dx, al

		dec dx

		mov al, 0x11
		out dx, al

		inc dx

		mov al, 0x0C
		out dx, al

		dec dx

		mov al, 0x12
		out dx, al

		inc dx

		mov al, 0xDF
		out dx, al

		dec dx

		mov al, 0x13
		out dx, al

		inc dx

		mov al, 0x28
		out dx, al

		dec dx

		mov al, 0x14
		out dx, al

		inc dx

		mov al, 0x0
		out dx, al

		dec dx

		mov al, 0x15
		out dx, al

		inc dx

		mov al, 0xE7
		out dx, al

		dec dx

		mov al, 0x16
		out dx, al

		inc dx

		mov al, 0x04
		out dx, al

		dec dx

		mov al, 0x17
		out dx, al

		inc dx

		mov al, 0xE3
		out dx, al

	.ScreenEnable:
		mov dx, 0x3C4
		mov al, 1
		out dx, al

		inc dx

		in al, dx
		and al, 11011111b
		out dx, al

	iret

InitBGA:
	mov ax, 0x4
	mov dx, 0x01CE
	out dx, ax ;0x1CE

	xor ax, ax		; Screen disable
	inc dx
	out dx, ax ;0x1CF

	mov ax, 0x1
	dec dx
	out dx, ax ;0x1CE

	push es
	mov ax, Segments.Variables
	mov es, ax

	mov eax, SCREEN_WIDTH		; X
	mov [es:ScreenWidth], ax
	inc dx
	out dx, ax ;0x1CF

	mov ax, 0x2
	dec dx
	out dx, ax ;0x1CE

	mov eax, SCREEN_HEIGHT		;	Y
	mov [es:ScreenHeight], ax
	inc dx
	out dx, ax ;0x1CF

	pop es

	mov ax, 0x3
	dec dx
	out dx, ax ;0x1CE

	mov ax, 32		; BPP
	inc dx
	out dx, ax ;0x1CF

	mov ax, 0x4
	dec dx
	out dx, ax ;0x1CE

	mov ax, 0x41	; Linear famebuffer and screen enable
	inc dx
	out dx, ax ;0x1CF

	iret
