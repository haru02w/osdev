[ORG 0x7C00] ;Set the origin offset needed by BIOS
[BITS 16] ;Set the address mode (16-bit Real Mode)
%define ENDL 0x0D,0x0A ; macro like #define in C

;FAT12 header-------------------------------------------------------------------

JMP SHORT main
NOP

; Name of bootsector
bdb_oem: DB "MSWIN4.1";8-byte long. For compatibility but could be anything.

;sector - pizza slices of disk
bdb_bytes_per_sector: DW 512

; cluster - unit of allocation. Define the minimum size of a file in disk
bdb_sectors_per_cluster: DB 1

; reserved_sectors - includes boot sector
bdb_reserved_sectors: DW 1

; number of file allocation tables
bdb_fat_count: DB 2

; define numbers of fat entries in tables (maximum number of files)
bdb_dir_entries_count: DW 0x00E0;

; define the size of disk
bdb_total_sectors: DW 2880; times 512 = 1.44KB

; define type of disk
bdb_media_descriptor_type: DB 0xF0; ;F0 - 3.5" floppy disk

; size of fat tables
bdb_sectors_per_fat: DW 9

; size of a track (height)
bdb_sectors_per_track: DW 18

; how many heads the disk have
bdb_heads: DW 2

bdb_hidden_sectors: DD 0
bdb_large_sector_count: DD 0

;Extended Boot Record
ebr_drive_number: DB 0 ; BIOS will give it
                DB 0; reserved

ebr_signature: DB 0x29 ; MUST BE 0x28 or 0x29 - reserved

ebr_volume_id: DD 0x12345678 ; serial number - can be anything

ebr_volume_label: DB "Haru02w OS " ; 11bytes long

ebr_system_id: DB "FAT12   " ; 8 bytes long

;end of FAT12 header------------------------------------------------------------


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

        MOV [ebr_drive_number],dl ;BIOS set dl as disk number
        MOV ax,1 ; LBA = 1, second sector from disk
        MOV cl,1 ; 1 sector to read
        MOV bx, 0x7E00 ; Data should be after the bootloader
        CALL disk_read ; Call functions

        ;clear screen
        MOV ah,0x00
        MOV al,0x03
        INT 0x10

        ;print hello
        MOV si, msg_hello; SI - Source Index for string operations
        CALL puts
        CLI ;disable interrupts
        HLT
.halt:
        JMP .halt

;Error handlers
floppy_error:
        MOV si, msg_error
        CALL puts
        JMP .reboot
.reboot:
        ;Wait for a key press
        MOV ah, 0
        INT 0x16

        CLI ;disable interrupts
        HLT

puts:
        ; put registers into stack
        PUSH si ; SI - Source Index for arrays
        PUSH ax ; AX - general register
.loop:
        LODSB ; LODSW,LODSD - Load a byte/word/double-word
        ;       from DS:SI - Data Segment and Source Index
        ;       to Al/AX/EAX and increment SI

        OR al,al ; bitwise or from source -> destination
                 ; Set zero flag if all bits are 0
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

; Disk routines
; translation of Logic Block Addressing to Cylinder Head Sector scheme
; Parameters: ax - LBA address
; Returns: cx - [bits 0-5]: sector number | [bits 6-15]: cylinder
;          dh - head
lba_to_chs:
        PUSH ax
        PUSH dx

        XOR dx,dx ; n XOR n = 0, so dx = 0

        ; ax = LBA / bdb_sectors_per_track
        ; dx = LBA % bdb_sectors_per_track
        DIV WORD [bdb_sectors_per_track]; DIV works with dx:ax. that's why we used XOR

        INC dx ; dx = (LBA % bdb_sectors_per_track) + 1
        MOV cx,dx; cx = dx = sector

        XOR dx,dx ; n XOR n = 0
        DIV WORD [bdb_heads] ; ax = LBA / bdb_sectors_per_track / Heads = cylinder
                             ; dx = LBA / bdb_sectors_per_track % Heads = head
        MOV dh,dl ; dh = head
        MOV ch,al ; ch = cylinder [8 lower bits]
        
        SHL ah,6 ;Shift Left 6 bits
        OR cl,ah ; put upper 2 bits of cylinder in CL

        ;POP dx ;dx overwrites dh - cannot do it
        POP ax ; use ax temporary
        MOV dl, al; store only low-bits to dl
        POP ax
        RET ; we return cx and dh as result


;Read from disk
; Parameters: 
;       ax - LBA number
;       cl - number of sectors to read
;       dl - drive number
;       es:bx - memory address where to store read data
disk_read:
        ;WHY??
; Since the function returns cx, we need to push to stack
        ; PUSH cx ;save CL (number of sectors to read)
        ; CALL lba_to_chs; CALL is to call a function, JMP is to change the IP register to especified location
        ; POP ax ; al - number of sectors to read

        ;Save registers we'll modify
        PUSH ax;
        PUSH bx;
        PUSH cx;
        PUSH dx;
        PUSH di;

        MOV ax, cx ; cx will be modified, so save it in ax
        CALL lba_to_chs

        MOV ah,0x02 ;arbitrary value
        MOV di, 3 ; retry count, if fails
.retry:
        PUSHA ;Store all registers in stack, we don't know what bios modifies
        STC   ;Set carry flag, some BIOS don't set it
        INT 0x13 ; if carry flag is clear, success
        JNC .done
        ; if fails:
        POPA ; bring back all registers
        CALL disk_reset

        DEC di
        TEST di,di ; change ZF flag if di = 0
        JNZ .retry ;if ZF != 0, JMP

.fail:
        ;after all attemps are exhausted
        JMP floppy_error

.done:
        POPA
        POP ax
        POP bx
        POP cx
        POP dx
        POP di
        RET
        
;Reset disk controller
; Parameters: dl - drive number
disk_reset:
        PUSHA
        MOV ah,0
        STC
        INT 0x13
        JC floppy_error; JMP if carry flag
        POPA
        RET
        


msg_hello: DB "Hello Word!",ENDL,0
msg_error: DB "Read from disk failed!",ENDL,"Press any key to reboot.",0
TIMES 510-($-$$) db 0
DW 0xAA55
