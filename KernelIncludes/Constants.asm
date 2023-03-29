GDTLoc equ 0x4000
Vars equ 0x2000

;Variables
GraphicsCardAddress equ 0x5
GraphicsFramebufferAddress equ 0x9
ScreenWidth equ 0xD
ScreenHeight equ 0x11
VESAMode equ 0x16							; VESA mode for 800x600x32bpp
VideoHardwareInterfaces equ 0x18
CustomSetting equ 0x80 						; First two bits control the detection of disks on ATA buses 0 and 1
FlPartitionInfo.firstSector equ 0x82 ; 8 bytes
DiskDriverVariableSpace equ 0x100
PCIDriverVariableSpace equ 0x150
