Syscall:
    .init:
        pusha
        push es

        mov ax, 0xA8
        mov es, ax

        mov ecx, 0x740>>2
        xor eax, eax
        xor edi, edi

        rep stosd

        mov dword es:[(0x0<<2)+4],  Print.string
        mov dword es:[(0x1<<2)+4],  Print.clearScreen
        mov dword es:[(0x2<<2)+4],  Print.charSyscall
        mov dword es:[(0x3<<2)+4],  Print.newLine
        mov dword es:[(0x20<<2)+4], ProcessManager.yield
        mov dword es:[(0x21<<2)+4], ProgramLoader.quickLoad
        mov dword es:[(0x22<<2)+4], ProcessManager.processExit
        mov dword es:[(0x30<<2)+4], MemoryManager.usermodeAllocate

        pop es
        popa
        ret

    .run: ; ebx - syscall number.
        push ebx
        push eax
        push es

        mov ax, 0xA8
        mov es, ax
        shl ebx, 2
        mov ebx, es:[ebx+4]
        cmp ebx, 0
        jz .run.zeroPointer

        pop es
        pop eax

        call ebx

        pop ebx
        iret

        .run.zeroPointer:
            mov eax, 0xFFFF0ADD
            mov ebx, 0x1D107
            ud1

    .add: ; ebx - syscall address, ecx - syscall number
        pusha
        push es

        mov ax, 0xA8
        mov es, ax

        ;mov eax, es:[0]
        shl ecx, 2
        mov es:[ecx+4], ebx

        pop es
        popa
        ret
