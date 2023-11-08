a:
[ org 0x8000 ]
[ BITS 16 ]

%include "KernelIncludes/Constants.asm"

KernelInit16:
	cli

	mov ax, 0xB800
	mov gs, ax

CustomSettings:
	xor di, di
	mov cx, 80*25*2/4
	.clearScreen:
		mov dword [gs:di], 0
		add di, 4
		loop .clearScreen

	xor di, di
	mov si, CustomSettingsMsg-a&0xFFFF
	mov ax, 0x800
	mov es, ax
	mov ah, 0x0F
	mov word [CustomSetting+Vars], 0

	call PrintLine16

	sti

	.waitForInput:
		mov ah, 1
		int 0x16							; Waiting for input
		jz .waitForInput

		mov ah, 0
		int 0x16

		cmp ah, 0x1C 						; Check selection if Enter button pressed
		je .test

		cmp al, 0x6E ; n
		je .waitForInput.1

		cmp al, 0x79 ; y
		je .waitForInput.1
		jmp .waitForInput

		.waitForInput.1:
		mov ah, 0x0F
		mov [gs:((80*23)+(80/2))*2], ax 	; Writing
		jmp .waitForInput

	.test:
		mov ax, [gs:((80*23)+(80/2))*2]
		cmp al, 0x79
		jnz SelectVideoMode
		xor bx, bx

	xor di, di
	mov cx, 80*25*2/4
	.clearScreen2:
		mov dword [gs:di], 0
		add di, 4
		loop .clearScreen2

	xor di, di
	mov si, CustomSettingsMsg2-a&0xFFFF
	mov ax, 0x800
	mov es, ax
	mov ah, 0x0F

	call PrintLine16

	.setSettings:
		mov ah, 1
		int 0x16							; Waiting for input
		jz .setSettings

		mov ah, 0
		push bx
		int 0x16
		pop bx

		cmp ah, 0x1C 						; Check selection if Enter button pressed
		je .exit

		cmp al, 0x08 						; Check selection if backspace button pressed
		je .backspace

		cmp al, 0x6E ; n
		je .setSettings.1

		cmp al, 0x79 ; y
		je .setSettings.1
		jmp .setSettings

		.setSettings.1:
		mov ah, 0x0F
		mov word [gs:bx+17*2], ax 	; Writing
		inc bx
		inc bx
		jmp .setSettings

	.backspace:
		cmp bx, 0
		jz .setSettings
		dec bx
		dec bx
		xor ax, ax
		mov word [gs:bx+17*2], ax
		jmp .setSettings

	.exit:
		xor cx, cx
		.exit.loop:
			mov ax, [gs:bx+17*2-2]

			cmp bx, 0
			jz .end

			dec bx
			dec bx

			shl cx, 1
			cmp al, 0x79
			jnz .exit.loop
			or cx, 1

			jmp .exit.loop
	.end:
		mov [CustomSetting+Vars], cx

SelectVideoMode:
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

	.noBGA:
	mov si, SelectVideoModeMsg
	mov ax, 800h
	mov es, ax

	.setRecomended:								; Setting video driver recommendation
		mov ds:[Vars+VideoHardwareInterfaces], dl
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
	mov ax, 0x800
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
			je .testSelection

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

			.testSelection:
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

				mov dword [Vars+GraphicsFramebufferAddress], 0xA0000

				jmp .done

			.VBE2Selected:
				xor ax, ax
				mov es, ax
				mov eax, [es:0x6500+0x28]
				mov [Vars+GraphicsFramebufferAddress], eax

				mov bx, [Vars+VESAMode]
				or bh, 01000000b
				mov ax, 0x4F02

				int 0x10

				cmp ax, 0x004F
				jne .error

				mov dword [Vars+ScreenWidth], SCREEN_WIDTH
				mov dword [Vars+ScreenHeight], SCREEN_HEIGHT

			.done:

			mov dword [Vars+1], edx
%include "KernelIncludes/GDT.asm"

Selection: db 'VGAH'
		   dd 0
		   dd 0
CustomSettingsMsg:		 db 'Do you want to set debug settings? Press [n] if no.', 0
CustomSettingsMsg2:		 db 'Custom settings: ', 0
SelectVideoModeMsg: 	 db 'Select a video driver. Recomended video mode is: VGAH_', 0
                         db '  1. VGA Hardware Driver (VGAH_)', 0
VideoModeSelectionVBE:	 db '  2. Video BIOS Extentions 2.0+ (VBE2+)', 0
VideoModeSelectionBochs: db '  #. Bochs Graphics Adaptor (BOCHS)', 0

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

		cmp word [es:di+0x12], SCREEN_WIDTH
		jne .loop
		cmp word [es:di+0x14], SCREEN_HEIGHT
		jne .loop
		cmp byte [es:di+0x19], 32
		jne .loop
		test word [es:di], 1<<7
		jz .loop

	.end:
		mov [es:Vars+VESAMode], cx
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

		mov [Vars+GraphicsCardAddress], eax			; Save BGA device and function number
		or eax, 10h

		out dx, eax

		add dx, 4

		in eax, dx
		and al, 0xF0
		mov [Vars+GraphicsFramebufferAddress], eax	; Save BGA graphics card BAR0

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

times 0x200*ThirdBootloaderSize-($-$$) db 0
