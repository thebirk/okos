package x86_terminal

import "core:mem"

import "kos:kfmt"
import "kos:arch/i386/io"

x86_terminal_device := kfmt.Kfmt_Device {
    write_string = write_string,
    log_string = com1_write_string,
}

@(private="file")
state: struct {
    x, y: int,
    width, height: int,
    fg, bg: u16,
}

@(private="file")
vga: []u16 = mem.slice_ptr(cast(^u16) (uintptr(0xB8000)), 80*25)

@(private="file")
update_cursor :: proc()
{
    pos := state.x + state.y * state.width
    vga[pos] = state.bg << 12 | state.fg << 8
    io.outb(0x3D4, 0x0E)
    io.outb(0x3D5, u8(pos >> 8))
    io.outb(0x3D4, 0x0F)
    io.outb(0x3D5, u8(pos))
}

init :: proc()
{
    state.x = 0
    state.y = 0

    state.width = 80
    state.height = 25

    // Full-height caret
    io.outb(0x3D4, 0x0A)
    io.outb(0x3D5, 0x0) // Start
    io.outb(0x3D4, 0x09)
    max := io.inb(0x3D5) & 0x1F
    io.outb(0x3D4, 0x0B)
    io.outb(0x3D5, max) // End

    // Replace two palette entries with custom colors
    // 5 magenta -> orange  - dece8d
    // 3 green -> dark blue - 001222
    io.outb(0x3C8, 5)
    io.outb(0x3C9, u8(u16(0xde * 253 + 512) >> 10))
    io.outb(0x3C9, u8(u16(0xce * 253 + 512) >> 10))
    io.outb(0x3C9, u8(u16(0x8d * 253 + 512) >> 10))
    io.outb(0x3C8, 3)
    io.outb(0x3C9, u8(u16(0x00 * 253 + 512) >> 10))
    io.outb(0x3C9, u8(u16(0x12 * 253 + 512) >> 10))
    io.outb(0x3C9, u8(u16(0x22 * 253 + 512) >> 10))

    state.fg = 5
    state.bg = 3

    for ch in &vga {
        ch = state.bg << 12 | state.fg << 8
    }

    update_cursor()
}

write_string :: proc(str: string)
{
    asm { "cli", "" }()
    for ch in str {
        // for _ in 0..<10000000 {}

        // io.outb(0x3F8, u8(ch))
        switch ch {
        case '\n':
            state.x = 0
            state.y += 1
        case:
            vga[state.x + state.y * state.width] = state.bg << 12 | state.fg << 8 | u16(ch)
            state.x += 1
        }

        if state.x == state.width {
            state.x = 0
            state.y += 1
        }

        if state.y == state.height {
            for y := 0; y < state.height - 1; y += 1 {
                for x := 0; x < state.width; x += 1 {
                    vga[x+y*state.width] = vga[x+(y+1)*state.width]
                }
            }

            for x := 0; x < state.width; x += 1 {
                vga[x+(state.y-1)*state.width] = state.bg << 12 | state.fg << 8
            }

            state.y -= 1
        }

        update_cursor()
    }
    asm { "sti", "" }()
}

com1_write_string :: proc(str: string)
{
    asm { "cli", "" }()
    io.outb(0x3F8, '\e')
    io.outb(0x3F8, '[')
    io.outb(0x3F8, '9')
    io.outb(0x3F8, '3')
    io.outb(0x3F8, 'm')
    for ch in transmute([]byte) str {
        io.outb(0x3F8, u8(ch))
    }
    io.outb(0x3F8, '\e')
    io.outb(0x3F8, '[')
    io.outb(0x3F8, '0')
    io.outb(0x3F8, 'm')
    asm { "sti", "" }()
}
