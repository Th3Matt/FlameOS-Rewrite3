[ org 0x20000 ]
[ BITS 16 ]
GDTLoc equ 0x4000

KernelInit16:
	cli	

%include "KernelIncludes/GDT.asm"

[ BITS 32 ]

KernelInit32:
	mov ax, 0x8
	mov ss, ax

	mov ax, 0x30
	mov gs, ax
	mov [gs:0], word 0xBF41

	pushf
	call 0x28:Init-0x20000

	mov ax, 0x38
	mov gs, ax
	mov ecx, 0x4000
	xor edi, edi

	.ClearLoop:
		mov dword gs:[edi], 0x88888888
		add edi, 4
		loop .ClearLoop
	jmp $

%include "Drivers/VGA.asm"