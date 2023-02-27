package irq

import "core:math/bits"

import "kos:kfmt"
import "kos:arch/i386/io"
import "kos:arch/i386/kcontext"
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

Interrupt_Handler :: #type proc(registers: Registers)

Registers :: struct #packed {
    gs, fs, es, ds: u32,
    edi, esi, ebp, esp: u32,
    ebx, edx, ecx, eax: u32,
    interrupt: u32,
    error_code: u32,
    eip, cs, eflags, user_esp, ss: u32
}

interrupt_descriptors: [49]Interrupt_Descriptor = {}
interrupt_handlers: [49]Interrupt_Handler

foreign {
    interrupt_handler_stubs: rawptr
    
    load_idt :: proc"contextless"(size: u16, base: rawptr, ds: u16) ---
}

kbmap_set2 := [?]u8 {
      0, 67, 65, 63, 61, 59, 60, 88,  0, 68, 66, 64, 62, 15, 41,117,
	  0, 56, 42, 93, 29, 16,  2,  0,  0,  0, 44, 31, 30, 17,  3,  0,
	  0, 46, 45, 32, 18,  5,  4, 95,  0, 57, 47, 33, 20, 19,  6,183,
	  0, 49, 48, 35, 34, 21,  7,184,  0,  0, 50, 36, 22,  8,  9,185,
	  0, 51, 37, 23, 24, 11, 10,  0,  0, 52, 53, 38, 39, 25, 12,  0,
	  0, 89, 40,  0, 26, 13,  0,  0, 58, 54, 28, 27,  0, 43,  0, 85,
	  0, 86, 91, 90, 92,  0, 14, 94,  0, 79,124, 75, 71,121,  0,  0,
	 82, 83, 80, 76, 77, 72,  1, 69, 87, 78, 81, 74, 55, 73, 70, 99,

	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	217,100,255,  0, 97,165,  0,  0,156,  0,  0,  0,  0,  0,  0,125,
	173,114,  0,113,  0,  0,  0,126,128,  0,  0,140,  0,  0,  0,127,
	159,  0,115,  0,164,  0,  0,116,158,  0,172,166,  0,  0,  0,142,
	157,  0,  0,  0,  0,  0,  0,  0,155,  0, 98,  0,  0,163,  0,  0,
	226,  0,  0,  0,  0,  0,  0,  0,  0,255, 96,  0,  0,  0,143,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,107,  0,105,102,  0,  0,112,
	110,111,108,112,106,103,  0,119,  0,118,109,  0, 99,104,119,  0,

    0,  0,  0, 65, 99,
}

Exception :: enum {
    Division_Error         = 0x0,
    Debug                  = 0x1,
    Non_Maskable_Interrupt = 0x2,
    Breakpoint = 0x3,
    Overflow = 0x4,
    Bound_Range_Exceeded = 0x5,
    Invalid_Opcode = 0x6,
    Device_Not_Available = 0x7,
    Double_Fault = 0x8,
    Coprocessor_Segment_Overrun = 0x9,
    Invalid_TSS = 0xA,
    Segment_Not_Present = 0xB,
    Stack_Segment_Fault = 0xC,
    General_Protection_Fault = 0xD,
    Page_Fault = 0xE,
    _Reserved_1 = 0xF,
    x87_Floating_Point_Exception = 0x10,
    Alignment_Check = 0x11,
    Machine_Check = 0x12,
    SIMD_Floating_Point_Exception = 0x13,
    Virtualization_Exception = 0x14,
    Control_Protection_Exception = 0x15,
    _Reserved_2 = 0x16,
    _Reserved_3 = 0x17,
    _Reserved_4 = 0x18,
    _Reserved_5 = 0x19,
    _Reserved_6 = 0x1A,
    _Reserved_7 = 0x1B,
    Hypervisor_Injection_Exception = 0x1C,
    VMM_Communication_Exception = 0x1D,
    Security_Exception = 0x1E,
    _Reserved_8 = 0x1F,
    //Triple Fault -
    //FPU Error Interrupt IRQ 13
}

exception_mnemonic := [Exception]string {
    .Division_Error =                 "#DE",
    .Debug =                          "#DB",
    .Non_Maskable_Interrupt =         "NMI",
    .Breakpoint =                     "#BP",
    .Overflow =                       "#OF",
    .Bound_Range_Exceeded =           "#BR",
    .Invalid_Opcode =                 "#UD",
    .Device_Not_Available =           "#NM",
    .Double_Fault =                   "#DF",
    .Coprocessor_Segment_Overrun =    "CSO",
    .Invalid_TSS =                    "#TS",
    .Segment_Not_Present =            "#NP",
    .Stack_Segment_Fault =            "#SS",
    .General_Protection_Fault =       "#GP",
    .Page_Fault =                     "#PF",
    ._Reserved_1 =                    "_Reserved_1",
    .x87_Floating_Point_Exception =   "#MF",
    .Alignment_Check =                "#AC",
    .Machine_Check =                  "#MC",
    .SIMD_Floating_Point_Exception =  "#XM",
    .Virtualization_Exception =       "#VE",
    .Control_Protection_Exception =   "#CP",
    ._Reserved_2 =                    "_Reserved_2",
    ._Reserved_3 =                    "_Reserved_3",
    ._Reserved_4 =                    "_Reserved_4",
    ._Reserved_5 =                    "_Reserved_5",
    ._Reserved_6 =                    "_Reserved_6",
    ._Reserved_7 =                    "_Reserved_7",
    .Hypervisor_Injection_Exception = "#HV",
    .VMM_Communication_Exception =    "#VC",
    .Security_Exception =             "#SX",
    ._Reserved_8 =                    "_Reserved_8",
}

@(export)
isr_handler :: proc"contextless"(regs: Registers)
{
    context = kcontext.kernel_context()
    //kfmt.logf("irq", "interrupt: %#v", regs)
    //kfmt.logf("irq", "Interrupt %v", regs.interrupt)

    //TODO: Complain if interrupts are enabled!
    //TODO: Handle spurious interrupts
    
    if regs.interrupt >= 0 && regs.interrupt <= 31
    {
        asm { "cli", "" }()
        kfmt.logf("PANIC", "Exception: 0x%0X/%s", regs.interrupt, exception_mnemonic[Exception(regs.interrupt)])
        for {
            asm { "hlt", "" }()
        }
    }

    if regs.interrupt >= 32 && regs.interrupt <= 48
    {
        if interrupt_handlers[regs.interrupt] != nil
        {
            interrupt_handlers[regs.interrupt](regs)
        }

        // EOI - end of interrupt
        io.outb(0x20, 0x20)
    }
}

set_interrupt_descriptor :: proc(interrupt: int, offset: rawptr, selector: u16, attributes: Interrupt_Descriptor_Attribute)
{
    interrupt_descriptors[interrupt].offset_1 = u16(uintptr(offset) & 0xFFFF)
    interrupt_descriptors[interrupt].offset_2 = u16((uintptr(offset) >> 16) & 0xFFFF)
    interrupt_descriptors[interrupt].selector = selector
    interrupt_descriptors[interrupt].attributes = attributes
}

idt_init :: proc(cs: u16, ds: u16)
{
    set_interrupt_descriptor(0, rawptr(isr_0), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(1, rawptr(isr_1), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(2, rawptr(isr_2), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(3, rawptr(isr_3), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(4, rawptr(isr_4), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(5, rawptr(isr_5), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(6, rawptr(isr_6), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(7, rawptr(isr_7), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(8, rawptr(isr_8), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(9, rawptr(isr_9), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(10, rawptr(isr_10), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(11, rawptr(isr_11), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(12, rawptr(isr_12), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(13, rawptr(isr_13), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(14, rawptr(isr_14), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(15, rawptr(isr_15), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(16, rawptr(isr_16), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(17, rawptr(isr_17), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(18, rawptr(isr_18), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(19, rawptr(isr_19), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(20, rawptr(isr_20), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(21, rawptr(isr_21), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(22, rawptr(isr_22), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(23, rawptr(isr_23), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(24, rawptr(isr_24), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(25, rawptr(isr_25), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(26, rawptr(isr_26), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(27, rawptr(isr_27), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(28, rawptr(isr_28), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(29, rawptr(isr_29), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(30, rawptr(isr_30), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(31, rawptr(isr_31), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(32, rawptr(isr_32), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(33, rawptr(isr_33), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(34, rawptr(isr_34), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(35, rawptr(isr_35), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(36, rawptr(isr_36), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(37, rawptr(isr_37), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(38, rawptr(isr_38), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(39, rawptr(isr_39), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(40, rawptr(isr_40), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(41, rawptr(isr_41), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(42, rawptr(isr_42), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(43, rawptr(isr_43), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(44, rawptr(isr_44), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(45, rawptr(isr_45), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(46, rawptr(isr_46), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(47, rawptr(isr_47), cs, .Present | .Gate_Interrupt_32)
    set_interrupt_descriptor(48, rawptr(isr_48), cs, .Present | .Gate_Interrupt_32)

    register_irq_handler(1, proc(registers: Registers) {
        // PS/2 Port 1
        ch := io.inb(0x60)
        kfmt.printf("PORT1: %0X\n", ch)
    })

    register_irq_handler(12, proc(registers: Registers) {
        // PS/2 Port 2
        ch := io.inb(0x60)
        kfmt.printf("PORT2: %0X\n", ch)
    })

    register_irq_handler(4, proc(registers: Registers) {
        // Serial
        ch := io.inb(0x3F8)
        kfmt.printf("COM1: %0X\n", ch)
    })


    kfmt.logf("irq", "load idt")
    load_idt(size_of(Interrupt_Descriptor) * len(interrupt_descriptors) - 1, &interrupt_descriptors[0], ds)
}

register_irq_handler :: proc(irq: int, handler: Interrupt_Handler) -> bool
{
    if irq < 0 || irq >= 16
    {
        kfmt.logf("irq", "register_irq_handler: irq %d out of range 0..15", irq)
        return false
    }

    if interrupt_handlers[32+irq] != nil
    {
        kfmt.logf("irq", "attempted to register irq handler for IRQ%d, but it was already registered", irq)
        return false
    }

    interrupt_handlers[32 + irq] = handler
    return true
}

foreign {
    isr_0 :: proc() ---
    isr_1 :: proc() ---
    isr_2 :: proc() ---
    isr_3 :: proc() ---
    isr_4 :: proc() ---
    isr_5 :: proc() ---
    isr_6 :: proc() ---
    isr_7 :: proc() ---
    isr_8 :: proc() ---
    isr_9 :: proc() ---
    isr_10 :: proc() ---
    isr_11 :: proc() ---
    isr_12 :: proc() ---
    isr_13 :: proc() ---
    isr_14 :: proc() ---
    isr_15 :: proc() ---
    isr_16 :: proc() ---
    isr_17 :: proc() ---
    isr_18 :: proc() ---
    isr_19 :: proc() ---
    isr_20 :: proc() ---
    isr_21 :: proc() ---
    isr_22 :: proc() ---
    isr_23 :: proc() ---
    isr_24 :: proc() ---
    isr_25 :: proc() ---
    isr_26 :: proc() ---
    isr_27 :: proc() ---
    isr_28 :: proc() ---
    isr_29 :: proc() ---
    isr_30 :: proc() ---
    isr_31 :: proc() ---
    isr_32 :: proc() ---
    isr_33 :: proc() ---
    isr_34 :: proc() ---
    isr_35 :: proc() ---
    isr_36 :: proc() ---
    isr_37 :: proc() ---
    isr_38 :: proc() ---
    isr_39 :: proc() ---
    isr_40 :: proc() ---
    isr_41 :: proc() ---
    isr_42 :: proc() ---
    isr_43 :: proc() ---
    isr_44 :: proc() ---
    isr_45 :: proc() ---
    isr_46 :: proc() ---
    isr_47 :: proc() ---
    isr_48 :: proc() ---
}