IRQs:
    .timerInterrupt:
        xchg bx, bx

		cmp [es:0xc], byte 0
		jz .timerInterrupt.stopPC

		cmp [es:0xc], byte 2
		jb .timerInterrupt.notEnoughTasks

            call ProcessManager.sheduler

            jmp .timerInterrupt.return

        .timerInterrupt.notEnoughTasks:     ; Not enough tasks to switch between
            mov al, byte [es:0x10]
            test byte [es:0x10], 00000001b
            jnz .timerInterrupt.return

            xor byte [es:0x10], 00000001b
            call ProcessManager.sheduler.skipWrite

        .timerInterrupt.return:
            mov al, 0x20
            out 0x20, al  ; EOI

            iret

        .timerInterrupt.stopPC:             ; No more tasks to execute, check whether to restart or shut down the computer
            jmp $   ; Currently just stop execution

SetUpInterrupts:
    pusha
    push es

    mov ax, 0x48
    mov es, ax

    xor eax, eax
    xor edi, edi
    mov ecx, 0xff/4
    rep stosd

    mov es:[0x20], dword IRQs.timerInterrupt-0x20000
    mov ax, ss
    mov es:[0x50], ax
    mov es:[0x38], esp
    mov es:[0x4C], word 0x28
    mov es:[0x48], word 0x40
    mov es:[0x00], word 0x58

    push ds
    mov ax, 0x20
    mov ds, ax

    mov eax, Exceptions.DF-0x20000
    mov bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0x8
    mov edx, 0x28 ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.TS-0x20000
    mov bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0xA
    mov edx, 0x28 ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.NP-0x20000
    mov bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0xB
    mov edx, 0x28 ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.SS-0x20000
    mov bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0xC
    mov edx, 0x28 ; Kernel code

    call IDT.modEntry

    mov eax, Exceptions.GP-0x20000
    mov bh, 10001110b ; DPL 0, Interrupt Gate
    mov ecx, 0xD
    mov edx, 0x28 ; Kernel code

    call IDT.modEntry

    xor eax, eax ; Clearing handler address
    mov bh, 10000101b ; DPL 0, Task Gate
    mov ecx, 0x20 ; Timer IRQ
    mov edx, 0x50 ; TSS 1

    call IDT.modEntry

    mov word ds:[256*8], 256*8
    mov dword ds:[256*8+2], 5000h
    lidt ds:[256*8]

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

        mov ax, 0x38
        mov es, ax
        mov gs, ax
        mov ax, 0x10
        mov ds, ax

        xor edi, edi
        xor ecx, ecx
        mov cx, ds:[ScreenWidth]
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

        mov eax, (21*1)
        mul ecx
        mov ecx, eax
        mov eax, 0x00000000
        rep stosd

        mov ax, 0x28
        mov ds, ax

        xor edx, edx

        mov ecx, 3

        call Print.newLine
        loop $-5

        mov eax, 0x00ff0000
        mov esi, .Exception-0x20000+2
        xor edi, edi
        mov di, [.Exception-0x20000]
        call Print.string

        mov ecx, 7

        call Print.newLine
        loop $-5

        mov eax, 0x00fffffff
        ;mov edx, 800/20*(6)*21
        mov esi, .Exception.2-0x20000+2
        mov di, [.Exception.2-0x20000]
        call Print.string

        mov ebp, esp ; Saving Handler stack
        add esp, 4+32
        xor ebx, ebx
        pop bx
        xchg esp, ebp ; Using Handler stack
        call Print.char
        xchg esp, ebp

        inc edx
        pop bx
        xchg esp, ebp ; Using Handler stack
        call Print.char

        add edx, 5

        mov esi, .Exception.3-0x20000+2
        mov di, [.Exception.3-0x20000]
        call Print.string
        xchg esp, ebp

        pop ecx
        xchg esp, ebp ; Using Handler stack

        call Print.hex32

        mov ecx, 10

        call Print.newLine
        loop $-5

        mov esi, .Exception.4-0x20000+2
        mov di, [.Exception.4-0x20000]
        call Print.string

        sub edx, 15*2+7*2+4
        mov ecx, ss:[esp+28]
        call Print.hex32

        add edx, 8
        mov ecx, ss:[esp+16]
        call Print.hex32

        add edx, 8
        mov ecx, ss:[esp+24]
        call Print.hex32

        add edx, 8
        mov ecx, ss:[esp+20]
        call Print.hex32

        mov ecx, 2

        call Print.newLine
        loop $-5

        mov esi, .Exception.5-0x20000+2
        mov di, [.Exception.5-0x20000]
        call Print.string

        sub edx, 7*2+2
        mov ecx, ss:[esp+4]
        call Print.hex32

        add edx, 8
        mov ecx, ss:[esp]
        call Print.hex32

        mov ecx, 10

        call Print.newLine
        loop $-5

        add edx, 800/20*21-(800/20/2-(.Exception.end-.Exception.6-2))*21
        mov esi, .Exception.6-0x20000+2
        mov di, [.Exception.6-0x20000]
        call Print.string
        xchg esp, ebp

        pop ecx
        mov esp, ebp ; Using only handler stack

        call Print.hex32

        jmp $

    .Exception:   dw (.Exception.2-.Exception-2)
                  db ",---EXCEPTION--------!!!"

    .Exception.2: dw (.Exception.3-.Exception.2-2)
                  db "Exception: #"

    .Exception.3: dw (.Exception.4-.Exception.3-2)
                  db "Error Code: 0x"

    .Exception.4: dw (.Exception.5-.Exception.4-2)
                  db "EAX: 0x         EBX: 0x         ECX: 0x         EDX: 0x"

    .Exception.5: dw (.Exception.6-.Exception.5-2)
                  db "ESI: 0x         EDI: 0x"

    .Exception.6: dw (.Exception.end-.Exception.6-2)
                  db "EIP:  0x"
    .Exception.end:
