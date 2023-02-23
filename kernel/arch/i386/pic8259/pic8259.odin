package pic8259

import "kos:arch/i386/io"

PIC_MASTER_COMMAND_PORT :: u16(0x0020)
PIC_MASTER_DATE_PORT    :: u16(0x0021)
PIC_SLAVE_COMMAND_PORT  :: u16(0x0020)
PIC_SLAVE_DATE_PORT     :: u16(0x0021)

remap :: proc()
{
    
}
