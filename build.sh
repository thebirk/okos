#!/bin/bash
shopt -s extglob 

ROOT="$(realpath $(dirname -- "${BASH_SOURCE[0]}"))"
cd $ROOT

TARGET="freestanding_i386_sysv"
ODIN_COMMON_FLAGS="-target:$TARGET -no-entry-point -default-to-nil-allocator -strict-style -collection:kos=\"$ROOT/kernel\""
OFLAGS="$ODIN_COMMON_FLAGS -reloc-mode:static -build-mode:object -disable-red-zone -debug -keep-temp-files"

CLANG_TARGET="i686-freestanding-elf"
CFLAGS="-target $CLANG_TARGET -ffreestanding -nostdlib -std=c11 -O0 -Wall -Wextra -Wimplicit-fallthrough -fno-pic -fno-pie -fno-builtin -fno-strict-aliasing -Wall -Wstrict-prototypes -Wnewline-eof -Wpointer-arith"

OBJDIR="bin"
KERNEL="kernel.bin"

REQUIRED_BINS=("clang" "nasm" "ld.lld" "qemu-system-i386")
ASM_SRC=(
    "arch/i386/io/io.asm"
    "arch/i386/irq/irq.asm"
    "arch/i386/boot.asm"
)
OBJS=()

RUN_QEMU=false
QEMU_STOPPED=
VERBOSE=false
VERY_VERBOSE=false
ODIN_CHECK=false
CLEAN=false
QEMU_WINDOWS=false

usage() {
    cat <<EUSAGE
Usage: 
    $0 [options] [command] <command args...>

Options:
    -g                      Start qemu in stopped state. Waiting for a connection to gdbserver.
    -c                      Only do `odin check`
    -h,   --help            Show script usage
    -r,   --run             Run qemu after a successful build
    -v,   --verbose         Show commands when they are run
    -V,   --very-verbose    Enable bash debug output
    -w                      If running under WSL try running qemu on windows

    --clean                 Delete object files and kernel binary

Commands:


EUSAGE
}


POSITIONAL=()
while (( $# )); do
    case $1 in
        -g)
            QEMU_STOPPED="-S"
            shift
            ;;
        -c)
            ODIN_CHECK=true
            shift
            ;;
        -r)
            RUN_QEMU=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -V|--very-verbose)
            VERY_VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 2
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        -w)
            QEMU_WINDOWS=true
            shift
            ;;
        -*|--*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done
set -- "${POSITIONAL[@]}"

if $VERY_VERBOSE; then
    (set -o posix; set)
fi

for bin in "${REQUIRED_BINS[@]}"; do
    if ! [[ -x $(which "$bin") ]]; then
        echo "Could not find '$bin'."
        exit 1
    fi
done

VERBOSE_COLOR="32"
# verbose args..
verbose() {
    if $VERBOSE; then
        echo -en "\e[${VERBOSE_COLOR}m"
        echo "$@"
        echo -en "\e[0m"
    fi
    eval "$@"
}

exit_on_err() {
    if ! eval "$@"; then
        exit $?
    fi
}

if $CLEAN; then
    echo CLEAN bin/
    exit_on_err verbose find bin -not -name '.gitkeep' -not -name 'bin' -delete
    echo CLEAN kernel.bin
    exit_on_err verbose rm -f kernel.bin
    exit 0
fi

if $ODIN_CHECK; then
    echo CHECK kernel
    verbose odin/odin check kernel $ODIN_COMMON_FLAGS
    exit 0
fi

echo ODIN kernel
exit_on_err verbose odin/odin build kernel/arch/i386 $OFLAGS -out:$OBJDIR/kernel.o
OBJ+=("$OBJDIR/kernel.o")

for asm in "${ASM_SRC[@]}"; do
    echo NASM $asm
    exit_on_err verbose mkdir -p $(dirname "bin/${asm%.asm}.o")
    exit_on_err verbose nasm -felf32 kernel/$asm -o "bin/${asm%.asm}.o"
    OBJ+=("bin/${asm%.asm}.o")
done

echo CC arith64.c
exit_on_err verbose clang $CFLAGS -c kernel/arch/i386/arith64.c -o $OBJDIR/arith64.o
OBJ+=("$OBJDIR/arith64.o")

echo LINK $KERNEL
exit_on_err verbose ld.lld -o $KERNEL -T linker.ld ${OBJ[@]}

if $RUN_QEMU; then
    if ! grep -qi wsl /proc/version; then
        QEMU_ARGS="$QEMU_ARGS -accel kvm -cpu host -display sdl"
    else
        QEMU_ARGS="$QEMU_ARGS -display gtk"
    fi

    QEMU_CMD="qemu-system-i386"
    if $QEMU_WINDOWS; then
        QEMU_CMD="qemu-system-i386.exe"
    fi
    
    verbose "$QEMU_CMD -kernel $KERNEL -serial stdio -d cpu_reset,guest_errors,int -no-reboot $QEMU_STOPPED $QEMU_ARGS"
fi