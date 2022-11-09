
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

    .findNextFreeProcessSlot: ; Output: ecx - Slot ID
        push es
		push edi

		push ebx
		push eax

		xor edi, edi
		mov ax, 0x40
		mov es, ax
		mov eax, [es:edi]
		xor ecx, ecx
		inc ecx
		mov ebx, 1

		.findNextFreeProcessSlot.searchForSlot:
			test eax, ebx
			jz .findNextFreeProcessSlot.slotFound

			inc ecx
			shl ebx, 1

			cmp ecx, 32
			jg .findNextFreeProcessSlot.slotNotFound
			jmp .findNextFreeProcessSlot.searchForSlot

        .findNextFreeProcessSlot.slotFound:
            clc

            pop eax
            pop ebx

            pop edi
            pop es
            ret

        .findNextFreeProcessSlot.slotNotFound:
            stc

            pop eax
            pop ebx

            pop edi
            pop es
            ret


	.startProcess:	; eax - User ID. Output: ecx - Process ID
		push es
		push edi
		push ebx

		push eax

		xor edi, edi
		mov ax, 0x40
		mov es, ax
		mov eax, [es:edi]
		xor ecx, ecx
		inc ecx
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

			pop ebx ; pop eax
			mov [es:eax+0x20], ebx
			mov dword [es:eax+0x20+0x4], 0
			mov dword [es:eax+0x20+0x8], 0
			
            inc dword [es:0xc]

            pop ebx
            pop edi
			pop es

            clc
			ret

        .startProcess.slotNotFound:
            pop eax
            pop ebx
            pop ecx

            pop ebx
            pop edi
            pop es
            stc
            ret

    .stopProcess:   ; ecx - Process ID
        push ebx
        xor ebx, ebx
        xor edi, edi
        mov bx, 0x1

        dec ecx

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

    .setLDT: ; ecx - Process ID
        push eax
        push ecx
        push edi
        push fs

        mov di, 0x60               ; preparing to write to GDT
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

    .setUpTask: ; eax - ESP0, ebx - ESP, ecx - Process ID, edx - EIP, esi - CS+(SS<<16), edi - SS0
        push ds
        push es
        push fs
        push esi
        push edi

        push ebx
        push eax

        push edi
        push esi

        push ecx

        mov di, 0x40
        mov ds, di

        mov di, 0x70
        mov es, di

        mov di, 0x60               ; preparing to write to GDT
        mov fs, di

        mov edi, ecx
        shr edi, 3+4+4 ; *0x800
        push edi

        call .setLDT

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

        mov [es:0x20], edx

        pop eax ; pop esi
        mov [es:0x4C], ax
        shr eax, 16
        mov [es:0x50], ax

        pop eax ; pop edi
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
