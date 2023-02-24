[bits 32]
MB_ALIGN    equ 1<<0
MB_MEMINFO  equ 1<<1
MB_FLAGS    equ MB_ALIGN | MB_MEMINFO
MB_MAGIC    equ 0x1BADB002
MB_CHECKSUM equ -(MB_MAGIC + MB_FLAGS)

section .multiboot
align 4
dd MB_MAGIC
dd MB_FLAGS
dd MB_CHECKSUM

section .bss
align 16
stack_bot:
resb 16384*4
stack_top:

section .text
global _start:function (_start.end - _start)
_start:
    cmp eax, 0x2BADB002
    je .good_magic
    mov ecx, BAD_MAGIC_ERROR
    jmp boot_error
.good_magic:

    ; set stack
    mov esp, stack_top
    push ds
    push cs
    push ebx
    
    call enable_sse
    
    ; enter kernel
    extern stage2
    call stage2

    cli
.hang:
    hlt
    jmp .hang
.end:


enable_sse:
    ; test for SSE and bail if not
    mov eax, 1
    cpuid
    test edx, 1<<25
    mov ecx, NO_SSE_ERROR
    jz boot_error

    ; enable SSE
    mov eax, cr0
    and ax, 0xFFFB
    or ax, 2
    mov cr0, eax
    mov eax, cr4
    or ax, 3<<9
    mov cr4, eax

    ret

VGA equ 0xB8000
; ecx - zero terminated string
boot_error:
    mov edx, 0
    mov ah, 0x0C
.loop:
    mov al, byte [ecx]
    cmp al, 0
    je .hang

    mov word [VGA + edx * 2], ax
    inc edx
    inc ecx

    jmp .loop

    cli
.hang:
    hlt
    jmp .hang


BAD_MAGIC_ERROR: db 'BOOT ERROR: bad bootloader magic', 0
NO_SSE_ERROR: db 'BOOT ERROR: SSE support required', 0
