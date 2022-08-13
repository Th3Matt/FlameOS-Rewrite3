a:
[ org 0x20000 ]
[ BITS 16 ]
GDTLoc equ 0x4000
Vars equ 0x2000


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
	mov ax, 0x2000
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
	mov ax, 0x2000
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
	mov ax, 2000h
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

				mov dword [Vars+ScreenWidth], 800
				mov dword [Vars+ScreenHeight], 600

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

GraphicsCardAddress equ 0x5
GraphicsFramebufferAddress equ 0x9
ScreenWidth equ 0xD
ScreenHeight equ 0x11
VESAMode equ 0x16							; VESA mode for 800x600x32bpp
VideoHardwareInterfaces equ 0x18
CustomSetting equ 0x80 						; First two bits control the detection of disks on ATA buses 0 and 1
DiskDriverVariableSpace equ 0x100;+Vars
PCIDriverVariableSpace equ 0x150;+Vars


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
	.loading:
		mov eax, 0xFFFFFFFF
		xor edx, edx
		mov dl, [StartupText-0x20000]
		mov esi, StartupText-0x20000+1
		mov edi, edx
		xor edx, edx

		call Print.string

		pusha

        mov al, (2<<6) + (11b<<4) + (2<<1) + 0
        out 0x43, al
        mov al, 2Eh
        out 0x40, al
        mov al, 9Ch
        out 0x40, al

		.setPIC:
        	mov al, 0x11
        	out 0x20, al
        
        	mov al, 0x11
        	out 0xA0, al
        	
        	mov al, 0x20
        	out 0x21, al
        	
        	mov al, 0x28
        	out 0xA1, al
        	
        	mov al, 0x04
        	out 0x21, al
        	
        	mov al, 0x02
        	out 0xA1, al
        	
        	mov al, 0x01
        	out 0x21, al
        	
        	mov al, 0x01
        	out 0xA1, al
        
        	mov al, 0x00
        	out 0x21, al
        
        	mov al, 0x00
        	out 0xA1, al
        
   		 	mov al, 11111110b
    		out 0x21, al
    		
    		mov al, 11111111b
    		out 0xA1, al

    	call SetUpInterrupts

    	popa

    	call Print.newLine

    	push edx

    	xor edx, edx
		mov dl, [IDTloaded-0x20000]
		mov esi, IDTloaded-0x20000+1
		mov edi, edx
		pop edx

		call Print.string

		call ProcessManager.init

        call MemoryManager.init

        ;xor eax, eax
        ;mov ecx, 4
		;call MemoryManager.memAlloc
		;push eax

        ;xor eax, eax
		;call MemoryManager.memAlloc

		;pop ebx
		;xor eax, eax
		;call MemoryManager.memFree

		;xor eax, eax
		;mov ecx, 2
		;call MemoryManager.memAlloc

		;xor eax, eax
		;mov ecx, 5
		;call MemoryManager.memAlloc

		;xor eax, eax
		;mov ecx, 2
		;call MemoryManager.memAlloc

        ;call MemoryManager.memAllocPrint

        ;call MemoryManager.memFreeAll

        ;call MemoryManager.memAllocPrint

        mov eax, Prog1-0x20000
        mov ebx, (0x08<<16) + 0x28
        mov ecx, 0x08
        call ProcessManager.startProcess

        mov eax, 0xA00
        mov ebx, 0x500
        call ProcessManager.setUpTask

        mov ax, 0x58
        ltr ax

        ;call MemoryManager.memAllocPrint

        call PCIDriver.detectDevices

        test byte es:[CustomSetting], 100b
        jnz PCITest

		call S_ATA_PI.detectDevices
		call EDDV3Read

		call Print.newLine
        call FlFS.init

        mov esi, Strings.Terminal-0x20000
        call FlFS.getFileNumber

        mov di, 0x08
        mov ds, di
        xor edi, edi
        call FlFS.readFile

		;sti
        cli

		jmp $

Strings:
	.Terminal:
		db 'Terminal.ub', 0

%include "KernelIncludes/EDD.asm"

PCITest:
	call PCIDriver.printDeviceTable

	jmp $

Prog1:
    mov eax, 0x00ffffff
    mov ebx, (200<<16) + 200
    mov ecx, (500<<16) + 600
    call Draw.rectangle

    jmp $

IDT:
    .modEntry:	; eax - Interrupt hander address, bh - Configuration, ecx - # of entry, edx - Segment Selector, ds - IDT segment.
        push es
        push edi

		shl ecx, 3
        mov edi, ecx
	
        mov [ds:edi], ax ; Offset 0:16
        
        shr eax, 16
        push ax
        
        add edi, 2
        
        mov ax, dx
        mov [ds:edi], ax ; Segment Selector 0:16
        
        add edi, 2
        
        mov al, 0
        mov ah, bh

        mov [ds:edi], ax ; Configuration
        
        add edi, 2
        
        pop ax
        mov [ds:edi], ax ; Offset 16:32
        
        add edi, 2

        pop edi
        pop es
        ret

%include "KernelIncludes/Drawing.asm"

Conv:
    .hexToChar8: ; dl - Hex number. Output: ax - chars
        push esi
        push ds
        push ebx
        push dx

        mov bx, 0x28
        mov ds, bx
        shr dl, 4

        xor ebx, ebx
        mov bl, dl
        mov esi, .HexConvTable-0x20000
        add esi, ebx
        mov dl, [esi]
        mov al, dl
        sub esi, ebx

        pop dx

        and dl, 0x0F
        xor ebx, ebx
        mov bl, dl
        add esi, ebx
        mov dl, [esi]
        mov ah, dl
        sub esi, ebx

        pop ebx
        pop ds
        pop esi

        ret

    .hexToChar16: ; dx - Hex number. Output: ebx - chars
        push eax
        ror dx, 8

        call .hexToChar8

        ror dx, 8
        shl eax, 16

        call .hexToChar8

        rol eax, 16

        mov ebx, eax
        pop eax
        ret

    .HexConvTable: db "0123456789ABCDEF"

%include "KernelIncludes/InterruptHandlers.asm"

%include "KernelIncludes/ProcessManager.asm"

%include "Drivers/VGA.asm"

StartupText:  db (.end-$-1), "Kernel: FlameOS Starting up...", 10, "Kernel: Video driver initialised."
	.end:

IDTloaded:	  db (.end-$-1), "Kernel: IDT initialised."
	.end:

%include "KernelIncludes/Glyphs.asm"

%include "Drivers/ATA.asm"

%include "Drivers/PCI.asm"

%include "Drivers/VFS.asm"

%include "Drivers/FLFS.asm"

times 0x200*32-($-$$) db 0
