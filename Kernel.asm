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

	xor dx, dx
	call CheckForVBE2
	jc .pastVBETest

	call SetUpVBE2
	jc .pastVBETest

	or dl, 00000001b

	.pastVBETest:

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

	xor di, di
	mov si, SelectVideoModeMsg-a&0xFFFF
	mov ax, 0x2000
	mov es, ax
	mov ah, 0x0F

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

			.error:
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

				cmp edx, "VBE2"
				je .VBE2Selected

				cmp edx, "VGAH"
				jne .done

				mov dword [GraphicsFramebufferAddress], 0xA0000

				jmp .done

			.VBE2Selected:
				xor ax, ax
				mov es, ax
				mov eax, [es:0x6500+0x28]
				mov [GraphicsFramebufferAddress], eax

				mov bx, [VESAMode]
				or bh, 01000000b
				mov ax, 0x4F02

				int 0x10

				cmp ax, 0x004F
				jne .error

				mov dword [ScreenWidth], 800
				mov dword [ScreenHeight], 600

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

GraphicsCardAddress equ Vars+0x5
GraphicsFramebufferAddress equ Vars+0x9
ScreenWidth equ Vars+0xD
ScreenHeight equ Vars+0x10
VESAMode equ Vars+0x15					; VESA mode for 800x600x32bpp

CheckForVBE2:
	xor ax, ax
	mov es, ax
	mov di, 0x6000
	mov dword [es:di], 'VBE2'
	mov ax, 0x4F00

	int 0x10

	cmp ax, 0x004F
	jne .end
	cmp dword [es:di], 'VESA'
	je .exists

	.end:
		stc
		ret

	.exists: 
		clc
		ret

SetUpVBE2:
	mov di, 0x6000+14
	mov esi, [es:di]
	ror esi, 16
	mov fs, si
	ror esi, 16
	mov di, 0x6500

	.loop:
		mov ax, 0x4F01
		mov cx, [fs:si]
		cmp cx, 0xFFFF
		je .error

		int 0x10

		inc si
		inc si

		cmp ax, 0x004F
		jne .error

		cmp word [es:di+0x12], 800
		jne .loop
		cmp word [es:di+0x14], 600
		jne .loop
		test word [es:di], 1<<7
		jz .loop

	.end:
		mov [es:VESAMode], cx
		clc
		ret

	.error:
		stc
		ret

CheckForBGA:
	push dx
	mov dx, 0x01CE
	xor ax, ax
	out dx, ax

	inc dx
	in ax, dx
	pop dx

	cmp ax, 0xB0C1
	jl .error
	cmp ax, 0xB0C5								; Checking BGA ID
	jg .error

	clc
	ret

	.error:
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
		or eax, 10h

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
	mov ax, 0x28
	mov ds, ax
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
	mov ecx, 800*600
	mov ax, 0x38
	mov gs, ax
	xor edi, edi

	.loop:
		mov dword [gs:edi], 0
		add edi, 4
		loop .loop

KERNEL:
		mov eax, 0xFFFFFFFF
		xor edx, edx
		xor ecx, ecx
		mov dl, [ecx+StartupText-0x20000]
		mov edi, edx
		xor edx, edx
		xor ebx, ebx

		.Greet:
			inc ecx
			mov bl, [ecx+StartupText-0x20000]
			call PrintChar
			inc edx
			cmp ecx, edi
			jle .Greet

		jmp $

PrintChar:	;eax - Color dword, ebx - Character #, edx - Character location
	push esi
	push eax
	push ecx
	push edi
	push ebx
	push edx
	push eax

	mov eax, [ds:Font.FontLength-0x20000]
	cmp eax, ebx
	jc .end

	mov eax, 5*4*2
	mul edx
	
	push eax

	mov eax, 25
	mul ebx

	pop edi
	mov ecx, 25*2
	xor edx, edx

	pop ebx

	.print:
		test byte [ds:eax+Font.Space-0x20000], 1
		jz .print.1

		mov [gs:edi], ebx

		.print.1:

		test byte [ds:eax+Font.Space-0x20000], 2
		jz .print.2

		mov [gs:edi+4], ebx

		.print.2:

		inc eax
		inc edx
		add edi, 8
		cmp dl, 5
		je .nextLine
		loop .print

	.end:
		pop edx
		pop ebx
		pop edi
		pop ecx
		pop eax
		pop esi
		ret

	.nextLine:
		mov dl, 0

		push es
		push eax

		mov ax, 0x10
		mov es, ax

		xor eax, eax
		mov ax, [es:ScreenWidth-Vars]
		shl ax, 2

		add edi, eax

		pop eax
		pop es

		sub edi, (5*2)*4

		cmp dh, 1 ; Checking if it's writing the second part of the 2x2 pixel cluster
		jne .repeat
		mov dh, 0

		loop .print
		jmp .end

	.repeat:
		dec ecx
		mov dh, 1
		sub ax, 5
		jmp .print

%include "Drivers/VGA.asm"

Font:
	.FontLength: dd (.end-($+4))/25
	.Space: db 0,0,0,0,0
			db 0,0,0,0,0
			db 0,0,0,0,0
			db 0,0,0,0,0
			db 0,0,0,0,0

	.0: db 0,3,3,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0
	
	.1: db 0,3,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,3,3,3,0

	.2: db 0,3,3,0,0
		db 0,0,0,3,0
		db 0,0,3,3,0
		db 0,3,3,0,0
		db 0,3,3,3,0

	.3: db 0,3,3,0,0
		db 0,0,0,3,0
		db 0,3,3,0,0
		db 0,0,0,3,0
		db 0,3,3,0,0

	.4: db 0,0,3,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,0,0,3,0

	.5: db 0,3,3,3,0
		db 0,3,0,0,0
		db 0,3,3,0,0
		db 0,0,0,3,0
		db 0,3,3,0,0

	.6: db 0,0,3,3,0
		db 0,3,0,0,0
		db 0,3,3,3,0
		db 0,3,0,3,0
		db 0,0,3,0,0

	.7: db 0,3,3,3,0
		db 0,0,0,3,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0

	.8: db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,0,3,0
		db 0,0,3,0,0

	.9: db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,0,3,3,0
		db 0,0,0,3,0
		db 0,3,3,0,0

	.A: db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,0,3,0

	.B:	db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,0,3,0
		db 0,3,3,0,0

	.C:	db 0,0,3,3,0
		db 0,3,0,0,0
		db 0,3,0,0,0
		db 0,3,0,0,0
		db 0,0,3,3,0

	.D:	db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,0,0

	.E: db 0,3,3,3,0
		db 0,3,0,0,0
		db 0,3,3,3,0
		db 0,3,0,0,0
		db 0,3,3,3,0

	.F: db 0,3,3,3,0
		db 0,3,0,0,0
		db 0,3,3,3,0
		db 0,3,0,0,0
		db 0,3,0,0,0

	.G: db 0,3,3,3,0
		db 0,3,0,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0

	.H: db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0

	.I: db 0,3,3,3,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,3,3,3,0

	.J: db 0,0,0,3,0
		db 0,0,0,3,0
		db 0,0,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0

	.K: db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0

	.L: db 0,3,0,0,0
		db 0,3,0,0,0
		db 0,3,0,0,0
		db 0,3,0,0,0
		db 0,3,3,3,0

	.M: db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0

	.N: db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,3,3,0
		db 0,3,3,3,0
		db 0,3,0,3,0

	.O: db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,0,3,0,0

	.P: db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,3,0,0
		db 0,3,0,0,0
		db 0,3,0,0,0

	.Q: db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,0,3,3,0

	.R: db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0

	.S: db 0,3,3,3,0
		db 0,3,0,0,0
		db 0,3,3,3,0
		db 0,0,0,3,0
		db 0,3,3,3,0

	.T: db 0,3,3,3,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0

	.U: db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0

	.V: db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,0,3,0,0

	.W: db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,3,3,0

	.X: db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0

	.Y: db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0

	.Z: db 0,3,3,3,0
		db 0,0,0,3,0
		db 0,0,3,0,0
		db 0,3,0,0,0
		db 0,3,3,3,0
	
	.a: db 0,3,3,0,0
		db 0,0,0,3,0
		db 0,0,3,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0

	.b:	db 0,3,0,0,0
		db 0,3,0,0,0
		db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,3,0,0

	.c:	db 0,0,0,0,0
		db 0,0,0,0,0
		db 0,0,3,0,0
		db 0,3,0,0,0
		db 0,0,3,0,0

	.d:	db 0,0,0,3,0
		db 0,0,0,3,0
		db 0,0,3,3,0
		db 0,3,0,3,0
		db 0,0,3,3,0

	.e: db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,3,3,0,0
		db 0,3,0,0,0
		db 0,0,3,3,0

	.f: db 0,0,3,3,0
		db 0,0,3,0,0
		db 0,3,3,3,0
		db 0,0,3,0,0
		db 0,0,3,0,0

	.g: db 0,3,3,3,0
		db 0,3,0,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0

	.h: db 0,3,0,0,0
		db 0,3,0,0,0
		db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0

	.i: db 0,0,3,0,0
		db 0,0,0,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0

	.j: db 0,0,0,3,0
		db 0,0,0,0,0
		db 0,0,0,3,0
		db 0,3,0,3,0
		db 0,3,3,3,0

	.k: db 0,3,0,0,0
		db 0,3,0,3,0
		db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0

	.l: db 0,3,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,3,3,0

	.m: db 0,0,0,0,0
		db 0,0,0,0,0
		db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,0,3,0

	.n: db 0,0,0,0,0
		db 0,0,0,0,0
		db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0

	.o: db 0,0,0,0,0
		db 0,0,0,0,0
		db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,0,3,0,0

	.p: db 0,0,0,0,0
		db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,3,0,0
		db 0,3,0,0,0

	.q: db 0,0,0,0,0
		db 0,0,0,0,0
		db 0,0,3,0,0
		db 0,3,0,3,0
		db 0,0,3,3,0

	.r: db 0,0,0,0,0
		db 0,3,3,0,0
		db 0,3,0,3,0
		db 0,3,3,0,0
		db 0,3,0,3,0

	.s: db 0,0,3,3,0
		db 0,3,0,0,0
		db 0,0,3,0,0
		db 0,0,0,3,0
		db 0,3,3,0,0

	.t: db 0,0,3,0,0
		db 0,3,3,3,0
		db 0,0,3,0,0
		db 0,0,3,0,0
		db 0,0,0,3,0

	.u: db 0,0,0,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,0,3,3,0

	.v: db 0,0,0,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,0,3,0,0

	.w: db 0,0,0,0,0
		db 0,0,0,0,0
		db 0,3,0,3,0
		db 0,3,3,3,0
		db 0,3,3,3,0

	.x: db 0,0,0,0,0
		db 0,0,0,0,0
		db 0,3,0,3,0
		db 0,0,3,0,0
		db 0,3,0,3,0

	.y: db 0,0,0,0,0
		db 0,3,0,3,0
		db 0,3,0,3,0
		db 0,0,3,0,0
		db 0,3,0,0,0

	.z: db 0,0,0,0,0
		db 0,3,3,3,0
		db 0,0,0,3,0
		db 0,0,3,0,0
		db 0,3,3,3,0
	.end:

				   					  ;F   L   A   M   E   O   S   _   S   T   A   R   T   U   P
StartupText:  db (.end-StartupText-1), 16, 48, 37, 49, 41, 25, 29, 00, 29, 56, 37, 54, 56, 57, 52
	.end: