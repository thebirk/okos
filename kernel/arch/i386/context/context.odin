package kcontext

import "core:mem"
import "core:runtime"

kernel_context :: proc"contextless"() -> runtime.Context
{
    c: runtime.Context
    _init_kernel_context(&c)
    return c
}

_init_kernel_context :: proc"contextless"(c: ^runtime.Context)
{
    c.assertion_failure_proc = kernel_assertion_failure_proc
    c.logger = kernel_logger()
}

kernel_assertion_failure_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> !
{
    vga: []u16 = mem.slice_ptr(cast(^u16) (uintptr(0xB8000)), 80*25)
    msg := "! ASSERTION FAILURE !"
    for ch, i in msg {
        vga[i] = u16(ch) | u16(12) << 8
    }

    i := 80
    for ch in prefix {
        vga[i] = u16(ch) | u16(12) << 8
        i += 1
    }

    vga[i] = ':' | u16(12) << 8
    i += 1
    vga[i] = ' ' | u16(12) << 8
    i += 1

    for ch in message {
        vga[i] = u16(ch) | u16(12) << 8
        i += 1
    }

    for {}
}

kernel_logger_proc :: proc(data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location)
{
	vga: []u16 = mem.slice_ptr(cast(^u16) (uintptr(0xB8000)), 80*25)
    for v in &vga {
        v = 0
    }
    vga[0] = '%' | 12 << 8
}

kernel_logger :: proc"contextless"() -> runtime.Logger
{
	return runtime.Logger{kernel_logger_proc, nil, .Debug, nil}
}