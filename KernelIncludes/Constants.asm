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

    CustomSetting                       equ VariablesBase+0x80 ; First two bits control the detection of disks on ATA buses 0 and 1

    ; FlameFS partition info
        FlPartitionInfo.firstSector     equ CustomSetting+2  ; 8 bytes

    DiskDriverVariableSpace             equ FlPartitionInfo.firstSector+0x7E
    PCIDriverVariableSpace              equ DiskDriverVariableSpace+0x50

    ; Keyboard Circular Buffer
        KCB.writeCounter                equ PCIDriverVariableSpace+0x50
        KCB.readCounter                 equ KCB.writeCounter+1
        KCB.buffer                      equ KCB.readCounter+1 ; 48 bytes
