IRQHandlers:
    .timerInterrupt:
        push eax

        push ds
        mov ax, Segments.Variables
        mov ds, ax

        inc dword ds:[Clock.clockTicks]

        pop ds

        call Print.refresh

        mov al, 0x20
        out 0x20, al  ; EOI

        pop eax
        iret

    .timerInterruptForcedTextMode:
        push eax

        push ds
        mov ax, Segments.Variables
        mov ds, ax

        inc dword ds:[Clock.clockTicks]

        pop ds

        mov bx, 0xFFFF
        call Print.refresh

        mov al, 0x20
        out 0x20, al  ; EOI

        pop eax
        iret

    .timerInterrupt2:
        push es
        mov ax, Segments.Variables
        mov es, ax

        inc dword es:[Clock.clockTicks]

        pop es

        test dword [es:PMDB.flags], 00000010b
        jz .timerInterrupt2.notDebug

        mov al, 0x20
        out 0x20, al  ; EOI

        call DebugMode.main
        jmp .timerInterrupt2.return.end

        .timerInterrupt2.notDebug:

		cmp [es:PMDB.ammoutOfActiveProcesses], dword 0
		jz .timerInterrupt2.stopPC

		cmp [es:PMDB.ammoutOfActiveProcesses], dword 2
		jb .timerInterrupt2.notEnoughTasks

            call ProcessManager.sheduler

            jmp .timerInterrupt2.return

        .timerInterrupt2.notEnoughTasks:     ; Not enough tasks to switch between
            test dword [es:PMDB.flags], 00000001b ; check if we need to update task context
            jnz .timerInterrupt2.return

            xor dword [es:PMDB.flags], 00000001b
            call ProcessManager.sheduler.skipWrite

        .timerInterrupt2.return:
            xor ebx, ebx

            call Print.refresh ; TODO: fix this.

            mov al, 0x20
            out 0x20, al  ; EOI

            .timerInterrupt2.return.end:
            iret
            jmp .timerInterrupt2 ; fix for an intended feature of the tss

        .timerInterrupt2.stopPC:             ; No more tasks to execute, check whether to restart or shut down the computer
            call Power.PS_2Restart

SetUpInterrupts:
    pusha
    push es

    mov ax, Segments.TSS_Write
    mov es, ax

    xor eax, eax
    xor edi, edi
    mov ecx, 0xff/4
    rep stosd

    push ds
    mov ax, Segments.IDT
    mov ds, ax

    mov eax, Breakpoints.breakpointSkip
    mov  bh, 11101110b ; DPL 3, Interrupt Gate
    mov ecx, 0x3 ; Breakpoint
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.UD
    mov  bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0x6
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.DF
    mov  bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0x8
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.TS
    mov  bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0xA
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.NP
    mov  bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0xB
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.SS
    mov  bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0xC
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.GP
    mov  bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0xD
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    push ds
    mov ax, Segments.Variables
    mov ds, ax

    mov dword ds:[Clock.clockTicks], 0

    pop ds

    mov eax, IRQHandlers.timerInterrupt
    mov  bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0x20 ; Timer IRQ
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    mov eax, Syscall.run
    mov  bh, 11101110b ; DPL 3, Interrupt Gate
    mov ecx, 0x30 ; Syscall
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    mov word  ds:[256*8],   256*8
    mov dword ds:[256*8+2], 5000h
    lidt ds:[256*8]

    pop ds
    pop es
    popa
    ret

ArmBreakpoint:
    pusha
    push es

    mov ax, Segments.IDT
    mov ds, ax

    mov eax, Breakpoints.breakpoint
    mov  bh, 11101110b ; DPL 3, Interrupt Gate
    mov ecx, 0x3 ; Breakpoint
    mov edx, Segments.KernelCode ; Kernel code

    call IDT.modEntry

    pop es
    popa
    ret

SetUpSheduler:
    pusha
    push es

    mov ax, Segments.TSS_Write
    mov es, ax

    mov es:[0x20], dword IRQHandlers.timerInterrupt2
    mov ax, ss
    mov es:[0x50], ax
    mov es:[0x38], esp
    mov es:[0x4C], word 0x28
    mov es:[0x48], word 0x40
    mov es:[0x00], word 0x58
    mov es:[0x60], word 0x98

    push ds
    mov ax, Segments.IDT
    mov ds, ax

    xor eax, eax ; Clearing handler address
    mov bh, 10000101b ; DPL 0, Task Gate
    mov ecx, 0x20 ; Timer IRQ
    mov edx, 0x50 ; TSS 1

    call IDT.modEntry

    pop ds
    pop es
    popa
    ret

Exceptions:
    .UD:
        push dword "U"+("D"<<16)
        call .panicScreen

    .DF:
        push dword "D"+("F"<<16)
        call .panicScreen

    .TS:
        push dword "T"+("S"<<16)
        call .panicScreen

    .NP:
        push dword "N"+("P"<<16)
        call .panicScreen

    .GP:
        push dword "G"+("P"<<16)
        call .panicScreen

    .SS:
        push dword "S"+("S"<<16)
        call .panicScreen

    .panicScreen:
        pusha

        push gs
        mov ax, Segments.VRAM_Graphics
        mov gs, ax


        call Print.clearScreen

        pop gs
        mov ax, Segments.VRAM_Graphics
        mov es, ax
        mov gs, ax
        mov ax, Segments.Variables
        mov ds, ax
        mov ax, Segments.CharmapOfScreen
        mov fs, ax

        xor edi, edi
        mov ecx, ds:[ScreenWidth]
        push ecx

        mov eax, (21*2)
        mul ecx
        mov ecx, eax
        mov eax, 0x00000000
        rep stosd

        pop ecx
        push ecx

        mov eax, (21*(600/20-4))
        mul ecx
        mov ecx, eax
        mov eax, 0x00aa6600
        rep stosd

        pop ecx
        push ecx

        mov eax, ecx
        mov ecx, 10
        xor edx, edx
        div ecx

        mov edi, eax
        shl edi, 2

        mov ecx, 50
        xor edx, edx
        mul ecx

        mov ecx, eax

        mov eax, 9
        xchg eax, edi
        mul edi
        xchg eax, edi

        .panicScreen.loop:
            mov dword fs:[edi+5], 0x00aa6600
            add edi, 9
            loop .panicScreen.loop

        pop ecx

        mov eax, (21*1)
        mul ecx
        mov ecx, eax
        mov eax, 0x00000000
        rep stosd

        mov ax, 0x28
        mov ds, ax

        xor edx, edx

        call Print.resetCurrentCursorPos

        mov ecx, 3

        call Print.newLine
        loop $-5

        mov eax, 0x00ff0000
        mov esi, .Exception

        call Print.string

        mov ecx, 7

        call Print.newLine
        loop $-5

        mov eax, 0x00fffffff
        ;mov edx, 800/20*(6)*21
        mov esi, .Exception.2
        mov ecx, 0x00aa6600
        call Print.string

        mov ebp, esp ; Saving Handler stack
        add esp, 4+32
        xor ebx, ebx
        pop bx
        xchg esp, ebp ; Using Handler stack
        call Print.char
        xchg esp, ebp

        pop bx
        xchg esp, ebp ; Using Handler stack
        call Print.char

        mov ebx, " "
        call Print.char

        mov esi, .Exception.3
        mov ecx, 0x00aa6600
        call Print.string
        xchg esp, ebp

        pop ebx
        xchg esp, ebp ; Using Handler stack

        mov ecx, 0x00aa6600
        call Print.hex32

        mov ecx, 10

        call Print.newLine
        loop $-5

        mov esi, .Exception.EAX
        movzx edi, byte [.Exception.registerTitleSize]
        mov ecx, 0x00aa6600
        call Print.stringWithSize

        mov ebx, ss:[esp+28]
        call Print.hex32

        mov ebx, " "
        call Print.char

        mov esi, .Exception.EBX
        movzx edi, byte [.Exception.registerTitleSize]
        call Print.stringWithSize

        mov ebx, ss:[esp+16]
        call Print.hex32

        mov ebx, " "
        call Print.char

        mov esi, .Exception.ECX
        movzx edi, byte [.Exception.registerTitleSize]
        call Print.stringWithSize

        mov ebx, ss:[esp+24]
        call Print.hex32

        mov ebx, " "
        call Print.char

        mov esi, .Exception.EDX
        movzx edi, byte [.Exception.registerTitleSize]
        call Print.stringWithSize

        mov ebx, ss:[esp+20]
        call Print.hex32

        mov ecx, 2

        call Print.newLine
        loop $-5

        mov esi, .Exception.ESI
        movzx edi, byte [.Exception.registerTitleSize]
        mov ecx, 0x00aa6600
        call Print.stringWithSize

        mov ebx, ss:[esp+4]
        call Print.hex32

        mov ebx, " "
        call Print.char

        mov esi, .Exception.EDI
        movzx edi, byte [.Exception.registerTitleSize]
        call Print.stringWithSize

        mov ebx, ss:[esp]
        call Print.hex32

        mov ecx, 10

        call Print.newLine
        loop $-5

        add edx, 800/20*21-(800/20/2-(.Exception.registerTitleSize))*21
        mov esi, .Exception.EIP
        movzx edi, byte [.Exception.registerTitleSize]
        mov ecx, 0x00aa6600
        call Print.stringWithSize
        xchg esp, ebp

        pop ebx
        mov esp, ebp ; Using only handler stack

        call Print.hex32

        mov bx, 0xFFFF
        call Print.refresh

        jmp $  ; TODO: Display interactive options

    section .rodata
    .Exception:   db (.Exception.2-.Exception-1)
                  db ",---EXCEPTION--------!!!"

    .Exception.2: db (.Exception.3-.Exception.2-1)
                  db "Exception: #"

    .Exception.3: db (.Exception.registerTitleSize-.Exception.3-1)
                  db "Error Code: 0x"

    .Exception.registerTitleSize: db (.Exception.EBX-.Exception.EAX)
    .Exception.EAX: db "EAX: 0x"
    .Exception.EBX: db "EBX: 0x"
    .Exception.ECX: db "ECX: 0x"
    .Exception.EDX: db "EDX: 0x"
    .Exception.ESI: db "ESI: 0x"
    .Exception.EDI: db "EDI: 0x"
    .Exception.EIP: db "EIP: 0x"

    section .text

Breakpoints:
  .breakpoint:
    push eax
    xor eax, eax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    pop eax

    pusha

    mov ebx, eax
    mov eax, 0x00FFFFFF
    xor ecx, ecx

    call Print.hex32

    popa
    pusha

    mov ecx, 0x00FFFFFF
    xor eax, eax

    call Print.hex32

    popa
    pusha

    mov ebx, ecx
    mov eax, 0x00FFFFFF
    xor ecx, ecx

    call Print.hex32

    popa
    pusha

    mov ebx, edx
    mov ecx, 0x00FFFFFF
    xor eax, eax

    call Print.hex32

    popa
    pusha

    mov ebx, esi
    mov eax, 0x00FFFFFF
    xor ecx, ecx

    call Print.hex32

    popa
    pusha

    mov ebx, edi
    mov ecx, 0x00FFFFFF
    xor eax, eax

    call Print.hex32

    popa
    pusha

    mov ebx, esp
    mov ecx, 0x0000FF00
    xor eax, eax

    call Print.hex32

    popa

    ;jmp $ 
    
    call Print.refresh

    jmp $

  .breakpointSkip:
    iret


