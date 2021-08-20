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

	xor bx, bx
	call CheckForBGA
	jc .noBGA

	or bl, 00000010b
	jmp SelectVideoMode

	.noBGA:
		mov dword [GraphicsFramebufferAddress], 0xA0000

SelectVideoMode:
	mov ah, 0x0F
	mov [Vars+0], bl
	test bl, 00000010b
	jz .notBochs

	mov dword [es:si+49], ('H'<<24)+('C'<<16)+('O'<<8)+'B'
	mov byte [es:si+53], 'S'
	jmp .recomendedSet

	.notBochs:
		test bl, 00000001b
		jz .notVBE

		mov dword [es:si+49], ('2'<<24)+('E'<<16)+('B'<<8)+'V'
		mov byte [es:si+53], '+'
		jmp .recomendedSet

	.notVBE:
	.recomendedSet:

	call PrintLine16
	inc si
	call PrintLine16
	inc si
	mov cx, '1'
	test bl, 00000001b
	jz .bochs

	.VBE2:
		inc cx
		call PrintLine16

	.bochs:
		test bl, 00000010b
		jz .printEnd
		inc cx

		.bochs.fixSI:
			cmp byte [es:si], 0
			jz .bochs.print

			inc si
			jmp .bochs.fixSI

		.bochs.print:
			inc si
			mov [es:si+2], cl
			call PrintLine16
			inc si

		.printEnd:
			mov ah, 1
			int 0x16
			jz .printEnd

			mov ah, 0
			int 0x16

			cmp ah, 0x1C
			je .testSecection

			cmp al, 0x30
			jl .printEnd

			cmp al, cl
			jg .printEnd

			mov ah, 0x0F
			mov [gs:((80*23)+(80/2))*2], ax
			jmp .printEnd

			.testSecection:
				mov ah, [gs:((80*23)+(80/2))*2]
				cmp ah, 0
				jz .printEnd

				cmp ah, 0x31
				jnz .notVGAHDriver
				mov dword [Vars+1], 'VGAH'
				jmp .done

				.notVGAHDriver:
					cmp ah, 0x32
					jnz .not2ndOption

					test byte [Vars+0], 00000010b
					jnz .2ndOption.2
					mov dword [Vars+1], 'VBE2'
					jmp .done

					.2ndOption.2:
						mov dword [Vars+1], 'BOCH'
						jmp .done

				.not2ndOption:
					mov dword [Vars+1], 'BOCH'

			.done:

%include "KernelIncludes/GDT.asm"

SelectVideoModeMsg: 	 db 'Select a video driver. Recomended video mode is: VGAH_', 0
                         db '  1. VGA Hardware Driver (VGAH_)', 0
VideoModeSelectionVBE:	 db '  2. Video BIOS Extentions 2.0+ (VBE2+)', 0
VideoModeSelectionBochs: db '  #. Bochs Graphics Adaptor (BOCHS)', 0

GraphicsCardAddress equ Vars+5
GraphicsFramebufferAddress equ Vars+9

CheckForBGA:
	mov dx, 0x01CE
	xor ax, ax
	out dx, ax

	inc dx
	in ax, dx

	cmp ax, 0xB0C1
	jl .error
	cmp ax, 0xB0C5
	jg .error

	mov cx, 0xFFFF
	mov eax, 1<<31
	mov dx, 0xCF8

	.loop:
		out dx, eax

		add dx, 4
		push eax
		in eax, dx
		sub dx, 4

		cmp eax, 0xFFFFFFFF
		je .loopcont

		cmp eax, 0x11111234
		je .done

	.loopcont:
		pop eax
		shr eax, 8
		inc eax
		shl eax, 8
		loop .loop

	.error:
		stc
		ret

	.done:
		pop eax

		mov [GraphicsCardAddress], eax
		or eax, 4

		out dx, eax

		add dx, 4

		in eax, dx
		and al, 0xF0
		mov [GraphicsFramebufferAddress], eax

		clc
		ret

PrintLine16:
	push cx
	xor cx, cx

	.loop:
		mov al, [es:si]
		mov [gs:di], ax
		inc si
		inc di
		inc di
		inc cl
		cmp byte [es:si], 0
		jnz .loop

	sub cl, 80
	not cl
	inc cl

	.loop2:
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
