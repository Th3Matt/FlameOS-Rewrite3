
KCB.writeCounter                equ KeyboardCircularBufferSpace
KCB.readCounter                 equ KCB.writeCounter+1
KCB.buffer                      equ KCB.readCounter+1 ; 48 bytes

PS_2_Keyboard:
    .init:
        pusha

        push ds

        mov ax, 0x20
        mov ds, ax

        mov byte ds:[KCB.writeCounter], 0
        mov byte ds:[KCB.readCounter], 0

        mov ax, 2
        mov bx, 1
        xor ecx, ecx

        call DeviceList.findDevice
        mov ecx, eax
        jc .init.end2

        call DeviceList.getDeviceEntry

        ror  ecx, 16

        test cl,  1
        jnz .init.Port2

        .init.Port1:

        call PS2.waitForWriteT

        mov al, 0xF0
        out PS2_DATA_PORT, al ; Set scancode set

        .init.Port1.1:

        call PS2.waitForReadT

        in al, PS2_DATA_PORT

        cmp al, 0x0
        je .init.Port1.1

        cmp al, 0xFE
        je .init.Port1

        cmp al, 0xFA
        jne .init.end

        mov al, 0x03
        out PS2_DATA_PORT, al

        .init.Port1.2:

        call PS2.waitForWriteT

        mov al, 0xF4
        out PS2_DATA_PORT, al ; Enable scanning

        .init.Port1.3:

        call PS2.waitForReadT

        in al, PS2_DATA_PORT

        cmp al, 0x0
        je .init.Port1.3

        cmp al, 0xFE
        je .init.Port1.2

        cmp al, 0xFA
        jne .init.end

        mov eax, .PS_2_Interrupt
        mov  bh, 10001110b ; DPL 0, Task Gate
        mov ecx, 0x21 ; PS/2 IRQ 1
        mov edx, 0x28 ; Kernel code

        call IDT.modEntry

        in al, 0x21
        and al, 11111101b
        out 0x21, al

        jmp .init.end

        .init.Port2:

        call PS2.waitForWriteT

        mov al, 0xF0
        call PS2.commandToSecondPort ; Set scancode set

        .init.Port2.1:

        call PS2.waitForReadT

        in al, PS2_DATA_PORT

        cmp al, 0x0
        je .init.Port2.1

        cmp al, 0xFE
        je .init.Port2

        cmp al, 0xFA
        jne .init.end

        mov al, 0x03
        call PS2.commandToSecondPort

        .init.Port2.2:

        call PS2.waitForWriteT

        mov al, 0xF4
        call PS2.commandToSecondPort ; Enable scanning

        .init.Port2.3:

        call PS2.waitForReadT

        in al, PS2_DATA_PORT

        cmp al, 0x0
        je .init.Port2.3

        cmp al, 0xFE
        je .init.Port2.2

        cmp al, 0xFA
        jne .init.end

        mov eax, .PS_2_Interrupt2
        mov  bh, 10001110b ; DPL 0, Task Gate
        mov ecx, 0x2C ; PS/2 IRQ 2
        mov edx, 0x28 ; Kernel code

        call IDT.modEntry

        in al, 0xA1
        and al, 11101111b
        out 0xA1, al

        .init.end:

        mov ebx, .getKey
        mov ecx, 0x10
        call Syscall.add

        .init.end2:

        pop ds
        popa
        ret

    .PS_2_Interrupt:
        push eax

        call .storeKey

        mov al, 0x20
        out 0x20, al  ; EOI

        pop eax
        iret

    .PS_2_Interrupt2:
        push eax

        call .storeKey

        mov al, 0x20
        out 0x20, al  ; EOI
        out 0xA0, al

        pop eax
        iret

    .storeKey:
        pusha

        in al, PS2_DATA_PORT

        cmp al, 0x07
        je .storeKey.triggerDebugMode

        push ds

        mov bx, 0x20
        mov ds, bx

        xor ebx, ebx
        mov bl, ds:[KCB.writeCounter]

        mov ds:[KCB.buffer+ebx], al

        cmp ebx, 0x30
        jl .storeKey.1

        mov ebx, 0x0
        jmp .storeKey.2

        .storeKey.1:

        inc ebx

        .storeKey.2:

        mov ds:[KCB.writeCounter], bl

        pop ds
        popa
        ret

        .storeKey.triggerDebugMode:
            popa

            call DebugMode.start

            ret

    .getKey:
        push ebx
        push ds

        mov ax, 0x20
        mov ds, ax

        xor ebx, ebx
        mov bl, ds:[KCB.readCounter]
        xor eax, eax
        cmp bl, ds:[KCB.writeCounter]
        je .getKey.end

        mov al, ds:[KCB.buffer+ebx]

        cmp ebx, 0x30
        jl .getKey.1

        mov ebx, 0x0
        jmp .getKey.2

        .getKey.1:

        inc ebx

        .getKey.2:

        mov ds:[KCB.readCounter], bl

        .getKey.end:

        pop ds
        pop ebx
        ret
