[bits 16]
[org 0x7c00]

start:
     xor ax, ax
     mov ds, ax
     mov es, ax
     mov [boot_drive], dl

     mov ah, 0x00
     mov al, 0x03
     int 0x10

     mov si, msg_torbsl

print_char:
     lodsb
     or al, al
     jz animate
     mov ah, 0x0E
     int 0x10
     jmp print_char

animate:
     call delay

     mov si, animation_frames
     mov cx, 4

next_frame:
     call clear_screen
     push cx

print_frame_char:
     lodsb
     cmp al, 0
     je frame_done
     cmp al,1
     je end_animation
     mov ah, 0x0E
     int 0x10
     jmp print_frame_char

frame_done:
     call delay
     pop cx
     loop next_frame

end_animation:
     mov ax, 0x07E0
     mov es, ax

     mov ah, 0x02
     mov al, 3
     mov ch, 0
     mov cl, 2
     mov dh, 0
     mov dl, [boot_drive]
     mov bx, 0

     int 0x13
     jc disk_error

     jmp 0x07E0:0000

print:
     lodsb
     cmp al, 0
     je .done
     mov ah, 0x0E
     int 0x10
     jmp print
.done:
     ret

disk_error:
     mov si, disk_error_msg
     call print
     jmp $

disk_address_packet:
     db 0x10
     db 0
     dw 3
dap_offset:
     dw 0
dap_segment:
     dw 0
     dq 1

msg_torbsl db 'TorbSL', 0
disk_error_msg db "Disk error :( 0x1", 0
boot_drive db 0

animation_frames:
     db 'T', 0
     db 'To', 0
     db 'Tor', 0
     db 'TorbSL', 0
     db 1

delay:
     mov cx, 0xFFFF
d1:
     push cx
     mov cx, 5000
d2:
     loop d2
     pop cx
     loop d1
     ret

clear_screen:
     mov ah, 0x00
     mov al, 0x03
     int 0x10
     ret

times 510-($-$$) db 0
dw 0xAA55