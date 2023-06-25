DescriptorSectorsSize equ 3
FSSize equ 1024*2-1
FileDescriptorSize equ 0x1A ; 26 ; 1+15+1+1+4+4
BootFileSize equ 0x30
TerminalFileSize equ 1+3

InfoSector:
	dd 41045015h			         ; Correct FlFS 0.2 signature
	db 01				             ; Autorun file index
	db DescriptorSectorsSize		 ; Ammount of file descriptor sectors
	dd FSSize						 ; FS size in sectors
	dw 0

	times 512-($-InfoSector) db 0

DescriptorSectors:
    Boot.sb:			             ; First file is kernel (and second stage bootloader), linked with the sectors after boot sector.
		db 00000101b 		         ; Flags. First bit - Present flag, second bit - Segmentation flag - does this descriptor show a segmentation table for the file (if the file is in pieces around the disk, AKA fragmented), third bit - executable bit.

		db '48Boot.sb'		         ; Filename.
		times 15-($-Boot.sb-1) db 0  ; Padding.

		db 0			             ; Emergency terminator for filename

		db 00000000b		         ; Owning userID.
		dd BootFileSize	             ; Size of file in sectors.

		dd 1						 ; Starting sector

	Terminal.ub:
		db 00000101b

		db 'Terminal.ub'
		times 15-($-Terminal.ub-1) db 0

		db 0

		db 00000001b
		dd TerminalFileSize

		dd BootFileSize+1+1+DescriptorSectorsSize

	Snake.ub:
		db 00000101b

		db 'Snake.ub'
		times 15-($-Snake.ub-1) db 0

		db 0

		db 00000001b
		dd 1+3

		dd BootFileSize+1+1+DescriptorSectorsSize+TerminalFileSize

	times DescriptorSectorsSize*512-($-DescriptorSectors) db 0
