bits 64
global start64
extern kmain

section .text
start64:
    ; reset stack frame
    mov rsp, stack_top
    mov rbp, rsp

    ; save function params for init code below
    ; kmain: extern "C" fn(eboot: *mut EBootTable)
    push rdi    ; eboot:  EBootTable

    call init_page_tables
    call enable_paging

    ; load 64-bit GDT
    lgdt [gdt64.pointer]

    ; load ds into all data segments
    mov ax, ds
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    pop rdi
    call kmain

.catch:
    hlt
    jmp start64.catch

init_page_tables:
    ; map the 511th entry of P4 to P4 to setup recursive mapping later
    mov eax, p4_table
    or eax, 0b11    ; present + writable
    mov [p4_table + 511 * 8], eax
    
    ; map first P4 entry to P3 table
    mov eax, p3_table
    or eax, 0b11        ; present + writable
    mov [p4_table], eax

    ; map first P3 entry to P2 table
    mov eax, p2_table
    or eax, 0b11
    mov [p3_table], eax

    ; map each P2 entry to a 2MiB page
    mov ecx, 0
.map_p2_table:
    mov eax, 0x200000
    mul ecx
    or eax, 0b10000011      ; present + writable + huge
    mov [p2_table + ecx * 8], eax

    inc ecx
    cmp ecx, 512
    jne .map_p2_table

    ret

enable_paging:
    ; load P4 to cr3 register
    mov rax, p4_table
    mov cr3, rax

    ; enable PAE-flag in cr4
    mov rax, cr4
    or rax, 1 << 5
    mov cr4, rax

    ; set long mode bit in EFER MSR
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; enable paging in cr0 register
    mov rax, cr0
    or eax, 1 << 31
    mov cr0, rax

    ret

section .rodata
gdt64:
    dq 0 ; zero
.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

section .bss
align 4096
p4_table:
    resb 4096           ; after the kernel is remapped this becomes the stack guard page
p3_table:
    resb 4096           ; after the kernel is remapped the original p3/p2 tables are not used
p2_table:               ; so they are used as an additional 8kb of stack space (24kb + 4k guard page total)
    resb 4096
stack_bottom:
    resb 4096 * 4       ; 16 KiB Stack
stack_top: