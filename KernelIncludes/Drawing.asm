
TMV.NextPlaceToPrintChar        equ TextModeVariableSpace ; 4 bytes

SOB.currentlySelectedEntry      equ ScreenOwnershipBuffer ; 1 byte
SOB.buffer                      equ SOB.currentlySelectedEntry+1 ; 8*1 bytes

;SOB buffer entry structure
    SOB.bufferEntry.flags       equ 0
    SOB.bufferEntry.PID         equ 2
    SOB.bufferEntry.segment     equ 6

Print:
  .updateVariables:
    pusha
    push ds

    mov ax, Segments.Variables
    mov ds, ax

    mov eax, [ds:ScreenWidth]
		mov ecx, [ds:ScreenHeight]
    mul ecx

    mov ds:[TotalPixels], eax ; precalculating total count of pixels

    mov eax, [ds:ScreenWidth]
		mov ecx, 10
		xor edx, edx
    div ecx

    mov ds:[CharsPerLine], eax

    mov eax, [ds:ScreenHeight]
		mov ecx, 12
		xor edx, edx
    div ecx

    mov ds:[LinesPerScreen], eax

    mov eax, [ds:CharsPerLine]
		mov ecx, [ds:LinesPerScreen]
    mul ecx

    mov ds:[TotalChars], eax ; precalculating total count of chars that can be on screen

    pop ds
    popa
    ret

  .clearScreen:
    pusha
    push gs
    push ds

    mov ax, Segments.Variables
    mov ds, ax

    mov ecx, ds:[TotalPixels]
    mov ax, Segments.VRAM_Graphics
    mov gs, ax
    xor edi, edi

    .clearScreen.loop:
      mov dword [gs:edi], 0
      add edi, 4
      loop .clearScreen.loop

    push edx
    mov ecx, ds:[TotalChars]
    mov eax, 9 ; nine bytes per char
    mul ecx
    mov ecx, 4 ; writing dwords
    xor edx, edx
    div ecx
    mov ecx, eax
    pop edx

    mov ax, Segments.CharmapOfScreen
    mov gs, ax
    xor edi, edi

    .clearScreen.loop2:
      mov dword [gs:edi], 0
      add edi, 4
      loop .clearScreen.loop2


    mov ax, Segments.Variables
    mov gs, ax
    mov gs:[TMV.NextPlaceToPrintChar], dword 0

    pop ds
    pop gs
    popa
    ret

  .charAtLocation:	;eax - foreground color dword, ebx - Character #, ecx - background color dword, edx - Character location
    push gs
    push edx
    push ecx
    push eax

    mov ax, Segments.CharmapOfScreen
    mov gs, ax

    xchg eax, edx

    mov ecx, 9
    mul ecx

    xchg eax, edx

    pop eax

    mov gs:[edx], bl
    pop ecx

    mov gs:[edx+1], eax
    mov gs:[edx+5], ecx

    pop edx
    pop gs
    ret

  .char:	;eax - foreground color dword, ebx - Character #, ecx - background color dword
    push gs
    push edx
    push eax
    mov ax, Segments.Variables
    mov gs, ax
    pop eax

    mov edx, gs:[TMV.NextPlaceToPrintChar]

    call .charAtLocation
    inc edx

    mov gs:[TMV.NextPlaceToPrintChar], edx

    pop edx
    pop es
    ret

  .charSyscall: ;eax - foreground color dword, ecx - background color dword, esi - Character #
    push ebx
    mov ebx, esi

    call .char

    pop ebx
    ret

  .stringAtLocation:    ; eax - Pixel color, ecx - background color dword, edx - First char printing location, ds:esi - String start address, edi - String length
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
      call .charAtLocation
      pop ecx
      inc edx

    .string.Check:
      cmp ecx, edi
      jle .string.loop

    pop ecx
    pop ebx
    ret

  .stringWithSize:    ; eax - Pixel color, ecx - background color dword, ds:esi - String start address, edi - String length
    push es
    push edx
    push eax
    mov ax, Segments.Variables
    mov es, ax
    pop eax

    mov edx, es:[TMV.NextPlaceToPrintChar]

    call .stringAtLocation

    mov es:[TMV.NextPlaceToPrintChar], edx

    pop edx
    pop es
    ret

  .string:    ; eax - Pixel color, ecx - background color dword, ds:esi - String start address
    push edi
    push esi

    movzx edi, byte [esi]
    inc esi

    call .stringWithSize

    pop esi
    pop edi
    ret

  .newLineFromLocation:   ; edx - Char pos
		push eax
		push ecx
		;xchg bx, bx

		push es

		mov cx, Segments.Variables
		mov es, cx

		mov eax, [es:CharsPerLine]

    xchg eax, edx

    push edx
    mov ecx, edx
    xor edx, edx
    div ecx
    pop edx

    inc eax
    mul edx
    mov edx, eax

    cmp edx, [es:TotalChars]
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

  .newLine:
    push es
    push eax

    mov ax, Segments.Variables
    mov es, ax

    pop eax

    mov edx, es:[TMV.NextPlaceToPrintChar]

    call .newLineFromLocation

    mov es:[TMV.NextPlaceToPrintChar], edx

    pop es
    ret

  .decCursorPos: ; eax - how much to decrease
    push es
    push edx
    push eax
    mov ax, Segments.Variables
    mov es, ax
    pop eax

    sub dword es:[TMV.NextPlaceToPrintChar], eax

    pop edx
    pop es
    ret

  .resetCurrentCursorPos:
    push edx
    xor edx, edx
    call .setCurrentCursorPos
    pop edx
    ret

  .setCurrentCursorPos:    ; edx - cursor position
    push es
    push edx
    push eax
    mov ax, Segments.Variables
    mov es, ax
    pop eax

    mov es:[TMV.NextPlaceToPrintChar], edx

    pop edx
    pop es
    ret

  .scrollDown:
    pusha

		push es

		mov cx, Segments.Variables
		mov es, cx

    mov eax, [es:CharsPerLine]
    mov ecx, 9
    mul ecx

    mov esi, eax
    xor edi, edi

    mov ecx, es:[TotalChars]
    sub ecx, es:[CharsPerLine]
    mov eax, 9 ; nine bytes per char
    mul ecx
    mov ecx, 4 ; writing dwords
    xor edx, edx
    div ecx
    mov ecx, eax

    mov ax, Segments.CharmapOfScreen

    push ds

    mov ds, ax
    mov es, ax

    rep movsd
        
    push es

		mov cx, Segments.Variables
		mov es, cx
    mov ecx, es:[CharsPerLine]

    pop es

    mov eax, 9
    mul ecx

    mov ecx, eax
    xor eax, eax

    rep stosb

    pop ds
    pop es

    popa
    ret

  .fillScreen: ; ecx - color
    push ecx
    push edi
    push gs

		mov cx, Segments.Variables
		mov gs, cx

    mov ecx, gs:[TotalChars]
    push eax
    mov ax, Segments.CharmapOfScreen
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

  .dec32AtLocation: ; eax - color dword, ebx - dword to print, ecx - bg color dword, edx - location on screen
    push ebx
    push edi
    push ebp

    mov ebp, esp
    mov edi, edx
    mov edx, ebx

    .dec32AtLocation.convert:
      call Conv.hexToBCD32

      push ebx
      jc .dec32AtLocation.convert

      mov edx, edi

      pop ebx
      call .dec32AtLocation.printFirst

      cmp esp, ebp
      jz .dec32AtLocation.end

    .dec32AtLocation.printLoop:
      pop ebx
      ;STOP_AND_CHECK eax
      call .hex32AtLocation

      cmp esp, ebp
      jnz .dec32AtLocation.printLoop

    .dec32AtLocation.end:

    pop ebp
    pop edi
    pop ebx
    ret

    .dec32AtLocation.printFirst: ; this gets rid of zeros before the number
			push edi
			push esi
			mov edi, 0xF0000000
			mov esi, 7

			.dec32AtLocation.printFirst.loop:
				test edi, ebx
				jnz .dec32AtLocation.printFirst.print

				dec esi
				shr edi, 4
				jnz .dec32AtLocation.printFirst.loop

				mov esi, 0
				mov edi, 0xF

				.dec32AtLocation.printFirst.print:
					push ebx

					push ecx
					mov ecx, esi
					shl ecx, 2

					and ebx, edi
					shr ebx, cl

					pop ecx

					push eax
					push edx
					mov edx, ebx

					call Conv.hexToChar8
					;STOP_AND_CHECK eax

					movzx ebx, al

					pop edx
					pop eax

					call .charAtLocation
					inc edx

					pop ebx
					dec esi
					shr edi, 4
					jnz .dec32AtLocation.printFirst.print

			pop esi
			pop edi
			ret

  .dec32:          ; eax - color dword, ebx - dword to print, ecx - bg color dword
    push gs
    push edx
    push eax
    mov ax, Segments.Variables
    mov gs, ax
    pop eax

    mov edx, gs:[TMV.NextPlaceToPrintChar]

    call .dec32AtLocation

    mov gs:[TMV.NextPlaceToPrintChar], edx

    pop edx
    pop gs
    ret
  
  .dec32_Syscall:    ; eax - color dword, ecx - bg color dword, edx - dword to print
    push ebx
    mov ebx, edx

    call .dec32

    pop ebx
    ret

  .hex32AtLocation:   ; eax - color dword, ebx - dword to print, ecx - bg color dword, edx - location on screen
    push ebx
    push edi
    
    xchg edi, edx
    mov edx, ebx
    call Conv.reverseBytes
    call Conv.hexToChar16
    push ebx
    
    shr edx, 16
    call Conv.hexToChar16
    push ebx
    xchg edi, edx
    
    mov edi, 8
    xchg edi, ecx
    xor ebx, ebx

    .hex32AtLocation.loop:
      xchg edi, ecx
      sub esp, 1
      pop bx
      shr bx, 8
      call .charAtLocation
      inc edx
      xchg edi, ecx

      loop .hex32AtLocation.loop
    
    xchg edi, ecx

    pop edi
    pop ebx
    ret
  
  .hex32:             ; eax - color dword, ebx - dword to print, ecx - bg color dword
    push gs
    push edx
    push eax
    mov ax, Segments.Variables
    mov gs, ax
    pop eax

    mov edx, gs:[TMV.NextPlaceToPrintChar]

    call .hex32AtLocation

    mov gs:[TMV.NextPlaceToPrintChar], edx

    pop edx
    pop gs
    ret

  .hex32_Syscall:				; eax - color dword, edx - dword to print, ecx - bg color dword
    mov ebx, edx

    call .hex32

    ret

	.context: ; eax - Pixel color, ecx - background color dword.
		pusha
		push ds

		mov si, 0x10
		mov ds, si

		movzx esi, byte ds:[CurrentContext.AmmountOfContexts]
		dec esi
		shl esi, 4 ; *0x10
		add esi, CurrentContext.StartOfContexts

		call .string

		pop ds
		popa
		ret

	.prefixedString:				; eax - Pixel color, ecx - background color dword, ds:esi - String start address
		pusha

		call .context

		call .string

		popa
		ret

  .addFramebuffer: ; ecx - PID, si - new framebuffer segment
    push eax
    push es

    mov ax, Segments.Variables
    mov es, ax

    xor eax, eax
    mov al, byte es:[SOB.currentlySelectedEntry]
    inc byte es:[SOB.currentlySelectedEntry]
    shl al, 2
    mov word es:[SOB.buffer+eax+SOB.bufferEntry.flags], 1b   ; setting flags
    mov es:[SOB.buffer+eax+SOB.bufferEntry.PID], ecx         ; setting PID
    mov es:[SOB.buffer+eax+SOB.bufferEntry.segment], si      ; setting segment

    pop es
    pop eax

    ret

  .delFramebuffer: ; ecx - PID
    push eax
    push es

    mov ax, Segments.Variables
    mov es, ax

    xor eax, eax
    mov al, byte es:[SOB.currentlySelectedEntry]
    dec eax
    shl eax, 2

    cmp dword es:[SOB.buffer+eax+SOB.bufferEntry.PID], ecx ; checking if the framebuffer was created for this process
    stc
    jne .delFramebuffer.end

    dec byte es:[SOB.currentlySelectedEntry]
    mov word es:[SOB.buffer+eax+SOB.bufferEntry.flags], 0   ; clearing flags
    mov dword es:[SOB.buffer+eax+SOB.bufferEntry.PID], 0    ; clearing PID
    mov word es:[SOB.buffer+eax+SOB.bufferEntry.segment], 0 ; clearing segment

    clc
    .delFramebuffer.end:
    pop es
    pop eax

    ret

  .refresh:
    pusha
    push ds
    push es
    push fs

    mov ax, Segments.Variables
    mov fs, ax

    cmp bx, 0xFFFF
    jz .refresh.textMode

    cmp byte fs:[SOB.currentlySelectedEntry], 0
    jz .refresh.textMode

    xor ecx, ecx
    mov cl, fs:[SOB.currentlySelectedEntry]
    dec cl
    shl cl, 2

    mov ds, fs:[SOB.buffer+ecx+SOB.bufferEntry.segment]
    ;mov cx, fs:[SOB.buffer+ecx]

    mov ax, Segments.VRAM_Graphics
    mov es, ax

    xor edi, edi
    xor esi, esi
    mov ecx, fs:[TotalPixels]

    rep movsd

    jmp .refresh.return

    .refresh.textMode:
      push gs

      mov ax, Segments.CharmapOfScreen
      mov ds, ax

      mov ax, Segments.KernelCode
      mov es, ax

      mov ax, Segments.VRAM_Graphics
      mov gs, ax

      xor esi, esi
      xor edi, edi

      mov eax, fs:[LinesPerScreen]

      push eax

      .refresh.textMode.newLine:
        mov eax, fs:[CharsPerLine]

        push eax

        .refresh.textMode.newLine.newChar:
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

          ; drawing pixels to seperate lines

          mov ecx, 10

          .refresh.textMode.newLine.newChar.sLine.1:
            mov [gs:ecx*4+edi], edx
            loop .refresh.textMode.newLine.newChar.sLine.1

            mov [gs:ecx*4+edi], edx

            push eax
            mov eax, [fs:ScreenWidth]
            shl eax, 2
            add edi, eax ; go to next line
            pop eax
            mov ecx, 5
            push ecx

            .refresh.textMode.newLine.newChar.0:

            xor ebp, ebp
            mov bp, [es:eax+Font.FontLength+4]
            and bp, 0x00ff

            .refresh.textMode.newLine.newChar.0.1:

            test bp, 1
            jz .refresh.textMode.newLine.newChar.1.1

            mov [gs:edi], ebx
            jmp .refresh.textMode.newLine.newChar.1

            .refresh.textMode.newLine.newChar.1.1:
              mov [gs:edi], edx

            .refresh.textMode.newLine.newChar.1:

            test bp, 2
            jz .refresh.textMode.newLine.newChar.2.1

            mov [gs:edi+4], ebx
            jmp .refresh.textMode.newLine.newChar.2

            .refresh.textMode.newLine.newChar.2.1:
              mov [gs:edi+4], edx

            .refresh.textMode.newLine.newChar.2:

            test bp, 100h
            jz .refresh.textMode.newLine.newChar.lowerHalf

            inc eax ; next block

            push eax
            mov eax, [fs:ScreenWidth]
            shl eax, 2
            sub edi, eax ; back one line
            pop eax

            add edi, 2*4 ; two pixels forward

            dec ecx
            jnz .refresh.textMode.newLine.newChar.0

            jmp .refresh.textMode.newLine.newChar.nextLine

            ; drawing pixels to seperate lines

            .refresh.textMode.newLine.newChar.sLine.2.prep:

            mov ecx, 10

            .refresh.textMode.newLine.newChar.sLine.2:
              mov [gs:ecx*4+edi], edx
              loop .refresh.textMode.newLine.newChar.sLine.2

            mov [gs:ecx*4+edi], edx
            add edi, 2*5*4 ; ten pixels forward

            pop ecx
            dec ecx
            jz .refresh.textMode.newLine.prep

            push ecx

            push eax
            mov eax, [fs:ScreenWidth]
            shl eax, 2
            push edx
            mov ecx, 11
            mul ecx
            pop edx
            sub edi, eax ; twelve lines back
            pop eax

            jmp .refresh.textMode.newLine.newChar

        .refresh.textMode.newLine.prep:
          pop ecx
          dec ecx
          jz .refresh.textMode.end

          push ecx
          jmp .refresh.textMode.newLine

    .refresh.textMode.end:
      pop gs

  .refresh.return:
  
  pop fs
  pop es
  pop ds
  popa
  ret

          .refresh.textMode.newLine.newChar.nextLine:
            push eax
            mov eax, [fs:ScreenWidth]
            shl eax, 3
            add edi, eax ; two lines forwards
            pop eax

            sub edi, 2*5*4 ; ten pixels (one char width) back

            pop ecx
            dec ecx
            jz .refresh.textMode.newLine.newChar.sLine.2.prep ; if done drawing char

            push ecx
            mov ecx, 5

            jmp .refresh.textMode.newLine.newChar.0

          .refresh.textMode.newLine.newChar.lowerHalf:
            shr ebp, 2
            or bp, 100h ; set flag for second part of block

            push eax
            mov eax, [fs:ScreenWidth]
            shl eax, 2
            add edi, eax ; go to next line
            pop eax

            jmp .refresh.textMode.newLine.newChar.0.1

Draw:
  .rectangle: ; eax - colour dword, bx - x1, ebx>>16 - y1, cx - x2, ecx>>16 - y2
    push edi
    push esi
    push edx
    push es

    push eax
    mov ax, Segments.Variables
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

    mov ax, Segments.VRAM_Graphics
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

  .writeChar: ; eax - foreground color dword, ecx - background color dword, edx - Character #, edi - character position, gs - framebuffer segment.
    push edx
    push edi
    push esi
    push fs
    push es
    push ecx

    push eax
    mov ax, Segments.Variables
    mov fs, ax

    mov ax, 0x28
    mov es, ax
    pop eax

    mov ecx, edx
    xchg eax, ecx
    mov edx, 25
    mul edx
    xchg ecx, eax
    mov edx, ecx

    xor ecx, ecx

    .writeChar.print:
      mov si, [es:edx+Font.FontLength+4]
      and si, 0xff

      test si, 1
      jz .writeChar.print.1.1

      mov [gs:edi], eax
      jmp .writeChar.print.1

      .writeChar.print.1.1:
      push eax
      add esp, 4
      pop eax
      mov [gs:edi], eax
      push eax
      sub esp, 4
      pop eax

      .writeChar.print.1:

      test si, 2
      jz .writeChar.print.2.1

      mov [gs:edi+4], eax
      jmp .writeChar.print.2

      .writeChar.print.2.1:
      push eax
      add esp, 4
      pop eax
      mov [gs:edi+4], eax
      push eax
      sub esp, 4
      pop eax

      .writeChar.print.2:

      push eax
      mov eax, [fs:ScreenWidth]
      shl eax, 2
      add edi, eax
      pop eax

      test si, 100b
      jz .writeChar.print.3.1

      mov [gs:edi], eax
      jmp .writeChar.print.3

      .writeChar.print.3.1:
      push eax
      add esp, 4
      pop eax
      mov [gs:edi], eax
      push eax
      sub esp, 4
      pop eax

      .writeChar.print.3:

      test si, 1000b
      jz .writeChar.print.4.1

      mov [gs:edi+4], eax
      jmp .writeChar.print.4

      .writeChar.print.4.1:
      push eax
      add esp, 4
      pop eax
      mov [gs:edi+4], eax
      push eax
      sub esp, 4
      pop eax

      .writeChar.print.4:

      push eax
      mov eax, [fs:ScreenWidth]
      shl eax, 2
      sub edi, eax
      add edi, 2*4
      pop eax

      inc cl
      inc edx

      cmp cl, 5
      jl .writeChar.print

      xor cl, cl
      inc ch

      push eax
      mov eax, [fs:ScreenWidth]
      shl eax, 3
      add edi, eax
      sub edi, 5*2*4
      pop eax

      cmp ch, 5
      jl .writeChar.print

    pop ecx

    pop es
    pop fs
    pop esi
    pop edi
    add edi, 5*2*4

    pop edx
    ret

  .writeStr: ; eax - foreground color dword, ecx - background color dword, edx - string length, edi - string position, ds:esi - string address, gs - framebuffer segment.
    push ebx
    push edx

    mov ebx, edx

    .writeStr.loop:
      mov dl, ds:[esi]
      call .writeChar

      inc esi
      dec ebx
      jnz .writeStr.loop

    pop edx
    pop ebx
    ret

  .writeHex32:   ; eax - color dword, ecx - bg color dword, edx - dword to print, edi - location on screen
    pusha
    
    call Conv.reverseBytes
    call Conv.hexToChar16
    push ebx
    
    shr edx, 16
    call Conv.hexToChar16
    push ebx
    
    mov ebx, 8
    xchg ebx, ecx
    xor edx, edx

    .hex32AtLocation.loop:
      xchg ebx, ecx
      sub esp, 1
      pop dx
      shr dx, 8
      call .writeChar
      xchg ebx, ecx
      loop .hex32AtLocation.loop

    popa
    ret

  .writeDec32: ; eax - color dword, ecx - bg color dword, edx - dword to print, edi - location on screen, gs - framebuffer segment
    pusha

    mov ebp, esp
    mov esi, edx

    .writeDec32.convert:
      call Conv.hexToBCD32

      push ebx
      jc .writeDec32.convert

    mov edx, esi

    pop ebx
    call .writeDec32.printFirst

    cmp esp, ebp
    jz .writeDec32.end

    .writeDec32.printLoop:
      pop ebx
      ;STOP_AND_CHECK eax
      call .writeHex32

      cmp esp, ebp
      jnz .writeDec32.printLoop

    .writeDec32.end:

    popa
    ret

    .writeDec32.printFirst: ; this gets rid of zeros before the number
			push edi
			push esi
      
      push edi
      mov edi, 0xF0000000
			mov esi, 7

			.writeDec32.printFirst.loop:
				test edi, ebx
				jnz .writeDec32.printFirst.prePrint

				dec esi
        shr edi, 4

				jnz .writeDec32.printFirst.loop

				mov esi, 0

      .writeDec32.printFirst.prePrint:
        pop edi
        
			.writeDec32.printFirst.print:
				push ebx

				push ecx
				mov ecx, esi
				shl ecx, 2

				shr ebx, cl
        and ebx, 0xF

				pop ecx

				push eax
				mov edx, ebx

				call Conv.hexToChar8
				;STOP_AND_CHECK eax

				movzx edx, al

				pop eax

				call .writeChar

				pop ebx
				dec esi
				jns .writeDec32.printFirst.print

			pop esi
			pop edi
			ret
