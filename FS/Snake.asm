[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd Snake
	.Flags:       dd 00000000000000000000000000000001b

times 512-($-$$) db 0

Vars.X equ 0
Vars.Y equ 1
Vars.lastClockRecord equ 2
Vars.direction equ 6
Vars.directionListWritePtr equ 7
Vars.directionListReadPtr equ 9
Vars.snakeLength equ 11
Vars.TailX equ 13
Vars.TailY equ 14
Vars.Score equ 15
Vars.FoodX equ 19
Vars.FoodY equ 20
Vars.directionList equ 21

%define StartX 24
%define StartY 25
%define StartSize 9
%define MaxDirectionListSize 0x73B

%define XMin 0
%define YMin 4
%define XMax SCREEN_WIDTH/16-1  ;49
%define YMax SCREEN_HEIGHT/16-1 ;36

%define TargetFramerate 15
%xdefine LoopDelay (1/50/TargetFramerate)

%define SnakeColor 0x00BB8800
%define FoodColor 0x00BBBB00
%define BackgroundColor 0x00008800
%define MenuBackgroundColor BackgroundColor+Brighten

%define Brighten 0x00777777

%define SCREEN_WIDTH  800
%define SCREEN_HEIGHT 600

Snake:
	push cs
	pop ds

	mov ebx, 0x31
	mov esi, File

	int 0x30

	cmp eax, 0
	jnz .error1

	mov es, si

	mov ecx, 1
  mov ebx, 0x30
  int 0x30
  mov fs, si

  .mainMenu:
  	push es
 
    mov bx, fs
    mov es, bx
    xor edi, edi
    mov ecx, 0xFFF
    xor eax, eax

    rep stosd

  	mov bx, gs
	  mov es, bx

  	mov ecx, SCREEN_WIDTH*SCREEN_HEIGHT
    mov eax, MenuBackgroundColor
  	xor edi, edi
	  rep stosd

  	pop es

	  xor eax, eax
  	mov ecx, eax
  	mov edi, (SCREEN_WIDTH*4/2)+(SCREEN_WIDTH*(SCREEN_HEIGHT-5*2)*4/2)-(5*2*(Str.end-Str)*4/2)
  	not eax
  	mov esi, Str+1
  	xor edx, edx
  	mov dl, ds:[esi-1]
  	mov ebx, 6

  	int 0x30 ; Print line 1

  	mov edi, (SCREEN_WIDTH*4/2)+(SCREEN_WIDTH*4*(SCREEN_HEIGHT-5*2)/2)+(SCREEN_WIDTH*4*5*2)-(5*2*(Str2.end-Str2)*4/2)
  	mov esi, Str2+1
  	xor edx, edx
  	mov dl, ds:[esi-1]

  	int 0x30 ; Print line 2

	  mov edi, (SCREEN_WIDTH*4/2)+(SCREEN_WIDTH*4*(SCREEN_HEIGHT-5*2)/2)+(SCREEN_WIDTH*4*5*2*2)-(5*2*(Str3.end-Str3)*4/2)
  	mov esi, Str3+1
  	xor edx, edx
  	mov dl, ds:[esi-1]

	  int 0x30 ; Print line 2

	  .mainMenu.loop:
      mov ebx, 0x20
      int 0x30

      mov ebx, 0x10
      int 0x30
      cmp eax, 0x0
      jz .mainMenu.loop

      cmp eax, 0x15 ; Q
      jz .quit

      cmp eax, 0x29 ; Space
      jz .start

      jmp .mainMenu.loop

    .mainMenu.fromGame:
      mov ebx, 0x20
      int 0x30

	    mov ebx, 0x10
      int 0x30
      cmp eax, 0xF0 ; wait for q to be released
      jnz .mainMenu.fromGame

      mov ebx, 0x10
      int 0x30

      jmp .mainMenu

    .error1:
		  push es
		  mov bx, gs
		  mov es, bx

		  xor edi, edi
		  mov ecx, SCREEN_WIDTH*SCREEN_HEIGHT
		  xor eax, eax
		  rep stosd

		  push es

		  xor eax, eax
		  mov ecx, eax
		  xor edi, edi
		  not eax
		  mov esi, ErrorStr+1
		  xor edx, edx
		  mov dl, ds:[esi-1]
		  mov ebx, 6

		  int 0x30

		  .error1.wait:
			  mov ebx, 0x20
			  int 0x30

			  mov ebx, 0x20
			  int 0x30

			  mov ebx, 0x10
			  int 0x30
			  cmp eax, 0x0
			  jz .error1.wait

			  cmp eax, 0x15 ; Q
			  jz .quit

			  jmp .error1.wait

	.quit:
    xor edi, edi
    mov ebx, 0x22
    int 0x30

	.start:
		push es
		mov bx, gs
		mov es, bx

		xor edi, edi
    mov eax, MenuBackgroundColor
    mov ecx, SCREEN_WIDTH*4*(SCREEN_HEIGHT/36)
    
    rep stosd

		mov ecx, SCREEN_WIDTH*SCREEN_HEIGHT - SCREEN_WIDTH*4*(SCREEN_HEIGHT/36)
		mov eax, BackgroundColor

		rep stosd

		pop es

		mov byte fs:[Vars.X], StartX
		mov byte fs:[Vars.Y], StartY

		mov byte fs:[Vars.TailX], StartX
		mov byte fs:[Vars.TailY], StartY

		xor ebx, ebx
		mov word fs:[Vars.directionListWritePtr], bx
		mov word fs:[Vars.directionListReadPtr], bx

		mov word fs:[Vars.snakeLength], StartSize

		mov ebx, 0x40
		int 0x30

		add eax, LoopDelay
		mov fs:[Vars.lastClockRecord], eax

	.loop:
		.loop.wait:
      mov ebx, 0x20
      int 0x30

		  mov ebx, 0x40
		  int 0x30 ; get clock tick value

		  mov ebx, fs:[Vars.lastClockRecord]

		  cmp eax, ebx
		  jle .loop.wait

		  add eax, LoopDelay
		  mov fs:[Vars.lastClockRecord], eax

    call MainLoop.drawPreviousBodySegment
    call MainLoop.dealWithHead
    call MainLoop.drawHead
    call MainLoop.checkForSegments
    call MainLoop.dealWithTail
    call MainLoop.storeCurrentDirection
    call MainLoop.registerInput
    call MainLoop.spawnFood
    call MainLoop.drawFood
    call MainLoop.drawScore

		jmp .loop

MainLoop:
  .drawHead:
    pusha
   
    movzx esi, byte fs:[Vars.direction]

		mov edx, SnakeColor
		mov ebx, BackgroundColor

		movzx di, byte fs:[Vars.Y]
		shl edi, 16
		movzx di, byte fs:[Vars.X]

		call DrawInTiles ; draw face

    popa
    ret
  
  .dealWithHead:
    pusha

		xor eax, eax
		mov al, fs:[Vars.direction]

		test al, 00000010b
		jnz .dealWithHead.coordAdd

		.dealWithHead.coordSub:

		test al, 00000001b
		jnz .dealWithHead.coordSub.X
		.dealWithHead.coordSub.Y:
			cmp byte fs:[Vars.Y], YMin
			;jle .dealWithHead.coord.done
			jle .drawGameOver   
      dec byte fs:[Vars.Y]
			jmp .dealWithHead.coord.done

		.dealWithHead.coordSub.X:
			cmp byte fs:[Vars.X], XMin
			;jle .dealWithHead.coord.done
			jle .drawGameOver   
			dec byte fs:[Vars.X]
			jmp .dealWithHead.coord.done

		.dealWithHead.coordAdd:

		test al, 00000001b
		jnz .dealWithHead.coordAdd.X
		.dealWithHead.coordAdd.Y:
			cmp byte fs:[Vars.Y], YMax
			;jge .dealWithHead.coord.done
      jge .drawGameOver   
			inc byte fs:[Vars.Y]
			jmp .dealWithHead.coord.done

		.dealWithHead.coordAdd.X:
			cmp byte fs:[Vars.X], XMax
			;jge .dealWithHead.coord.done
      jge .drawGameOver   
			inc byte fs:[Vars.X]
			jmp .dealWithHead.coord.done

		.dealWithHead.coord.done:

    mov ax, fs:[Vars.FoodX]
    cmp fs:[Vars.X], ax ; check both coords at the same time
    jne .dealWithHead.end

    mov byte fs:[Vars.FoodX], 0
    mov byte fs:[Vars.FoodY], 0
    inc word fs:[Vars.snakeLength]
    add dword fs:[Vars.Score], 200

    .dealWithHead.end:
    
    popa
    ret

  .drawPreviousBodySegment: ; edi - location 
    pusha

		mov si, fs:[Vars.directionListWritePtr]
		cmp si, 0
		jnz .loop.previousDirection.done

		mov si, MaxDirectionListSize+1

		.loop.previousDirection.done:
		dec si

		movzx edx, byte fs:[si+Vars.directionList]

		shl edx, 2

    movzx eax, byte fs:[Vars.direction]
    add edx, eax

		movzx esi, byte ds:[edx+TurnTable]

		mov edx, SnakeColor
		mov ebx, BackgroundColor

		movzx di, byte fs:[Vars.Y]
		shl edi, 16
		movzx di, byte fs:[Vars.X]

		call DrawInTiles ; draw snake segment

    popa
    ret

  .dealWithTail:
    pusha	

		mov esi, 6 ; Empty space 

		mov edx, SnakeColor
		mov ebx, BackgroundColor

		movzx di, byte fs:[Vars.TailY]
		shl edi, 16
		movzx di, byte fs:[Vars.TailX]

		call DrawInTiles ; clear previous tail tile

    mov si, fs:[Vars.directionListReadPtr]
		push di
		mov di, fs:[Vars.directionListWritePtr]
		cmp di, si ; check if we went past the end of the list
		jge .dealWithTail.coord.notWraparound

		sub di, MaxDirectionListSize+1
		not di
		inc di

		add di, si

		jmp .dealWithTail.coord.wraparound.done

		.dealWithTail.coord.notWraparound:
		sub di, si

		.dealWithTail.coord.wraparound.done:

		cmp di, fs:[Vars.snakeLength]
		pop di
		jl .dealWithTail.coord.done

		xor eax, eax
		mov al, fs:[si+Vars.directionList]

		.dealWithTail.getDirection:
		inc word fs:[Vars.directionListReadPtr]
		inc si
		cmp si, MaxDirectionListSize+1
		jl .dealWithTail.coordCalc

		.dealWithTail.getDirection.overflow:
		
    mov word fs:[Vars.directionListReadPtr], 0
		
    .dealWithTail.coordCalc:
    
    test al, 00000010b
		jnz .dealWithTail.coordAdd

		.dealWithTail.coordSub:

		test al, 00000001b
		jnz .dealWithTail.coordSub.X
		.dealWithTail.coordSub.Y:
			cmp byte fs:[Vars.TailY], YMin
			jle .dealWithTail.coord.done
			dec byte fs:[Vars.TailY]
			jmp .dealWithTail.coord.done

		.dealWithTail.coordSub.X:
			cmp byte fs:[Vars.TailX], XMin
			jle .dealWithTail.coord.done
			dec byte fs:[Vars.TailX]
			jmp .dealWithTail.coord.done

		.dealWithTail.coordAdd:

		test al, 00000001b
		jnz .dealWithTail.coordAdd.X
		.dealWithTail.coordAdd.Y:
			cmp byte fs:[Vars.TailY], YMax
			jge .dealWithTail.coord.done
			inc byte fs:[Vars.TailY]
			jmp .dealWithTail.coord.done

		.dealWithTail.coordAdd.X:
			cmp byte fs:[Vars.TailX], XMax
			jge .dealWithTail.coord.done
			inc byte fs:[Vars.TailX]
			jmp .dealWithTail.coord.done

		.dealWithTail.coord.done:

		inc si
		movzx esi, byte fs:[si+Vars.directionList]
		add esi, 12

		mov edx, SnakeColor
		mov ebx, BackgroundColor

		movzx di, byte fs:[Vars.TailY]
		shl edi, 16
		movzx di, byte fs:[Vars.TailX]

		call DrawInTiles

    popa
    ret
  
  .storeCurrentDirection:
    pusha
		mov al, fs:[Vars.direction]

		mov si, fs:[Vars.directionListWritePtr]
		mov fs:[si+Vars.directionList], al

		cmp si, MaxDirectionListSize
		jge .storeCurrentDirection.overflow

		inc word fs:[Vars.directionListWritePtr]
		jmp .storeCurrentDirection.end

		 .storeCurrentDirection.overflow:
			mov word fs:[Vars.directionListWritePtr], 0

    .storeCurrentDirection.end:
    
    popa
    ret

  .registerInput:
    pusha
		mov ebx, 0x10
		int 0x30
		cmp eax, 0x0
		jz .registerInput.end

		cmp eax, 0x15 ; Q
    jz .registerInput.quit

		cmp eax, 0x1D ; W
		jnz .registerInput.notUp
    
    cmp fs:[Vars.direction], byte 2
    je .registerInput.end
		mov fs:[Vars.direction], byte 0
		jmp .registerInput.end

		.registerInput.notUp:

		cmp eax, 0x1C ; A
		jnz .registerInput.notLeft

    cmp fs:[Vars.direction], byte 3
    je .registerInput.end
		
    mov fs:[Vars.direction], byte 1
		jmp .registerInput.end

		.registerInput.notLeft:

		cmp eax, 0x1B ; S
		jnz .registerInput.notDown

    cmp fs:[Vars.direction], byte 0
    je .registerInput.end
		mov fs:[Vars.direction], byte 2
		jmp .registerInput.end

		.registerInput.notDown:

		cmp eax, 0x23 ; D
		jnz .registerInput.end

    cmp fs:[Vars.direction], byte 1
    je .registerInput.end
		mov fs:[Vars.direction], byte 3
		jmp .registerInput.end 
		
    .registerInput.end:
    
    popa
    ret

    .registerInput.quit:
      popa
      jmp Snake.mainMenu.fromGame

  .spawnFood:
    pusha

    cmp word fs:[Vars.FoodX], 0
    jnz .spawnFood.end

    mov ebx, 0x50
    int 0x30

    push eax

    xor edx, edx
    mov ecx, XMax-XMin-1
    div ecx

    add edx, XMin
    mov fs:[Vars.FoodX], dl

    pop eax

    xor edx, edx
    mov ecx, YMax-YMin-1
    div ecx

    add edx, YMin
    mov fs:[Vars.FoodY], dl

    .spawnFood.end:
    popa
    ret

  .drawFood:
    pusha
     
    cmp word fs:[Vars.FoodX], 0
    jz .drawFood.end

    mov esi, 16
		mov edx, FoodColor
		mov ebx, BackgroundColor

		movzx di, byte fs:[Vars.FoodY]
		shl edi, 16
		movzx di, byte fs:[Vars.FoodX]

		call DrawInTiles 
   
    .drawFood.end:
      popa
      ret

  .drawScore:
    pusha

    xor eax, eax
  	mov ecx, MenuBackgroundColor
  	mov edi, (SCREEN_WIDTH*4/2)-(5*2*(ScoreStr.end-ScoreStr)*4/2)+(SCREEN_WIDTH*4*10)
  	mov esi, ScoreStr+1
  	xor edx, edx
  	mov dl, ds:[esi-1]
  	mov ebx, 6

  	int 0x30
    
    mov edx, fs:[Vars.Score]
    mov ebx, 0xA

    int 0x30

    popa
    ret

  .drawGameOver:
    popa
    xor eax, eax
    not eax
  	mov ecx, 0x00880000
  	mov edi, (SCREEN_WIDTH*4/2)-(5*2*(GameOverStr.end-GameOverStr)*4/2)+(SCREEN_WIDTH*4*(SCREEN_HEIGHT)/2)
  	mov esi, GameOverStr+1
  	xor edx, edx
  	mov dl, ds:[esi-1]
  	mov ebx, 6

  	int 0x30

    mov ebx, 0x40
    int 0x30

    mov edx, eax
    add edx, 50

    .drawGameOver.wait:
      mov ebx, 0x20
      int 0x30

		  mov ebx, 0x40
		  int 0x30 ; get clock tick value

		  cmp eax, edx
		  jle .drawGameOver.wait

    jmp Snake.mainMenu

  .checkForSegments:
    pusha

    xor esi, esi
    mov si, fs:[Vars.directionListReadPtr]
    mov al, fs:[Vars.X]
    mov ah, fs:[Vars.Y]
    mov bl, fs:[Vars.TailX]
    mov bh, fs:[Vars.TailY]

    cmp ax, bx
    je .drawGameOver

    cmp si, fs:[Vars.directionListWritePtr]
    je .checkForSegments.done

    .checkForSegments.loop:
      mov cl, fs:[esi+Vars.directionList]
      inc si

      test cl, 00000010b
      jnz .checkForSegments.loop.add
      .checkForSegments.loop.sub:
        .checkForSegments.loop.subY:
          cmp cl, 0
          jne .checkForSegments.loop.subX

          dec bh

          jmp .checkForSegments.loop.check

        .checkForSegments.loop.subX:
          cmp cl, 1
          jne .checkForSegments.loop.check

          dec bl

          jmp .checkForSegments.loop.check
      .checkForSegments.loop.add:
        .checkForSegments.loop.addY:
          cmp cl, 2
          jne .checkForSegments.loop.addX

          inc bh

          jmp .checkForSegments.loop.check

        .checkForSegments.loop.addX:
          cmp cl, 3
          jne .checkForSegments.loop.check

          inc bl

          jmp .checkForSegments.loop.check

      .checkForSegments.loop.check:

      cmp si, MaxDirectionListSize
      jng .checkForSegments.loop.check.1

      xor esi, esi
      
      .checkForSegments.loop.check.1:

      cmp ax, bx
      je .drawGameOver

      cmp si, fs:[Vars.directionListWritePtr]
      jne .checkForSegments.loop

    .checkForSegments.done:

    popa
    ret


TurnTable:
	.a:
		.aa:
			db 4
		.ab:
			db 10
		.ac:
			db 4
		.ad:
			db 11
	.b:
		.ba:
			db 9
		.bb:
			db 5
		.bc:
			db 11
		.bd:
			db 5
	.c:
		.ca:
			db 4
		.cb:
			db 8
		.cc:
			db 4
		.cd:
			db 9
	.d:
		.da:
			db 8
		.db:
			db 5
		.dc:
			db 10
		.dd:
			db 5

DrawInTiles:; es:esi - sprite, di - x, edi>>16 - y, edx - foreground color, ebx - background color
	push edi
	push esi
	xor esi, esi
	mov si, di
	shl esi, 3 ; times 8 - tile size
	shr edi, 16

	push eax
	push edx

	mov eax, SCREEN_WIDTH*4*2
	mul edi

	add esi, eax

	pop edx
	pop eax

	mov edi, esi
	pop esi
	shl esi, 3

	call DrawSprite

	pop edi

	ret

DrawSprite: ; es:esi - sprite, gs:edi - screen, edx - foreground color, ebx - background color
	push 8
	push 8

	.loop:
		xor eax, eax
		mov al, [es:esi]
		rol al, 1

		.loop.loop:
			test al, 00000001b
			jz .loop.loop.dont

			push ebx
			mov ebx, edx
			call DrawBlock
			pop ebx

			jmp .loop.loop.done

			.loop.loop.dont:

			call DrawBlock

			.loop.loop.done:

			inc edi
			rol al, 1
			pop ecx
			dec ecx
			push ecx
			jnz .loop.loop

		add edi, (SCREEN_WIDTH/2-4)*2
		inc esi
		pop ecx
		pop ecx
		dec ecx
		push ecx
		push 8
		jnz .loop

	pop ecx
	pop ecx

	ret

DrawBlock:
	push edi
	shl edi, 1+2

	mov gs:[edi], ebx
	mov gs:[edi+4], ebx

	add edi, (SCREEN_WIDTH)*4

	mov gs:[edi], ebx
	mov gs:[edi+4], ebx

	pop edi
	ret

Str: db .end-$-1, "Snake v0.1.0"
	.end:
Str2: db .end-$-1, "Press Space to start, q to quit"
	.end:
Str3: db .end-$-1, "WASD to move."
	.end:
ErrorStr: db .end-$-1, "Error: data file missing."
	.end:
ScoreStr: db .end-$-1, "Score: " 
  .end:
GameOverStr: db .end-$-1, "GAME OVER" 
  .end:

File: db "/SnakeData.dat", 0


times 512*4-($-Snake) db 0
