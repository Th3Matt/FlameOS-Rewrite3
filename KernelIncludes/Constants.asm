Vars   equ 0x2000
GDTLoc equ 0x4000

ThirdBootloaderSize equ 0x6 ; in sectors

SCREEN_WIDTH  equ 800
SCREEN_HEIGHT equ 600

; SCREEN_WIDTH  equ 1280
; SCREEN_HEIGHT equ 720

;Segments
    Segments.NULL                       equ 0x0
    Segments.KernelStack                equ 0x8
    Segments.Variables                  equ 0x10
    Segments.BIOS_MemMap                equ 0x18
    Segments.IDT                        equ 0x20
    Segments.KernelCode                 equ 0x28
    Segments.VRAM_Text                  equ 0x30
    Segments.VRAM_Graphics              equ 0x38
    Segments.ProcessData                equ 0x40
    Segments.TSS_Write                  equ 0x48
    Segments.TSS1                       equ 0x50
    Segments.TSS2                       equ 0x58
    Segments.GDT_Write                  equ 0x60
    Segments.LDT                        equ 0x68
    Segments.UserspaceMem               equ 0x70
    Segments.MemAllocData               equ 0x78
    Segments.PCIDriverData              equ 0x80
    Segments.FS_Header                  equ 0x88
    Segments.SysLDT                     equ 0x98
    Segments.CharmapOfScreen            equ 0xA0
    Segments.ListOfSyscalls             equ 0xA8
    Segments.DevicesList                equ 0xB0
    Segments.BIOS_Data                  equ 0xB8
    Segments.AllMemory                  equ 0xC0
    Segments.AHCI_ABAR                  equ 0xC8

;Variables
    VariablesBase                       equ 0x0

    ; Graphics dirver info
        GraphicsDriverNameString        equ 1                                   ; 4 bytes
        GraphicsCardAddress             equ GraphicsDriverNameString+4          ; 4 bytes
        GraphicsFramebufferAddress      equ GraphicsCardAddress+4               ; 4 bytes
        ScreenWidth                     equ GraphicsFramebufferAddress+4        ; 4 bytes
        ScreenHeight                    equ ScreenWidth+4                       ; 4 bytes
        VESAMode                        equ ScreenHeight+4                      ; 4 bytes ; VESA mode for 800x600x32bpp
        VideoHardwareInterfaces         equ VESAMode+4                          ; 4 bytes
        TotalPixels                     equ VideoHardwareInterfaces+4           ; 4 bytes
        CharsPerLine                    equ TotalPixels+4                       ; 4 bytes
        LinesPerScreen                  equ CharsPerLine+4                      ; 4 bytes
        TotalChars                      equ LinesPerScreen+4                    ; 4 bytes

    Clock                               equ VariablesBase+0x40                  ; 4 byte

    ; Segments for kernel drivers
        AllocSegments.VFS_Data          equ Clock+4                             ; 2 bytes
        AllocSegments.AHCI_Data         equ AllocSegments.VFS_Data+2            ; 2 bytes

    CustomSetting                       equ VariablesBase+0x80                  ; 2 bytes
    ; First two bits control the detection of disks on ATA buses 0 and 1, the third, if set, prints PCI Device table.

    ; FlameFS partition info
        FlPartitionInfo.firstSector     equ CustomSetting+2                     ; 8 bytes

    DiskDriverVariableSpace             equ FlPartitionInfo.firstSector+0x7E    ; 0x50 bytes
    PCIDriverVariableSpace              equ DiskDriverVariableSpace+0x50        ; 0x50 bytes
    PS2Devices                          equ PCIDriverVariableSpace+0x50         ; 8 bytes
    GenericDriverVariables              equ PS2Devices+8                        ; 4 bytes

    TextModeVariableSpace               equ GenericDriverVariables+4            ; 0x10 bytes
    ScreenOwnershipBuffer               equ TextModeVariableSpace+0x10          ; 1+8 bytes

    CurrentContextVariables             equ ScreenOwnershipBuffer+9             ; 0x31 bytes

    ACPIDriverVariableSpace             equ CurrentContextVariables+0x31

%macro SWITCH_TO_SYSTEM_LDT 1
    sldt %1
    push %1
    mov %1, Segments.SysLDT
    lldt %1
%endmacro

%macro SWITCH_BACK_TO_PROCESS_LDT 1
    pop %1
    lldt %1
%endmacro

%macro STOP_AND_CHECK 1
    	mov ebx, %1

    xor eax, eax
    xor ecx, ecx
    not eax
    call Print.hex32

    hlt
    jmp $-1
%endmacro

;%define DEBUGMEM
