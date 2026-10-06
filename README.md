# TorbSL
16-bit x86 kernel written in Assembly.

Built-in commands:

    info — displays kernel information

    help — displays available commands

    clear — clears the screen

    reboot — reboots through BIOS

    mem — displays the kernel's calculated size

    uptime — displays system uptime using the BIOS timer tick counter

    beep — produces a PC speaker tone

    echo — prints user-provided text

    math_help — displays mathematical operation information

Basic arithmetic expressions using +, -, *, and /

Kernel panic screen

No operating system or standard library required

install:

    git clone https://github.com/bb7716546/TorbSL.git
    cd TorbSL
    qemu-system-i386 -drive format=raw,file=floppy.img

