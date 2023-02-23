[bits 32]

section .text

    align 16
idt:
    .size: dw 0
    .base: dd 0

global double_fault
double_fault:
    int 8
    ret

global load_idt
load_idt:
    push ebp
    mov ebp, esp

    mov dx, [ebp+8]
    mov eax, [ebp+12]

    mov [idt.size], dx
    mov [idt.base], eax
    lidt [idt]

    mov esp, ebp
    pop ebp
    ret

    global isr_entrypoint
extern interrupt_handlers
isr_entrypoint:
    ; switch on irq and call the appropriate handler
    cli
    mov al,20h
    out 20h,al
    sti
    iret
