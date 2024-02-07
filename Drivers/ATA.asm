
ATA1    equ 0x1F0 ; ATA bus 1
ATA1_C  equ 0x3F6 ; ATA bus 1 control
ATA2    equ 0x170 ; ATA bus 2
ATA2_C  equ 0x376 ; ATA bus 2 control

ATA_DR  equ 0 ; Data register                 ; RW ; 16
ATA_ER  equ 1 ; Error register                ; R  ; 8
ATA_FR  equ 1 ; Features register             ; W  ; 8
ATA_SCR equ 2 ; Sector count register         ; RW ; 8
ATA_LL  equ 3 ; Sector # / LBA low byte       ; RW ; 8
ATA_LM  equ 4 ; Cylinder low / LBA mid byte   ; RW ; 8
ATA_LH  equ 5 ; Cylinder high / LBA high byte ; RW ; 8
ATA_DHR equ 6 ; Drive / head register         ; RW ; 8
ATA_SR  equ 7 ; Status register               ; R  ; 8
ATA_CR  equ 7 ; Command register              ; W  ; 8

ATA_ASR equ 0 ; Alternative status register   ; R  ; 8
ATA_DCR equ 0 ; Device control register       ; W  ; 8
ATA_DAR equ 1 ; Drive address register        ; R  ; 8

ATA_STATUS_ERR  equ 00000001b    ; Error
ATA_STATUS_IDX  equ 00000010b    ; Index
ATA_STATUS_CORR equ 00000100b    ; Corrected data
ATA_STATUS_DRQ  equ 00001000b    ; Data request
ATA_STATUS_SRV  equ 00010000b    ; Overlapped mode service request
ATA_STATUS_DF   equ 00100000b    ; Drive fault (no ERR)
ATA_STATUS_RDY  equ 01000000b    ; Ready
ATA_STATUS_BSY  equ 10000000b    ; Busy

ATA_ERR_BBLK equ 10000000b    ; Bad block
ATA_ERR_UNC  equ 01000000b    ; Uncorrectable data
ATA_ERR_MC   equ 00100000b    ; Media changed
ATA_ERR_IDNF equ 00010000b    ; ID mark not found
ATA_ERR_MCR  equ 00001000b    ; Media change request
ATA_ERR_CMAB equ 00000100b    ; Command aborted
ATA_ERR_T0NF equ 00000010b    ; Track 0 not found
ATA_ERR_NADM equ 00000001b    ; No address mark

ADB     equ DiskDriverVariableSpace+0    ; Available disk bus' bitmap
ABAddr1 equ DiskDriverVariableSpace+2    ; ATA bus 1 IO address
ABAddr2 equ DiskDriverVariableSpace+4    ; ATA bus 2 IO address
ADA1    equ DiskDriverVariableSpace+0x10 ; ATA disk availability field for bus 1
ADA2    equ DiskDriverVariableSpace+0x11 ; ATA disk availability field for bus 2

EndOfATADriverSpace equ DiskDriverVariableSpace+0x20

ATA.CMD.READ.PIO      equ 0x20
ATA.CMD.READ.DMA_EXT  equ 0x25
ATA.CMD.WRITE.PIO     equ 0x30
ATA.CMD.IDENTIFY      equ 0xEC

ATA_MAX_DRIVE_ERRORS equ 3

S_ATA_PI:
    .delay400: ; dx - ATA status register port
        pusha
        mov ecx, 15
        .delay400.1:
            in al, dx
            loop .delay400.1
        popa
        ret

    .detectDevices:
        push ds
        push es
        push fs
        push edx

        mov dx, Segments.Variables
        mov es, dx

        mov dx, Segments.KernelCode
        mov ds, dx

        test byte es:[CustomSetting], 1
        jnz .detectDevices.bus2

        mov eax, 0x01018000
        xor ebx, ebx

        call PCIDriver.deviceInfoByDword3
        jc .detectDevices.nonExistantBus

        call PCIDriver.getBAR
        jz .detectDevices.bus1.defaultPort
        jc .detectDevices.nonExistantBus
        and eax, 0xFFFFFFFC ; we are sure that this will be a IO port so we immediately process it
        mov edx, eax

        jmp .detectDevices.bus1.nonDefault

        .detectDevices.bus1.defaultPort:
        mov edx, ATA1

        .detectDevices.bus1.nonDefault:

        mov es:[ABAddr1], dx

        add dx, ATA_SR

        in al, dx

        inc al
        jz .detectDevices.bus1OFF

        mov ebx, 0
        pop edi  ; pop edx
        call .checkATABus
        push edi ; push edx
        test byte es:[ADA1], 00010001b
        jz .detectDevices.bus1OFF

        or byte es:[ADB], 1

        .detectDevices.bus2:

        test byte es:[CustomSetting], 10b
        jnz .detectDevices.bus2Done

        ;jmp .detectDevices.bus2Done ; Skip bus 2

        mov eax, 0x01018000
        xor ebx, ebx

        call PCIDriver.deviceInfoByDword3
        jc .detectDevices.nonExistantBus

        mov ebx, 2
        call PCIDriver.getBAR
        jz .detectDevices.bus2.defaultPort
        jc .detectDevices.nonExistantBus
        and eax, 0xFFFFFFFC ; we are sure that this will be a IO port so we immediately process it
        mov edx, eax

        jmp .detectDevices.bus2.nonDefault

        .detectDevices.bus2.defaultPort:
        mov edx, ATA2

        .detectDevices.bus2.nonDefault:

        mov es:[ABAddr2], dx

        add dx, ATA_SR

        in al, dx

        inc al
        jz .detectDevices.bus2OFF

        mov ebx, 1
        pop edi  ; pop edx
        call .checkATABus
        push edi ; push edx

        test byte es:[ADA2], 00010001b
        jz .detectDevices.bus2OFF

        or byte es:[ADB], 2

        .detectDevices.bus2Done:
        pop edx
        pop fs
        pop es
        pop ds
        ret

        .detectDevices.bus1OFF:
            pop edx

            push eax
            push ecx

            xor ecx, ecx
            xor eax, eax
            not eax
            mov esi, .Driver_Message_Prefix

            call Print.string

            mov esi, .noBus1Message

            call Print.string

            pop ecx

            pop eax
            push edx
            jmp .detectDevices.bus2

        .detectDevices.bus2OFF:
            pop edx

            push eax
            push ecx

            xor ecx, ecx
            xor eax, eax
            not eax
            mov esi, .Driver_Message_Prefix

            call Print.string

            mov esi, .noBus2Message

            call Print.string

            pop ecx

            pop eax
            push edx
            test byte es:[ADB], 1
            jnz .detectDevices.bus2Done

        .detectDevices.nonExistantBus:
            pop edx
        .detectDevices.allBusOFF:
            push ecx

            xor ecx, ecx
            xor eax, eax
            not eax
            mov esi, .Driver_Message_Prefix

            call Print.string

            mov eax, 0x00CC0000
            mov esi, .noBusOnMessage

            call Print.string

            pop ecx

            ;hlt
            ;jmp $-1

            push edx
            jmp .detectDevices.bus2Done

    .checkATABus: ; dx - ATA status register port, edi - Terminal printing location, ebx - Bus #
        push eax
        push ecx
        push edx
        push esi

        .checkATABus.Disk1:

        push edx
        push ecx

        mov edx, edi

        xor ecx, ecx
        xor eax, eax
        not eax
        mov esi, .Driver_Message_Prefix

        call Print.string

        mov esi, .noBus1Message
        mov edi, 6

        call Print.stringWithSize

        push ebx

        add ebx, '0'
        call Print.char

        inc edx
        mov ebx, ":"
        call Print.char

        inc edx
        mov ebx, "0"
        call Print.char

        inc edx
        mov ebx, ")"
        call Print.char

        inc edx
        mov edi, edx

        pop ebx
        pop ecx
        pop edx

        dec edx

        mov al, 10100000b ; LBA, Disk 0
        out dx, al

        call .checkATABus.checkDisk

        .checkATABus.Disk2:

        push edx
        push ecx

        mov edx, edi

        xor ecx, ecx
        xor eax, eax
        not eax
        mov esi, .Driver_Message_Prefix

        call Print.string

        mov esi, .noBus1Message
        mov edi, 6

        call Print.stringWithSize

        push ebx

        add ebx, '0'
        call Print.char

        inc edx
        mov ebx, ":"
        call Print.char

        inc edx
        mov ebx, "1"
        call Print.char

        inc edx
        mov ebx, ")"
        call Print.char

        inc edx
        mov edi, edx

        pop ebx
        pop ecx
        pop edx

        mov al, 10110000b ; LBA, Disk 1
        out dx, al

        call .checkATABus.checkDisk

        .checkATABus.end:

        pop esi
        pop edx
        pop ecx
        pop eax
        ret

        .checkATABus.checkDisk:
            push edx

            inc edx
            call .delay400

            dec edx
            dec edx
            xor eax, eax
            out dx, al ; LBA high byte

            dec edx
            out dx, al ; LBA mid byte

            dec edx
            out dx, al ; LBA low byte

            dec edx
            out dx, al ; Sector count register

            add edx, 5
            mov eax, ATA.CMD.IDENTIFY

            out dx, al ; Command register

            in al, dx  ; Status register
            cmp al, 0
            jnz .checkATABus.checkDisk.1

            .checkATABus.checkDisk.noDisk:
            call .checkATABus.Disks.noDisk

            jmp .checkATABus.checkDisk.end

            .checkATABus.checkDisk.1:
            cmp al, 0xFF
            je .checkATABus.checkDisk.noDisk

            test al, ATA_STATUS_ERR
            jnz .checkATABus.checkDisk.loop1.done

            mov ecx, 1000000                   ; some random timeout number

            .checkATABus.checkDisk.loop1:
                dec ecx
                jnz .checkATABus.checkDisk.2

                call .checkATABus.Disks.noDisk ; timeout
                jmp .checkATABus.checkDisk.end

                .checkATABus.checkDisk.2:
                in al, dx ; Status register
                test al, ATA_STATUS_BSY
                jnz .checkATABus.checkDisk.loop1

            .checkATABus.checkDisk.loop1.done:
            dec edx
            dec edx

            in al, dx ; LBA high byte
            dec edx
            push ax

            cmp al, 0
            jz .checkATABus.checkDisk.3

            call .checkATABus.Disks.notATA
            pop ax
            jmp .checkATABus.checkDisk.end

            .checkATABus.checkDisk.3:

            in al, dx ; LBA mid byte

            cmp al, 0
            jz .checkATABus.checkDisk.4

            call .checkATABus.Disks.notATA.1
            pop ax
            jmp .checkATABus.checkDisk.end

            .checkATABus.checkDisk.4:
            pop ax

            add edx, 3
            mov ecx, ATA_MAX_DRIVE_ERRORS

            .checkATABus.checkDisk.loop2:
                in al, dx ; Status register
                test al, (ATA_STATUS_ERR|ATA_STATUS_DF)
                jz .checkATABus.checkDisk.5
                call .checkATABus.Disks.error
                jc .checkATABus.checkDisk.end

                dec dx

                jmp .checkATABus.checkDisk

                .checkATABus.checkDisk.5:

                test al, ATA_STATUS_DRQ
                jz .checkATABus.checkDisk.loop2

            sub edx, 7
            mov ecx, 256

            .checkATABus.checkDisk.6:
                rep in ax, dx ; Data register
                loop .checkATABus.checkDisk.6

            mov esi, .ATA___Message
            push edx

            mov edx, edi
            xor eax, eax
            not eax

            push ecx
            xor ecx, ecx

            call Print.string

            pop ecx

            mov edi, edx

            pop edx

            push eax
            xor eax, eax
            or  al, 00000001b ; ATA, Present
            ror al, 4
            mov es:[ebx+ADA1], al
            pop eax

            .checkATABus.checkDisk.end:

            pop edx

            ret

        .checkATABus.Disks.notATA:
            in al, dx

            .checkATABus.Disks.notATA.1:

            shl eax, 16
            add esp, 4
            pop ax
            sub esp, 6
            shl ax, 8
            shr eax, 8

            cmp ax, 0x14EB
            jne .checkATABus.Disks.notATAPI

            mov esi, .ATAPI_Message
            push edx

            mov edx, edi
            xor eax, eax
            not eax

            push ecx
            xor ecx, ecx

            call Print.string

            pop ecx

            mov edi, edx

            push eax
            mov al, es:[ebx+ADA1]
            and al, 0xF0
            or  al, 00000011b ; ATAPI, Present
            ror al, 4
            mov es:[ebx+ADA1], al
            pop eax

            pop edx
            ret

            .checkATABus.Disks.notATAPI:

            cmp ax, 0x3CC3
            jne .checkATABus.Disks.notSATA

            mov esi, .SATA__Message
            push edx

            mov edx, edi
            xor eax, eax
            not eax

            push ecx
            xor ecx, ecx

            call Print.string

            pop ecx

            mov edi, edx

            push eax
            mov al, es:[ebx+ADA1]
            and al, 0xF0
            or  al, 00000101b ; SATA, Present
            ror al, 4
            mov es:[ebx+ADA1], al
            pop eax

            pop edx
            ret

            .checkATABus.Disks.notSATA:

            mov esi, .UKNWN_Message
            push edx

            mov edx, edi
            xor eax, eax
            not eax

            push ecx
            xor ecx, ecx

            call Print.string

            pop ecx

            mov edi, edx

            push eax
            mov al, es:[ebx+ADA1]
            and al, 0xF0
            or  al, 00001001b ; Unknown, Present
            ror al, 4
            mov es:[ebx+ADA1], al
            pop eax

            pop edx

            ret

        .checkATABus.Disks.error:
            mov esi, .Error_Message
            push edx

            mov edx, edi
            xor eax, eax
            not eax

            push ecx
            xor ecx, ecx

            call Print.string

            pop ecx

            mov edi, edx

            pop edx

            dec ecx

            jz .checkATABus.Disks.error.1
            ret

            .checkATABus.Disks.error.1:

            mov esi, .Fail__Message
            push edx

            mov edx, edi
            xor eax, eax
            not eax

            push ecx
            xor ecx, ecx

            call Print.string

            pop ecx

            mov edi, edx

            pop edx

            stc
            ret

        .checkATABus.Disks.noDisk:
            mov esi, .noDiskMessage
            push edi
            push edx

            mov edx, edi
            xor eax, eax
            not eax

            push ecx
            xor ecx, ecx

            call Print.string

            pop ecx

            mov edi, edx

            push eax
            mov al, es:[ebx+ADA1]
            and al, 0xF0
            ror al, 4
            mov es:[ebx+ADA1], al
            pop eax

            pop edx
            sub edx, 4
            pop edi
            ret

    .readSectors:   ; eax - starting sector, ebx - disk #, ecx - sectors to read, fs:edi - buffer.
        pusha
        push ds
        push ecx
        mov ecx, 10

        mov dx, Segments.Variables
        mov ds, dx

        test ebx, 1
        jnz .readSectors.secondDisk

        .readSectors.firstDisk:

        shr ebx, 1

        mov esi, ADA1
        add esi, ebx

        mov dl, ds:[esi]

        and dl, 1111b

        cmp dl, 0001b
        jne .readSectors.notATA

        .readSectors.firstDisk.ATA:

        xor esi, esi
        mov si,  ABAddr1
        shl ebx, 1
        add esi, ebx
        mov dx,  ds:[esi]

        add dx,  ATA_DHR

        push eax

        shr eax, 24
        and al,  00001111b
        or  al,  11100000b

        jmp .readSectors.ATA.prepareForReading

        .readSectors.secondDisk:

        shr ebx, 1

        mov esi, ADA1
        add esi, ebx

        mov dl, ds:[esi]

        and dl, 11110000b

        cmp dl, 00010000b
        jne .readSectors.notATA

        .readSectors.secondDisk.ATA:

        xor esi, esi
        mov si,  ABAddr1
        shl ebx, 1
        add esi, ebx
        mov dx,  ds:[esi]

        add dx,  ATA_DHR

        push eax

        shr eax, 24
        and al,  00001111b
        or  al,  11110000b

        .readSectors.ATA.prepareForReading:

        out dx,  al

        inc dx

        call .delay400

        .readSectors.ATA.retryRead:

        dec dx
        dec dx

        pop  eax
        push eax

        shr eax, 16

        out dx,  al

        pop  eax
        push eax

        shr eax, 8
        dec dx

        out dx,  al

        pop eax

        dec dx

        out dx,  al

        pop eax ; pop ecx
        push eax ; push ecx
        dec dx

        out dx,  al

        add dx,  ATA_CR-2
        mov al,  ATA.CMD.READ.PIO

        out dx, al

        call .ATA.waitUntilDone
        jc .readSectors.ATA.error.check

        sub dx, 7
        ;shl ecx, 9
        pop eax ; pop ecx

        push es

        push edx
        mov dx, fs
        mov es, dx
        pop edx

        .readSectors.ATA.read:
        dec eax
        mov ecx, 128

        rep insd

        cmp eax, 0
        jnz .readSectors.ATA.recheck

        pop es

        .readSectors.ATA.done:
            clc
        .readSectors.ATA.end:
            pop ds
            popa
            ret

        .readSectors.ATA.error.es:
            pop es

        .readSectors.ATA.error:
            stc
            jmp .readSectors.ATA.end

        .readSectors.ATA.error.check:
            dec ecx
            jnz .readSectors.ATA.retryRead
            pop ecx
            jmp .readSectors.ATA.error

        .readSectors.notATA:
            pop ecx
            jmp .readSectors.ATA.error

        .readSectors.ATA.recheck:
            add edx, ATA_CR
            call .delay400
            call .ATA.waitUntilDone
            jc .readSectors.ATA.error.es
            sub edx, ATA_CR
            jmp .readSectors.ATA.read

    .writeSectors:   ; eax - starting sector, ebx - disk #, ecx - sectors to write, esi - buffer, fs - buffer selector.
        pusha
        push ds

        mov dx, Segments.Variables
        mov ds, dx

        test ebx, 1
        jnz .writeSectors.secondDisk

        .writeSectors.firstDisk:

        shr ebx, 1

        mov edi, ADA1
        add edi, ebx

        mov dl, ds:[edi]

        and dl, 1111b

        cmp dl, 0001b
        jne .writeSectors.notATA

        .writeSectors.firstDisk.ATA:

        xor edi, edi
        mov di,  ABAddr1
        shl ebx, 1
        add edi, ebx
        mov dx,  ds:[edi]

        add dx,  ATA_DHR

        push eax

        shr eax, 24
        and al,  00001111b
        or  al,  11100000b

        out dx,  al

        inc dx

        call .delay400

        dec dx
        dec dx

        pop  eax
        push eax

        shr eax, 16

        out dx,  al

        pop  eax
        push eax

        shr eax, 8
        dec dx

        out dx,  al

        pop  eax

        dec dx

        out dx,  al

        mov eax, ecx
        dec dx

        out dx,  al

        add dx,  ATA_CR-2
        mov al,  ATA.CMD.READ.PIO

        out dx, al

        call .ATA.waitUntilDone
        jc .writeSectors.ATA.error

        sub dx, 7
        shl ecx, 7

        push es

        push edx
        mov dx, fs
        mov es, dx
        pop edx

        rep outsd

        pop es

        jmp .writeSectors.ATA.done

        .writeSectors.secondDisk:

        shr ebx, 1

        mov edi, ADA1
        add edi, ebx

        mov dl, ds:[edi]

        and dl, 1111b

        cmp dl, 0001b
        jne .writeSectors.notATA

        .writeSectors.secondDisk.ATA:

        xor edi, edi
        mov di,  ABAddr1
        shl ebx, 1
        add edi, ebx
        mov dx,  ds:[edi]

        add dx,  ATA_DHR

        push eax

        shr eax, 24
        and al,  00001111b
        or  al,  11110000b

        out dx,  al

        inc dx

        call .delay400

        dec dx
        dec dx

        pop  eax
        push eax

        shr eax, 16

        out dx,  al

        pop  eax
        push eax

        shr eax, 8
        dec dx

        out dx,  al

        pop eax

        dec dx

        out dx,  al

        mov eax, ecx
        dec dx

        out dx,  al

        add dx,  ATA_CR-2
        mov al,  ATA.CMD.WRITE.PIO

        out dx, al

        call .ATA.waitUntilDone
        jc .writeSectors.ATA.error

        sub dx, 7
        shl ecx, 7

        push es

        push edx
        mov dx, fs
        mov ds, dx
        pop edx

        rep outsd

        pop es

        .writeSectors.ATA.done:
            clc
        .writeSectors.ATA.end:
            pop ds
            popa
            ret

        .writeSectors.ATA.error:
            stc
            jmp .writeSectors.ATA.end

        .writeSectors.notATA:
            jmp .writeSectors.ATA.error

    .ATA.waitUntilDone:
        pusha

        .ATA.waitUntilDone.loop:
            in   al, dx

            test al, (ATA_STATUS_ERR|ATA_STATUS_DF)
            jnz  .ATA.waitUntilDone.error

            test al, ATA_STATUS_BSY
            jnz  .ATA.waitUntilDone.loop

            test al, ATA_STATUS_DRQ
            jz  .ATA.waitUntilDone.loop

        clc
        popa
        ret

        .ATA.waitUntilDone.error:
            stc
            popa
            ret

    section .rodata

    .Driver_Message_Prefix: db .Fail__Message-.Driver_Message_Prefix-1, "S_ATA_PI: "
    .Fail__Message: db .Error_Message-.Fail__Message-1, "This device has encountered too many errors and will be skipped.", 10
    .Error_Message: db .noDiskMessage-.Error_Message-1, " has encountered an error.", 10
    .noDiskMessage: db .SATA__Message-.noDiskMessage-1, " doesn't exist.", 10
    .SATA__Message: db .ATAPI_Message-.SATA__Message-1, " is a SATA disk.", 10
    .ATAPI_Message: db .UKNWN_Message-.ATAPI_Message-1, " is an ATAPI disk.", 10
    .UKNWN_Message: db .ATA___Message-.UKNWN_Message-1, " is an unidentified device.", 10
    .ATA___Message: db .noBus1Message-.ATA___Message-1, " is an ATA disk.", 10
    .noBus1Message: db .noBus2Message-.noBus1Message-1, "(ATA:0) has no drives attached.", 10
    .noBus2Message: db .noBusOnMessage-.noBus2Message-1, "(ATA:1) has no drives attached.", 10
    .noBusOnMessage: db .end-.noBusOnMessage-1, "Both ATA buses have no drives attached.", 10
    .end:

    section .text
