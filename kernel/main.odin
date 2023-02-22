package kernel

import "core:mem"
import "core:intrinsics"

import "arch/i386/smbios"

foreign {
    @(link_name="__$startup_runtime")
    __startup_runtime :: proc() ---
}

foreign {
    double_fault :: proc"naked"() ---
}

cpuid :: intrinsics.x86_cpuid

@(private)
_cpu_name_buf: [72]u8
cpu_name:     Maybe(string)

@(private)
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

@export
kmain :: proc "contextless" () -> !
{
    context = kernel_context()
    __startup_runtime()
    kernel_fmt_init()
    klogf("kmain", "booting")

    init_cpu_name()
    klogf("cpu", "%v", cpu_name)
    
    idt_init()

    //for _ in 0..<100000000 {}


    for {
        //for _ in 0..<1000000 {}
        //kprintf("Hello, world!")
    }
}

print_smbios :: proc()
{
    if ep, ok := smbios.find_entry_point(); ok {
        kprintf("SMBIOS %d.%d\n", ep.major_version, ep.minor_version)
        kprintf("  Magic: %s\n", transmute(string) ep.magic[:])

        if info, ok := smbios.find_structure(&ep, .System_Information); ok {
            kprintf("System:\n")

            if str, ok := smbios.find_string_in_structure(info, info.system_information.manufacturer); ok {
                kprintf("  Manufacturer: %s\n", str)
            }

            if str, ok := smbios.find_string_in_structure(info, info.system_information.product_name); ok {
                kprintf("  Product Name: %s\n", str)
            }

            if str, ok := smbios.find_string_in_structure(info, info.system_information.version); ok {
                kprintf("  Version: %s\n", str)
            }

            if str, ok := smbios.find_string_in_structure(info, info.system_information.sku_number); ok {
                kprintf("  SKU Number: %s\n", str)
            }

            if str, ok := smbios.find_string_in_structure(info, info.system_information.family); ok {
                kprintf("  Family: %s\n", str)
            }
        }
    }
}