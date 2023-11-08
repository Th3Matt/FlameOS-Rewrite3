
PS2.Device1                equ PS2Devices
PS2.Device2                equ PS2.Device1+4

PS2_keyboardBufferSize equ 0x80-DeviceList.EntryDriverDataOffset-2

PS_2_Keyboard:
    .init:
        pusha

        push ds
        push es

        mov ax, Segments.IDT
        mov ds, ax

        mov ax, Segments.Variables
        mov es, ax

        mov dword es:[PS2.Device1], 0
        mov dword es:[PS2.Device2], 0
        xor ecx, ecx

        .init.loop:
            mov ax, 2 ; Keyboard
            mov bx, 1 ; PS/2

            pusha

            call DeviceList.findDevice
            mov ecx, eax
            jc .init.end

            mov esi, 1
            xor eax, eax
            call DeviceList.writeWordToDeviceEntry

            xor esi, esi
            call DeviceList.readDwordFromDeviceEntry
            mov ecx, eax

            ror  ecx, 16

            test cl,  1
            jnz .init.loop.Port2

            .init.loop.Port1:

            call PS2.waitForWriteT

            mov al, 0xF0
            out PS2_DATA_PORT, al ; Set scancode set

            .init.loop.Port1.1:

            call PS2.waitForReadT

            in al, PS2_DATA_PORT

            cmp al, 0x0
            je .init.loop.Port1.1

            cmp al, 0xFE
            je .init.loop.Port1

            cmp al, 0xFA
            jne .init.loop.Port2

            mov al, 0x03
            out PS2_DATA_PORT, al

            .init.loop.Port1.2:

            call PS2.waitForWriteT

            mov al, 0xF4
            out PS2_DATA_PORT, al ; Enable scanning

            .init.loop.Port1.3:

            call PS2.waitForReadT

            in al, PS2_DATA_PORT

            cmp al, 0x0
            je .init.loop.Port1.3

            cmp al, 0xFE
            je .init.loop.Port1.2

            cmp al, 0xFA
            jne .init.loop.Port2

            mov eax, .PS_2_Interrupt
            mov  bh, 10001110b ; DPL 0, Task Gate
            mov ecx, 0x21 ; PS/2 IRQ 1
            mov edx, 0x28 ; Kernel code

            call IDT.modEntry

            in al, 0x21
            and al, 11111101b
            out 0x21, al

            popa

            call DeviceList.findDevice
            mov es:[PS2.Device1], eax

            pusha

            jmp .init.loop.end

            .init.loop.Port2:

            call PS2.waitForWriteT

            mov al, 0xF0
            call PS2.commandToSecondPort ; Set scancode set

            .init.loop.Port2.1:

            call PS2.waitForReadT

            in al, PS2_DATA_PORT

            cmp al, 0x0
            je .init.loop.Port2.1

            cmp al, 0xFE
            je .init.loop.Port2

            cmp al, 0xFA
            jne .init.loop.end

            mov al, 0x03
            call PS2.commandToSecondPort

            .init.loop.Port2.2:

            call PS2.waitForWriteT

            mov al, 0xF4
            call PS2.commandToSecondPort ; Enable scanning

            .init.loop.Port2.3:

            call PS2.waitForReadT

            in al, PS2_DATA_PORT

            cmp al, 0x0
            je .init.loop.Port2.3

            cmp al, 0xFE
            je .init.loop.Port2.2

            cmp al, 0xFA
            jne .init.loop.end

            mov eax, .PS_2_Interrupt2
            mov  bh, 10001110b ; DPL 0, Task Gate
            mov ecx, 0x2C ; PS/2 IRQ 2
            mov edx, 0x28 ; Kernel code

            call IDT.modEntry

            in al, 0xA1
            and al, 11101111b
            out 0xA1, al

            popa

            call DeviceList.findDevice
            mov es:[PS2.Device2], eax

            pusha

        .init.loop.end:
            popa

            inc ecx

            jmp .init.loop

        .init.end:
        popa

        pop es
        pop ds

        popa
        ret

    .PS_2_Interrupt:
        push eax

        xor eax, eax
        call .storeKey

        mov al, 0x20
        out 0x20, al  ; EOI

        pop eax
        iret

    .PS_2_Interrupt2:
        push eax

        mov eax, 1
        call .storeKey

        mov al, 0x20
        out 0x20, al  ; EOI
        out 0xA0, al

        pop eax
        iret

    .storeKey:
        pusha

        push eax

        in al, PS2_DATA_PORT
        xor edx, edx
        mov dl, al

        pop eax

        cmp dl, 0x07
        je .storeKey.triggerDebugMode

        push ds

        mov bx, Segments.Variables
        mov ds, bx

        mov ecx, PS2.Device1

        cmp eax, 0
        jz .storeKey.device1

        add ecx, 4

        .storeKey.device1:

        mov ecx, ds:[ecx]

        mov esi, 1

        call DeviceList.readByteFromDeviceEntry

        push eax
        add eax, 3
        mov esi, eax
        mov eax, edx

        call DeviceList.writeByteToDeviceEntry

        pop ebx ; pop eax

        inc ebx
        cmp ebx, PS2_keyboardBufferSize ; check for overflow
        jl .storeKey.1

        mov ebx, 0x0

        .storeKey.1:

        mov esi, 1
        mov eax, ebx

        call DeviceList.writeByteToDeviceEntry

        pop ds
        popa
        ret

        .storeKey.triggerDebugMode:
            popa

            call DebugMode.start

            ret
