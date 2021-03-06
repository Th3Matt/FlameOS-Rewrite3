	            ;			Raw Descriptor	Descriptor+RPL  Description
		            ;---------------------00       -      00         -   NULL
    mov edi, GDTLoc
    mov dword [di], 0
    add di, 4
    mov dword [di], 0
    add di, 4
                    ;---------------------08 	   -      08         -   Kernel Stack
		            ;500 - 1fff
    mov ax, 0x1fff
    mov [di], ax

    add di, 2

    mov ax, 0x500
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b   ; Flags and Limit 16:19
    shl ecx, 8
    mov ch, 10010010b   ; Access Byte
    ;mov cl, 0
    mov [di], ecx

    add di, 4
                    ;---------------------10       -      10         -   System Variables
                    ;2000 - 2fff
    mov ax, 0x2fff
    mov [di], ax

    add di, 2

    mov ax, 0x2000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    ;mov cl, 0
    mov [di], ecx

    add di, 4
                    ;---------------------18       -      18         -   BIOS Memory Map
                    ;3000 - 3fff
    mov ax, 0x3fff
    mov [di], ax

    add di, 2

    mov ax, 0x3000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    ;mov cl, 0
    mov [di], ecx

    add di, 4
                    ;---------------------20       -      20         -   IDT (256 entries)
                    ;5000 - 5fff
    mov ax, 0x5fff
    mov [di], ax

    add di, 2

    mov ax, 0x5000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    ;mov cl, 0
    mov [di], ecx

    add di, 4
                    ;---------------------28       -      28         -   Kernel Code
                    ;20000 - 21fff
    mov ax, 0x1fff
    mov [di], ax

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010010b
    shl ecx, 8
    mov ch, 10011010b
    mov cl, 2
    mov [di], ecx

    add di, 4
                    ;---------------------30       -      30         -   Video RAM (TextMode)
                    ;b8000 - b8fff
    mov ax, 0x8fff
    mov [di], ax

    add di, 2

    mov ax, 0x8000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01011011b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0xB
    mov [di], ecx

    add di, 4
                    ;---------------------38       -      38         -   Video RAM
                    ;a0000 - e6500 or PCI device 1234:1111 BAR0
    mov eax, [GraphicsFramebufferAddress]
    shr eax, 12
    add ax, (800*600*4)>>12
    mov [di], ax

    add di, 2

    mov ax, [GraphicsFramebufferAddress]
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov cl, [GraphicsFramebufferAddress+3]
    shr cl, 4
    and cl, 00001111b
    or cl, 11000000b
    mov ch, [GraphicsFramebufferAddress+3]

    shl ecx, 16
    mov ch, 10010010b
    mov cl, [GraphicsFramebufferAddress+2]
    mov [di], ecx

    add di, 4
                    ;---------------------40       -      40         -   Process Manager Data
                    ;6000 - 6fff
    mov ax, 0x6fff
    mov [di], ax

    add di, 2

    mov ax, 0x6000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    ;mov cl, 0x0
    mov [di], ecx

    add di, 4
                    ;---------------------48       -      48         -   TSSs in a writable segment
                    ;5900 - 59ff
    mov ax, 0x59ff
    mov [di], ax

    add di, 2

    mov ax, 0x5900
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    ;mov cl, 0x0
    mov [di], ecx

    add di, 4
                    ;---------------------50       -      50         -   TSS 1
                    ;5900 - 5968
    mov ax, 0x68
    mov [di], ax

    add di, 2

    mov ax, 0x5900
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01000000b
    shl ecx, 8
    mov ch, 0x89
    ;mov cl, 0x0
    mov [di], ecx

    add di, 4
                    ;---------------------58       -      58         -   TSS 2
                    ;5968 - 59CF
    mov ax, 0x68
    mov [di], ax

    add di, 2

    mov ax, 0x5968
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01000000b
    shl ecx, 8
    mov ch, 0x89
    ;mov cl, 0x0
    mov [di], ecx

    add di, 4
                    ;---------------------60       -      60         -   Writable GDT
                    ;4000 - 4fff
    mov ax, GDTLoc+0xfff ; 0x4fff
    mov [di], ax

    add di, 2

    mov ax, GDTLoc ; 0x4000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    ;mov cl, 0x0
    mov [di], ecx

    add di, 4
                    ;---------------------68       -      68         -   LDT
                    ;undefined
    xor eax, eax
    mov [di], ax

    add di, 2

    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10000010b
    ;mov cl, 0x0
    mov [di], ecx

    add di, 4
                    ;---------------------70       -      70         -   LDT list
                    ;100000 - 10ffff
    mov ax, 0x10f
    mov [di], ax

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 11010000b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0x10
    mov [di], ecx

    add di, 4
                    ;---------------------78       -      78         -   MemAlloc Data
                    ;7900 - 88ff
    mov ax, 0x88ff
    mov [di], ax

    add di, 2

    mov ax, 0x7900
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    ;mov cl, 0x0
    mov [di], ecx

    add di, 4       ;=====================

    mov si, di
    sub si, GDTLoc
    dec si
    mov [di], si
    mov eax, edi
    add di, 2
    mov dword [di], GDTLoc

    xchg bx, bx

    lgdt [eax]

    mov eax, cr0
    or al, 1       ; set PE (Protection Enable) bit in CR0 (Control Register 0)
    mov cr0, eax

    jmp 0x28:KernelInit32

    SetGDT:
