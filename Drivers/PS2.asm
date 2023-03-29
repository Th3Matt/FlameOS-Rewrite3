
PS2_DATA_PORT equ 0x60
PS2_STATUS_PORT equ 0x60
PS2_COMMAND_PORT equ 0x60

TIMEOUT equ 500


PS2:
    .init:
        pusha
        xor ebx, ebx

        mov al, 0xAD
        out PS2_COMMAND_PORT, al ; disabling PS/2 first port

        mov al, 0xA7
        out PS2_COMMAND_PORT, al ; disabling PS/2 second port

        in al, PS2_DATA_PORT ; flushing

        mov al, 0x20
        out PS2_COMMAND_PORT, al ; getting the controller configuration byte

        call .waitForRead

        in al, PS2_DATA_PORT

        and al, 10111100b

        test al, 00100000b
        jnz .init.isDualChannel
	
        or bl, 10b

        .init.isDualChannel:

        push eax

        mov al, 0x60
        out PS2_COMMAND_PORT, al ; setting the controller configuration byte

        call .waitForWrite

        pop eax

        out PS2_DATA_PORT, al

        mov al, 0xAA
        out PS2_COMMAND_PORT, al ; performing controller self-test

        call .waitForRead

        in al, PS2_DATA_PORT
        cmp al, 0x55
        jnz .init.error

        mov al, 0xA8
        out PS2_COMMAND_PORT, al ; enabling PS/2 second port

        mov al, 0x20
        out PS2_COMMAND_PORT, al ; getting the controller configuration byte

        call .waitForRead

        in al, PS2_DATA_PORT
        test al, 00100000b
        jz .init.isDualChannel2

        or bl, 10b

        .init.isDualChannel2:

        mov al, 0xA7
        out PS2_COMMAND_PORT, al ; disabling PS/2 second port

        mov al, 0xAB
        out PS2_COMMAND_PORT, al ; getting the controller configuration byte

        call .waitForRead

        in al, PS2_DATA_PORT

        cmp al, 0
        jz .init.pastTest1

        or bl, 1

        .init.pastTest1:

        test bl, 10b
        jnz .init.pastTest2

        mov al, 0xAB
        out PS2_COMMAND_PORT, al ; getting the controller configuration byte

        call .waitForRead

        in al, PS2_DATA_PORT

        cmp al, 0
        jz .init.pastTest2

        or bl, 10b

        .init.pastTest2:

        test bl, 1
        jnz .init.pastReset1

        mov al, 0xAE
        out PS2_COMMAND_PORT, al ; enabling PS/2 first port

        call .waitForWrite

        mov al, 0xFF
        out PS2_DATA_PORT, al    ; reseting device 1

        call .waitForReadT
        jnc .init.Reset1

        or bl, 1
        jmp .pastReset1

        .init.Reset1:

        in al, PS2_DATA_PORT
        cmp al, 0xFA
        jz .init.Reset1.1

        or bl, 1
        jmp .pastReset1

        .init.Reset1.1:

        call .waitForReadT
        jnc .init.Reset1.2

        or bl, 1
        jmp .pastReset1

        .init.Reset1.2:

        in al, PS2_DATA_PORT

        .init.pastReset1:

        test bl, 10b
        jnz .init.pastReset2

        mov al, 0xA8
        out PS2_COMMAND_PORT, al ; enabling PS/2 second port

        mov al, 0xD4
        out PS2_COMMAND_PORT, al

        call .waitForWrite

        mov al, 0xFF
        out PS2_DATA_PORT, al    ; reseting device 2

        call .waitForReadT
        jnc .init.Reset2

        or bl, 1
        jmp .pastReset2

        .init.Reset2:

        in al, PS2_DATA_PORT
        cmp al, 0xFA
        jz .init.Reset2.1

        or bl, 1
        jmp .pastReset2

        .init.Reset2.1:

        call .waitForReadT
        jnc .init.Reset2.2

        or bl, 1
        jmp .pastReset1

        .init.Reset1.2:

        in al, PS2_DATA_PORT

        .init.pastReset2:

        cmp ebx, 0
        jz .init.error

        mov ax, 0xB0
        push ds

        mov ds, ax

        inc word [ds:DeviceList.Size]
        xor eax, eax
        mov ax, [ds:DeviceList.Size]
        shl ax, 5
        mov word [ds:DeviceList.FirstEntry+ax], 1


        pop ds

        popa
        ret

        .init.error:
            stc
            popa
            ret

    .waitForWrite:
        push eax

        .waitForWrite.1:
        in al, PS2_STATUS_PORT

        test al, 11000000b
        jnz .waitForWrite.error

        test al, 00000010b
        jnz .waitForWrite.1

        clc
        pop eax
        ret

        .waitForWrite.error:
            stc
            pop eax
            ret

    .waitForRead:
        push eax

        .waitForRead.1:
        in al, PS2_STATUS_PORT

        test al, 11000000b
        jnz .waitForRead.error

        test al, 00000001b
        jz .waitForRead.1

        clc
        pop eax
        ret

        .waitForRead.error:
            stc
            pop eax
            ret

    .waitForWriteT:
        push eax
        push ecx

        mov ecx, TIMEOUT
        .waitForWriteT.1:
        in al, PS2_STATUS_PORT

        test al, 11000000b
        jnz .waitForWriteT.error

        test al, 00000010b
        jnz .waitForWriteT.1

        clc
        pop ecx
        pop eax
        ret

        .waitForWriteT.error:
            stc
            pop ecx
            pop eax
            ret

    .waitForReadT:
        push eax
        push ecx

        mov ecx, TIMEOUT
        .waitForReadT.1:
        in al, PS2_STATUS_PORT

        cmp ecx, 0
        jz .waitForReadT.error

        test al, 11000000b
        jnz .waitForReadT.error

        test al, 00000001b
        jz .waitForReadT.1

        clc
        pop ecx
        pop eax
        ret

        .waitForReadT.error:
            stc
            pop ecx
            pop eax
            ret
