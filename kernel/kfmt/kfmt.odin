package kmft

import core_fmt "core:fmt"
import "core:mem"

Kfmt_Device :: struct {
    write_string: proc(str: string),
    log_string: proc(str: string),
}

@(private)
current_device: ^Kfmt_Device

set_terminal_device :: proc(device: ^Kfmt_Device)
{
    current_device = device
}

printf :: proc(fmt: string, args: ..any)
{
    buffer: [1024]u8
    str := core_fmt.bprintf(buffer[:], fmt, ..args)
    current_device.write_string(str)
}

logf :: proc(category: string, fmt: string, args: ..any)
{
    // excessive stack usage?
    fmt_buffer: [1024]u8
    cat_fmt := core_fmt.bprintf(fmt_buffer[:], "[%s] %s\n", category, fmt)

    buffer: [1024]u8
    str := core_fmt.bprintf(buffer[:], cat_fmt, ..args)
    current_device.log_string(str)
    current_device.write_string(str)
}