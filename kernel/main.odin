package kernel

import "core:mem"
import "kos:kfmt"

kmain :: proc() -> !
{
    kfmt.logf("kmain", "Booting kOS..")

    for {
        //for _ in 0..<10000000 {}
        asm { "hlt", "" }()
        //kfmt.printf("Hello, world!")
        kfmt.logf("hlt", "woke up!")
    }
}
