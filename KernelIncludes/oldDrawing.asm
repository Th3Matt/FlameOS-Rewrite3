Print:
    .string:    ; eax - Pixel color, edx - First char printing location, esi - String start address, edi - String length, ds - string segment
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
            call .char
            inc edx

        .string.Check:
            cmp ecx, edi
            jle .string.loop

        pop ecx
        pop ebx
        ret

    .newLine: ; edx - Char pos
		push eax
		push ecx

		mov eax, edx
		xor edx, edx
		xor ecx, ecx
		push es

		mov cx, 0x10
		mov es, cx

		mov cx, [es:ScreenWidth]

        pop es
		push eax
		push ecx

		mov eax, 10
		xchg eax, ecx
		div ecx
		mov ecx, eax

		pop ecx
		add ecx, eax ; Extra pixel between chars vertically
		pop eax

		div ecx

		inc eax

		mul ecx

		mov edx, eax

		pop ecx
		pop eax

		ret


    .char:	;eax - Color dword, ebx - Character #, edx - Character location
        push esi
        push eax
        push ecx
        push edi
        push ebx
        push edx
        push gs
        push eax
        mov ax, 0x38
        mov gs, ax

        mov eax, [ds:Font.FontLength-0x20000]
        cmp eax, ebx
        jc .char.end

        mov eax, 5*4*2
        mul edx

        push eax

        mov eax, 25
        mul ebx

        pop edi
        mov ecx, 25
        xor edx, edx

        .char.print:
            mov bl, [ds:eax+Font.FontLength+4-0x20000]

            .char.print.0:

            test bl, 1
            jz .char.print.1

            push ebx
            add esp, 4
            pop ebx
            mov [gs:edi], ebx
            push ebx
            sub esp, 4
            pop ebx

            .char.print.1:

            test bl, 2
            jz .char.print.2

            push ebx
            add esp, 4
            pop ebx
            mov [gs:edi+4], ebx
            push ebx
            sub esp, 4
            pop ebx

            .char.print.2:

            test dh, 2
            jz .char.lowerHalf

            xor dh, 2
            rol ebx, 2
            sub edi, (800*4)-8

            inc eax
            inc edx
            cmp dl, 5
            je .char.nextLine
            loop .char.print

        .char.end:
            pop ebx
            pop gs
            pop edx
            pop ebx
            pop edi
            pop ecx
            pop eax
            pop esi
            ret

        .char.nextLine:
            mov dl, 0

            push es
            push eax

            mov ax, 0x10
            mov es, ax

            xor eax, eax
            mov eax, [es:ScreenWidth]
            shl eax, 3

            add edi, eax

            pop eax
            pop es

            sub edi, (5*2)*4

            loop .char.print
            jmp .char.end

        .char.lowerHalf:
            xor dh, 2
            ror ebx, 2

            push es
            push eax

            mov ax, 0x10
            mov es, ax

            xor eax, eax
            mov eax, [es:ScreenWidth]

            shl eax, 2
            add edi, eax

            pop eax
            pop es

            jmp .char.print.0

    .hex32:   ; eax - color dword, ecx - dword to print, edx - location on screen
        push ebx

        xchg ecx, edx
        ror edx, 16
        call Conv.hexToChar16

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        call .char
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        call .char
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        call .char
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        call .char
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        ror edx, 16
        call Conv.hexToChar16

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        call .char
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        call .char
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        push ebx
        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        call .char
        inc edx
        xchg ecx, edx ; ecx
        pop ebx

        shr ebx, 8

        shl ebx, 24
        shr ebx, 24
        xchg ecx, edx ; edx
        call .char
        inc edx

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

