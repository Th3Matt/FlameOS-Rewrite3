
SnakeHead:
    .Forward:
        db 00011000b
        db 01111110b
        db 01111110b
        db 11011011b
        db 11111111b
        db 01111110b
        db 00111100b
        db 00111100b

    .Left:
        db 00011000b
        db 01111110b
        db 01101111b
        db 11111111b
        db 11111111b
        db 01101111b
        db 00111110b
        db 00011000b

    .Down:
        db 00111100b
        db 00111100b
        db 01111110b
        db 11111111b
        db 11011011b
        db 01111110b
        db 01111110b
        db 00111100b

    .Right:
        db 00011000b
        db 01111110b
        db 11110110b
        db 11111111b
        db 11111111b
        db 11110110b
        db 00111110b
        db 00011000b

SnakeBody:
    .Vertical:
        db 00111100b
        db 00111100b
        db 00111100b
        db 00111100b
        db 00111100b
        db 00111100b
        db 00111100b
        db 00111100b

    .Horizontal:
        db 00000000b
        db 00000000b
        db 11111111b
        db 11111111b
        db 11111111b
        db 11111111b
        db 00000000b
        db 00000000b

    .Empty:
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b

    .Empty2:
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b

SnakeBend:
   .UpLeft:
       db 00111100b
       db 00111100b
       db 11111100b
       db 11111100b
       db 11111100b
       db 11111000b
       db 00000000b
       db 00000000b

   .UpRight:
       db 00111100b
       db 00111100b
       db 00111111b
       db 00111111b
       db 00111111b
       db 00011111b
       db 00000000b
       db 00000000b

   .DownLeft:
       db 00000000b
       db 00000000b
       db 11111000b
       db 11111100b
       db 11111100b
       db 11111100b
       db 00111100b
       db 00111100b

   .DownRight:
       db 00000000b
       db 00000000b
       db 00011111b
       db 00111111b
       db 00111111b
       db 00111111b
       db 00111100b
       db 00111100b

SnakeTail:
    .Up:
        db 00111100b
        db 00111100b
        db 00111100b
        db 00011000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b

    .Left:
        db 00000000b
        db 00000000b
        db 11100000b
        db 11110000b
        db 11110000b
        db 11100000b
        db 00000000b
        db 00000000b

    .Down:
        db 00000000b
        db 00000000b
        db 00000000b
        db 00000000b
        db 00011000b
        db 00111100b
        db 00111100b
        db 00111100b

    .Right:
        db 00000000b
        db 00000000b
        db 00000111b
        db 00001111b
        db 00001111b
        db 00000111b
        db 00000000b
        db 00000000b

Food:
    .F1:
        db 00000000b
        db 00011000b
        db 00111100b
        db 01111110b
        db 01111110b
        db 00111100b
        db 00011000b
        db 00000000b


times 2*512-($-$$) db 0
