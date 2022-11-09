FileDescriptorSize equ 0x1A
BootFileSize equ 0x30

FlFS:
    .init: ; ds - segment containing LDT
        pusha
        push fs
        push ds

        mov ax, 0x88
        mov fs, ax

        push es
        mov ax, 0x10
        mov es, ax

        mov eax, BootFileSize+1
        xor ebx, ebx
        mov bx, es:[EDD_DetectedDiskNumber]
        pop es
        push ebx

        mov ecx, 1
        xor edi, edi

        call S_ATA_PI.readSectors
        jc .init.error


        cmp dword fs:[0], 0x41045015
        jnz .init.error.sig

        xor ecx, ecx
        mov cl, fs:[5] ; Saving descriptor sector amount

        push ecx

        shr ecx, 3
        inc ecx
        xor eax, eax

        call MemoryManager.memAlloc

        shl ecx, 9
        dec ecx

        push ecx
        mov cx, 0x70
        mov ds, cx

        push edx
        xor edx, edx
        xor ecx, ecx
        mov ebx, eax
        add ebx, 0xfff

        call MemoryManager.createLDTEntry
        pop ecx
        mov fs:[10], si

        pop edx
        pop ecx

        mov fs, si

        mov eax, BootFileSize+2
        pop ebx
        push ebx
        xor edi, edi

        call S_ATA_PI.readSectors

        mov si, fs
        mov ds, si
        mov si, 0x28
        mov es, si
        mov esi, 1
        xor ecx, ecx

        .init.fileNameLoop:
            lodsb

            cmp byte es:[.KernelFileName-0x20000+ecx], 0
            jz .init.fileNameLoop.done

            cmp al, es:[.KernelFileName-0x20000+ecx]
            jnz .init.error.kernelFile

            inc ecx
            jmp .init.fileNameLoop

        .init.fileNameLoop.done:

        pop ebx
        mov fs:[0], ebx ; saving disk number over signature

        mov si, 0x28
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .FoundBootDiskMsg-0x20000+1
        mov di, [.FoundBootDiskMsg-0x20000]
        and di, 0xff

        call Print.string

        pop ds
        pop fs
        popa
        ret

        .init.error:
            mov eax, 0x00FF0000
            mov esi, .DiskNotFoundMsg-0x20000+1
            mov di, [.DiskNotFoundMsg-0x20000]
            and di, 0xff

            call Print.string
            jmp $

        .init.error.sig:
            mov eax, 0x00FF0000
            mov esi, .FSSignatureWrongMsg-0x20000+1
            mov di, [.FSSignatureWrongMsg-0x20000]
            and di, 0xff

            call Print.string
            jmp $

        .init.error.kernelFile:
            mov si, 0x28
            mov ds, si
            mov eax, 0x00FF0000
            mov esi, .KernelFileMissingMsg-0x20000+1
            mov di, [.KernelFileMissingMsg-0x20000]
            and di, 0xff

            call Print.string
            jmp $

    .readFile: ; eax - file number, edi - buffer address, ds - buffer segment
        pusha
        push fs

        mov ecx, FileDescriptorSize
        mul ecx

        mov bx, 0x88
        mov fs, bx

        sldt bx
        push bx
        mov bx, 0x98
        lldt bx

        mov bx, fs:[10]
        mov fs, bx
        mov cl, fs:[eax]
        test cl, 00000001b
        jz .readFile.noFile
        mov edx, fs:[eax+22]
        mov ecx, fs:[eax+18]
        mov eax, edx
        mov ebx, fs:[0]

        pop dx
        lldt dx

        mov dx, ds
        mov fs, dx

        call S_ATA_PI.readSectors

        clc

        .readFile.end:
            pop fs
            popa
            ret

        .readFile.noFile:
            pop bx
            lldt bx
            stc
            jmp .readFile.end

    .getFileInfo: ; eax - file number. Output: ebx - file size, dl - file flags.
        push fs
        push eax
        mov bx, 0x88
        mov fs, bx
        mov bx, fs:[10]
        mov fs, bx

        mov ebx, FileDescriptorSize
        mul ebx
        mov ebx, fs:[eax+18]
        xor ecx, ecx
        mov cl,  fs:[eax+17]
        xor edx, edx
        mov dl,  fs:[eax]

        pop eax
        pop fs
        ret

    .getFileNumber: ; esi - file name string (zero-terminated), ds - file name string segment. Output: eax - file number
        push ebx
        push ecx
        push edx
        push esi
        push edi
        push fs

        mov ax, 0x88
        mov fs, ax
        mov ax, fs:[10]
        mov fs, ax

        mov edi, 1

        xor ebx, ebx
        mov bl, fs:[5]
        inc ebx
        shl ebx, 4+4+3

        xor ecx, ecx
        xor edx, edx
        push dword 0 ; file number

        .getFileNumber.loop:
            cmp edx, 512*3
            jge .getFileNumber.noFile

            test byte fs:[edx], 00000001b ; only check filename if file exists
            jz .getFileNumber.next

        .getFileNumber.loop.1:
            cmp byte ds:[esi], 0                ; check if end of string
            jnz .getFileNumber.loop.2

            cmp byte fs:[edi+edx], 0            ; check if end of filename
            jz .getFileNumber.done

        .getFileNumber.loop.2:
            lodsb
            cmp al, fs:[edi+edx]
            jne .getFileNumber.next

            inc ecx
            inc edi

            jmp .getFileNumber.loop.1

            .getFileNumber.next:
                pop eax
                inc eax

                dec esi
                sub esi, ecx
                sub edi, ecx
                xor ecx, ecx

                add edx, FileDescriptorSize     ; go to next file

                cmp edx, ebx                    ; check if end reached
                push eax
                jge .getFileNumber.noFile
                jmp .getFileNumber.loop

        .getFileNumber.noFile:
            stc
            pop eax
            jmp .getFileNumber.end

        .getFileNumber.done:
            jcxz .getFileNumber.next

            pop eax
            clc

        .getFileNumber.end:
            pop fs
            pop edi
            pop esi
            pop edx
            pop ecx
            pop ebx
            ret

    .FoundBootDiskMsg:     db .FSSignatureWrongMsg-.FoundBootDiskMsg-1,     'FlFS: Boot disk found.'
    .FSSignatureWrongMsg:  db .KernelFileMissingMsg-.FSSignatureWrongMsg-1, 'FlFS: FLFS signature not found.'
    .KernelFileMissingMsg: db .DiskNotFoundMsg-.KernelFileMissingMsg-1,     "FlFS: Kernel file '32Boot.sb' not found."
    .DiskNotFoundMsg:      db .end-.DiskNotFoundMsg-1,                      'FlFS: Boot disk not found.'
    .end:
    .KernelFileName: db '48Boot.sb', 0
