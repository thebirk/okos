/**
  * https://www.gnu.org/software/grub/manual/multiboot/multiboot.html
  */
package multiboot

Multiboot_Information_Flags :: enum u32 {
    Memory               = 1<<0,
    Boot_Device          = 1<<1,
    Command_Line         = 1<<2,
    Modules              = 1<<3,
    Aout_Kernel          = 1<<4,    
    Elf_Kernel           = 1<<5,
    Memory_Map           = 1<<6,
    Drives               = 1<<7,
    Configuration        = 1<<8,
    Boot_Loader_Name     = 1<<9,
    Apm                  = 1<<10,
    Vesa_Bios_Extensions = 1<<11,
    Framebuffer          = 1<<12,
}

Multiboot_Framebuffer_Type :: enum u8 {
    Indexed = 0,
    RGB = 1,
    Text_Mode = 2,
}

Multiboot_Aout_Symbols :: struct #packed {
    tabsize: u32,
    strsize: u32,
    addr: u32,
    _reserved: u32,
}

Multiboot_Elf_Symbols :: struct #packed {
    num: u32,
    size: u32,
    addr: u32,
    shndx: u32,
}

Multiboot_Information :: struct #packed {
    flags: Multiboot_Information_Flags,

    // .Memory
    mem_lower: u32,
    mem_upper: u32,

    // .Boot_Device
    boot_device: u32,

    // .Command_Line
    cmdline: cstring,

    // .Modules
    mods_count: u32,
    mods_addr: u32,

    // .Aout_Kernel or .Elf_Kernel
    syms: struct #raw_union {
        aout: Multiboot_Aout_Symbols,
        elf: Multiboot_Elf_Symbols,
    },
    
    // .Memory_Map
    mmap_length: u32,
    mmap_addr: u32,
    
    // .Drives
    drives_length: u32,
    drives_addr: u32,
    
    // .Configuration
    config_table: u32,
    
    // .Boot_Loader_Name
    boot_loader_name: cstring,
    
    // .Apm
    apm_table: u32,

    // .Vesa_Bios_Extensions
    vbe_control_info: u32,
    vbe_mode_info: u32,
    vbe_mode: u16,
    vbe_interface_seg: u16,
    vbe_interface_off: u16,
    vbe_interface_len: u16,

    // .Framebuffer
    framebuffer_addr: u64,
    framebuffer_pitch: u32,
    framebuffer_width: u32,
    framebuffer_height: u32,
    framebuffer_bpp: u8,
    framebuffer_type: Multiboot_Framebuffer_Type,
    color_info: struct #raw_union {
        indexed: struct #packed {
            palette_addr: u32,
            palette_num_colors: u16,
        },
        rgb: struct #packed {
            red_field_position: u8,
            red_mask_size: u8,
            green_field_position: u8,
            green_mask_size: u8,
            blue_field_position: u8,
            blue_mask_size: u8,
        },
    }
}