/** 
 * The 8259 PIC is reponsible for for coordinating hardware interrupts. -- https://wiki.osdev.org/PIC
 * 
 */

package pic8259

import "kos:arch/i386/io"
import "kos:kfmt"

PIC_MASTER_COMMAND_PORT :: u16(0x0020)
PIC_MASTER_DATA_PORT    :: u16(0x0021)
PIC_SLAVE_COMMAND_PORT  :: u16(0x00A0)
PIC_SLAVE_DATA_PORT     :: u16(0x00A1)

Icw1 :: enum u8 {
    Icw4            = 0b000_00001,
    Single          = 0b000_00010,
    Interval        = 0b000_00100,
    Level_Triggered = 0b000_01000,
    Init            = 0b000_10000,
}

Icw4 :: enum u8 {
    Mode_8086                 = 0b000_00001,
    Auto_Eoi                  = 0b000_00010,
    Non_Buffered              = 0b000_00000,
    Buffered_Slave            = 0b000_01000,
    Buffered_Master           = 0b000_01100,
    Special_Fully_Nested_Mode = 0b000_10000,
}

remap_interrupts :: proc()
{
    kfmt.logf("pic8592", "resetting PIC...")

    // Save interrupt mask
    old_mask_m := io.inb(PIC_MASTER_DATA_PORT)
    old_mask_s := io.inb(PIC_SLAVE_DATA_PORT)

    // Start reset for master
    io.outb(PIC_MASTER_COMMAND_PORT, u8(Icw1.Init | Icw1.Icw4))
    io.wait()

    // Start reset for slave
    io.outb(PIC_SLAVE_COMMAND_PORT, u8(Icw1.Init | Icw1.Icw4))
    io.wait()

    // Offset master interrupt vector by 32 to avoid collision with protected mode exceptions
    io.outb(PIC_MASTER_DATA_PORT, 32)
    io.wait()

    // Offset slave interrupt vector so they follow directly after master
    io.outb(PIC_SLAVE_DATA_PORT, 32 + 8)
    io.wait()

    // Tell master to use IRQ2 for slave
    io.outb(PIC_MASTER_DATA_PORT, 0b100)
    io.wait()

    // Tell slave that it is responding to IRQ2
    io.outb(PIC_SLAVE_DATA_PORT, 0b10)
    io.wait()

    // Set 8086 mode
    io.outb(PIC_MASTER_DATA_PORT, u8(Icw4.Mode_8086))
    io.wait()
    io.outb(PIC_SLAVE_DATA_PORT, u8(Icw4.Mode_8086))
    io.wait()

    // Restore old interrupt mask
    //io.outb(PIC_MASTER_DATA_PORT, old_mask_m)
    //io.outb(PIC_SLAVE_DATA_PORT, old_mask_s)

    io.outb(PIC_MASTER_DATA_PORT, 0b1111_1001)
    io.outb(PIC_SLAVE_DATA_PORT,  0b1111_1111)

    kfmt.logf("pic8592", "done")
}
