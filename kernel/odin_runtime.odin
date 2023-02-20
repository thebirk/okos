package kernel

import "core:mem"


@export
memset :: proc "c" (ptr: rawptr, val: i32, len: int) -> rawptr
{
    if ptr != nil && len != 0 {
        b := byte(val)
        p := ([^]byte)(ptr)
        for i in 0..<len {
            p[i] = b
        }
    }
    return ptr
}

@export
memmove :: proc "c" (dst, src: rawptr, len: int) -> rawptr
{
    d, s := ([^]byte)(dst), ([^]byte)(src)
    if d == s || len == 0 {
        return dst
    }
    if d > s && uintptr(d)-uintptr(s) < uintptr(len) {
        for i := len-1; i >= 0; i -= 1 {
            d[i] = s[i]
        }
        return dst
    }

    if s > d && uintptr(s)-uintptr(d) < uintptr(len) {
        for i := 0; i < len; i += 1 {
            d[i] = s[i]
        }
        return dst
    }
    return memcpy(dst, src, len)
}

@export
memcpy :: proc "c" (dst, src: rawptr, len: int) -> rawptr
{
    d, s := ([^]byte)(dst), ([^]byte)(src)
    if d != s {
        for i := 0; i < len; i += 1 {
            d[i] = s[i]
        }
    }
    return d
}

/*
@export
__udivdi3 :: proc() {}
@export
__umoddi3 :: proc() {}
@export
__moddi3 :: proc() {}
@export
__divdi3 :: proc() {}
*/
