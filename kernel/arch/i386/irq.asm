[bits 32]

section .text

global double_fault
double_fault:
    int 8
    ret

global load_idt
extern interrupt_descriptor_table
load_idt:
    lidt [interrupt_descriptor_table]
    ret

    global isr_entrypoint
extern interrupt_handlers
isr_entrypoint:
    ; switch on irq and call the appropriate handler
    
    iret
