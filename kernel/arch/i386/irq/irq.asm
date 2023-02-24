[bits 32]

section .text

    align 16
idt:
    .size: dw 0
    .base: dd 0

data_segment:
    dw 0

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
    mov ebx, [ebp+16]
    mov [data_segment], ebx

    mov [idt.size], dx
    mov [idt.base], eax
    lidt [idt]

    mov esp, ebp
    pop ebp
    ret

isr_common:
    pusha
    push ds
    push es
    push fs
    push gs

    mov ax, [data_segment]   ; Load the Kernel Data Segment descriptor!
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, esp
    push eax

    extern isr_handler
    call isr_handler

    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    popa
    add esp, 8 ; clear interrupt number from stack
    iret

%macro ISR_WITHOUT_ERROR_CODE 1
    global isr_%1
isr_%1:
    push byte 0  ; push error code - zero in this case because there is none
    push byte %1 ; push interrupt number
    jmp isr_common
%endmacro

%macro ISR_WITH_ERROR_CODE 1
    global isr_%1
isr_%1:
    ; no need to push error code as its already on the stack
    push byte %1 ; push interrupt number
    jmp isr_common
%endmacro

    align 16
    global interrupt_handler_stubs
interrupt_handler_stubs:
ISR_WITHOUT_ERROR_CODE 0
ISR_WITHOUT_ERROR_CODE 1
ISR_WITHOUT_ERROR_CODE 2
ISR_WITHOUT_ERROR_CODE 3
ISR_WITHOUT_ERROR_CODE 4
ISR_WITHOUT_ERROR_CODE 5
ISR_WITHOUT_ERROR_CODE 6
ISR_WITHOUT_ERROR_CODE 7
ISR_WITH_ERROR_CODE    8
ISR_WITHOUT_ERROR_CODE 9
ISR_WITH_ERROR_CODE   10
ISR_WITH_ERROR_CODE   11
ISR_WITH_ERROR_CODE   12
ISR_WITH_ERROR_CODE   13
ISR_WITH_ERROR_CODE   14
ISR_WITHOUT_ERROR_CODE 15
ISR_WITHOUT_ERROR_CODE 16
ISR_WITHOUT_ERROR_CODE 17
ISR_WITHOUT_ERROR_CODE 18
ISR_WITHOUT_ERROR_CODE 19
ISR_WITHOUT_ERROR_CODE 20
ISR_WITHOUT_ERROR_CODE 21
ISR_WITHOUT_ERROR_CODE 22
ISR_WITHOUT_ERROR_CODE 23
ISR_WITHOUT_ERROR_CODE 24
ISR_WITHOUT_ERROR_CODE 25
ISR_WITHOUT_ERROR_CODE 26
ISR_WITHOUT_ERROR_CODE 27
ISR_WITHOUT_ERROR_CODE 28
ISR_WITHOUT_ERROR_CODE 29
ISR_WITHOUT_ERROR_CODE 30
ISR_WITHOUT_ERROR_CODE 31
ISR_WITHOUT_ERROR_CODE 32
ISR_WITHOUT_ERROR_CODE 33
ISR_WITHOUT_ERROR_CODE 34
ISR_WITHOUT_ERROR_CODE 35
ISR_WITHOUT_ERROR_CODE 36
ISR_WITHOUT_ERROR_CODE 37
ISR_WITHOUT_ERROR_CODE 38
ISR_WITHOUT_ERROR_CODE 39
ISR_WITHOUT_ERROR_CODE 40
ISR_WITHOUT_ERROR_CODE 41
ISR_WITHOUT_ERROR_CODE 42
ISR_WITHOUT_ERROR_CODE 43
ISR_WITHOUT_ERROR_CODE 44
ISR_WITHOUT_ERROR_CODE 45
ISR_WITHOUT_ERROR_CODE 46
ISR_WITHOUT_ERROR_CODE 47
ISR_WITHOUT_ERROR_CODE 48
