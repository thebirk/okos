package kernel

import "core:math/bits"

@(private="file")
Interrupt_Descriptor_Attribute :: enum u8 {
    Gate_Task         = 0b0101,
    Gate_Interrupt_16 = 0b0110,
    Gate_Trap_16      = 0b0111,
    Gate_Interrupt_32 = 0b1110,
    Gate_Trap_32      = 0b1111,
}

@(private="file")
Interrupt_Descriptor :: struct #packed {
    offset_1: u16,
    selector: u16,
    _pad0: u8,
    attributes: u8,
    offset_2: u16
}

@(private="file")
Interrupt_Descriptor_Table :: struct #packed {
    size: u16,
    base: uintptr,
}

Interrupt_Handler :: #type proc()

@export
interrupt_descriptor_table: [256]Interrupt_Descriptor = {}
interrupt_handlers: [256]Interrupt_Handler

foreign {
    isr_entrypoint :: proc"naked"() ---
    load_idt :: proc"contextless"() ---
}

idt_init :: proc()
{
    for id in &interrupt_descriptor_table {
        id.offset_1 = u16(uintptr(rawptr(isr_entrypoint)) & 0xFFFF)
        id.offset_2 = u16(uintptr(rawptr(isr_entrypoint)) >> 16 & 0xFFFF)
    }

    // IRQ 1 - Set present
    interrupt_descriptor_table[9].attributes |= 0b1_00_0_0000
    
    
    klogf("idt", "isr_entrypoint: %p", isr_entrypoint)
}
