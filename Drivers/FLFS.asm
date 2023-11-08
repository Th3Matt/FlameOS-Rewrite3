FileDescriptorSize equ 0x1A
BootFileSize equ 0x30

FlFS:
    .init: ; ds - segment containing LDT
        pusha
        push fs
        push ds
        push es
        push edx

        mov ax, Segments.FS_Header
        mov fs, ax

        mov ax, Segments.Variables
        mov es, ax

        mov eax, BootFileSize+1
        add eax, [es:FlPartitionInfo.firstSector]
        xor ebx, ebx
        mov bx, es:[EDD_DetectedDiskNumber]
        push ebx

        mov ecx, 5
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

        xor edx, edx
        call API.alloc

        pop ecx

        mov fs:[10], si
        mov fs, si

        mov ax, Segments.Variables
        mov es, ax

        mov eax, BootFileSize+2
        add eax, [es:FlPartitionInfo.firstSector]

        pop ebx
        push ebx
        xor edi, edi

        call S_ATA_PI.readSectors

        mov si, fs
        mov ds, si
        mov si, Segments.KernelCode
        mov es, si
        mov esi, 1
        xor ecx, ecx

        ;cli
        ;jmp $

        .init.fileNameLoop:
            lodsb

            cmp byte es:[.KernelFileName+ecx], 0
            jz .init.fileNameLoop.done

            cmp al, es:[.KernelFileName+ecx]
            jnz .init.error.kernelFile

            inc ecx
            jmp .init.fileNameLoop

        .init.fileNameLoop.done:

        mov bx, Segments.FS_Header
        mov fs, bx

        pop ebx
        mov fs:[0], ebx ; saving disk number over signature

        mov si, Segments.KernelCode
        mov ds, si
        mov eax, 0x00FFFFFF
        mov esi, .FoundBootDiskMsg
        pop edx

        push ecx
        xor ecx, ecx

        call Print.string

        pop ecx

        pop es
        pop ds
        pop fs
        popa
        ret

        .init.error:
            mov eax, 0x00FF0000
            mov esi, .DiskNotFoundMsg
            xor ecx, ecx

            call Print.string

            hlt
            jmp $-1

        .init.error.sig:
            mov eax, 0x00FF0000
            mov esi, .FSSignatureWrongMsg
            xor ecx, ecx

            call Print.string

            hlt
            jmp $-1

        .init.error.kernelFile:
            mov si, Segments.KernelCode
            mov ds, si
            mov eax, 0x00FF0000
            mov esi, .KernelFileMissingMsg
            xor ecx, ecx

            call Print.string

            hlt
            jmp $-1

    .readFile: ; eax - file number, edi - buffer address, ds - buffer segment
        pusha
        push fs
        push es

        mov ecx, FileDescriptorSize
        mul ecx

        mov bx, Segments.FS_Header
        mov fs, bx

        mov bx, Segments.Variables
        mov es, bx

        SWITCH_TO_SYSTEM_LDT bx

        mov ebx, fs:[0]

        push ecx
        mov cx, fs:[10]
        mov fs, cx
        pop ecx

        mov cl, fs:[eax]
        test cl, 00000001b
        jz .readFile.noFile
        mov edx, fs:[eax+22]
        mov ecx, fs:[eax+18]
        mov eax, edx
        add eax, [es:FlPartitionInfo.firstSector]

        SWITCH_BACK_TO_PROCESS_LDT dx

        mov dx, ds
        mov fs, dx

        call S_ATA_PI.readSectors

        clc

        .readFile.end:
            pop es
            pop fs
            popa
            ret

        .readFile.noFile:
            pop bx
            lldt bx
            stc
            jmp .readFile.end

    .getFileInfo: ; eax - file number. Output: ebx - file size, cl - UserID, dl - file flags.
        push fs
        push eax
        mov bx, Segments.FS_Header
        mov fs, bx

        SWITCH_TO_SYSTEM_LDT bx

        mov bx, fs:[10]
        mov fs, bx

        mov ebx, FileDescriptorSize
        mul ebx

        mov ebx, fs:[eax+18]
        xor ecx, ecx
        mov cl,  fs:[eax+17]
        xor edx, edx
        mov dl,  fs:[eax]

        SWITCH_BACK_TO_PROCESS_LDT dx

        pop eax
        pop fs
        ret

    .getFileNumber: ; ds:esi - file name string (zero-terminated). Output: eax - file number
        push ebx
        push ecx
        push edx
        push esi
        push edi
        push fs

        SWITCH_TO_SYSTEM_LDT bx

        mov ax, Segments.FS_Header
        mov fs, ax
        mov ax, fs:[10]
        mov fs, ax

        mov edi, 1

        movzx ebx, byte fs:[5]
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
            SWITCH_BACK_TO_PROCESS_LDT dx

            pop fs
            pop edi
            pop esi
            pop edx
            pop ecx
            pop ebx
            ret

    section .rodata

    .FoundBootDiskMsg:     db .FSSignatureWrongMsg-.FoundBootDiskMsg-1,     'FlFS: Boot disk found.', 10
    .FSSignatureWrongMsg:  db .KernelFileMissingMsg-.FSSignatureWrongMsg-1, 'FlFS: FLFS signature not found.', 10
    .KernelFileMissingMsg: db .DiskNotFoundMsg-.KernelFileMissingMsg-1,     "FlFS: Kernel file '48Boot.sb' not found.", 10
    .DiskNotFoundMsg:      db .end-.DiskNotFoundMsg-1,                      'FlFS: Boot disk not found.', 10
    .end:
    .KernelFileName: db '48Boot.sb', 0

    section .text
