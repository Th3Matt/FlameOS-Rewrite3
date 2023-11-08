	            ;			Raw Descriptor	Descriptor+RPL  Description
		            ;---------------------00       -      00         -   NULL
    mov edi, GDTLoc
    mov dword [di], 0
    add di, 4
    mov dword [di], 0
    add di, 4
                    ;---------------------08 	   -      08         -   Kernel Stack
		            ;500 - 1fff
    mov ax, 0x19ff
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
    mov ax, 0xfff
    mov [di], ax

    add di, 2

    mov ax, Vars
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
    mov ax, 0xfff
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
    mov ax, 0xfff
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
                    ;20000 - 25fff
    mov ax, 0x5fff
    mov [di], ax

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10011010b
    mov cl, 2
    mov [di], ecx

    add di, 4
                    ;---------------------30       -      30         -   Video RAM (TextMode)
                    ;b8000 - b8fff
    mov ax, 0xfff
    mov [di], ax

    add di, 2

    mov ax, 0x8000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0xB
    mov [di], ecx

    add di, 4
                    ;---------------------38       -      38         -   Video RAM
                    ;PCI device 1234:1111 BAR0
    mov ax, ((SCREEN_WIDTH*SCREEN_HEIGHT*4)>>12)+1
    mov [di], ax

    add di, 2

    mov ax, [GraphicsFramebufferAddress+Vars]
    mov [di], ax

    add di, 2

    xor ecx, ecx
    or cl, 11000000b
    mov ch, [GraphicsFramebufferAddress+3+Vars]

    shl ecx, 16
    mov ch, 10010010b
    mov cl, [GraphicsFramebufferAddress+2+Vars]
    mov [di], ecx

    add di, 4
                    ;---------------------40       -      40         -   Process Manager Data
                    ;6000 - 6fff
    mov ax, 0xfff
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
    mov ax, 0xff
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
    mov ax, 0xfff ; 0x4fff
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
                    ;---------------------70       -      70         -   Userspace memory
                    ;100000 - ffffffff
    mov ax, 0xffff
    mov [di], ax

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 11011111b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0x10
    mov [di], ecx

    add di, 4
                    ;---------------------78       -      78         -   MemAlloc Data
                    ;26000 - 3ffff
    mov ax, 0x9fff
    mov [di], ax

    add di, 2

    mov ax, 0x6000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010001b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0x2
    mov [di], ecx

    add di, 4
                    ;---------------------80       -      80         -   PCI Driver Data
                    ;50000 - 5ffff
    mov ax, 0xffff
    mov [di], ax

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0x05
    mov [di], ecx

    add di, 4
                    ;---------------------88       -      88         -   Filesystem header
                    ;a000 - bfff
    mov ax, 0x1fff
    mov [di], ax

    add di, 2

    mov ax, 0xa000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    ;mov cl, 0x0
    mov [di], ecx

    add di, 4
    add di, 4+2+2
                    ;---------------------98       -      98         -   System LDT
                    ;100000-100fff
    mov bx, 0xfff
    mov [di], bx

    add di, 2

    xor eax, eax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10000010b
    mov cl, 0x10
    mov [di], ecx

    add di, 4
                    ;---------------------A0       -      A0        -   Charmap of screen
                    ;60000
    mov bx, ((SCREEN_WIDTH*SCREEN_HEIGHT*9/100)>>12)+1
    mov [di], bx

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 11010000b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 6
    mov [di], ecx

    add di, 4
                    ;---------------------A8       -      A8        -   List of Syscalls
                    ;d000 - e000
    mov bx, 0x1000
    mov [di], bx

    add di, 2

    mov ax, 0xd000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0x0
    mov [di], ecx

    add di, 4
                    ;---------------------B0       -      B0        -   Devices List
                    ;40000 - 4ffff
    mov bx, 0xffff
    mov [di], bx

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0x4
    mov [di], ecx

    add di, 4
                    ;---------------------B8       -      B8        -   BIOS Data
                    ;80000 - 9FFFF
    mov bx, 0xFFFF
    mov [di], bx

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010001b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0x8
    mov [di], ecx

    add di, 4
                    ;---------------------C0       -      C0        -   All Memory
                    ;0 - FFFFFFFF
    mov bx, 0xFFFF
    mov [di], bx

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 11011111b
    shl ecx, 8
    mov ch, 10010010b
    mov [di], ecx

    add di, 4
                    ;---------------------C8       -      C8        -   AHCI ABAR
                    ;7000 - 77ff
    mov bx, 0x7ff
    mov [di], bx

    add di, 2

    mov ax, 0x7000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
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

    cli

    lgdt [eax]

    mov eax, cr0
    or al, 1       ; set PE (Protection Enable) bit in CR0 (Control Register 0)
    mov cr0, eax

    jmp Segments.KernelCode:0

    SetGDT:
