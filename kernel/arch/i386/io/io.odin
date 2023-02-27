package i386_io

foreign {
    outb :: proc"contextless"(port: u16, v: byte) ---
    inb :: proc"contextless"(port: u16) -> byte ---
}

wait :: proc"contextless"()
{
    // just waste some time
    outb(0x80, 0)
}

nmi_enable :: proc"contextless"()
{
    outb(0x70, inb(0x70) & 0b0111_1111)
    inb(0x71)
}

nmi_disable :: proc"contextless"()
{
    outb(0x70, inb(0x70) | 0b1000_0000)
    inb(0x71)
}