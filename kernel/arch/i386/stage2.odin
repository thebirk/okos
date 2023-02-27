package i386

import kernel "kos:."
import "kos:kfmt"
import "kos:arch/i386/x86_terminal"
import "kos:arch/i386/kcontext"
import "kos:arch/i386/io"
import "kos:arch/i386/irq"
import "kos:arch/i386/pic8259"
import "kos:arch/i386/multiboot"

foreign {
    //kmain :: proc() -> ! ---

    @(link_name="__$startup_runtime")
    __startup_runtime :: proc() ---

    double_fault :: proc"naked"() ---
}

@(export)
stage2 :: proc"contextless"(ebx: u32, cs: u16, ds: u16) -> !
{
    context = kcontext.kernel_context()
    __startup_runtime()
    x86_terminal.init()
    kfmt.set_terminal_device(&x86_terminal.x86_terminal_device)
    kfmt.logf("stage2", "arch/i386")
    kfmt.logf("cpu", "%v", cpu_name)

    multiboot_info := cast(^multiboot.Multiboot_Information) uintptr(ebx)
    if multiboot_info.flags & .Boot_Loader_Name > multiboot.Multiboot_Information_Flags(0)
    {
        kfmt.logf("multiboot", "bootloader name: '%s'", multiboot_info.boot_loader_name)
    }
    if multiboot_info.flags & .Command_Line > multiboot.Multiboot_Information_Flags(0)
    {
        kfmt.logf("multiboot", "kernel command line: '%s'", multiboot_info.cmdline)
    }

    pic8259.remap_interrupts()
    irq.idt_init(cs, ds)

    { // Keyboard controller
        // Disable both ports
        io.outb(0x64, 0xAD)
        io.outb(0x64, 0xA7)

        // Read until status register indicated empty buffer
        i8042_empty_buffer()

        // Disable irq and translation
        conf_byte := io.inb(0x20)
        conf_byte &= ~u8(0b1000011)
        i8042_wait_write()
        io.outb(0x60, conf_byte)

        //TODO: test bit 5 for dual channel

        // Self-test
        io.outb(0x64, 0xAA)
        i8042_wait_read()
        if result := io.inb(0x60); result != 0x55
        {
            kfmt.logf("i8042", "Self test failed")
        }

        io.outb(0x64, 0xAE)
        io.outb(0x64, 0xA8)
        i8042_wait_write()
        io.outb(0x60, 0b00000011)

        io.outb(0x64, 0xFF)
        i8042_wait_read()
        io.inb(0x60)
    }



    { // RTC
        io.outb(0x70, (io.inb(0x70) & 0b1000_0000) | 0x0B)
        status_reg_b := io.inb(0x71)

        binary := status_reg_b & 4 > 0
        _24hour := status_reg_b & 2 > 0

        io.outb(0x70, (io.inb(0x70) & 0b1000_0000) | 0x00)
        seconds := io.inb(0x71)
        io.outb(0x70, (io.inb(0x70) & 0b1000_0000) | 0x02)
        minutes := io.inb(0x71)
        io.outb(0x70, (io.inb(0x70) & 0b1000_0000) | 0x04)
        hours := io.inb(0x71)

        if binary 
        {
            kfmt.logf(
                "rtc",
                "current time %s%02d:%02d:%02d",
                _24hour ? "" : (hours & 0b1000_0000 > 0) ? "PM" : "AM",
                hours, minutes, seconds
            )
        }
        else
        {
            kfmt.logf(
                "rtc",
                "current time %s%02X:%02X:%02X",
                _24hour ? "" : (hours & 0b1000_0000 > 0) ? "PM " : "AM ",
                hours, minutes, seconds
            )
        }
    }

    kfmt.logf("irq", "enabling interrupts")
    asm { "sti", "" }()
    kernel.kmain()
}

//TODO: bool return
i8042_empty_buffer :: proc()
{
    limit := 1000
    for (io.inb(0x64) & 1 != 0) && limit > 0
    {
        io.inb(0x60)

        limit -= 1
    }
}

//TODO: bool return
i8042_wait_read :: proc()
{
    limit := 1000
    for (io.inb(0x64) & 1 == 0) && limit > 0
    {
        limit -= 1
        asm { "pause", "" }()
    }
}

//TODO: bool return
i8042_wait_write :: proc()
{
    limit := 1000
    for (io.inb(0x64) & 2 == 0) && limit > 0
    {
        limit -= 1
        asm { "pause", "" }()
    }
}