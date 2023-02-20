[bits 32]

; leave outb/inb here for now, inline asm support still shaky
global outb
outb:
    push ebp
    mov ebp, esp

    mov dx, [ebp+8]
    mov al, [ebp+12]
    out dx, al

    mov esp, ebp
    pop ebp
    ret

global inb
inb:
    push ebp
    mov ebp, esp

    mov dx, [ebp+8]
    in al, dx

    mov esp, ebp
    pop ebp
    ret
