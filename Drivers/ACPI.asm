
; RSDP
    RDSP.signature          equ 0                       ; 8 bytes ; char[8]
    RSDP.checksum           equ RDSP.signature+8        ; 1 byte  ; uint8
    RSDP.OEM                equ RSDP.checksum+1         ; 6 bytes ; char[6]
    RSDP.revision           equ RSDP.OEM+6              ; 1 byte  ; uint8
    RSDP.RSDT_address       equ RSDP.revision+1         ; 4 bytes ; uint32

    RSDP.size               equ RSDP.RSDT_address+3

    RSDP.length             equ RSDP.RSDT_address+4     ; 4 bytes ; uint32
    RSDP.XSDT_address       equ RSDP.length+4           ; 8 bytes ; uint64
    RSDP.extChecksum        equ RSDP.XSDT_address+8     ; 1 byte  ; uint8
    RSDP.reserved           equ RSDP.extChecksum+1      ; 3 bytes ; uint8[3]

    RSDP.size2              equ RSDP.reserved+3

;-------------------------------------------------------------------
; ACPI Table Header
    ACPITH.signature        equ 0                       ; 4 bytes ; char[4]
    ACPITH.length           equ ACPITH.signature+4      ; 4 bytes ; uint32
    ACPITH.revision         equ ACPITH.length+4         ; 1 byte  ; uint8
    ACPITH.checksum         equ ACPITH.revision+1       ; 1 byte  ; uint8
    ACPITH.OEMID            equ ACPITH.checksum+1       ; 6 bytes ; char[6]
    ACPITH.OEMTableID       equ ACPITH.OEMID+6          ; 8 bytes ; char[8]
    ACPITH.OEMRevision      equ ACPITH.OEMTableID+8     ; 4 bytes ; uint32
    ACPITH.CreatorID        equ ACPITH.OEMRevision+4    ; 4 bytes ; uint32
    ACPITH.CreatorRevision  equ ACPITH.CreatorID+4      ; 4 bytes ; uint32

    ACPITH.size             equ ACPITH.CreatorRevision

;-------------------------------------------------------------------
; RSDT Entry
    RSDT.pointerToSDT       equ ACPITH.size             ; 4 bytes ; uint32

    RSDT.entrySize          equ 4

;-------------------------------------------------------------------
; FADT
    FADT.header             equ 0                       ;         ; ACPITH
    FADT.firmwareCtrl       equ FADT.header+ACPITH.size ; 4 bytes ; uint32
    FADT.DSDT               equ FADT.firmwareCtrl+4     ; 4 bytes ; uint32
    FADT.reserved1          equ FADT.DSDT+4             ; 1 byte  ; uint8
    ; Preserved Power Management Profile
    FADT.PPMP               equ FADT.reserved1+1        ; 1 byte  ; uint8
    FADT.SCI_Interrupt      equ FADT.PPMP+1             ; 2 bytes ; uint16
    FADT.SMI_CommandPort    equ FADT.SCI_Interrupt+2    ; 4 bytes ; uint32
    FADT.ACPIEnable         equ FADT.SMI_CommandPort+4  ; 1 byte  ; uint8
    FADT.ACPIDisable        equ FADT.ACPIEnable+1       ; 1 byte  ; uint8
    FADT.S3BIOS_REQ         equ FADT.ACPIDisable+1      ; 1 byte  ; uint8
    FADT.PSTATECtrl         equ FADT.S3BIOS_REQ+1       ; 1 byte  ; uint8
    FADT.PM1aEventBlock     equ FADT.PSTATECtrl+1       ; 4 bytes ; uint32
    FADT.PM1bEventBlock     equ FADT.PM1aEventBlock+4   ; 4 bytes ; uint32
    FADT.PM1aControlBlock   equ FADT.PM1bEventBlock+4   ; 4 bytes ; uint32
    FADT.PM1bControlBlock   equ FADT.PM1aControlBlock+4 ; 4 bytes ; uint32
    FADT.PM2ControlBlock    equ FADT.PM1bControlBlock+4 ; 4 bytes ; uint32
    FADT.PMTimerBlock       equ FADT.PM2ControlBlock+4  ; 4 bytes ; uint32
    FADT.GPE0Block          equ FADT.PMTimerBlock+4     ; 4 bytes ; uint32
    FADT.GPE1Block          equ FADT.GPE0Block+4        ; 4 bytes ; uint32
    FADT.PM1EventLength     equ FADT.GPE1Block+4        ; 1 byte  ; uint8
    FADT.PM1ControlLength   equ FADT.PM1EventLength+1   ; 1 byte  ; uint8
    FADT.PM2ControlLength   equ FADT.PM1ControlLength+1 ; 1 byte  ; uint8
    FADT.GPE0Length         equ FADT.PM2ControlLength+1 ; 1 byte  ; uint8
    FADT.GPE1Length         equ FADT.GPE0Length+1       ; 1 byte  ; uint8
    FADT.GPE1Base           equ FADT.GPE1Length+1       ; 1 byte  ; uint8
    FADT.CStateControl      equ FADT.GPE1Base+1         ; 1 byte  ; uint8
    FADT.WorstC2Latency     equ FADT.CStateControl+1    ; 2 bytes ; uint16
    FADT.WorstC3Latency     equ FADT.WorstC2Latency+2   ; 2 bytes ; uint16
    FADT.FlushSize          equ FADT.WorstC3Latency+2   ; 2 bytes ; uint16
    FADT.FlushStride        equ FADT.FlushSize+2        ; 2 bytes ; uint16
    FADT.DutyOffset         equ FADT.FlushStride+2      ; 1 byte  ; uint8
    FADT.DutyWidth          equ FADT.DutyOffset+1       ; 1 byte  ; uint8
    FADT.DayAlarm           equ FADT.DutyWidth+1        ; 1 byte  ; uint8
    FADT.MonthAlarm         equ FADT.DayAlarm+1         ; 1 byte  ; uint8
    FADT.Century            equ FADT.MonthAlarm+1       ; 1 byte  ; uint8
    ; Boot Architecture Flags
    FADT.BAF                equ FADT.Century+1          ; 2 byte  ; uint16
    FADT.reserved2          equ FADT.BAF+2              ; 1 byte  ; uint8
    FADT.flags              equ FADT.reserved2+1        ; 4 byte  ; uint32
    FADT.resetReg           equ FADT.flags+4            ;         ; GAS
    FADT.resetValue         equ FADT.resetReg+GAS.size  ; 1 byte  ; uint8
    FADT.reserved3          equ FADT.resetValue+1       ; 3 byte  ; uint8[3]

    FADT.size1              equ FADT.reserved3+3

   ;FADT.extFirmwareCtrl    equ FADT.reserved3
   ;FADT.extDSDT            equ extFirmwareCtrl

;-------------------------------------------------------------------
; Generic Address Structure
    GAS.addressSpace        equ 0                       ; 1 byte  ; uint8
    GAS.bitWidth            equ GAS.addressSpace+1      ; 1 byte  ; uint8
    GAS.bitOffset           equ GAS.bitWidth+1          ; 1 byte  ; uint8
    GAS.accessSize          equ GAS.bitOffset+1         ; 1 byte  ; uint8
    GAS.address             equ GAS.accessSize+1        ; 4 bytes ; uint64

    GAS.size                equ GAS.address+4

;===================================================================
;Variables

    ACPI.RSDTPointer                equ ACPIDriverVariableSpace ; 4 bytes
    ACPI.ACPIRevision               equ ACPI.RSDTPointer+4      ; 1 byte

ACPID:
    .init:
        push eax
        push ebx
        push ecx
        push esi
        push edi
        push fs
        push ds

        mov ax, Segments.BIOS_Data
        mov fs, ax

        push cs
        pop ds

        xor ecx, ecx
        mov esi, TableSignatures.RSDP
        xor edi, edi

        .init.loop: ; Finding the RSDP
            lodsb
            inc ecx
            cmp al, 0
            jz .init.loop.checksum

            cmp al, fs:[edi]
            jne .init.loop.next

            inc edi
            jmp .init.loop

        .init.loop.next:
            sub esi, ecx
            sub edi, ecx

            .init.loop.next.2:

            add edi, 15

            xor ecx, ecx

            cmp edi, 0x1FFFF
            jl .init.loop
            jmp .init.failed

        .init.loop.checksum:
            sub esi, ecx
            sub edi, ecx
            inc edi

            xor ecx, ecx
            xor ebx, ebx

            .init.loop.checksum.loop:
                add ebx, [edi+ecx]
                inc ecx
                cmp ecx, RSDP.size
                jl .init.loop.checksum.loop

            cmp bl, 0
            jnz .init.loop.next.2

        xor eax, eax
        not eax

        xor ebx, ebx
        mov esi, .msg1

        call Print.string

        mov

        .init.end:

        pop ds
        pop fs
        pop edi
        pop esi
        pop ecx
        pop ebx
        pop eax
        ret

    section .rodata

    .msg1: db .msg2-.msg1, "ACPID: ACPI RDSP found.", 10, "ACPID: OEM - "
    .msg2:


TableSignatures:
    .RSDP: db "RSD PTR ", 0
    .RSDT: db "RSDT", 0
    .FADT: db "FACP", 0

    section .text
