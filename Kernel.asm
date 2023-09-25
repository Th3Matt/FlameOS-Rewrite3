
[ BITS 32 ]

global KernelInit32
section .text

%include "KernelIncludes/Constants.asm"

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
	call 0x28:InitVGAH
	jmp .done

	.notVGAHDriver:
	cmp dword [es:0x1], 'BOCH'
	jnz .done
	pushf
	call 0x28:InitBGA
	;jmp .done

	.done:

ClearScreen:
	mov ax, 0x0
	mov gs, ax

	call Print.clearScreen

KERNEL:
	.loading:
		mov es:[SOB.currentlySelectedEntry], byte 0

		mov eax, 0xFFFFFFFF
		xor edx, edx
		mov dl, [StartupText]
		mov esi, StartupText+1
		mov edi, edx
		xor edx, edx
		xor ecx, ecx

		call Print.string

		pusha

        mov al, (0<<6) + (11b<<4) + (2<<1) + 0
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
    	sti

    	popa

    	call Print.newLine

    	push edx

    	xor edx, edx
		mov dl, [IDTloaded]
		mov esi, IDTloaded+1
		mov edi, edx
		pop edx

		xor ecx, ecx

		call Print.string

		call ProcessManager.init
		xor eax, eax
		xor ecx, ecx
        call ProcessManager.pauseProcess

        call MemoryManager.init
        call DeviceList.init

        call PS2.init
        call PS2.initDevices

        call Syscall.init
        call PS_2_Keyboard.init

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

        mov ax, 0x58
        ltr ax

        ;call MemoryManager.memAllocPrint

        call PCIDriver.detectDevices

        test byte es:[CustomSetting], 100b
        jnz PCITest

		call S_ATA_PI.detectDevices
		call EDDV3Read

		call Print.newLine

        mov cx, 0x98
        lldt cx
        call FlFS.init

        call VFS.init

        mov ax, 0x88
        mov fs, ax
        mov esi, Strings.Terminal
        call FlFS.getFileNumber
        jc NoBootFile
        cmp al, fs:[4]
        jnz NoBootFile

        push edx

        call FlFS.getFileInfo
        push eax

        push ds
        mov ax, 0x70
        mov ds, ax
        xor eax, eax
        mov ecx, ebx

        call MemoryManager.memAlloc

        push eax ; saving allocation address
        xor eax, eax

        call ProcessManager.startProcess

        shl ebx, 4+4+3
        pop eax
        add ebx, eax
        dec ebx
        mov edx, 3

        call MemoryManager.createLDTEntry

        pop ds
		pop eax

        call ProcessManager.setLDT

        mov ds, si
        xor edi, edi
        call FlFS.readFile

        xor eax, eax
		mov ebx, ecx
		mov edx, 3
        call ProgramLoader.exec

        ;ud1
        hlt
        cli

        pop edx

        call SetUpSheduler

        call Print.saveCurrentCursorPos
        call Print.newLineSyscall
        call Print.newLineSyscall

		sti
		hlt
		jmp $-1

TestException:
	mov eax, 0xAAAAAAAA
	mov ebx, 0xBBBBBBBB
	mov ecx, 0xCCCCCCCC
	mov edx, 0xDDDDDDDD
	mov esi, 0xEEEEEEEE
	mov edi, 0xFFFFFFFF
	ud1

NoBootFile:
	call Print.newLine

	xor eax, eax
	not eax
	xor ecx, ecx
	mov esi, .msg+1
	mov di, [.msg]
	and di, 0xff

	call Print.string

	mov eax, 0x00CC0000
	mov esi, .msg2+1
	mov di, [.msg2]
	and di, 0xff

	call Print.string
	hlt
	jmp $-1

PCITest:
	call PCIDriver.printDeviceTable

	hlt
	jmp $-1

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
        mov esi, .HexConvTable
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

DebugMode:
	.start:
		push eax
		push es

		mov ax, 0x40
		mov es, ax

		or dword es:[PMDB.flags], 10b ; turn on debug mode

		pop es
		pop eax
		ret

	.main:
		pusha
		push ds

		mov ax, 0x20
		mov ds, ax

		mov eax, IRQHandlers.timerInterruptForcedTextMode
		mov  bh, 10001110b ; DPL 0, Interrupt Gate
		mov ecx, 0x20 ; Timer IRQ
		mov edx, 0x28 ; Kernel code

		call IDT.modEntry

		sti

		call MemoryManager.memAllocPrint

		hlt
		jmp $-1 ; TODO: implement this

		cli

		xor eax, eax ; Clearing handler address
		mov bh, 10000101b ; DPL 0, Task Gate
		mov ecx, 0x20 ; Timer IRQ
		mov edx, 0x50 ; TSS 1

		call IDT.modEntry

		mov ax, 0x40
		mov es, ax

		and dword es:[PMDB.flags], 0xFFFFFFFD ; turn off debug mode

		pop ds
		popa

		ret

Power:
	.ForceRestart:
		mov ax, 0x02
		mov ds, ax
		lidt [ds:0]
		ud1          ; Restart
	.PS_2Restart:
		call PS2.waitForWrite

		mov  al, 0xFE
		out  0x64, al

%include "Drivers/VGA.asm"
%include "Drivers/ATA.asm"
%include "Drivers/PCI.asm"
%include "Drivers/VFS.asm"
%include "Drivers/FLFS.asm"
%include "Drivers/PS2.asm"
%include "Drivers/PS2Keyboard.asm"

%include "KernelIncludes/EDD.asm"
%include "KernelIncludes/Drawing.asm"
%include "KernelIncludes/InterruptHandlers.asm"
%include "KernelIncludes/ProcessManager.asm"
%include "KernelIncludes/MemoryManager.asm"
%include "KernelIncludes/ProgramLoader.asm"
%include "KernelIncludes/API.asm"
%include "KernelIncludes/Syscall.asm"
%include "KernelIncludes/DeviceListTools.asm"

section .rodata


StartupText:  db (.end-$-1), "Kernel: FlameOS Starting up...", 10
			  db             "Kernel: Video driver initialised."
	.end:

IDTloaded:	  db (.end-$-1), "Kernel: IDT initialised."
	.end:

Conv.HexConvTable: db "0123456789ABCDEF"

NoBootFile.msg: db NoBootFile.msg2-NoBootFile.msg-1, "Kernel: "
NoBootFile.msg2: db NoBootFile.end-NoBootFile.msg2-1, "Boot file is missing or filename is incorrect."
NoBootFile.end:


Strings:
	.Terminal:
		db 'Terminal.ub', 0


%include "KernelIncludes/Glyphs.asm"
; times 0x200*(0x30-ThirdBootloaderSize)-($-$$) db 0
