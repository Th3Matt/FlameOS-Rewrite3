
PS2_DATA_PORT equ 0x60
PS2_STATUS_PORT equ 0x64
PS2_COMMAND_PORT equ 0x64

TIMEOUT equ 100000


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

        and  al, 10111100b
        or   al, 00000011b

        test al, 00100000b
        jnz .init.isDualChannel
	
        or   bl, 00000010b

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
        out PS2_COMMAND_PORT, al ; Performing test on the first port

        call .waitForRead

        in al, PS2_DATA_PORT

        cmp al, 0
        jz .init.pastTest1

        or bl, 1

        .init.pastTest1:

        test bl, 10b
        jnz .init.pastTest2

        mov al, 0xA9
        out PS2_COMMAND_PORT, al ; Performing test on the second port

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
        jmp .init.pastReset1

        .init.Reset1:

        in al, PS2_DATA_PORT
        cmp al, 0xFA
        je .init.Reset1.1

        or bl, 1
        jmp .init.pastReset1

        .init.Reset1.1:

        call .waitForReadT
        jnc .init.Reset1.2

        or bl, 1
        jmp .init.pastReset1

        .init.Reset1.2:

        in al, PS2_DATA_PORT

        cmp al, 0xAA
        je .init.pastReset1

        or bl, 1

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

        or bl, 10b
        jmp .init.pastReset2

        .init.Reset2:

        in al, PS2_DATA_PORT
        cmp al, 0xFA
        jz .init.Reset2.1



        or bl, 10b
        jmp .init.pastReset2

        .init.Reset2.1:

        call .waitForReadT
        jnc .init.Reset2.2

        or bl, 10b
        jmp .init.pastReset2

        .init.Reset2.2:

        in al, PS2_DATA_PORT

        cmp al, 0xAA
        je .init.pastReset2

        or bl, 10b

        .init.pastReset2:

        cmp bl, 11b ; If neither port is useful
        jz .init.error

        mov eax, (0<<16)+1
        mov ecx, ebx
        mov ebx, 1

        call DeviceList.addDevice

        popa
        clc
        ret

        .init.error:
            stc
            popa
            ret

    .initDevices:
        pusha
        mov ax, 1
        mov bx, 1

        call DeviceList.findDevice
        mov ecx, eax
        push eax
        jc .initDevices.pastDevice2

        call DeviceList.getDeviceEntry

        test cl, 1
        jnz .initDevices.pastDevice1

        .initDevices.Device1:

        call .clearOutputBuffer

        call .waitForWriteT
        mov al, 0xF5
        out PS2_DATA_PORT, al ; disable scanning

        call .waitForReadT

        jc .initDevices.pastDevice1

        in al, PS2_DATA_PORT
        cmp al, 0xFE ; resend
        je .initDevices.Device1
        cmp al, 0xFA ; acknowlegement
        jne .initDevices.pastDevice1

        .initDevices.Device1.1:

        call .waitForWriteT
        mov al, 0xF2
        out PS2_DATA_PORT, al ; identify device

        .initDevices.Device1.readResponse:
        call .waitForReadT

        jc .initDevices.pastDevice1

        in al, PS2_DATA_PORT

        cmp al, 0x00
        je .initDevices.Device1.readResponse
        cmp al, 0xFE ; resend
        je .initDevices.Device1.1
        cmp al, 0xFA ; acknowlegement
        jne .initDevices.pastDevice1

        call .waitForReadT

        jc .initDevices.Device1.write

        in al, PS2_DATA_PORT
        mov dl, al

        call .waitForReadT

        jc .initDevices.Device1.write

        in al, PS2_DATA_PORT
        mov dh, al

        .initDevices.Device1.write:

        pop eax
        push eax
        shl eax, 16

        call .whatIsThisDevice

        mov bx, 1
        push ecx
        shl edx, 16
        mov dl, 0
        ror edx, 16
        mov ecx, edx

        call DeviceList.addDevice

        pop ecx

        .initDevices.pastDevice1:

        test cl, 2
        jnz .initDevices.pastDevice2

        .initDevices.Device2:

        call .clearOutputBuffer

        mov al, 0xF5
        call .commandToSecondPort ; disable scanning

        .initDevices.Device2.readResponse:
        call .waitForReadT

        jc .initDevices.pastDevice2

        in al, PS2_DATA_PORT

        cmp al, 0x00
        je .initDevices.Device2.readResponse
        cmp al, 0xFE ; resend
        je .initDevices.Device2
        cmp al, 0xFA ; acknowlegement
        jne .initDevices.pastDevice2

        .initDevices.Device2.1:

        mov al, 0xF2
        call .commandToSecondPort ; identify device

        call .waitForReadT

        jc .initDevices.pastDevice2

        in al, PS2_DATA_PORT
        cmp al, 0xFE ; resend
        je .initDevices.Device2.1
        cmp al, 0xFA ; acknowlegement
        jne .initDevices.pastDevice2

        call .waitForReadT

        jc .initDevices.Device2.write

        in al, PS2_DATA_PORT
        mov dl, al

        call .waitForReadT

        jc .initDevices.Device2.write

        in al, PS2_DATA_PORT
        mov dh, al

        .initDevices.Device2.write:

        pop eax
        push eax
        shl eax, 16

        call .whatIsThisDevice

        mov bx, 1
        push ecx
        shl edx, 16
        mov dl, 1
        ror edx, 16
        mov ecx, edx

        call DeviceList.addDevice

        pop ecx
        .initDevices.pastDevice2:

        pop eax

        popa
        ret

    .whatIsThisDevice: ; dx - identification bytes. Output: ax - Device type
        cmp dx, 0x0
        jne .whatIsThisDevice.1

        mov ax, 0x3
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.1:

        cmp dx, 0x2
        jne .whatIsThisDevice.2

        mov ax, 0x3
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.2:

        cmp dx, 0x3
        jne .whatIsThisDevice.3

        mov ax, 0x3
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.3:

        cmp dx, 0x4
        jne .whatIsThisDevice.4

        mov ax, 0x3
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.4:

        ror dx, 8

        cmp dx, 0xAB83
        jne .whatIsThisDevice.5

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.5:

        cmp dx, 0xAB84
        jne .whatIsThisDevice.6

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.6:

        cmp dx, 0xAB85
        jne .whatIsThisDevice.7

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.7:

        cmp dx, 0xAB86
        jne .whatIsThisDevice.8

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.8:

        cmp dx, 0xAB90
        jne .whatIsThisDevice.9

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.9:

        cmp dx, 0xAB91
        jne .whatIsThisDevice.10

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.10:

        cmp dx, 0xAB92
        jne .whatIsThisDevice.11

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.11:

        cmp dx, 0xABA1
        jne .whatIsThisDevice.12

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.12:

        cmp dx, 0xABC1
        jne .whatIsThisDevice.13

        mov ax, 0x2
        jmp .whatIsThisDevice.end

        .whatIsThisDevice.13:

        mov ax, 0x0

        .whatIsThisDevice.end:

        ret

    .commandToSecondPort: ; al - command;
        push eax
        mov al, 0xD4
        out PS2_COMMAND_PORT, al
        pop eax

        call .waitForWrite

        out PS2_DATA_PORT, al

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
        dec ecx

        cmp ecx, 0
        jz .waitForWriteT.error

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
        dec ecx

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

    .clearOutputBuffer:
        pusha

        .clearOutputBuffer.loop:
            call .waitForReadT
            jc .clearOutputBuffer.loopDone

            in al, PS2_DATA_PORT

            jmp .clearOutputBuffer.loop
        .clearOutputBuffer.loopDone:

        popa
        ret
