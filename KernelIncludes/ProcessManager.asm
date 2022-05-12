
ProcessManager:
	.init:
		push es
		push eax
		push ecx

		mov ax, 0x40 ; Clearing process manager data segment
		mov es, ax

		xor eax, eax
		mov ecx, 0xfff
		xor edi, edi

		rep stosb ;[edi]

		mov cx, 0x70 ; Clearing LDT lists
		mov es, cx

		mov ecx, 0x800*32/4
		xor edi, edi

		rep stosd

        ;mov cx, 0x60 ; Clearing LDT segment
		;mov es, cx

		;mov ecx, 0x800/4
		;xor edi, edi

		;rep stosd

		mov cx, 0x78 ; Clearing memAlloc segment
		mov es, cx

		mov ecx, 7ffh
		xor edi, edi

		rep stosb

		pop ecx
		pop eax
		pop es
		ret

	.startProcess:	; eax - EIP, bx - CS, ebx>>16 - SS, cx - SS0. Output: ecx - Process ID
		push es
		push edi

		push ecx
		push ebx
		push eax

		xor edi, edi
		mov ax, 0x40
		mov es, ax
		mov eax, [es:edi]
		xor ecx, ecx 
		mov ebx, 1

		.startProcess.searchForSlot:
			test eax, ebx
			jz .startProcess.slotFound

			inc ecx
			shl ebx, 1

			cmp ecx, 32
			jg .startProcess.slotNotFound
			jmp .startProcess.searchForSlot

		.startProcess.slotFound:
			or eax, ebx
			mov [es:edi], eax

			mov eax, ecx
			shl eax, 4

			mov [es:eax+0x20+0xc], ecx

			pop ebx ; pop eax
			mov [es:eax+0x20], ebx
			pop ebx ; pop ebx
			mov [es:eax+0x20+0x4], ebx
			pop ebx ; pop ecx
			mov [es:eax+0x20+0x8], ebx
			
            inc dword [es:0xc]

            pop edi
			pop es

            clc
			ret

        .startProcess.slotNotFound:
            pop eax
            pop ebx
            pop ecx

            pop es
            stc
            ret

    .stopProcess:   ; ecx - Process ID
        push ebx
        xor ebx, ebx
        xor edi, edi
        mov bx, 0x1

        shl ebx, cl

        not ebx

        push es
        push eax
        mov ax, 0x40
        mov es, ax
        pop eax

        test [es:edi], ebx
        jz .stopProcess.notStarted

        and [es:edi], ebx

        dec dword [es:0xc]

        clc
        pop es
        pop ebx
        ret

        .stopProcess.notStarted:
            stc
            pop es
            pop ebx
            ret

    .setUpTask: ; ecx - Process ID, eax - ESP0, ebx - ESP
        push ds
        push es
        push fs
        push esi
        push edi

        push ebx
        push eax

        push ecx

        mov di, 0x40
        mov ds, di

        mov di, 0x70
        mov es, di

        mov di, 0x60               ; preparing to write to GDT
        mov fs, di

        mov edi, ecx
        shl edi, 4

        mov edi, ecx
        shr edi, 3+4+4 ; *0x800

        push edi
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

        pop ecx
        mov eax, ecx
        push ecx

        mov ecx, 1
        call MemoryManager.memAlloc

        pop ecx

        pop esi ; pop edi

        push ecx

        mov ebx, eax
        shr ebx, 12

        mov [es:esi], bx

        add esi, 2
        mov [es:esi], ax

        add esi, 2

        xor ecx, ecx

        ror eax, 16
        mov ch, ah
        shr ebx, 16
        mov cl, bl
        and cl, 0x0f
        or cl, 11010000b
        shl ecx, 16
        mov ch, 10010010b
        mov cl, al
        mov [es:esi], ecx

        mov ax, 0x0+4
        mov es, ax

        pop ecx
        shl ecx, 4

        mov eax, [ds:ecx+0x20]
        mov [es:0x20], eax

        mov eax, [ds:ecx+0x20+4]
        mov [es:0x4C], ax
        shr eax, 16
        mov [es:0x50], ax

        mov eax, [ds:ecx+0x20+8]
        mov [es:0x08], ax

        pop eax

        mov [es:0x04], eax

        pop ebx

        mov [es:0x38], ebx

        xor edi, edi
        mov [es:0x00], edi

        mov di, 0x68
        mov [es:0x60], edi

        pop edi
        pop esi
        pop fs
        pop es
        pop ds

        ret

    .sheduler:
        push es

        mov cx, 0x48               ; preparing to read from TSS
        mov ds, cx
        mov cx, 0x0+100b           ; reparing to write to saved TSS
        mov es, cx

        xor ecx, ecx
        mov cx, 0x64               ; read 64 bytes

        mov esi, 0x64              ; selecting second TSS
        xor edi, edi

        rep movsb

        pop es

        .sheduler.skipWrite:

        push es

        mov ax, 0x40
		mov es, ax

        mov ecx, [es:8]             ; get task #
		mov eax, [es:4]             ; get saved mask

		.sheduler.shiftMask:
            inc ecx
            shl eax, 1
            jnz .sheduler.checkSlot

		.sheduler.setTo1:
            mov eax, 1              ; reset mask
            mov ecx, 0              ; reset task #

        .sheduler.checkSlot:
            cmp eax, [es:4]
            stc
            jz .sheduler.return
            test [es:0], eax        ; check process slot
            jz .sheduler.shiftMask

        push eax
        push ecx

         xor eax, eax
         ;mov al, 0x10
         ;mul cx
         mov ax, cx
         ;shl ax, 5
         ;mov ecx, [es:eax+0x20+0x10] ; reading LDT number       ; Deprecated! LDT number is now the same as process ID


         shl eax, 4+4+3             ; getting the address of LDT

         add eax, 0x100000
         mov cx, 0x60               ; preparing to write to GDT
         mov es, cx

         mov [es:0x68+2], ax        ; writing BASE[0:15] of LDT

         shr eax, 16

         mov [es:0x68+4], al        ; writing BASE[16:23] of LDT
         mov [es:0x68+7], ah        ; writing BASE[24:31] of LDT

         xor ecx, ecx
         mov cx, 0x800

         add ecx, eax               ; getting the address of LDT limit

         mov [es:0x68], cx          ; writing LIMIT[0:15] of LDT
         shr ecx, 16
         and byte [es:0x68+6], 0xf0
         or [es:0x68+6], cl         ; writing LIMIT[16:19] of LDT

         mov cx, 0x68

         lldt cx                    ; reloading LDTR

         mov cx, 0x48               ; preparing to write to TSS
         mov es, cx

         mov es:[0x00], word 0x58

         mov cx, 0x0+100b           ; reparing to read from saved TSS
         mov ds, cx

         xor ecx, ecx
         mov cx, 0x68               ; read 64 bytes

         mov edi, 0x68              ; selecting second TSS
         xor esi, esi

         rep movsb

        pop ecx
        pop eax

        mov [es:4], eax             ; save mask
        mov [es:8], ecx             ; save task #
		pop es

		clc

		;mov ax, 0x58
		;call 0x58:0

        .sheduler.return:
            ret

ALLOCATABLE_SPACE_TABLE_SIZE equ 511>>2 ; ((4*1024-1)*1024-(0xffff/1024))/8/1024

MemoryManager:
    .init:
        pusha
        push es

        mov ax, 0x78
		mov es, ax

		mov ecx, (0x8900-0x7900)/4
		xor edi, edi
		xor eax, eax

		rep stosd

		pop es
		popa
		ret

    .memAlloc:    ; eax - process ID, ecx - requested blocks of 4 KiB. Output: eax - address of allocated space
        push es
        push edi
        push edx
        push ebx

        push eax

        mov ax, 0x78
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
            inc edi
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
            jz .memAlloc.writeAllocation

            mov eax, 80000000h
            dec edi

        .memAlloc.setBits.2:
            cmp edx, ecx
            jnz .memAlloc.setBits

		.memAlloc.writeAllocation:
            mov ebx, eax
            pop eax
            push esi
            xor esi, esi

            .memAlloc.writeAllocation.testIfWrite:
                cmp dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8], 0
                jnz .memAlloc.nextAlloc

        shl edi, 5

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

        pop ebx
        pop edx
        pop edi
        pop es
        ret

        .memAlloc.nextAlloc:
            add esi, 16
            jmp .memAlloc.writeAllocation.testIfWrite

        .memAlloc.outOfMemory:
            mov ax, 0x38
            mov es, ax
            xor edi, edi

            mov ecx, 800*600
            mov eax, 0xff880000
            rep stosd
            jmp $

    .memFreeAll:  ; eax - process ID ; Note: frees all memory taken by process with PID
        push eax
        push ecx
        push es
        push esi

        mov ax, 0x78
        mov es, ax

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

        mov ax, 0x78
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
            dec ecx
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

        push es
        mov ax, 0x38
        mov es, ax
        xor edi, edi

        mov ecx, 800*600
        xor eax, eax
        rep stosd
        pop es

        mov ax, 0x28
        mov ds, ax

        mov eax, 0xffffffff
        xor edx, edx
        mov esi, .memTableTop+1-0x20000
        mov edi, [ds:esi-1]
        shl edi, 24
        shr edi, 24

        call Print.string

        push es
        mov cx, 0x78
        mov es, cx

        mov ecx, 4
        xor ebx, ebx

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
            mov esi, .memTableEntry+1-0x20000
            mov edi, 4

            call Print.string

            mov ecx, [es:ebx+ALLOCATABLE_SPACE_TABLE_SIZE]

            call Print.hex32

            mov edi, 5
            add esi, 4

            call Print.string

            mov ecx, [es:ebx+ALLOCATABLE_SPACE_TABLE_SIZE+12]

            call Print.hex32

            mov edi, 5
            add esi, 5

            call Print.string

            mov ecx, [es:ebx+ALLOCATABLE_SPACE_TABLE_SIZE+8]

            call Print.hex32

            mov edi, 3
            add esi, 5

            call Print.string

            mov esi, .memTableEnd+1-0x20000
            mov edi, [ds:esi-1]
            shl edi, 24
            shr edi, 24

            call Print.string

            pop ecx
            ret

    .memTableTop: db .memTableEntry-.memTableTop-1
        db "|--------------------------------------|", 10
        db "| PID        | StartAddr  | Size       |", 10
        db "|--------------------------------------|", 10

    .memTableEntry: db .memTableEnd-.memTableEntry-1
        db "| 0x", " | 0x", " | 0x", " |", 10

    .memTableEnd: db .memTable.end-.memTableEnd-1
        db "|--------------------------------------|", 10
    .memTable.end:
