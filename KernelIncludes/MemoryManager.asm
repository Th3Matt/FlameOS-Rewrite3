 
ALLOCATABLE_SPACE_TABLE_SIZE equ 0x7FF8

MemoryManager:
    .init:
        pusha
        push es

        mov ax, Segments.MemAllocData
		mov es, ax

		xor edi, edi

		mov ecx, (0x6ffff-0x60000)/4
		xor eax, eax

		rep stosd

		mov ax, Segments.UserspaceMem
		mov es, ax

		xor edi, edi
		xor eax, eax
		mov ecx, 256*32*32

		rep stosd

		mov ax, Segments.SysLDT
        lldt ax

		pop es
		popa
		ret

    .memAlloc:    ; eax - process ID, ecx - requested blocks of 4 KiB. Output: eax - address of allocated space
        push es
        push ecx
        push edi
        push edx
        push ebx

        push eax

        mov ax, Segments.MemAllocData
		mov es, ax

		xor edi, edi
		xor eax, eax
		mov al, 1
        xor edx, edx
		jmp .memAlloc.checkSlot

        .memAlloc.notFree:
            xor edx, edx

		.memAlloc.shiftMask:
            shl eax, 1
            jnz .memAlloc.checkSlot

		.memAlloc.setTo1:
            mov eax, 1              ; reset mask
            add edi, 4
            cmp edi, ALLOCATABLE_SPACE_TABLE_SIZE
            jz .memAlloc.outOfMemory

        .memAlloc.checkSlot:
            test [es:edi], eax        ; check memory slot
            jnz .memAlloc.notFree
            inc edx
            cmp edx, ecx
            jnz .memAlloc.shiftMask

        xor edx, edx

        .memAlloc.setBits:
            or [es:edi], eax
            inc edx
            shr eax, 1
            jnz .memAlloc.setBits.2

            cmp edx, ecx
            jnl .memAlloc.writeAllocation

            mov eax, 80000000h
            sub edi, 4

        .memAlloc.setBits.2:
            cmp edx, ecx
            jl .memAlloc.setBits

		.memAlloc.writeAllocation:
            mov ebx, eax
            pop eax
            push esi
            xor esi, esi

            .memAlloc.writeAllocation.testIfWrite:
                cmp dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8], 0
                jnz .memAlloc.nextAlloc

        shl edi, 5-2 ; encoding

        .memAlloc.getPosMidByte:
            cmp ebx, 0
            jz .memAlloc.getPosMidByte.done

            inc edi
            shr ebx, 1

            jmp .memAlloc.getPosMidByte

        .memAlloc.getPosMidByte.done:

        mov [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE], eax              ; PID
        mov [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+4], edi            ; Allocation location in table
        mov [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8], ecx            ; Allocated space

        shl edi, 12

        add edi, 0x110000
        mov [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+12], edi           ; Start address of allocation
        pop esi

        mov eax, edi

        .memAlloc.end:

%ifdef DEBUGMEM
    pusha 
   
    mov ebx, eax
    mov eax, 0x00888888
    xor ecx, ecx

    call Print.hex32 
  
    popa
%endif

        pop ebx
        pop edx
        pop edi
        pop ecx
        pop es
        ret

        .memAlloc.nextAlloc:
            add esi, 16
            jmp .memAlloc.writeAllocation.testIfWrite

        .memAlloc.outOfMemory:
            mov ax, Segments.VRAM_Graphics
            mov es, ax
            xor edi, edi

            mov ecx, 800*600
            mov eax, 0xff880000
            rep stosd

            mov ecx, 0xff880000
            call Print.fillScreen

            mov si, Segments.KernelCode
            mov ds, si
            mov eax, 0x00FFFFFF
            mov esi, .outOfMemoryErrorMsg

            mov edx, (800/10)*(30/10)+(800/20)
            push edi
            shr edi, 1
            sub edx, edi
            pop edi

            call Print.string

            mov bx, 0xFFFF
            call Print.refresh
            jmp $

    .memAllocAtLocation: ; ecx - ammount of 4 KiB blocks to allocate, edi - location.
        pusha
        push es

        mov ax, Segments.MemAllocData
		    mov es, ax

        sub edi, 0x110000
        shr edi, 12

        mov eax, 1

        add edi, ecx
        push ecx

        mov ecx, edi
        shr edi, 5
        and ecx, 11111b

        shl eax, cl

        pop ecx

        xor edx, edx

        .memAllocAtLocation.setBits:
            or [es:edi], eax
            inc edx
            shr eax, 1
            jnz .memAllocAtLocation.setBits.2

            cmp edx, ecx
            jnl .memAllocAtLocation.end

            mov eax, 80000000h
            sub edi, 4

        .memAllocAtLocation.setBits.2:
            cmp edx, ecx
            jl .memAllocAtLocation.setBits


        .memAllocAtLocation.end:

        pop es
        popa
        ret

    .memFreeAll:  ; eax - process ID ; Note: frees all memory taken by process with PID
        push eax
        push ecx
        push es
        push esi

        mov cx, Segments.MemAllocData
        mov es, cx

        mov ecx, (0x1000-0x200)/16
        xor esi, esi

        .memFreeAll.loop:
            cmp [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE], eax
            jnz .memFreeAll.loop.1

            mov ebx, [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+12]

            call .memFree

            .memFreeAll.loop.1:
                add esi, 16
                loop .memFreeAll.loop

        pop edi
        pop es
        pop ecx
        pop eax
        ret

    .memFree:     ; eax - process ID, ebx - allocation address.
        push es
        push eax
        push esi
        push ecx

        push eax

        mov ax, Segments.MemAllocData
		mov es, ax

        pop eax
        mov esi, [es:ALLOCATABLE_SPACE_TABLE_SIZE]

        .memFree.test:
            cmp [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE], eax
            jnz .memFree.nextAlloc
            cmp [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+12], ebx
            jnz .memFree.nextAlloc

        mov ecx, [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+4]
        mov ebx, [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8]
        add ecx, ebx

        push cx     ; deencoding
        shr ecx, 5
        shl ecx, 7
        xor eax, eax
        pop ax
        and eax, 11111b
        add ecx, eax

        push ecx

        mov eax, 1
        and cl, 0x1f
        dec ecx
        shl eax, cl

        pop ecx
        shr ecx, 5

        .memFree.clearBits:
            xor [es:ecx], eax
            dec ebx
            cmp ebx, 0
            jz .memFree.clearAllocation

            shr eax, 1
            jnz .memFree.clearBits

            mov eax, 80000000h
            sub ecx, 4
            jmp .memFree.clearBits

        .memFree.clearAllocation:
            mov dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE], 0
            mov dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+4], 0
            mov dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8], 0
            mov dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+12], 0

        pop ecx
        pop esi
        pop eax
        pop es
        clc

        .memFree.end:
            ret

        .memFree.nextAlloc:
            add esi, 16

            cmp esi, (0x1000-0x200)
            stc
            jz .memFree.end

            jmp .memFree.test

    .memAllocPrint:
        pusha
        push ds

        call Print.clearScreen

        mov ax, Segments.KernelCode
        mov ds, ax

        xor eax, eax
        not eax
        xor edx, edx
        mov esi, .memTableTop
        xor ecx, ecx

        call Print.string

        push es
        mov cx, Segments.MemAllocData
        mov es, cx

        mov ecx, 18
        mov ebx, ALLOCATABLE_SPACE_TABLE_SIZE

        .memAllocPrint.PrintEntries:
            call .memAllocPrint.drawEntry
            add ebx, 16
            loop .memAllocPrint.PrintEntries

        pop es
        pop ds
        popa
        ret

        .memAllocPrint.drawEntry: ; ebx - entry
            push ecx
            push ebx
            xor ebx, ebx

            mov esi, .memTableEntry+1
            mov edi, 4
            xor ecx, ecx

            call Print.stringWithSize

            pop ebx
            push ebx
            mov ebx, [es:ebx]

            call Print.hex32

            mov edi, 5
            add esi, 4

            call Print.stringWithSize

            pop ebx
            push ebx
            mov ebx, [es:ebx+12]

            call Print.hex32

            mov edi, 5
            add esi, 5

            call Print.stringWithSize

            pop ebx
            push ebx

            mov ebx, [es:ebx+8]
            push eax
            push edx
            mov eax, 0x1000
            mul ebx
            mov ebx, eax
            pop edx
            pop eax

            call Print.hex32

            mov edi, 3
            add esi, 5

            call Print.stringWithSize

            mov esi, .memTableEnd

            call Print.string

            pop ebx
            pop ecx
            ret

    section .rodata

    .memTableTop: db .memTableEntry-.memTableTop-1
        db "|--------------------------------------|", 10
        db "| PID        | StartAddr  | Size       |", 10
        db "|--------------------------------------|", 10

    .memTableEntry: db .memTableEnd-.memTableEntry-1
        db "| 0x", " | 0x", " | 0x", " |", 10

    .memTableEnd: db .memTable.end-.memTableEnd-1
        db "|--------------------------------------|", 10
    .memTable.end:

    .outOfMemoryErrorMsg: db .end-.outOfMemoryErrorMsg-1
        db "OUT OF MEMORY, so that sucks, I guess."
    .end:

    section .text


LDT:
    .createEntry: ; eax - base, ebx - limit, ecx - Process ID, edx - cpu ring, ds - writable segment containing LDT. Output: esi - LDT entry.
        push eax
        push ebx
        push ecx
        push edx

        and dx, 11b
        shl dx, 5
        push edx

        shl ecx, 3+8
        mov esi, ecx
        sub esi, 8

        .createEntry.loop: ; Finding free LDT entry
            add esi, 8
            test byte [ds:esi+5], 10000000b
            jnz .createEntry.loop

        shr ebx, 12

        mov [ds:esi], bx

        add esi, 2
        mov [ds:esi], ax

        add esi, 2

        xor ecx, ecx

        ror eax, 16
        mov ch, ah
        shr ebx, 16
        mov cl, bl
        and cl, 0x0f
        or cl, 11010000b
        shl ecx, 16

        pop edx
        or ch, dl

        or ch, 10010010b
        mov cl, al
        mov [ds:esi], ecx

        and esi, 0xff

        pop edx
        pop ecx
        pop ebx
        pop eax
        ret

    .clear: ; ecx - process ID, ds - writable segment containing LDT.
        push esi

        xor esi, esi

        .clear.loop:
            call .deleteEntry

            add esi, 8
            cmp esi, 0x200*8
            jle .clear.loop

        pop esi
        ret

    .deleteEntry: ; ecx - Process ID, esi - LDT entry, ds - writable segment containing LDT.
        push ecx
        push esi

        shl ecx, 3+4+4 ; *0x800
        and esi, 111111111111111111111111111000b
        add esi, ecx
        and byte [ds:esi+5], 0

        pop esi
        pop ecx
        ret

    .set: ; ecx - Process ID
        push eax
        push ecx
        push edi
        push fs

        mov di, Segments.GDT_Write               ; preparing to write to GDT
        mov fs, di
        mov edi, ecx
        shl edi, 3+4+4 ; *0x800

        mov eax, edi
        add eax, 0x100000

        mov [fs:0x68+2], ax        ; writing BASE[0:15] of LDT

        ror eax, 16

        mov [fs:0x68+4], al        ; writing BASE[16:23] of LDT
        mov [fs:0x68+7], ah        ; writing BASE[24:31] of LDT

        shr eax, 16

        mov ecx, 0x800             ; getting the address of LDT limit
        add ecx, eax

        mov [fs:0x68], cx          ; writing LIMIT[0:15] of LDT
        shr ecx, 16
        and byte [fs:0x68+6], 0xf0
        and cl, 0xf0
        or [fs:0x68+6], cl         ; writing LIMIT[16:19] of LDT

        mov ecx, 0x68

        lldt cx                    ; reloading LDTR

        pop fs
        pop edi
        pop ecx
        pop eax
        ret

    .getEntryBaseAddress: ; ds - entry. Output: esi - address.
        push eax
        push ecx
        push ds

        xor eax, eax
        mov ax, ds
        and eax, 0xFFFFFFFF^(111b)

        call ProcessManager.getCurrentPID
        shl ecx, 3+8
        add eax, ecx

        mov si, Segments.UserspaceMem
        mov ds, si

        mov cl, ds:[eax+7]
        shl ecx, 8
        mov cl, ds:[eax+4]
        shl ecx, 16
        mov cx, ds:[eax+2]
        mov esi, ecx

        pop ds
        pop ecx
        pop eax

        ret
