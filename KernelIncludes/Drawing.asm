 
Print:
    .clearScreen:
        pusha
        push gs

        mov ecx, 800*600
        mov ax, 0x38
        mov gs, ax
        xor edi, edi

        .clearScreen.loop:
            mov dword [gs:edi], 0
            add edi, 4
            loop .clearScreen.loop

        mov ecx, 80*60*9/4
        mov ax, 0xA0
        mov gs, ax
        xor edi, edi

        .clearScreen.loop2:
            mov dword [gs:edi], 0
            add edi, 4
            loop .clearScreen.loop2

        pop gs
        popa
        ret

    .string:    ; eax - Pixel color, ecx - background color dword, edx - First char printing location, esi - String start address, edi - String length, ds - string segment
        push ebx
        push ecx
        dec edi
        xor ebx, ebx
        xor ecx, ecx

        .string.loop:
            mov bl, [ds:ecx+esi]
            inc ecx
            cmp ebx, 10
            jne .string.print

            call .newLine
            jmp .string.Check

        .string.print:
            push ecx
            add esp, 4
            pop ecx
            sub esp, 8
            call .char
            pop ecx
            inc edx

        .string.Check:
            cmp ecx, edi
            jle .string.loop

        pop ecx
        pop ebx
        ret

    .newLine:   ; edx - Char pos
		push eax
		push ecx
		;xchg bx, bx

		push es

		mov cx, 0x10
		mov es, cx

		mov eax, [es:ScreenWidth]
		mov ecx, 10
		push edx
		xor edx, edx
        div ecx
        pop edx

        xchg eax, edx

        push edx
        mov ecx, edx
        xor edx, edx
        div ecx
        pop edx

        inc eax
        mul edx
        mov edx, eax

        cmp edx, 80*50
        jl .newLine.end

        mov eax, [es:ScreenWidth]
		mov ecx, 10
		push edx
		xor edx, edx
        div ecx
        pop edx

        sub edx, eax

        call .scrollDown

        .newLine.end:

        pop es

		pop ecx
		pop eax

		ret

    .scrollDown:
        pusha

		push es

		mov cx, 0x10
		mov es, cx

        mov eax, [es:ScreenWidth]
		mov ecx, 10
		xor edx, edx
        div ecx
        mov ecx, 9
        mul ecx

        mov esi, eax
        xor edi, edi
        mov ecx, 80*59*9/4

        mov ax, 0xA0

        push ds

        mov ds, ax
        mov es, ax

        rep movsd

        pop ds
        pop es

        popa
        ret

    .fillScreen: ; ecx - color
        push ecx
        push edi
        push gs

        mov ecx, 80*60
        push eax
        mov ax, 0xA0
        mov gs, ax
        pop eax
        xor edi, edi

        .fillScreen.loop:
            mov byte [gs:edi], 0
            mov dword [gs:edi+5], eax
            add edi, 9
            loop .fillScreen.loop

        pop gs
        pop edi
        pop ecx
        ret

    .char:	;eax - foreground color dword, ebx - Character #, ecx - background color dword, edx - Character location
        push ds
        push edx
        push ecx
        push eax

        mov ax, 0xA0
        mov ds, ax

        xchg eax, edx

        mov ecx, 9
        mul ecx

        xchg eax, edx

        pop eax

        mov ds:[edx], bl
        pop ecx

        mov ds:[edx+1], eax
        mov ds:[edx+5], ecx

        pop edx
        pop ds
        ret

    .hex32:   ; eax - color dword, ebx - bg color dword, ecx - dword to print, edx - location on screen
        push ebp
        push ebx
        mov ebp, esp

        xchg ecx, edx
        ror edx, 16
        call Conv.hexToChar16

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        push ecx
        mov ecx, [ss:ebp]
        call .char
        pop ecx
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        push ecx
        xor ecx, ecx
        mov ecx, [ss:ebp]
        call .char
        pop ecx
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        push ecx
        xor ecx, ecx
        mov ecx, [ss:ebp]
        call .char
        pop ecx
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        push ecx
        xor ecx, ecx
        mov ecx, [ss:ebp]
        call .char
        pop ecx
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        ror edx, 16
        call Conv.hexToChar16

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        push ecx
        xor ecx, ecx
        mov ecx, [ss:ebp]
        call .char
        pop ecx
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        push ecx
        xor ecx, ecx
        mov ecx, [ss:ebp]
        call .char
        pop ecx
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        push ecx
        xor ecx, ecx
        mov ecx, [ss:ebp]
        call .char
        pop ecx
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        push ecx
        xor ecx, ecx
        mov ecx, [ss:ebp]
        call .char
        pop ecx
        inc edx

        pop ebx
        pop ebp
        ret

    .refresh:
        pusha
        push ds
        push es
        push fs
        push gs

        mov ax, 0xA0
        mov ds, ax

        mov ax, 0x28
        mov es, ax

        mov ax, 0x10
        mov fs, ax

        mov ax, 0x38
        mov gs, ax

        xor esi, esi
        xor edi, edi

        push word 0x32
        push word 0x50

        .refresh.loop:
            xor eax, eax
            lodsb ; read char

            mov edx, 25
            mul edx
            push eax

            lodsd ; read fg color
            mov ebx, eax
            lodsd ; read bg color
            mov edx, eax

            pop eax

            .refresh.print:
                mov ecx, 5
                push cx
                push cx

                ;push edi

                .refresh.print.0:
                    xor ecx, ecx
                    mov cl, [es:eax+Font.FontLength+4]

                    .refresh.print.0.1:

                    test cl, 1
                    jz .refresh.print.1.1

                        mov [gs:edi], ebx
                        jmp .refresh.print.1

                    .refresh.print.1.1:
                        mov [gs:edi], edx

                    .refresh.print.1:

                    test cl, 2
                    jz .refresh.print.2.1

                        mov [gs:edi+4], ebx
                        jmp .refresh.print.2

                    .refresh.print.2.1:
                        mov [gs:edi+4], edx

                    .refresh.print.2:

                    test ch, 1
                    jz .refresh.lowerHalf

                and ch, 0xFE
                pop edi
                add edi, 8

                inc eax
                pop cx
                dec cl
                push cx

                jnz .refresh.print.0

                pop cx
                pop cx
                dec cl
                push cx
                push word 5

                jnz .refresh.nextLine

            push eax
            mov eax, [fs:ScreenWidth]
            shl eax, 3
            mov ecx, 4
            mul ecx

            sub edi, eax
            pop eax

            pop cx
            pop cx
            pop cx
            dec cx
            push cx
            jnz .refresh.loop

            pop cx
            pop cx
            dec cx

            push eax
            mov eax, [fs:ScreenWidth]
            mov edi, 6
            mul edi
            shl eax, 3

            mov edi, ecx
            sub edi, 0x32
            not edi
            inc edi

            mul edi

            mov edi, eax

            pop eax

            cmp cx, 0
            push cx
            push word 0x50
            jnz .refresh.loop

        pop ecx

        pop gs
        pop fs
        pop es
        pop ds
        popa
        ret

            .refresh.nextLine:
                push eax
                mov eax, [fs:ScreenWidth]
                shl eax, 3
                sub eax, 4*5*2

                add edi, eax
                pop eax

                jmp .refresh.print.0

            .refresh.lowerHalf:
                shr ecx, 2
                or ch, 1

                push edi

                push eax
                mov eax, [fs:ScreenWidth]
                shl eax, 2
                add edi, eax
                pop eax

                jmp .refresh.print.0.1

    .charSyscall: ;eax - foreground color dword, ecx - background color dword, edx - Character location, esi - Character #
        push ebx
        mov ebx, esi

        call .char

        pop ebx
        ret

Draw:
    .rectangle: ; eax - colour dword, bx - x1, ebx>>16 - y1, cx - x2, ecx>>16 - y2
        push edi
        push esi
        push edx
        push es

        push eax
        mov ax, 0x10
        mov es, ax

        xor edx, edx
        mov dx, bx
        shr ebx, 16
        xor eax, eax
        mov ax, [es:ScreenWidth]
        push edx
        mul ebx
        pop edx
        mov edi, eax
        add edi, edx
        shl edi, 2

        xor esi, esi
        mov si, cx
        shr ecx, 16
        xor eax, eax
        mov ax, [es:ScreenWidth]

        sub edx, esi
        not edx
        inc edx

        mov esi, eax
        sub esi, edx

        push edx
        mul ecx
        pop edx
        mov ecx, eax
        add ecx, edx
        shl ecx, 2

        mov ax, 0x38
        mov es, ax

        pop eax

        shl esi, 2
        .rectangle.writeloop:
            push ecx
            mov ecx, edx
            rep stosd

            add edi, esi
            pop ecx
            cmp edi, ecx
            jl .rectangle.writeloop

        .rectangle.end:
            pop es
            pop edx
            pop esi
            pop edi
            ret
