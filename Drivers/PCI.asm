PCI_FunctionDoesNotExist equ 0xFFFFFFFF

PCIDeviceFunctionAmmount equ PCIDriverVariableSpace+0
PCITableEntrySize equ 0x100

; PCI Table Entry Parts
    PCIT.DEV_ID equ 0x00 ; Device ID
    PCIT.VENDID equ 0x00 ; Vendor ID

    PCIT.STAT   equ 0x04 ; Status register
    PCIT.COM    equ 0x04 ; Command register

    PCIT.CLASS  equ 0x08 ; Class code
    PCIT.SCLASS equ 0x08 ; Subclass code
    PCIT.PROGIF equ 0x08 ; Prog IF
    PCIT.REVID  equ 0x08 ; Revision ID

    PCIT.BIST   equ 0x0C ; BIST
    PCIT.HEADT  equ 0x0C ; Header Type
    PCIT.LTIMER equ 0x0C ; Latency Timer
    PCIT.CACHES equ 0x0C ; Cache Line Size

    PCIT.BAR0   equ 0x10 ; Base address #0

    PCIT.BAR1   equ 0x14 ; Base address #1

    PCIT.BAR2   equ 0x18 ; Base address #2

    PCIT.BAR3   equ 0x1C ; Base address #3

    PCIT.BAR4   equ 0x20 ; Base address #4

    PCIT.BAR5   equ 0x24 ; Base address #5

    PCIT.CBCISP equ 0x28 ; Cardbus CIS Pointer

    PCIT.SSYSID equ 0x2C ; Subsystem ID
    PCIT.SSVID  equ 0x2C ; Subsystem Vendor ID

    PCIT.EROMBA equ 0x30 ; Expansion ROM base address

    PCIT.RESV   equ 0x34 ; Reserved
    PCIT.C_P    equ 0x34 ; Capabilities Pointer

    PCIT.RESV2  equ 0x38 ; Reserved

    PCIT.MaxL   equ 0x3C ; Max latency
    PCIT.MinG   equ 0x3C ; Min Grant
    PCIT.I_PIN  equ 0x3C ; Interrupt PIN
    PCIT.I_Line equ 0x3C ; Interrupt Line

PCIDriver:
    .detectDevices:
        pusha
        push ds
        push es

        mov word es:[PCIDeviceFunctionAmmount], 0
        mov edi, 0
        mov cx, Segments.PCIDriverData
        mov ds, cx
        mov cx, Segments.Variables
        mov es, cx
        mov cx, 0xFFFF
        mov eax, 1<<31
        mov edx, 0xCF8

        .detectDevices.loop:
            out dx, eax

            add dx, 4
            push ecx
            push eax
            in eax, dx
            sub dx, 4

            cmp eax, PCI_FunctionDoesNotExist						; Check if device function exists

            je .detectDevices.loopcont

            mov ds:[edi+4], eax
            pop eax
            push eax
            mov ds:[edi], eax

            call .updateDeviceInfo

            inc word es:[PCIDeviceFunctionAmmount]
            add edi, PCITableEntrySize

        .detectDevices.loopcont:
            pop eax
            pop ecx
            shr eax, 8
            inc eax
            shl eax, 8
            loop .detectDevices.loop

        .detectDevices.done:
            pop es
            pop ds
            popa
            ret


    .updateDeviceInfo: ; edi - data location
        push edx
        push esi
        push ds

        mov esi, 4
        mov dx, Segments.PCIDriverData
        mov ds, dx
        mov edx, 0xCF8

        .updateDeviceInfo.loop:
            push eax

            or eax, esi
            out dx, eax
            add dx, 4
            in eax, dx
            sub dx, 4
            add esi, 4
            mov ds:[edi+esi], eax

            pop eax

            cmp esi, PCITableEntrySize-4
            jl .updateDeviceInfo.loop

        pop ds
        pop esi
        pop edx
        ret

    .deviceInfoByDword3: ; eax - (Class << 12) + (Subclass << 8) + (ProgIF << 4) + #, ebx - register in table. Output: eax - Requested data
        push ecx
        push edi
        push ds
        push ebx

        mov di, Segments.Variables
        mov ds, di
        mov ecx, [ds:PCIDeviceFunctionAmmount]
        cmp ecx, 0
        jz .deviceInfoByDword3.loop.error

        mov di, Segments.PCIDriverData
        mov ds, di

        xor edi, edi

        .deviceInfoByDword3.loop:
            mov ebx, [ds:edi+12]
            and bl, 0x0
            cmp eax, ebx
            je .deviceInfoByDword3.loop.found

            .deviceInfoByDword3.loop.2:
            add edi, PCITableEntrySize

            loop .deviceInfoByDword3.loop

        .deviceInfoByDword3.loop.error:
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

    .deviceByLocation: ; eax - (Bus << 16) + (Device << 11) + (Function << 8). Output: edi - data location
        push eax
        push ebx
        push ecx
        push ds

        mov di, Segments.Variables
        mov ds, di
        mov ecx, [ds:PCIDeviceFunctionAmmount]
        cmp ecx, 0
        jz .deviceByLocation.loop.error

        mov di, Segments.PCIDriverData
        mov ds, di

        xor edi, edi
        and eax, 0x00FFFF00

        .deviceByLocation.loop:
            mov ebx, [ds:edi]
            and ebx, 0x00FFFF00
            cmp eax, ebx
            clc
            je .deviceByLocation.loop.done

            .deviceByLocation.loop.2:
            add edi, PCITableEntrySize

            loop .deviceByLocation.loop

        .deviceByLocation.loop.error:
        stc

        .deviceByLocation.loop.done:

        pop ds
        pop ecx
        pop ebx
        pop eax
        ret

    .deviceInfoByLocation: ; eax - (Bus << 16) + (Device << 11) + (Function << 8), ebx - register in table. Output: eax - Requested data
        push edi

        call .deviceByLocation
        jc .deviceInfoByLocation.end

        push ds
        push ebx

        push edi
        mov di, Segments.PCIDriverData
        mov ds, di
        pop edi

        shl ebx, 2
        add edi, ebx

        mov eax, [ds:edi]
        pop ebx
        pop ds
        clc

        .deviceInfoByLocation.end:

        pop edi
        ret

    .updateDeviceInfoByLocation: ; eax - (Bus << 16) + (Device << 11) + (Function << 8)
        push eax
        push edi

        call .deviceByLocation
        jc .updateDeviceInfoByLocation.end

        call .updateDeviceInfo

        clc

        .updateDeviceInfoByLocation.end:

        pop edi
        pop eax

        ret


    .sendToDevice: ; eax - (Bus << 16) + (Device << 11) + (Function << 8) + offset, ebx - dword to send.
        push eax
        push edx
        mov dx, 0xCF8

        and eax, 0x00FFFFFF
        or eax, 1<<31
        add eax, 4

        out dx, eax
        add dx, 4

        mov eax, ebx
        out dx, eax

        pop edx
        pop eax
        ret

    .getStatus: ; eax - (Bus << 16) + (Device << 11) + (Function << 8). Output: ax - status.
        push edx
        mov dx, 0xCF8

        and eax, 0x00FFFF00
        or eax, 1<<31
        add eax, 4

        out dx, eax
        add dx, 4

        in eax, dx
        shr eax, 16

        pop edx
        ret

    .checkCapability: ; eax - (Bus << 16) + (Device << 11) + (Function << 8), bx - capability ID, ecx - register offset. Output: eax - Requested data
        push edi

        call .deviceByLocation
        jc .checkCapability.end

        push ds

        push edi
        mov di, Segments.PCIDriverData
        mov ds, di
        pop edi
        push edi

        add edi, (0xD+1)<<2

        mov edi, [ds:edi]

        pop eax ; pop edi
        add edi, eax

        .checkCapability.capabilityLoop:
        add edi, 4 ; account for one extra value at start of table

        cmp bl, [ds:edi]
        jz .checkCapability.capabilityFound

        push ebx

        mov bx, [ds:edi+1]
        and bx, 0xFF
        cmp bx, 0
        jz .checkCapability.capabilityNotFound

        and edi, 0x00FFFF00
        add di, bx

        pop ebx

        jmp .checkCapability.capabilityLoop

        .checkCapability.capabilityNotFound:
            pop ebx
            pop ds
            stc

            jmp .checkCapability.end

        .checkCapability.capabilityFound:

        mov eax, [ds:edi+ecx]

        clc

        pop ds

        .checkCapability.end:

        pop edi
        ret

    .getBAR: ; eax - (Bus << 16) + (Device << 11) + (Function << 8), ebx - BAR number. Output: eax - LDT segment/IO address, ebx - size.
        push edi

        call .deviceByLocation
        jc .deviceInfoByLocation.end

        push ecx
        push eax

        push ds
        push ebx

        push edi
        mov di, Segments.PCIDriverData
        mov ds, di
        pop edi

        add ebx, 4 ; adding BAR0 register number
        inc ebx
        shl ebx, 2
        add edi, ebx

        mov eax, [ds:edi]
        pop ebx
        pop ds
        mov ecx, eax
        pop ecx

        cmp ecx, 0
        jz .getBAR.emptyBAR

        test ecx, 1
        jz .getBAR.mmioAddress

        call .getSizeOfBAR

        mov ebx, eax
        mov eax, ecx

        pop eax
        clc

        .getBAR.end:
        pop edi

        ret

        .getBAR.mmioAddress:
            pop eax
            stc
            jmp .getBAR.end

        .getBAR.emptyBAR:
            pop eax
            stc
            cmp eax, eax ; set zero flag
            jmp .getBAR.end

    .getSizeOfBAR: ; eax - (Bus << 16) + (Device << 11) + (Function << 8), ebx - BAR number. Output: eax - size
        push edx
        mov dx, 0xCF8

        and eax, 0x00FFFF00
        or eax, 1<<31
        add eax, 4

        shl ebx, 2
        add ebx, PCIT.BAR0<<2
        add eax, ebx

        push eax
        out dx, eax
        add dx, 4

        xor eax, eax
        not eax

        out dx, eax ; request size

        pop eax
        sub dx, 4
        out dx, eax
        add dx, 4

        in eax, dx
        not eax

        pop edx
        ret

    .printDeviceTable:
        pusha
        push ds

        push es
        mov ax, Segments.VRAM_Graphics
        mov es, ax
        xor edi, edi

        mov ecx, 800*600
        xor eax, eax
        rep stosd
        pop es

        mov ax, Segments.KernelCode
        mov ds, ax

        mov eax, 0xffffffff
        xor edx, edx
        mov esi, .deviceTableTop

        push ecx
        xor ecx, ecx

        call Print.string

        pop ecx

        push es
        mov cx, Segments.PCIDriverData
        mov es, cx

        push ds
        mov cx, Segments.Variables
        mov ds, cx

        xor ecx, ecx
        mov cx, ds:[PCIDeviceFunctionAmmount]
        pop ds

        xor ebx, ebx

        .deviceTablePrint.Print:
            call .deviceTablePrint.draw
            add ebx, PCITableEntrySize
            loop .deviceTablePrint.Print

        pop es
        pop ds
        popa
        ret

        .deviceTablePrint.draw: ; ebx - device #
            push ecx
            mov esi, .deviceTableEntry+1
            mov edi, 4

            xor ecx, ecx

            call Print.stringWithSize

            push ebx
            mov ebx, [es:ebx]

            call Print.hex32
            pop ebx

            mov edi, 5
            add esi, 4

            call Print.stringWithSize

            push ebx

            mov ebx, [es:ebx+4]

            call Print.hex32
            pop ebx

            mov edi, 5
            add esi, 5

            call Print.stringWithSize

            push ebx
            mov ebx, [es:ebx+12]

            call Print.hex32
            pop ebx

            mov edi, 5
            add esi, 5

            call Print.stringWithSize

            push ebx
            mov ebx, [es:ebx+20]

            call Print.hex32
            pop ebx

            mov edi, 5
            add esi, 5

            call Print.stringWithSize

            push ebx
            mov ebx, [es:ebx+24]

            call Print.hex32
            pop ebx

            mov edi, 5
            add esi, 5

            call Print.stringWithSize

            push ebx
            mov ebx, [es:ebx+28]

            call Print.hex32
            pop ebx

            mov edi, 3
            add esi, 5

            call Print.stringWithSize

            mov esi, .deviceTableEnd

            call Print.string

            call Print.refresh
            pop ecx
            ret

    section .rodata

    .deviceTableTop: db .deviceTableEntry-.deviceTableTop-1
        db "|-----------------------------------------------------------------------------|", 10
        db "| ID         | V/D_ID     | C/SC       | BAR0       | BAR1       | BAR2       |", 10
        db "|-----------------------------------------------------------------------------|", 10

    .deviceTableEntry: db .deviceTableEnd-.deviceTableEntry-1
        db "| 0x",     " | 0x",     " | 0x",     " | 0x",     " | 0x",     " | 0x",     " |", 10

    .deviceTableEnd: db .deviceTable.end-.deviceTableEnd-1
        db "|-----------------------------------------------------------------------------|", 10
    .deviceTable.end:

    section .text
