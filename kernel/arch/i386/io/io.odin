package i386_io

foreign {
    outb :: proc"c"(port: u16, v: byte) ---
    inb :: proc"c"(port: u16) -> byte ---
}
