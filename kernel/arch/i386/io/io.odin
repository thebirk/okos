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
