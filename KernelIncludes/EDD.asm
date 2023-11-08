EDD_DetectedDiskNumber equ EndOfATADriverSpace

EDDV3Read:
	pusha
	push ds
	push es

	mov ax, Segments.KernelStack
	mov ds, ax
	mov ax, Segments.Variables
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
		mov eax, ds:[0x30]

		xor edx, edx

		mov dl, al
		shl edx, 16
		shr eax, 8
		mov dh, al
		shr dx, 3
		mov dh, ah
		shl dx, 3

		mov eax, edx
		mov ebx, 0x4

		call PCIDriver.deviceInfoByLocation
		jc .noEDD

		cmp eax, 0
		jnz .PCI.API.notStandard

		mov eax, ATA1

		.PCI.API.notStandard:

		cmp es:[ABAddr1], ax
		jne .noEDD


		mov eax, ds:[0x38]
		and eax, 0x1
		mov word es:[EDD_DetectedDiskNumber], ax

		jmp .end

	.notSupported.USB:
		mov si, Segments.KernelCode
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .USBMessage
        xor ecx, ecx

        call Print.string

        jmp $

	.notSupported.SCSI:
		mov si, Segments.KernelCode
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .SCSIMessage
        xor ecx, ecx

        call Print.string

        jmp $


	.notSupported.FireWire:
		mov si, Segments.KernelCode
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .FireWireMessage
        xor ecx, ecx

        call Print.string

        jmp $

	.notSupported.Fibre:
		mov si, Segments.KernelCode
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .FibreMessage
        xor ecx, ecx

        call Print.string

        jmp $

	.notSupported.ATAPI:
		mov si, Segments.KernelCode
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .ATAPIMessage
        xor ecx, ecx

        call Print.string

        jmp $

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


	section .rodata

	.ATAPIMessage:    db .FibreMessage-.ATAPIMessage,    "Boot from ATAPI (CDROM) detected. It is currently unsupported. Halting.", 10
	.FibreMessage:    db .FireWireMessage-.FibreMessage, "Boot from Fibre channel detected. It is currently unsupported. Halting.", 10
	.FireWireMessage: db .SCSIMessage-.FireWireMessage,  "Boot from FireWire detected. It is currently unsupported. Halting.", 10
	.SCSIMessage:     db .USBMessage-.SCSIMessage,       "Boot from SCSI detected. It is currently unsupported. Halting.", 10
	.USBMessage:      db .endStr-.USBMessage,            "Boot from USB detected. It is currently unsupported. Halting.", 10
	.endStr:

	section .text
