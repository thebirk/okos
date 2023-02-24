package i386

import "core:intrinsics"

cpuid :: intrinsics.x86_cpuid

cpu_name:     Maybe(string)

@(private)
_cpu_name_buf: [72]u8

@(init)
init_cpu_name :: proc "c" () {
	number_of_extended_ids, _, _, _ := cpuid(0x8000_0000, 0)
	if number_of_extended_ids < 0x8000_0004 {
		return
	}

	_buf := transmute(^[12]u32)&_cpu_name_buf
	_buf[ 0], _buf[ 1], _buf[ 2], _buf[ 3] = cpuid(0x8000_0002, 0)
	_buf[ 4], _buf[ 5], _buf[ 6], _buf[ 7] = cpuid(0x8000_0003, 0)
	_buf[ 8], _buf[ 9], _buf[10], _buf[11] = cpuid(0x8000_0004, 0)

	// Some CPUs like may include leading or trailing spaces. Trim them.
	// e.g. `      Intel(R) Xeon(R) CPU E5-1650 v2 @ 3.50GHz`

	brand := string(_cpu_name_buf[:])
	for len(brand) > 0 && brand[0] == 0 || brand[0] == ' ' {
		brand = brand[1:]
	}
	for len(brand) > 0 && brand[len(brand) - 1] == 0 || brand[len(brand) - 1] == ' ' {
		brand = brand[:len(brand) - 1]
	}
	cpu_name = brand
}
