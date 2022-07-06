
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

ATA_ERR  equ 00000001b    ; Error
ATA_IDX  equ 00000010b    ; Index
ATA_CORR equ 00000100b    ; Corrected data
ATA_DRQ  equ 00001000b    ; Data request
ATA_SRV  equ 00010000b    ; Overlapped mode service request
ATA_DF   equ 00100000b    ; Drive fault (no ERR)
ATA_RDY  equ 01000000b    ; Ready
ATA_BSY  equ 10000000b    ; Busy

ADB  equ DiskDriverVariableSpace+0 ; Available disk bus' bitmap
ADA1 equ DiskDriverVariableSpace+1 ; ATA disk availability bitmap 1
ADA2 equ DiskDriverVariableSpace+2 ; ATA disk availability bitmap 2

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
        pusha
        push ds
        push es
        push edx

        mov dx, 0x10
        mov es, dx

        mov dx, 0x28
        mov ds, dx

        mov edx, ATA1
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

        mov edx, ATA2
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
        pop es
        pop ds
        popa
        ret

        .detectDevices.bus1OFF:
            pop edx

            push eax
            xor eax, eax
            mov al, [.noBus1Message-0x20000]
            mov esi, .noBus1Message-0x20000+1
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

            pop eax
            push edx
            jmp .detectDevices.bus2

        .detectDevices.bus2OFF:
            pop edx

            push eax

            xor eax, eax
            mov al, [.noBus2Message-0x20000]
            mov esi, .noBus2Message-0x20000+1
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

            pop eax
            push edx
            test byte es:[ADB], 1
            jnz .detectDevices.bus2Done

        .detectDevices.allBusOFF:
            xor eax, eax
            mov al, [.noBusOnMessage-0x20000]
            mov esi, .noBusOnMessage-0x20000+1
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

            cli
            hlt

    .checkATABus: ; dx - ATA status register port, edi - Terminal printing location, ebx - Bus #
        push eax
        push ecx
        push edx
        push esi

        mov ecx, 3
        push ecx
        .checkATABus.Disk1:

        mov esi, .noBus1Message-0x20000+1

        xor eax, eax
        not eax

        push edx

        mov edx, edi
        mov edi, 6

        call Print.string

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
        pop edx

        dec edx

        mov al, 10100000b ; LBA, Disk 0
        out dx, al

        inc edx
        call .delay400

        dec edx
        dec edx
        xor eax, eax

        out dx, al
        dec edx
        out dx, al
        dec edx
        out dx, al
        dec edx
        out dx, al

        add edx, 5
        mov eax, 0xE0

        out dx, al

        in al, dx
        cmp al, 0
        jnz .checkATABus.Disk1.1

        call .checkATABus.Disks.noDisk
        jmp .checkATABus.Disk2

        .checkATABus.Disk1.1:

        test al, ATA_ERR
        jnz .checkATABus.Disk1.loop1.done

        mov ecx, 1000000                   ; some random timeout number

        .checkATABus.Disk1.loop1:
            dec ecx
            jnz .checkATABus.Disk1.2

            call .checkATABus.Disks.noDisk ; timeout
            jmp .checkATABus.Disk2

            .checkATABus.Disk1.2:
            in al, dx
            test al, ATA_BSY
            jnz .checkATABus.Disk1.loop1

        .checkATABus.Disk1.loop1.done:
        dec edx
        dec edx
        in al, dx
        dec edx

        cmp al, 0
        jz .checkATABus.Disk1.3

        call .checkATABus.Disks.notATA
        jmp .checkATABus.Disk2

        .checkATABus.Disk1.3:

        in al, dx

        cmp al, 0
        jz .checkATABus.Disk1.4

        call .checkATABus.Disks.notATA
        jmp .checkATABus.Disk2

        .checkATABus.Disk1.4:

        add edx, 3

        .checkATABus.Disk1.loop2:
            in al, dx
            test al, ATA_ERR
            jz .checkATABus.Disk1.5
            pop ecx
            call .checkATABus.Disks.error
            jc .checkATABus.Disk2
            push ecx
            jmp .checkATABus.Disk1

            .checkATABus.Disk1.5:

            test al, ATA_DRQ
            jnz .checkATABus.Disk1.loop2

        pop ecx
        sub edx, 7
        mov ecx, 256

        .checkATABus.Disk1.6:
            rep in ax, dx
            loop .checkATABus.Disk1.6

        mov esi, .ATA___Message-0x20000+1
        push edx

        mov edx, edi
        xor eax, eax
        mov al, [.ATA___Message-0x20000]
        mov edi, eax
        xor eax, eax
        not eax

        call Print.string

        mov edi, edx

        pop edx

        push eax
        xor eax, eax
        or  al, 00000001b ; ATA, Present
        ror al, 4
        mov es:[ebx+ADA1], al
        pop eax

        add edx, 3

        mov ecx, 3
        push ecx
        .checkATABus.Disk2:

        add edx, 3

        mov esi, .noBus1Message-0x20000+1

        xor eax, eax
        not eax

        push edx

        mov edx, edi
        mov edi, 6

        call Print.string

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
        pop edx

        mov al, 10110000b ; LBA, Disk 1
        out dx, al

        inc edx
        call .delay400

        dec edx
        dec edx
        xor eax, eax

        out dx, al
        dec edx
        out dx, al
        dec edx
        out dx, al
        dec edx
        out dx, al

        add edx, 5
        mov eax, 0xE0

        out dx, al

        in al, dx
        cmp al, 0
        jnz .checkATABus.Disk2.1

        call .checkATABus.Disks.noDisk
        jmp .checkATABus.end

        .checkATABus.Disk2.1:

        test al, ATA_ERR
        jnz .checkATABus.Disk2.loop1.done

        mov ecx, 1000000                   ; some random timeout number

        .checkATABus.Disk2.loop1:
            dec ecx
            jnz .checkATABus.Disk2.2

            call .checkATABus.Disks.noDisk ; timeout
            jmp .checkATABus.end

            .checkATABus.Disk2.2:
            in al, dx
            test al, ATA_BSY
            jnz .checkATABus.Disk2.loop1

        .checkATABus.Disk2.loop1.done:
        dec edx
        dec edx

        in al, dx
        dec edx

        cmp al, 0
        jz .checkATABus.Disk2.3

        call .checkATABus.Disks.notATA
        jmp .checkATABus.end

        .checkATABus.Disk2.3:

        in al, dx

        cmp al, 0
        jz .checkATABus.Disk2.4

        call .checkATABus.Disks.notATA
        jmp .checkATABus.end

        .checkATABus.Disk2.4:

        add edx, 3

        .checkATABus.Disk2.loop2:
            in al, dx
            test al, ATA_ERR
            jz .checkATABus.Disk2.5
            pop ecx
            call .checkATABus.Disks.error
            jc .checkATABus.end
            push ecx
            jmp .checkATABus.Disk2

            .checkATABus.Disk2.5:

            test al, ATA_DRQ
            jnz .checkATABus.Disk2.loop2

        pop ecx
        sub edx, 7
        mov ecx, 256

        .checkATABus.Disk2.6:
            rep in ax, dx
            loop .checkATABus.Disk2.6

        mov esi, .ATA___Message-0x20000+1
        push edx

        mov edx, edi
        xor eax, eax
        mov al, [.ATA___Message-0x20000]
        mov edi, eax
        xor eax, eax
        not eax

        call Print.string

        mov edi, edx

        pop edx

        push eax
        mov al, es:[ebx+ADA1]
        and al, 0xF0
        or  al, 00000001b ; ATA, Present
        ror al, 4
        mov es:[ebx+ADA1], al
        pop eax

        .checkATABus.end:

        pop esi
        pop edx
        pop ecx
        pop eax
        ret

        .checkATABus.Disks.notATA:
            in al, dx
            dec dx
            shl ax, 8
            in al, dx

            cmp ax, 0x14EB
            jne .checkATABus.Disks.notATAPI

            mov esi, .ATAPI_Message-0x20000+1
            push edx

            mov edx, edi
            xor eax, eax
            mov al, [.ATAPI_Message-0x20000]
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

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

            mov esi, .SATA__Message-0x20000+1
            push edx

            mov edx, edi
            xor eax, eax
            mov al, [.SATA__Message-0x20000]
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

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

            mov esi, .UKNWN_Message-0x20000+1
            push edx

            mov edx, edi
            xor eax, eax
            mov al, [.UKNWN_Message-0x20000]
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

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
            mov esi, .Error_Message-0x20000+1
            push edx

            mov edx, edi
            xor eax, eax
            mov al, [.Error_Message-0x20000]
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

            mov edi, edx

            pop edx

            dec ecx

            jz .checkATABus.Disks.error.1
            ret

            .checkATABus.Disks.error.1:

            mov esi, .Fail__Message-0x20000+1
            push edx

            mov edx, edi
            xor eax, eax
            mov al, [.Fail__Message-0x20000]
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

            mov edi, edx

            pop edx

            stc
            ret

        .checkATABus.Disks.noDisk:
            mov esi, .noDiskMessage-0x20000+1
            push edi
            push edx

            mov edx, edi
            xor eax, eax
            mov al, [.noDiskMessage-0x20000]
            mov edi, eax
            xor eax, eax
            not eax

            call Print.string

            mov edi, edx

            push eax
            mov al, es:[ebx+ADA1]
            and al, 0xF0
            ror al, 4
            mov es:[ebx+ADA1], al
            pop eax

            pop edx
            pop edi
            ret

    .Fail__Message: db .Error_Message-.Fail__Message-1, 10, "This device has encountered too many errors and will be skiped."
    .Error_Message: db .noDiskMessage-.Error_Message-1, " has encountered an error."
    .noDiskMessage: db .SATA__Message-.noDiskMessage-1, " doesn't exist."
    .SATA__Message: db .ATAPI_Message-.SATA__Message-1, " is a SATA disk."
    .ATAPI_Message: db .UKNWN_Message-.ATAPI_Message-1, " is an ATAPI disk."
    .UKNWN_Message: db .ATA___Message-.UKNWN_Message-1, " is an unidentified device."
    .ATA___Message: db .noBus1Message-.ATA___Message-1, " is an ATA disk."
    .noBus1Message: db .noBus2Message-.noBus1Message-1, 10, "(ATA:0) has no drives attached."
    .noBus2Message: db .noBusOnMessage-.noBus2Message-1, 10, "(ATA:1) has no drives attached."
    .noBusOnMessage: db .end-.noBusOnMessage-1, 10, "Both ATA buses have no drives attached. Halting."
    .end:
