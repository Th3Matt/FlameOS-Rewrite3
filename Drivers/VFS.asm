
VFS:
    .init:
        pusha
        push es
        push fs

        mov ax, 0x90
        mov es, ax

        mov ax, 0x88
        mov fs, ax

        xor eax, eax
        mov ecx, 0xfff/4
		xor edi, edi

		rep stosd

		mov byte es:[0], 00000001b   ; flags - mount point present
		mov eax, fs:[0]
		mov es:[1], eax              ; mounted disk

		mov byte es:[5], '/'         ; mount point (string, 26 byte max length)

		pop fs
        pop es
        popa
        ret

    .getFileInfo: ; ebx - UserID, ds:esi - file name string (zero-terminated). Output: ebx - file size, dl - file flags
        push edi
        push esi
        push edx
        push ecx
        push eax
        mov eax, esi
        call .mountCheck

        cmp eax, esi
        je .getFileInfo.error1

        call FlFS.getFileNumber
        jc .getFileInfo.error1

        cmp ebx, 0
        jz .getFileInfo.skipCheck

        call FlFS.getFileInfo
        cmp ebx, ecx

        jnz .getFileInfo.error2

        .getFileInfo.skipCheck:

        call FlFS.getFileInfo

        pop eax
        pop ecx
        pop esi ; pop edx
        pop esi
        pop edi
        ret

    .getFileInfo.error1:
        pop eax
        pop ecx
        pop edx
        pop esi
        pop edi

        jmp .error1.postpop

    .getFileInfo.error2:
        pop eax
        pop ecx
        pop edx
        pop esi
        pop edi

        jmp .error2.postpop

    .readFileForNewProcess: ; ebx - UserID, ecx - new PID, esi - file name string (zero-terminated), edi - buffer, ds - file name string segment, fs - buffer segment.
        pusha
        mov eax, esi
        push ecx
        call .mountCheck
        mov edx, ecx

        cmp eax, esi
        je .error1


        call ProcessManager.getCurrentPID
        call ProcessManager.setLDT
        pop ecx

        call FlFS.getFileNumber

        call ProcessManager.setLDT
        mov ecx, edx

        jc .error1

        cmp ebx, 0
        jz .readFileForNewProcess.skipCheck
        push ecx
        push ebx
        call FlFS.getFileInfo
        pop ebx
        cmp ebx, ecx
        pop ecx
        jnz .error2

        .readFileForNewProcess.skipCheck:

        mov bx, fs
        mov ds, bx

        call FlFS.readFile

        popa
        ret

    .readFile: ; ebx - UserID, esi - file name string (zero-terminated), edi - buffer, ds - file name string segment, fs - buffer segment.
        pusha
        mov eax, esi
        call .mountCheck

        cmp eax, esi
        je .error1

        call FlFS.getFileNumber

        jc .error1

        cmp ebx, 0
        jz .readFile.skipCheck
        push ebx
        call FlFS.getFileInfo
        pop ebx
        cmp ebx, ecx
        jnz .error2

        .readFile.skipCheck:

        mov bx, fs
        mov ds, bx

        call FlFS.readFile

        popa
        ret

        .mountCheck: ; ds:esi - file path. Output: ecx - mounted disk, esi - path from mountpoint.
            push edx
            push eax
            push ebx
            push edi
            push fs

            mov cx, 0x90
            mov fs, cx

            xor ecx, ecx
            xor edi, edi
            xor ebx, ebx

            .mountCheck.loop:
                mov dl, fs:[edi+ecx+5]     ; read char from mountpoint path
                cmp dl, ds:[esi+ecx]       ; compare
                jne .mountCheck.next

                inc ecx
                cmp byte fs:[edi+ecx+5], 0 ; check if mountpoint path string has ended
                jnz .mountCheck.loop

                cmp ecx, ebx
                jl .mountCheck.next

                mov ebx, ecx
                mov eax, fs:[edi+1]

            .mountCheck.next:
                xor ecx, ecx
                add edi, 0x20

                cmp edi, 0xfdf
                jle .mountCheck.loop

            mov ecx, eax
            add esi, ebx

            pop fs
            pop edi
            pop ebx
            pop eax
            pop edx
            ret

        .error1:
            popa
        .error1.postpop:
            stc
            mov ebx, 0x00000001 ; Impossible path
            ret

        .error2:
            popa
        .error2.postpop:
            stc
            mov ebx, 0x00000002 ; Not permitted to access
            ret
