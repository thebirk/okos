package irq

import "core:math/bits"

import "kos:kfmt"
import "kos:arch/i386/x86_terminal"

@(private="file")
Interrupt_Descriptor_Attribute :: enum u8 {
    Present           = 0b1_00_0_0000,
    Gate_Task         = 0b0_00_0_0101,
    Gate_Interrupt_16 = 0b0_00_0_0110,
    Gate_Trap_16      = 0b0_00_0_0111,
    Gate_Interrupt_32 = 0b0_00_0_1110,
    Gate_Trap_32      = 0b0_00_0_1111,
}

@(private="file")
Interrupt_Descriptor :: struct #packed {
    offset_1: u16,
    selector: u16,
    _pad0: u8,
    attributes: Interrupt_Descriptor_Attribute,
    offset_2: u16,
}
#assert(size_of(Interrupt_Descriptor) == 8)

Interrupt_Handler :: #type proc()

interrupt_descriptors: [32]Interrupt_Descriptor = {}
interrupt_handlers: [32]Interrupt_Handler

#assert(size_of(rawptr) == 4)

foreign {
    isr_entrypoint :: proc"naked"() ---
    load_idt :: proc"contextless"(size: u16, base: rawptr) ---
}

idt_init :: proc(cs: u16)
{
    for id in &interrupt_descriptors {
        id.offset_1 = u16(uintptr(rawptr(isr_entrypoint)) & 0xFFFF)
        id.offset_2 = u16(uintptr(rawptr(isr_entrypoint)) >> 16 & 0xFFFF)
        id.selector = cs
        id.attributes = .Present | .Gate_Interrupt_32
    }

    // IRQ 1 - Set present
    //interrupt_descriptors[9].attributes |= 0b1_00_0_0000
    load_idt(size_of(Interrupt_Descriptor) * (len(interrupt_descriptors) - 1), &interrupt_descriptors[0])
    kfmt.logf("idt", "isr_entrypoint: %p", isr_entrypoint)
}
