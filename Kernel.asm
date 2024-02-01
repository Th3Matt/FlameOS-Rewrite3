
[ BITS 32 ]

global KernelInit32
section .text

%include "KernelIncludes/Constants.asm"

KernelInit32:
	mov ax, Segments.KernelStack
	mov ss, ax
	mov ax, Segments.KernelCode
	mov ds, ax
	mov esp, 0x1000

	mov ax, Segments.NULL
	mov gs, ax				; clearing gs so function returns don't crash

GraphicsModeSetUp:
	mov ax, Segments.Variables
	mov es, ax
	cmp dword [es:GraphicsDriverNameString], 'VGAH'
	jnz .notVGAHDriver
	pushf
	call Segments.KernelCode:InitVGAH
	jmp .done

	.notVGAHDriver:
	cmp dword [es:GraphicsDriverNameString], 'BOCH'
	jnz .done
	pushf
	call Segments.KernelCode:InitBGA
	;jmp .done

	.done:

	call Print.updateVariables

	mov esi, Prefix.kernel
	call CurrentContext.addNew

ClearScreen:

	call Print.clearScreen

KERNEL:
	.loading:
		mov es:[SOB.currentlySelectedEntry], byte 0

    call Print.resetCurrentCursorPos

		mov eax, 0xFFFFFFFF
		mov esi, StartupText
		xor ecx, ecx

		call Print.prefixedString

		mov esi, VideoDriver

		call Print.prefixedString

		pusha

    mov al, (0<<6) + (11b<<4) + (2<<1) + 0
    out 0x43, al
    mov al, 2Eh
    out 0x40, al
    mov al, 9Ch
    out 0x40, al ; ~ 0.019991s

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

		mov esi, IDTloaded

		xor ecx, ecx

		call Print.prefixedString

    call Print.newLine

; ----------------------------------------------------------------------------------------------
;									Interrupts initialised
; ----------------------------------------------------------------------------------------------

		call ProcessManager.init
		xor eax, eax
		xor ecx, ecx
    call ProcessManager.pauseProcess

    call MemoryManager.init

; ----------------------------------------------------------------------------------------------
;									Memory manager initialised
; ----------------------------------------------------------------------------------------------

    call DeviceList.init

    call Syscall.init
    call GenericDrivers.init

    call PS2.init
    call PS2.initDevices

    call PS_2_Keyboard.init

    mov ax, Segments.TSS2
    ltr ax

    call PCIDriver.detectDevices

; ----------------------------------------------------------------------------------------------
;								PCI and some devices initialised
; ----------------------------------------------------------------------------------------------

    test byte es:[CustomSetting], 100b
    jnz PCITest

		call S_ATA_PI.detectDevices
		call AHCIDriver.init

    mov ecx, 1
    xor edx, edx

    call API.allocWithAddress

    mov fs, si

    mov eax, 0
    xor ebx, ebx
    mov ecx, 2
    xor edi, edi 
    
    call AHCIDriver.readSectors

    jc .readSectors
    
    pusha 
   
    mov ebx, 0x00FA1100
    mov eax, 0x00FF8800
    xor ecx, ecx

    call Print.hex32 
  
    popa
  
    .readSectors:

; ----------------------------------------------------------------------------------------------
;									Disk drivers initialised
; ----------------------------------------------------------------------------------------------

		call EDDV3Read

    mov cx, Segments.SysLDT
    lldt cx
    call FlFS.init

    call VFS.init

; ----------------------------------------------------------------------------------------------
;								VFS and filesystem initialised
; ----------------------------------------------------------------------------------------------

    mov ax, Segments.FS_Header
    mov fs, ax
    mov esi, Strings.Terminal
    
    call FlFS.getFileNumber
    jnc .terminalFileFound
      
      call NoTerminalFile
    
    .terminalFileFound:
      cmp al, fs:[4]
      jz .terminalFileAutorun
        
        call DifferentAutorunFile
		
      .terminalFileAutorun:

		mov al, fs:[4]
		cmp al, 0
		jz .NoAutorunFile

    push edx

    call FlFS.getFileInfo
    push eax

    push ds
    mov ax, Segments.UserspaceMem
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

    call LDT.createEntry

    pop ds
		pop eax

    call LDT.set

    push ds

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

    pop ds

    pop edx

    call SetUpSheduler

    mov eax, 0x00FFFFFF
    mov esi, InitDone
    xor ecx, ecx

    call Print.prefixedString

    call Print.newLine

		sti
		hlt
		jmp $-1

	.NoAutorunFile:
		call Print.newLine

		mov eax, 0x00CC0000
		xor ecx, ecx
		mov esi, NoAutorunFile

		call Print.prefixedString

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

NoTerminalFile:
	pusha

	call Print.newLine

	mov eax, 0x00CC0000
	xor ecx, ecx
	mov esi, .msg

	call Print.prefixedString

	popa
	ret

DifferentAutorunFile:
	pusha

	call Print.newLine

	mov eax, 0x00CC0000
	xor ecx, ecx
	mov esi, .msg

	call Print.prefixedString

	popa
	ret

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

        mov bx, Segments.KernelCode
        mov ds, bx
        shr dl, 4

        xor ebx, ebx
        mov bl, dl
        mov esi, .HexConvTable
        add esi, ebx
        mov dl, [esi]
        mov ah, dl
        sub esi, ebx

        pop dx

        and dl, 0x0F
        xor ebx, ebx
        mov bl, dl
        add esi, ebx
        mov dl, [esi]
        mov al, dl
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

	.reverseBytes: ; edx - bytes to reverse. Output: edx - reversed bytes.
		ror dl, 4
		ror edx, 8

		ror dl, 4
		ror edx, 8

		ror dl, 4
		ror edx, 8

		ror dl, 4
		ror edx, 8

		ret

	.hexToBCD32: ; edx - hex number. Output: ebx - BCD number, edx - leftover hex number, CF - set if number didn't fit register
		push eax
		push ecx
		push edi

		mov ecx, 32/4
		mov eax, edx
		xor ebx, ebx
		mov edi, 10

		.hexToBCD32.loop:
			xor edx, edx
			idiv edi

			add ebx, edx
			ror ebx, 4

			loop .hexToBCD32.loop

		mov edx, eax
		cmp edx, 0
		jz .hexToBCD32.end
		stc
		.hexToBCD32.end:
		pop edi
		pop ecx
		pop eax
		ret

DebugMode:
	.start:
		push eax
		push es

		mov ax, Segments.ProcessData
		mov es, ax

		or dword es:[PMDB.flags], 10b ; turn on debug mode

		pop es
		pop eax
		ret

	.main:
		pusha
		push ds

		mov ax, Segments.IDT
		mov ds, ax

		mov eax, IRQHandlers.timerInterruptForcedTextMode
		mov  bh, 10001110b ; DPL 0, Interrupt Gate
		mov ecx, 0x20 ; Timer IRQ
		mov edx, Segments.KernelCode ; Kernel code

		call IDT.modEntry

		sti

		call MemoryManager.memAllocPrint

		hlt
		jmp $-1 ; TODO: implement this

		cli

		xor eax, eax ; Clearing handler address
		mov bh, 10000101b ; DPL 0, Task Gate
		mov ecx, 0x20 ; Timer IRQ
		mov edx, Segments.TSS1 ; TSS 1

		call IDT.modEntry

		mov ax, Segments.ProcessData
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

Sleep: ; ecx - clock ticks to wait
; note - this will break if clockTicks is close to overflow or ecx is really high
	pusha

	push es
	mov ax, Segments.Variables
	mov es, ax

	mov edx, es:[Clock.clockTicks]

	.loop:
		hlt

		push edx
		add edx, ecx
		cmp edx, es:[Clock.clockTicks]
		pop edx
		jnbe .loop

	pop es

	popa
	ret

%include "Drivers/VGA.asm"
%include "Drivers/ATA.asm"
%include "Drivers/AHCI.asm"
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
%include "KernelIncludes/CurrentContext.asm"

%include "GenericDrivers/GenericInit.asm"


section .rodata

%include "KernelIncludes/Glyphs.asm"

StartupText:  				db (.end-$-1), "FlameOS Starting up...", 10
	.end:

VideoDriver:  				db (.end-$-1), "Video driver initialised.", 10
	.end:

IDTloaded:	  				db (.end-$-1), "IDT initialised.", 10
	.end:

NoAutorunFile:				db (.end-$-1), "Autorun file index is corrupt.", 10
	.end:

Prefix.kernel: 				db Prefix.kernel.end-$-1, "Kernel: "
Prefix.kernel.end:

NoTerminalFile.msg: 		db (.end-$-1), "Terminal file is missing or filename is modified."
	.end:

DifferentAutorunFile.msg: 	db (.end-$-1), "Autorun file index is modified."
	.end:

InitDone: 	db (.end-$-1), "Initialisation done.", 10
	.end:

Conv.HexConvTable: db "0123456789ABCDEF"


Strings:
	.Terminal:
		db 'Terminal.ub', 0

; times 0x200*(0x30-ThirdBootloaderSize)-($-$$) db 0
