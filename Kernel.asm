a:
[ org 0x20000 ]
[ BITS 16 ]
GDTLoc equ 0x4000
Vars equ 0x2000

KernelInit16:
	cli

	mov ax, 0xB800
	mov gs, ax

	xor di, di
	mov cx, 80*25*2/4

	.clearScreen:
		mov dword [gs:di], 0
		add di, 4
		loop .clearScreen

	xor di, di
	mov si, SelectVideoModeMsg-a&0xFFFF
	mov ax, 0x2000
	mov es, ax

	xor dx, dx
	call CheckForBGA
	jc .noBGA

	or dl, 00000100b							; BGA ID verified

	call CheckBGACard
	jc .noBGA

	or dl, 00001000b							; BGA graphics card found
	jmp SelectVideoMode

	.noBGA:

SelectVideoMode:
	.setRecomended:								; Setting video driver recommendation
		mov ah, 0x0F
		mov [Vars+0], dl
		test dl, 00001000b
		jz .notBochs

		mov dword [es:si+49], ('H'<<24)+('C'<<16)+('O'<<8)+'B'
		mov byte [es:si+53], 'S'
		jmp .recomendedSet

	.notBochs:
		test dl, 00000001b
		jz .notVBE

		mov dword [es:si+49], ('2'<<24)+('E'<<16)+('B'<<8)+'V'
		mov byte [es:si+53], '+'
		jmp .recomendedSet

	.notVBE:
	.recomendedSet:

	call PrintLine16							; Video mode select message
	inc si
	call PrintLine16							; VGA hardware driver option
	mov bx, Selection+4
	inc si
	mov cx, '1'
	test dl, 00000001b
	jz .bochs

	.VBE2:
		inc cx
		call PrintLine16						; VBE 2+ driver option
		mov dword [es:bx], "VBE2"
		add bx, 4

	.bochs:
		test dl, 00000100b
		jz .printEnd
		inc cx
		mov dword [es:bx], "BOCH"
		add bx, 4

		.bochs.fixSI:							; Looping until next NULL character
			cmp byte [es:si], 0
			jz .bochs.checkActive

			inc si
			jmp .bochs.fixSI

		.bochs.checkActive:
			test dl, 00001000b
			jnz .bochs.print
			mov ah, 0x08

		.bochs.print:
			inc si
			mov [es:si+2], cl

			call PrintLine16					; BGA driver option
			mov ah, 0x0F
			inc si

		.printEnd:
			push dx
		.waitForInput:
			mov ah, 1
			int 0x16							; Waiting for input
			jz .waitForInput

			mov ah, 0
			int 0x16

			cmp ah, 0x1C 						; Check selection if Enter button pressed
			je .testSecection

			cmp al, 0x30						; Check if number (lower bound)
			jl .waitForInput

			cmp al, cl 							; Check if number (upper bound)
			jg .waitForInput

			mov ah, 0x0F
			mov [gs:((80*23)+(80/2))*2], ax 	; Writing number
			jmp .waitForInput

			.testBochs:
				xchg bx, dx
				pop dx
				test dl, 00001000b
				xchg bx, dx
				jnz .done

				mov byte [gs:((80*23)+(80/2))*2+1], 0x40
				jmp .printEnd

			.testSecection:
				mov ah, [gs:((80*23)+(80/2))*2]
				cmp ah, 0
				jz .waitForInput

				xor bx, bx
				mov bl, ah
				sub bl, 0x31
				shl bx, 2
				add bx, Selection
				mov edx, [es:bx]

				cmp edx, "BOCH"
				je .testBochs

				cmp edx, "VGAH"
				jne .done

				mov dword [GraphicsFramebufferAddress], 0xA0000

			.done:

			mov dword [Vars+1], edx
%include "KernelIncludes/GDT.asm"

Selection: db 'VGAH'
		   dd 0
		   dd 0
SelectVideoModeMsg: 	 db 'Select a video driver. Recomended video mode is: VGAH_', 0
                         db '  1. VGA Hardware Driver (VGAH_)', 0
VideoModeSelectionVBE:	 db '  2. Video BIOS Extentions 2.0+ (VBE2+)', 0
VideoModeSelectionBochs: db '  #. Bochs Graphics Adaptor (BOCHS)', 0

GraphicsCardAddress equ Vars+5
GraphicsFramebufferAddress equ Vars+9

CheckForBGA:
	push dx
	mov dx, 0x01CE
	xor ax, ax
	out dx, ax

	inc dx
	in ax, dx

	cmp ax, 0xB0C1
	jl .error
	cmp ax, 0xB0C5								; Checking BGA ID
	jg .error

	pop dx
	clc
	ret

	.error:
		pop dx
		stc
		ret

CheckBGACard:
	push dx
	mov cx, 0xFFFF
	mov eax, 1<<31
	mov dx, 0xCF8

	.loop:
		out dx, eax

		add dx, 4
		push eax
		in eax, dx
		sub dx, 4

		cmp eax, 0xFFFFFFFF						; Check if device function exists
		je .loopcont

		cmp eax, 0x11111234						; Check if vendor and device ids match BGA graphics card
		je .done

	.loopcont:
		pop eax
		shr eax, 8
		inc eax
		shl eax, 8
		loop .loop

	.error:
		pop dx
		stc
		ret

	.done:
		pop eax

		mov [GraphicsCardAddress], eax			; Save BGA device and function number
		or eax, 4

		out dx, eax

		add dx, 4

		in eax, dx
		and al, 0xF0
		mov [GraphicsFramebufferAddress], eax	; Save BGA graphics card BAR0

		pop dx
		clc
		ret

PrintLine16:
	push cx
	xor cx, cx

	.loop:										; Writing string
		mov al, [es:si]
		mov [gs:di], ax
		inc si
		inc di
		inc di
		inc cl
		cmp byte [es:si], 0
		jnz .loop

	sub cl, 80
	not cl 										; cl = 80 - cl

	inc cl

	.loop2:										; Finishing up a line
		mov word [gs:di], 0
		inc di
		inc di
		loop .loop2

	pop cx
	ret

[ BITS 32 ]

KernelInit32:
	mov ax, 0x8
	mov ss, ax
	mov esp, 0x1000

GraphicsModeSetUp:
	mov ax, 0x10
	mov es, ax
	cmp dword [es:0x1], 'VGAH'
	jnz .notVGAHDriver
	pushf
	call 0x28:InitVGAH-0x20000
	jmp .done

	.notVGAHDriver:
	cmp dword [es:0x1], 'BOCH'
	jnz .done
	pushf
	call 0x28:InitBGA-0x20000
	;jmp .done

	.done:

ClearScreen:
	mov ecx, 720*400
	mov ax, 0x38
	mov gs, ax
	xor edi, edi

	.loop:
		mov dword [gs:edi], 0x00FFFFFF
		add edi, 4
		loop .loop

KERNEL:
		jmp $

%include "Drivers/VGA.asm"
