use16
org 0x0000

; kernel verison 1.2

start:
     cld

     mov ax, 0x07e0
     mov ds, ax

     xor ax, ax
     mov es, ax

     cli
     mov word [es:0x00], divide_error
     mov word [es:0x02], 0x07e0
     sti

     mov ax, 0x07e0
     mov es, ax

     mov ah, 0x00
     mov al, 0x03
     int 0x10

     mov si, welcome
     call print
     call newline

main_loop:
     mov si, prompt_msg
     call print
     call read_input

     mov si, input_buffer
     mov di, info_cmd
     call str_eq
     cmp al, 1
     je do_info

     mov si, input_buffer
     mov di, ping_cmd
     call str_eq
     cmp al, 1
     je do_ping

     mov si, input_buffer
     mov di, beep_cmd
     call str_eq
     cmp al, 1
     je do_beep

     mov si, input_buffer
     mov di, clear_cmd
     call str_eq
     cmp al, 1
     je do_clear

     mov si, input_buffer
     mov di, math_help_cmd
     call str_eq
     cmp al, 1
     je do_math_help

     mov si, input_buffer
     mov di, reboot_cmd
     call str_eq
     cmp al, 1
     je do_reboot

     mov si, input_buffer
     mov di, uptime_cmd
     call str_eq
     cmp al, 1
     je do_uptime

     mov si, input_buffer
     mov di, mem_cmd
     call str_eq
     cmp al, 1
     je do_mem

     mov si, input_buffer
     call try_math
     cmp al, 1
     je main_loop

     mov si, input_buffer
     cmp byte [si], 'e'
     jne .not_echo
     cmp byte [si+1], 'c'
     jne .not_echo
     cmp byte [si+2], 'h'
     jne .not_echo
     cmp byte [si+3], 'o'
     jne .not_echo

     cmp byte [si+4], 0
     je do_echo

     cmp byte [si+4], ' '
     je do_echo

.not_echo:

     mov si, input_buffer
     mov di, help_cmd
     call str_eq
     cmp al, 1
     je do_help

     mov si, input_buffer
     mov di, panic_cmd
     call str_eq
     cmp al, 1
     je do_panic

     mov si, input_buffer
     mov di, crash_cmd
     call str_eq
     cmp al, 1
     je do_crash

     mov si, unknown_msg
     call print
     call newline
     jmp main_loop


newline:
     mov ah, 0x0E
     mov al, 0x0D
     int 0x10
     mov al, 0x0A
     int 0x10
     ret

print:
     lodsb
     cmp al, 0
     je .done
     mov ah, 0x0E
     int 0x10
     jmp print

.done:
     ret

read_input:
     mov di, input_buffer

.r:
     mov ah, 0
     int 0x16

     cmp al, 0x0D
     je .e

     cmp al, 0x08
     je .b

     cmp di, input_buffer + INPUT_MAX
     jae .r

     stosb
     mov ah, 0x0E
     int 0x10
     jmp .r

.b:
     cmp di, input_buffer
     je .r

     dec di

     mov ah, 0x0E
     mov al, 0x08
     int 0x10
     mov al, ' '
     int 0x10
     mov al, 0x08
     int 0x10

     jmp .r

.e:
     mov al, 0
     stosb

     mov ah, 0x0E
     mov al, 0x0D
     int 0x10
     mov al, 0x0A
     int 0x10

     ret

str_eq:
     push si
     push di
.n:
     lodsb
     scasb
     jne .no
     test al, al
     jnz .n

     pop di
     pop si
     mov al, 1
     ret

.no:
     pop di
     pop si
     mov al, 0
     ret

print_num:
     xor cx, cx
     mov bx, 10

.convert:
     xor dx, dx
     div bx
     push dx
     inc cx
     cmp ax, 0
     jne .convert

.print:
     pop dx
     add dl, '0'
     mov ah, 0x0E
     mov al, dl
     int 0x10
     loop .print
     ret


do_clear:
     mov ah, 0x00
     mov al, 0x03
     int 0x10

     mov si, welcome
     call print
     call newline

     jmp main_loop

do_reboot:
     int 0x19

do_info:
     mov si, info_msg
     call print
     call newline
     jmp main_loop

do_mem:
     mov si, mem_msg
     call print

     mov ax, kernel_size
     call print_num

     mov si, bytes_msg
     call print
     call newline
     jmp main_loop

do_help:
     mov si, help_msg
     call print
     call newline
     jmp main_loop

do_ping:
     mov si, ping_msg
     call print
     call newline
     jmp main_loop

do_beep:
     mov al, 0xB6
     out 0x43, al

     mov ax, 1193
     out 0x42, al
     mov al, ah
     out 0x42, al

     in al, 0x61
     or al, 0x03
     out 0x61, al

     mov cx, 0xFFFF
.delay1:
     push cx
     mov cx, 0xFFFF
.delay2:
     loop .delay2
     pop cx
     loop .delay1

     in al, 0x61
     and al, 0xFC
     out 0x61, al

     jmp main_loop

do_echo:
     mov si, input_buffer
     add si, 4

.skip_spaces:
     cmp byte [si], ' '
     jne .print
     inc si
     jmp .skip_spaces

.print:
     call print
     call newline
     jmp main_loop


do_panic:
     jmp kernel_panic

do_crash:
     xor ax, ax
     xor dx, dx
     div dx

divide_error:
     jmp kernel_panic

do_math_help:
     mov si, math_help_msg
     call print
     call newline
     jmp main_loop

try_math:
     push si
     push bx
     push cx
     push dx

     call parse_number
     jc .not_math

     mov bx, ax

     lodsb

     cmp al, '+'
     je .add
     cmp al, '-'
     je .sub
     cmp al, '*'
     je .mul
     cmp al, '/'
     je .div

     jmp .not_math

.add:
     call parse_number
     jc .not_math

     add bx, ax
     mov ax, bx
     jmp .result

.sub:
     call parse_number
     jc .not_math

     sub bx, ax
     mov ax, bx
     jmp .result

.mul:
     call parse_number
     jc .not_math

     imul bx, ax
     mov ax, bx
     jmp .result

.div:
     call parse_number
     jc .not_math

     cmp ax, 0
     je .divide_zero

     mov cx, ax
     mov ax, bx
     xor dx, dx

     div cx

     jmp .result

.divide_zero:
     mov si, divide_msg
     call print
     call newline
     jmp .success

.result:
     call print_num
     call newline

.success:
     pop dx
     pop cx
     pop bx
     pop si

     mov al, 1
     ret

.not_math:
     pop dx
     pop cx
     pop bx
     pop si

     xor al, al
     ret

do_uptime:
     push ds
     mov ax, 0x0040
     mov ds, ax
     mov ax, [0x006C]
     pop ds

     xor dx, dx
     mov bx, 18
     div bx

     push ax
     mov si, uptime_msg
     call print
     pop ax
     call print_num

     mov si, seconds_msg
     call print
     call newline
     jmp main_loop

parse_number:
     push bx
     xor ax, ax
     xor cx, cx

.parse:
     mov dl, [si]

     cmp dl, '0'
     jb .done

     cmp dl, '9'
     ja .done

     sub dl, '0'
     xor dh, dh

     push dx
     mov bx, 10
     mul bx
     pop dx

     add ax, dx

     inc si
     inc cx

     jmp .parse

.done:
     cmp cx, 0
     je .error

     pop bx
     clc
     ret

.error:
     pop bx
     stc
     ret

kernel_panic:
     mov ax, 0x0600
     mov bh, 0x4F
     mov cx, 0x0000
     mov dx, 0x184F
     int 0x10

     mov ah, 0x02
     mov bh, 0x00
     mov dh, 8
     mov dl, 15
     int 0x10

     mov si, kernel_panic_title
     call print

     mov ah, 0x02
     mov bh, 0x00
     mov dh, 10
     mov dl, 25
     int 0x10

     mov si, kernel_panic_msg
     call print

     mov ah, 0x02
     mov bh, 0x00
     mov dh, 11
     mov dl, 25
     int 0x10

     mov si, kernel_panic_code
     call print

     mov ah, 0x02
     mov bh, 0x00
     mov dh, 13
     mov dl, 25
     int 0x10

     mov si, kernel_panic_stop
     call print

.halt:
     cli
     hlt
     jmp .halt

welcome db "TorbSL v1.2", 0
prompt_msg db "TorbSL> ", 0
INPUT_MAX equ 31
input_buffer times INPUT_MAX + 1 db 0
info_cmd db "info", 0
clear_cmd db "clear", 0
reboot_cmd db "reboot", 0
mem_msg db "Memory: ", 0
bytes_msg db " B", 0
mem_cmd db "mem", 0
math_help_cmd db "math_help", 0
ping_cmd db "ping", 0
help_cmd db "help", 0
uptime_cmd db "uptime", 0
seconds_msg db " seconds", 0
beep_cmd db "beep", 0
echo_cmd db "echo", 0
divide_msg db "Error: division by zero. 0x3", 0
ping_msg db "Pong!", 0 ; easter egg
panic_cmd db "panic", 0 ; hidden command to test kernel panic
crash_cmd db "crash", 0 ; divide by zero to test kernel panic

kernel_panic_title db "================ KERNEL PANIC ================", 0
kernel_panic_msg   db "A fatal error has occurred.", 0
kernel_panic_code  db "Error code: 0x2", 0
kernel_panic_stop  db "System halted.", 0

math_help_msg db "Mathematical operations: +, -, *, /, example: 5+3, most math isnt always correct due to 16-bit limitations", 0
uptime_msg db "System uptime: ", 0
help_msg db "Commands: info, clear, reboot, mem, help, beep, echo, math_help, uptime", 0 
info_msg db "TorbSL v1.2 (2026-10-04)", 0
unknown_msg db "Unknown command.", 0

kernel_end:
kernel_size equ kernel_end
