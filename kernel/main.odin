package kernel

import "core:mem"
import "kos:kfmt"

@export
kmain :: proc() -> !
{
    //for _ in 0..<100000000 {}
    kfmt.logf("kmain", "booting")

    for {
        //for _ in 0..<1000000 {}
        //kprintf("Hello, world!")
    }
}

/*
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
*/
