package kernel

import "core:mem"
import "kos:kfmt"

kmain :: proc() -> !
{
    kfmt.logf("kmain", "booting")

    for {
        for _ in 0..<10000000 {}
        kfmt.printf("Hello, world!")
    }
}
