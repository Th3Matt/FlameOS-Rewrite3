
AHCIDriver:
    .initController:
        pusha
        push ds

        mov si, Segments.KernelCode
        mov ds, si

        mov eax, 0x01060100
        mov ebx, 0x9 ; BAR 5

        call PCIDriver.deviceInfoByDword3
        jc .initController.ideCheck

    .initController.AHCI1_0:
        push eax
        mov eax, 0x00FFFFFF
        mov esi, .msgAHCI1_0
        xor ecx, ecx

        call Print.string

        jmp .initController.checkIPorts

    .initController.ideCheck:
        mov eax, 0x01018000
        mov ebx, 0x9+1 ; BAR 5

        call PCIDriver.deviceInfoByDword3
        jc .doesntWork
        cmp eax, 0
        jz .doesntWork

        push eax
        mov eax, 0x00FFFFFF
        mov esi, .msgIDE
        xor ecx, ecx

        call Print.string

    .initController.checkIPorts:
        mov esi, .msgBAR5

        call Print.string

        pop ebx
        push ebx

        call Print.hex32

        mov esi, .msgBAR5_END

        call Print.string

        mov eax, 0x01060100
        xor ebx, ebx ; Location

        call PCIDriver.deviceInfoByDword3

        jnc .initController.getLocation

        mov eax, 0x01018000
        xor ebx, ebx ; Location

        call PCIDriver.deviceInfoByDword3

        pop ebx

        jc .doesntWork

        push ebx

        .initController.getLocation:

        push eax

        call PCIDriver.getStatus

        test ax, 1<<4 ; Capabilities
        jz .initController.capabilitiesCheckEnd


        pop eax
        push eax

        mov ebx, 0x12 ; SATA

        call PCIDriver.checkCapability
        jc .initController.capabilitiesCheckEnd

        xor eax, eax
        not eax
        xor ecx, ecx

        mov esi, .msgCAP

        call Print.string

        .initController.capabilitiesCheckEnd:

        pop eax

        mov ebx, 5
        call PCIDriver.getBAR

        test eax, 1
        jz .initController.end ; TODO: implement support for MMIO

        and eax, 0xFFFFFFFC ; preparing IO port address
        mov edx, eax

        add edx, 0xC
        in eax, dx

        cmp eax, 0
        jz .initController.noPortsImplemented

        clc
    .initController.end:
        pop ebx
        pop ds

        popa
        ret

    .initController.noPortsImplemented:
        mov eax, 0x00FFFFFF
        mov esi, .msgNoPortsImplemented
        xor ecx, ecx

        call Print.string

        stc
        jmp .initController.end

    .doesntWork:
        mov eax, 0x00FFFFFF
        mov esi, .msgFail
        xor ecx, ecx

        call Print.string

        stc
        pop ds
        popa
        ret

section .rodata

    .msgFail:
        db .msgFail.end-.msgFail-1, "AHCIDriver: AHCI controller insane or doesn't exist.", 10
        .msgFail.end:
    .msgBAR5:
        db .msgBAR5.end-.msgBAR5-1, "AHCIDriver: AHCI controller BAR5 is 0x"
        .msgBAR5.end:
    .msgCAP:
        db .msgCAP.end-.msgCAP-1, "AHCIDriver: AHCI controller has SATA capability.", 10
        .msgCAP.end:
    .msgBAR5_END:
        db .msgBAR5_END.end-.msgBAR5_END-1, ".", 10
        .msgBAR5_END.end:
    .msgNoPortsImplemented:
        db .msgNoPortsImplemented.end-.msgNoPortsImplemented-1, "AHCIDriver: No ports implemented, exiting.", 10
        .msgNoPortsImplemented.end:
    .msgAHCI1_0:
        db .msgAHCI1_0.end-.msgAHCI1_0-1, "AHCIDriver: AHCI controller detected.", 10
        .msgAHCI1_0.end:
    .msgIDE:
        db .msgIDE.end-.msgIDE-1, "AHCIDriver: AHCI controller in IDE mode detected.", 10
        .msgIDE.end:

section .text
