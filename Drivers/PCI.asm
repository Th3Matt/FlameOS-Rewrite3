PCI_FunctionDoesNotExist equ 0xFFFFFFFF

PCIDeviceFunctionAmmount equ PCIDriverVariableSpace+0

PCIDriver:
    .detectDevices:
        pusha
        push ds
        push es
        mov word es:[PCIDeviceFunctionAmmount], 0
        mov edi, 0
        mov cx, 0x80
        mov ds, cx
        mov cx, 0x10
        mov es, cx
        mov cx, 0xFFFF
        mov eax, 1<<31
        mov dx, 0xCF8

        .detectDevices.loop:
            out dx, eax

            add dx, 4
            push eax
            in eax, dx
            sub dx, 4

            cmp eax, PCI_FunctionDoesNotExist						; Check if device function exists
            je .detectDevices.loopcont

            mov ds:[edi+4], eax
            pop eax
            push eax
            mov ds:[edi], eax

            or eax, 0x8
            out dx, eax
            add dx, 4
            in eax, dx
            sub dx, 4
            mov ds:[edi+8], eax

            pop eax
            push eax

            or eax, 0x10
            out dx, eax
            add dx, 4
            in eax, dx
            sub dx, 4
            mov ds:[edi+12], eax

            pop eax
            push eax

            or eax, 0x14
            out dx, eax
            add dx, 4
            in eax, dx
            sub dx, 4
            mov ds:[edi+16], eax

            pop eax
            push eax

            or eax, 0x18
            out dx, eax
            add dx, 4
            in eax, dx
            sub dx, 4
            mov ds:[edi+20], eax

            pop eax
            push eax

            or eax, 0x1B
            out dx, eax
            add dx, 4
            in eax, dx
            sub dx, 4
            mov ds:[edi+24], eax

            pop eax
            push eax

            or eax, 0x20
            out dx, eax
            add dx, 4
            in eax, dx
            sub dx, 4
            mov ds:[edi+28], eax

            inc word es:[PCIDeviceFunctionAmmount]
            add edi, 0x20

        .detectDevices.loopcont:
            pop eax
            shr eax, 8
            inc eax
            shl eax, 8
            loop .detectDevices.backToLoop

        .detectDevices.done:
            pop es
            pop ds
            popa
            ret

        .detectDevices.backToLoop: ; loop instruction can't jump back far enough
            jmp .detectDevices.loop

    .deviceInfoByDword3: ; eax - (Class << 12) + (Subclass << 8) + (ProgIF << 4) + #, ebx - offset in table. Output: eax - Requested data
        push ecx
        push edi
        push ds
        push ebx

        mov di, 0x10
        mov ds, di
        mov ecx, [ds:PCIDeviceFunctionAmmount]

        mov di, 0x80
        mov ds, di

        xor edi, edi

        .deviceInfoByDword3.loop:
            mov ebx, [ds:edi+8]
            and bl, 0x0
            cmp eax, ebx
            je .deviceInfoByDword3.loop.found

            .deviceInfoByDword3.loop.2:
            add edi, 0x20

            loop .deviceInfoByDword3.loop

        stc

        .deviceInfoByDword3.loop.done:

        pop ebx
        pop ds
        pop edi
        pop ecx
        ret

        .deviceInfoByDword3.loop.found:
            cmp al, 0
            jz .deviceInfoByDword3.read
            dec eax
            jmp .deviceInfoByDword3.loop.2

        .deviceInfoByDword3.read:
            pop ebx
            push ebx

            shl ebx, 2
            add edi, ebx

            mov eax, [ds:edi]

            clc
            jmp .deviceInfoByDword3.loop.done

    .printDeviceTable:
        pusha
        push ds

        push es
        mov ax, 0x38
        mov es, ax
        xor edi, edi

        mov ecx, 800*600
        xor eax, eax
        rep stosd
        pop es

        mov ax, 0x28
        mov ds, ax

        mov eax, 0xffffffff
        xor edx, edx
        mov esi, .deviceTableTop+1-0x20000
        mov edi, [ds:esi-1]
        shl edi, 24
        shr edi, 24

        call Print.string

        push es
        mov cx, 0x80
        mov es, cx

        push ds
        mov cx, 0x10
        mov ds, cx

        xor ecx, ecx
        mov cx, ds:[PCIDeviceFunctionAmmount]
        pop ds

        xor ebx, ebx

        .deviceTablePrint.Print:
            call .deviceTablePrint.draw
            add ebx, 0x20
            loop .deviceTablePrint.Print

        pop es
        pop ds
        popa
        ret

        .deviceTablePrint.draw: ; ebx - device #
            push ecx
            mov esi, .deviceTableEntry+1-0x20000
            mov edi, 4

            call Print.string

            mov ecx, [es:ebx]

            call Print.hex32

            mov edi, 5
            add esi, 4

            call Print.string

            mov ecx, [es:ebx+4]

            call Print.hex32

            mov edi, 5
            add esi, 5

            call Print.string

            mov ecx, [es:ebx+8]

            call Print.hex32

            mov edi, 5
            add esi, 5

            call Print.string


            mov ecx, [es:ebx+12]

            call Print.hex32

            mov edi, 5
            add esi, 5

            call Print.string

            mov ecx, [es:ebx+16]

            call Print.hex32

            mov edi, 5
            add esi, 5

            call Print.string

            mov ecx, [es:ebx+20]

            call Print.hex32

            mov edi, 3
            add esi, 5

            call Print.string

            mov esi, .deviceTableEnd+1-0x20000
            mov edi, [ds:esi-1]
            shl edi, 24
            shr edi, 24

            call Print.string

            pop ecx
            ret

    .deviceTableTop: db .deviceTableEntry-.deviceTableTop-1
        db "|-----------------------------------------------------------------------------|", 10
        db "| ID         | V/D_ID     | C/SC       | BAR0       | BAR1       | BAR2       |", 10
        db "|-----------------------------------------------------------------------------|", 10

    .deviceTableEntry: db .deviceTableEnd-.deviceTableEntry-1
        db "| 0x",     " | 0x",     " | 0x",     " | 0x",     " | 0x",     " | 0x",     " |", 10

    .deviceTableEnd: db .deviceTable.end-.deviceTableEnd-1
        db "|-----------------------------------------------------------------------------|", 10
    .deviceTable.end:
