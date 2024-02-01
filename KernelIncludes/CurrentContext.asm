CurrentContext.AmmountOfContexts			equ CurrentContextVariables
CurrentContext.StartOfContexts			equ CurrentContextVariables+1
CurrentContext.ContextInfoSize			equ 0x10

CurrentContext:
    .addNew: ; ds:esi - context name string
        pusha
        push es

        mov di, 0x10
        mov es, di
        mov edi, CurrentContext.StartOfContexts

		movzx edi, byte es:[CurrentContext.AmmountOfContexts]
		shl edi, 4 ; *0x10
		add edi, CurrentContext.StartOfContexts

		mov ecx, CurrentContext.ContextInfoSize/4

		.addNew.loop:
            lodsd
            stosd

            loop .addNew.loop

		mov byte es:[edi-1], 0

        inc byte es:[CurrentContext.AmmountOfContexts]

		pop es
        popa
        ret

	.delContext:
		pusha
        push es

        mov di, 0x10
        mov es, di

        dec byte es:[CurrentContext.AmmountOfContexts]

		pop es
        popa
        ret
