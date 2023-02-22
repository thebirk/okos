package i386

import kernel "kos:."
import "kos:kfmt"
import "kos:arch/i386/x86_terminal"
import "kos:arch/i386/kcontext"

foreign {
    //kmain :: proc() -> ! ---

    @(link_name="__$startup_runtime")
    __startup_runtime :: proc() ---

    double_fault :: proc"naked"() ---
}


@(export)
stage2 :: proc"contextless"() -> !
{
    context = kcontext.kernel_context()
    __startup_runtime()
    x86_terminal.init()
    kfmt.set_terminal_device(&x86_terminal.x86_terminal_device)

    kfmt.logf("stage2", "booting")

    init_cpu_name()
    kfmt.logf("cpu", "%v", cpu_name)
    
    idt_init()

    kernel.kmain()
}