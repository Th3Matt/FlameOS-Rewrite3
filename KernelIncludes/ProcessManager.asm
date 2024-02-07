
; Process Manager Data Blob
    PMDB.activeProcessMask            equ 0                                   ; 4 bytes ; dword
    PMDB.shedulerCurrentProcessMask   equ PMDB.activeProcessMask+4            ; 4 bytes ; dword
    PMDB.shedulerCurrentProcessNumber equ PMDB.shedulerCurrentProcessMask+4   ; 4 bytes ; dword
    PMDB.ammoutOfActiveProcesses      equ PMDB.shedulerCurrentProcessNumber+4 ; 4 bytes ; dword
    PMDB.flags                        equ PMDB.ammoutOfActiveProcesses+4      ; 4 bytes ; dword

ProcessManager:
	.init:
		push es
		push eax
		push ecx

		mov ax, Segments.ProcessData ; Clearing process manager data segment
		mov es, ax

		xor eax, eax
		mov ecx, 0xfff
		xor edi, edi

		rep stosb ;[edi]
    dec dword [es:PMDB.ammoutOfActiveProcesses] ; hiding the kernel process

		mov cx, Segments.UserspaceMem ; Clearing LDT lists
		mov es, cx

		mov ecx, 0x800*32/4
		xor edi, edi

		rep stosd
		xor eax, eax
		call .startProcess

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
		mov ax, Segments.ProcessData
		mov es, ax
		mov eax, [es:edi] ; read current process list dword
		xor ecx, ecx
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

		push eax

		xor edi, edi
		mov ax, Segments.ProcessData
		mov es, ax
		mov eax, [es:edi] ; read current process list dword
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

			pop ebx ; pop eax
			mov [es:eax+0x20], ebx
			xor ebx, ebx
			mov dword [es:eax+0x20+0x4], ebx
			mov dword [es:eax+0x20+0x8], ebx
			
            inc dword [es:PMDB.ammoutOfActiveProcesses]

            pop eax
            pop ebx
            pop edi
			pop es

            clc
			ret

        .startProcess.slotNotFound:
            pop eax
            pop ebx
            pop ecx

            pop eax
            pop ebx
            pop edi
            pop es
            stc
            ret

    .pauseProcess:  ; eax - reason for pausing process, ecx - Process ID
        push ebx
        push edi
        push ecx
        xor ebx, ebx
        xor edi, edi
        mov bx, 0x1

        shl ebx, cl

        push es
        push eax
        mov ax, Segments.ProcessData
        mov es, ax
        pop eax

        test [es:edi], ebx                  ; Checking if process exists
        jz .pauseProcess.notStarted

        shl ecx, 4

        or byte [es:ecx+0x20+0x4], 1       ; Marking the process paused
        mov dword [es:ecx+0x20+0x8], eax

        clc
        pop es
        pop ecx
        pop edi
        pop ebx
        ret

        .pauseProcess.notStarted:
            stc
            pop es
            pop ecx
            pop edi
            pop ebx
            ret

    .resumeProcess: ; ecx - Process ID
        push ebx
        push edi
        push ecx
        xor ebx, ebx
        xor edi, edi
        mov bx, 0x1

        shl ebx, cl

        push es
        push eax
        mov ax, Segments.ProcessData
        mov es, ax
        pop eax

        test [es:edi], ebx                  ; Checking if process exists
        jz .resumeProcess.notStarted

        shl ecx, 4
        xor ebx, ebx
        and byte [es:ecx+0x20+0x4], 0xFE
        mov dword [es:ecx+0x20+0x8], ebx

        clc
        pop es
        pop ecx
        pop edi
        pop ebx
        ret

        .resumeProcess.notStarted:
            stc
            pop es
            pop ecx
            pop edi
            pop ebx
            ret

    .stopProcess:   ; ecx - Process ID
        push ebx
        push edi
        xor ebx, ebx
        xor edi, edi
        mov bx, 0x1

        shl ebx, cl

        push es
        push eax
        mov ax, Segments.ProcessData
        mov es, ax
        pop eax

        test [es:edi], ebx                  ; Checking if process exists
        jz .stopProcess.notStarted

        xor [es:edi], ebx
        
        call .resumeWaitingProcesses

        push eax
        mov eax, ecx
        call MemoryManager.memFreeAll
        pop eax

        mov bx, Segments.UserspaceMem
        push ds
        mov ds, bx
        call LDT.clear
        pop ds

        dec dword [es:PMDB.ammoutOfActiveProcesses]

        clc
        pop es
        pop edi
        pop ebx
        ret

        .stopProcess.notStarted:
            stc
            pop es
            pop edi
            pop ebx
            ret

    .resumeWaitingProcesses: ; ecx - PID. Resumes processes waiting for another one to finish.
        pusha

		xor edi, edi
		mov ax, Segments.ProcessData
		mov es, ax
		mov eax, [es:edi]
		xor edx, edx
		mov ebx, 1

		.resumeWaitingProcesses.search:
			test eax, ebx
			jnz .resumeWaitingProcesses.found

        .resumeWaitingProcesses.search.continue:
			inc edx
			shl ebx, 1

			cmp edx, 32
			jg .resumeWaitingProcesses.done
			jmp .resumeWaitingProcesses.search

		.resumeWaitingProcesses.found:
			shl edx, 4

			cmp dword [es:edx+0x20+0x8], ecx
			pushf
			shr edx, 4
			popf
			jne .resumeWaitingProcesses.search.continue

			xchg edx, ecx
			call .resumeProcess
			xchg edx, ecx

			jmp .resumeWaitingProcesses.search.continue

        .resumeWaitingProcesses.done:
            popa

            ret

    .setUpTask: ; eax - ESP0, ebx - ESP, ecx - Process ID, edx - EIP, esi - CS+(SS<<16), edi - SS0
        push ds
        push es
        push ecx
        push esi
        push edi

        push ebx
        push eax

        push edi
        push esi

        mov di, Segments.UserspaceMem
        mov es, di

        mov edi, ecx
        shl edi, 3+4+4 ; *0x800
        push edi

        push ecx

        call LDT.set

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

        add esi, 8*3

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

        mov ax, (3<<3)+4
        mov es, ax

        push edi
        xor edi, edi
        mov ecx, 0x64/4
        xor eax, eax
        rep stosd
        pop edi

        pop ecx
        shl ecx, 4

        mov [es:0x20], edx  ; EIP

        pop eax ; pop esi
        mov [es:0x4C], ax   ; CS
        shr eax, 16
        mov [es:0x50], ax   ; SS

        pop eax ; pop edi
        mov [es:0x08], ax   ; SS0

        pop eax

        mov [es:0x04], eax  ; ESP0

        pop ebx

        mov [es:0x38], ebx  ; ESP

        xor edi, edi
        mov [es:0x00], edi  ; LINK

        mov di, 0x68
        mov [es:0x60], edi  ; LDTR
        mov dword es:[0x24], 0x0200 ; setting interrupt flag

        pop edi
        pop esi
        pop ecx
        pop es
        pop ds

        ret

    .sheduler:
        mov ax, Segments.ProcessData
		mov es, ax

        mov ecx, [es:PMDB.shedulerCurrentProcessNumber]
        call LDT.set

        mov cx, Segments.TSS_Write               ; preparing to read from current TSS
        mov ds, cx
        mov cx, (3<<3)+100b           ; preparing to write to saved TSS
        mov es, cx

        mov ecx, 0x68               ; read 64 bytes

        mov esi, 0x68              ; selecting second TSS
        xor edi, edi

        rep movsb

        .sheduler.skipWrite: ; sheduler entry point for when we don't need to save previous task context

        mov ax, Segments.ProcessData
		mov es, ax

        mov ecx, [es:PMDB.shedulerCurrentProcessNumber]           ; get task #
		mov eax, [es:PMDB.shedulerCurrentProcessMask]             ; get saved mask

		.sheduler.shiftMask:
            inc ecx
            shl eax, 1              ; go to next process slot
            jnz .sheduler.checkSlot

		.sheduler.setTo1:
            mov eax, 1              ; reset mask
            mov ecx, 0              ; reset task #

        .sheduler.checkSlot:
            cmp eax, [es:PMDB.shedulerCurrentProcessMask] ; check if we wrapped back around to where we started
            stc
            jz .sheduler.return
            test [es:PMDB.activeProcessMask], eax        ; check process slot
            jz .sheduler.shiftMask
            mov ebx, ecx
            shl ebx, 4
            test byte [es:ebx+0x20+0x4], 1
            jnz .sheduler.shiftMask

        push eax
        push ecx

         call LDT.set

         mov cx, Segments.TSS_Write               ; preparing to write to TSS
         mov es, cx

         mov es:[PMDB.activeProcessMask], word 0x58

         mov cx, (3<<3)+100b           ; reparing to read from saved TSS
         mov ds, cx

         xor ecx, ecx
         mov cx, 0x68               ; read 64 bytes

         mov edi, 0x68              ; selecting second TSS
         xor esi, esi

         rep movsb

        xor eax, eax
        mov ds, ax

        mov ax, Segments.ProcessData
		mov es, ax

        pop ecx
        pop eax


        mov [es:PMDB.shedulerCurrentProcessMask], eax             ; save mask
        mov [es:PMDB.shedulerCurrentProcessNumber], ecx           ; save task #

		clc

		;mov ax, 0x58
		;call 0x58:0

        .sheduler.return:
            ret

    .getCurrentPID: ; Output: ecx - PID
      push eax
      push gs

      mov ax, Segments.ProcessData
		  mov gs, ax

      mov ecx, [gs:PMDB.shedulerCurrentProcessNumber]

      pop gs
      pop eax

      ret
    
    .setCurrentPID: ; ecx - ammount
      push eax
      push gs

      mov ax, Segments.ProcessData
		  mov gs, ax

      mov [gs:PMDB.shedulerCurrentProcessNumber], ecx

      pop gs
      pop eax

      ret
