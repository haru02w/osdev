[ORG 0x7C00] ;Set the origin offset needed by BIOS
[BITS 16] ;Set the address mode (16-bit Real Mode)

%define ENDL 0x0D,0x0A ; macro like #define in C


main:
        ; setup DS and ES registers
        ; DS - Data Segment, ES - Extra Segment
        MOV ax, 0 ;Since DS/ES can't be written directly
        MOV ds, ax
        MOV es, ax
        ;the above code is needed to setup segment and offset equal to all pcs
        ; since some pcs use segment 0x7C00 and offset 0

        ;Setup stack
        MOV ss, ax ;SS - stack segment
        ; stack grows downwards
        MOV sp, 0x7C00 ;SP - stack pointer

        ;#MAIN

        ;clear screen
        MOV ah,0x00
        MOV al,0x03
        INT 0x10

        

        ;print hello
        MOV si, string_hello
        CALL puts
        hlt

.halt:
        jmp .halt

puts:
        ; put registers into stack
        PUSH si ; SI - Source Index for arrays
        PUSH ax ; AX - general register
.loop:
        LODSB ; LODSW,LODSD - Load a byte/word/double-word
        ;       from DS:SI - Data Segment and Source Index
        ;       to Al/AX/EAX and increment SI

        OR al,al ; bitwise or from source -> destination
        JZ .done

        ; setup for BIOS interrupt
        MOV ah,0x0E
        MOV bh,0x0
        INT 0x10;BIOS interrupt

        JMP .loop
.done:
        ;take the registers back from stack
        POP ax
        POP si
        ;return from function
        RET

string_hello: DB "Hello Word!",ENDL,0

TIMES 510-($-$$) db 0
DW 0xAA55
