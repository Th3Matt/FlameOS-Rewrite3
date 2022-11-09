
VFS:
    .init:
        pusha
        push ds
        push fs

        mov ax, 0x90
        mov ds, ax

        mov ax, 0x88
        mov fs, ax

        xor eax, eax
        mov ecx, 0xfff/4
		xor edi, edi

		rep stosd

		mov byte ds:[0], 00000001b   ; flags - mount point present
		mov eax, fs:[0]
		mov ds:[1], eax              ; mounted disk

		mov byte ds:[5], '/'         ; mount point (string, 26 byte max length)

		pop fs
        pop ds
        popa
        ret

    .getFileInfo: ; ebx - UserID, esi - file name string (zero-terminated). Output: ebx - file size, dl - file flags
        call .mountCheck

        pusha
        jz .error1
        popa

        call FlFS.getFileNumber

        cmp ebx, 0
        jz .getFileInfo.skipCheck

        call FlFS.getFileInfo
        cmp ebx, ecx

        pusha
        jnz .error2
        popa

        ret

        .getFileInfo.skipCheck:

        call FlFS.getFileInfo

        popa
        ret

    .readFile: ; ebx - UserID, esi - file name string (zero-terminated), edi - buffer, ds - file name string segment, fs - buffer segment.
        pusha

        call .mountCheck
        jz .error1

        call FlFS.getFileNumber

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

        .mountCheck:
            push fs
            mov cx, 0x90
            mov fs, cx

            xor edi, edi
            xor ecx, ecx

            push word 0
            push dword 0

            .mountCheck.1:
                mov dl, fs:[edi+5]
                inc edi

                inc esi
                cmp dl, ds:[esi-1] ; Comparing path against mount list
                jnz .mountCheck.next

                inc ecx

                cmp byte ds:[edi+5], 0
                jnz .mountCheck.1

                sub edi, ecx
                sub esi, ecx

                add edi, 0x20

                pop ecx
                pop dx
                cmp dl, cl
                jg .mountCheck.3
                and ecx, 0xffffff00
                push cx
                mov ecx, [edi+1]
                push ecx

                xor ecx, ecx

                cmp edi, 0xfdf
                jnl .mountCheck.2

                jmp .mountCheck.1

            .mountCheck.3:
                xor ecx, ecx
                jmp .mountCheck.1

            .mountCheck.next:
                sub edi, ecx
                sub esi, ecx
                xor ecx, ecx

                add edi, 0x20

                cmp edi, 0xfdf
                jl .mountCheck.1

            .mountCheck.2:
                pop ecx
                cmp ecx, 0

                xor edx, edx
                pop dx
                add esi, edx

                pop fs
                ret

        .error1:
            stc
            popa
            mov ebx, 0x00000001 ; Impossible path
            ret

        .error2:
            stc
            popa
            mov ebx, 0x00000002 ; Not permitted to access
            ret
