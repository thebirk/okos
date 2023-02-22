package smbios

import "core:mem"

Structure_Type :: enum u8 {
    Bios_Information = 0,
    System_Information = 1,
    Processor_Information = 4,
}

EntryPoint :: struct #packed {
    magic:                [4]u8,
    checksum:             u8,
    length:               u8,
 	major_version:        u8,
 	minor_version:        u8,
 	max_structure_size:   u16,
 	entry_point_revision: u8,
 	formatted_area:       [5]u8,
 	entry_point_string_2: [5]u8,
 	checksum_2:           u8,
 	table_length:         u16,
 	table_address:        u32,
 	number_of_structures: u16,
 	bcd_revision:         u8,
}

Header :: struct #packed {
    type:   Structure_Type,
    length: u8,
    handle: u16,
}

BiosInfoStructure :: struct #packed {
    vendor:                   u8,
    version:                  u8,
    starting_address_segment: u16,
    release_date:             u8,
    rom_size:                 u8,
    characteristics:          u64,
    // characteristics_extension_bytes
}

SystemInformationStructure :: struct #packed {
    manufacturer:  u8,
    product_name:  u8,
    version:       u8,
    serial_number: u8,
    uuid:          [16]u8,
    wake_up_type:  u8,
    sku_number:    u8,
    family:        u8,
}

ProcessorInformationStructure :: struct #packed {
    socket_designation:     u8,
    processor_type:         u8,
    processor_family:       u8,
    processor_manufacturer: u8,
    processor_id:           u64,
    processor_version:      u8,
    voltage:                u8,
    external_clock:         u16,
    max_speed:              u16,
    current_speed:          u16,
    status:                 u8,
    processor_upgrade:      u8,
}

Structure :: struct #packed {
    header: Header,

    using _: struct #raw_union {
        bios_info: BiosInfoStructure,
        system_information: SystemInformationStructure,
        processor_information: ProcessorInformationStructure,
    },
}

EntryPointSearchStart :: uintptr(0xF0000)
EntryPointSearchEnd   :: uintptr(0xFFFFF)
EntryPointMagic       ::  u32(0x5F4D535F) // _SM_

find_entry_point :: proc() -> (EntryPoint, bool)
{
    mem_8: [^]u8 = cast(^u8) EntryPointSearchStart
    mem_32: [^]u32 = cast(^u32) EntryPointSearchStart

    length := EntryPointSearchEnd - EntryPointSearchStart + 1

    for i := uintptr(0); i < length; i += 16 {
        if mem_32[i / 4] != EntryPointMagic {
            continue
        }

        ep := cast(^EntryPoint) rawptr(EntryPointSearchStart + length)
        length := ep.length
        checksum := u8(0)
        for i := u8(0); i < length; i += 1 {
            checksum += mem_8[i]
        }

        if checksum == 0 {
            entry_point: EntryPoint
            mem.copy(&entry_point, rawptr(EntryPointSearchStart + i), size_of(EntryPoint))
            return entry_point, true
        }
    }
    
    return {}, false
}

find_structure :: proc(entry_point: ^EntryPoint, type: Structure_Type) -> (^Structure, bool)
{
    m := cast(^u8) (uintptr(entry_point.table_address))

    for _ in 0..<entry_point.number_of_structures {
        header := cast(^Header) m
        if header.type == type {
            return cast(^Structure)m, true
        }

        m = mem.ptr_offset(m, header.length)

        for m^ != 0 {
            for m^ != 0  {
                m = mem.ptr_offset(m, 1)
            }

            m = mem.ptr_offset(m, 1)
        }
        m = mem.ptr_offset(m, 1)
    }

    return nil, false
}

find_string_in_structure :: proc(structure: ^Structure, index: u8) -> (string, bool)
{
    if index == 0 {
        return {}, false
    }

    m := cast(^u8) (uintptr(structure) + uintptr(structure.header.length))
    i := u8(1)

    for m^ != 0 {
        if i == index {
            return string(cstring(m)), true
        }

        for m^ != 0 {
            m = mem.ptr_offset(m, 1)
        }
        m = mem.ptr_offset(m, 1)
        i += 1
    }

    return {}, false
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
