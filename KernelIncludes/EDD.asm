EDD_DetectedDiskNumber equ EndOfATADriverSpace

EDDV3Read:
	pusha
	push ds
	push es

	mov ax, 0x08
	mov ds, ax
	mov ax, 0x10
	mov es, ax

	mov ax, ds:[0x1E]
	cmp ax, 0xBEDD
	jne .noEDD

	mov edx, ds:[0x28]
	mov eax, ds:[0x24]

	cmp edx, "USB "
	je .notSupported.USB
	cmp edx, "SCSI"
	je .notSupported.SCSI
	cmp edx, "1394"
	je .notSupported.FireWire
	cmp edx, "FIBR"
	je .notSupported.Fibre
	cmp edx, "ATAP"
	je .notSupported.ATAPI

	cmp eax, "ISA "
	je .ISA

	cmp eax, "PCI "
	je .PCI

	jmp $

	.PCI:
		jmp $

	.notSupported.USB:
		mov si, 0x28
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .USBMessage-0x20000+1
        mov di, [.USBMessage-0x20000]
        and di, 0xff

        call Print.string

        jmp $

	.notSupported.SCSI:
		mov si, 0x28
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .SCSIMessage-0x20000+1
        mov di, [.SCSIMessage-0x20000]
        and di, 0xff

        call Print.string

        jmp $


	.notSupported.FireWire:
		mov si, 0x28
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .FireWireMessage-0x20000+1
        mov di, [.FireWireMessage-0x20000]
        and di, 0xff

        call Print.string

        jmp $

	.notSupported.Fibre:
		mov si, 0x28
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .FibreMessage-0x20000+1
        mov di, [.FibreMessage-0x20000]
        and di, 0xff

        call Print.string

        jmp $

	.notSupported.ATAPI:
		mov si, 0x28
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .ATAPIMessage-0x20000+1
        mov di, [.ATAPIMessage-0x20000]
        and di, 0xff

        call Print.string

        jmp $

	.ATAPIMessage:    db .FibreMessage-.ATAPIMessage,    "Boot from ATAPI (CDROM) detected. It is currently unsupported. Halting."
	.FibreMessage:    db .FireWireMessage-.FibreMessage, "Boot from Fibre channel detected. It is currently unsupported. Halting."
	.FireWireMessage: db .SCSIMessage-.FireWireMessage,  "Boot from FireWire detected. It is currently unsupported. Halting."
	.SCSIMessage:     db .USBMessage-.SCSIMessage,       "Boot from SCSI detected. It is currently unsupported. Halting."
	.USBMessage:      db .end-.USBMessage,               "Boot from USB detected. It is currently unsupported. Halting."

	.end:
		clc
		pop es
		pop ds
		popa
		ret

	.noEDD:
        mov word es:[EDD_DetectedDiskNumber], 0xFFFF

		stc
		pop es
		pop ds
		popa
		ret

	.ISA:
		.ISA.ATA:
			mov al, es:[ADB]

			test al, 00000001b
			jz .ISA.ATA.ATABus2

			mov si, ds:[0x30]
			mov cx, ds:[0x38]
			cmp es:[ABAddr1], si
			jne .ISA.ATA.ATABus2

			mov bl, es:[ADA1]

			test cx, 00000001b
			jnz .ISA.ATA.1.disk2

			.ISA.ATA.1.disk1:
				test bl, 00000001b
				jz .noEDD

				test bl, 000001110b
				jnz .noEDD

				mov word es:[EDD_DetectedDiskNumber], 0

				jmp .end

			.ISA.ATA.1.disk2:
				test bl, 00010000b
				jz .noEDD

				test bl, 11100000b
				jnz .noEDD

				mov word es:[EDD_DetectedDiskNumber], 1
				jmp .end

			.ISA.ATA.ATABus2:
				test al, 00000010b
				jz .noEDD

				mov si, ds:[0x30]
				mov cx, ds:[0x38]
				cmp es:[ABAddr2], si
				jne .noEDD

				mov bl, es:[ADA2]

				test cx, 00000001b
				jnz .ISA.ATA.2.disk2

				.ISA.ATA.2.disk1:
					test bl, 00000001b
					jz .noEDD

					test bl, 000001110b
					jnz .noEDD

					mov word es:[EDD_DetectedDiskNumber], 2

					jmp .end

				.ISA.ATA.2.disk2:
                    test bl, 00010000b
                    jz .noEDD

                    test bl, 11100000b
                    jnz .noEDD

					mov word es:[EDD_DetectedDiskNumber], 3
					jmp .end
