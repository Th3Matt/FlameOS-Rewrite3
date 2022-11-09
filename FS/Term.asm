[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd 0x200

times 512-($-$$) db 0

Terminal:
    jmp $

db "This is a program."

times 512*3-($-Terminal) db 0
