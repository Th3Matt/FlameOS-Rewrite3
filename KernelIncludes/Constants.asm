Vars   equ 0x2000
GDTLoc equ 0x4000

ThirdBootloaderSize equ 0x5 ; in sectors

;Variables
    VariablesBase                       equ 0x0

    ; Graphics dirver info
        GraphicsCardAddress             equ 0x5
        GraphicsFramebufferAddress      equ 0x9
        ScreenWidth                     equ 0xD
        ScreenHeight                    equ 0x11
        VESAMode                        equ 0x16  ; VESA mode for 800x600x32bpp
        VideoHardwareInterfaces         equ 0x18

    Clock                               equ VariablesBase+0x40 ; 4 byte

    CustomSetting                       equ VariablesBase+0x80 ; First two bits control the detection of disks on ATA buses 0 and 1

    ; FlameFS partition info
        FlPartitionInfo.firstSector     equ CustomSetting+2  ; 8 bytes

    DiskDriverVariableSpace             equ FlPartitionInfo.firstSector+0x7E ; 0x50 bytes
    PCIDriverVariableSpace              equ DiskDriverVariableSpace+0x50     ; 0x50 bytes
    KeyboardCircularBufferSpace         equ PCIDriverVariableSpace+0x50      ; 0x32 bytes

    TextModeVariableSpace               equ KeyboardCircularBufferSpace+0x32 ; 0x10 bytes
    ScreenOwnershipBuffer               equ TextModeVariableSpace+0x10       ; 1+8 bytes
    ACPIDriverVariableSpace             equ ScreenOwnershipBuffer+9
