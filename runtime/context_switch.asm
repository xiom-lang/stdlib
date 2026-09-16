; ================================================================
; XIOM Context Switch Assembly — x86_64 (NASM syntax)
; Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
; Licensed under the Apache-2.0 license.
;
; Provides:
;   - xiom_asm_ctx_save:  Save current execution context
;   - xiom_asm_ctx_load:  Load and jump to a saved context
;   - xiom_asm_ctx_swap:  Save current, load target (atomic switch)
;   - xiom_asm_stack_init: Initialize a new stack for a fresh context
;
; Context structure (xiom_context, 64 bytes, 16-byte aligned):
;   [0x00] RSP  (stack pointer)
;   [0x08] RIP  (instruction pointer / entry point)
;   [0x10] RBX  (callee-saved)
;   [0x18] RBP  (callee-saved)
;   [0x20] R12  (callee-saved)
;   [0x28] R13  (callee-saved)
;   [0x30] R14  (callee-saved)
;   [0x38] R15  (callee-saved)
;
; Calling convention: System V AMD64 ABI
; Build: nasm -f elf64 context_switch.asm -o context_switch.o
; ================================================================

section .text
global xiom_asm_ctx_save
global xiom_asm_ctx_load
global xiom_asm_ctx_swap
global xiom_asm_stack_init

; ================================================================
; int xiom_asm_ctx_save(xiom_context* ctx)
;   RDI = ctx (pointer to context structure)
;   Returns: 0 on first return (save path), 1 on resume (load path)
;
; Saves the current execution context into ctx.
; When this context is later loaded, execution resumes here
; with return value 1 (distinguishing save vs resume).
; ================================================================

xiom_asm_ctx_save:
    ; Save callee-saved registers to context structure
    mov     [rdi + 16], rbx
    mov     [rdi + 24], rbp
    mov     [rdi + 32], r12
    mov     [rdi + 40], r13
    mov     [rdi + 48], r14
    mov     [rdi + 56], r15

    ; Save current stack pointer
    lea     rax, [rsp + 8]        ; RSP at call time (before return address push)
    mov     [rdi], rax

    ; Save return address as RIP
    mov     rax, [rsp]            ; return address from call stack
    mov     [rdi + 8], rax

    ; Return 0 to indicate "just saved" path
    xor     eax, eax
    ret

; ================================================================
; void xiom_asm_ctx_load(xiom_context* ctx)
;   RDI = ctx
;   Never returns — jumps to the saved context's RIP
;
; Loads a previously saved context and jumps to its instruction pointer.
; The loaded context will see return value 1 from its xiom_asm_ctx_save call.
; ================================================================

xiom_asm_ctx_load:
    ; Restore stack pointer
    mov     rsp, [rdi]

    ; Restore callee-saved registers
    mov     rbx, [rdi + 16]
    mov     rbp, [rdi + 24]
    mov     r12, [rdi + 32]
    mov     r13, [rdi + 40]
    mov     r14, [rdi + 48]
    mov     r15, [rdi + 56]

    ; Set return value to 1 (indicates resume path)
    mov     eax, 1

    ; Jump to saved instruction pointer
    jmp     [rdi + 8]
    ; Execution continues at the return address from the original ctx_save call

; ================================================================
; int xiom_asm_ctx_swap(xiom_context* from_ctx, xiom_context* to_ctx)
;   RDI = from_ctx (save current state here)
;   RSI = to_ctx  (load this context)
;   Returns: 1 (indicates resume path after being swapped back)
;
; Atomic save + load. Equivalent to save(from) then load(to),
; but guaranteed to happen without interruption.
; ================================================================

xiom_asm_ctx_swap:
    ; Save current context to from_ctx
    mov     [rdi + 16], rbx
    mov     [rdi + 24], rbp
    mov     [rdi + 32], r12
    mov     [rdi + 40], r13
    mov     [rdi + 48], r14
    mov     [rdi + 56], r15

    lea     rax, [rsp + 8]
    mov     [rdi], rax
    mov     rax, [rsp]
    mov     [rdi + 8], rax

    ; Load target context from to_ctx
    mov     rsp, [rsi]
    mov     rbx, [rsi + 16]
    mov     rbp, [rsi + 24]
    mov     r12, [rsi + 32]
    mov     r13, [rsi + 40]
    mov     r14, [rsi + 48]
    mov     r15, [rsi + 56]

    ; Return 1 to indicate resume
    mov     eax, 1

    jmp     [rsi + 8]

; ================================================================
; void xiom_asm_stack_init(xiom_context* ctx, void* stack_top, 
;                           void (*entry_fn)(void*), void* arg)
;   RDI = ctx
;   RSI = stack_top (points to HIGHEST address of stack — stack grows down)
;   RDX = entry_fn (function pointer for the new context)
;   RCX = arg (argument to pass to entry_fn)
;
; Initializes a fresh context on a new stack. When this context
; is first loaded via ctx_load or ctx_swap, it will call:
;   entry_fn(arg)
; and when that function returns, the context exits.
; ================================================================

xiom_asm_stack_init:
    ; Align stack to 16 bytes (required by System V ABI)
    and     rsi, ~0xF             ; clear low 4 bits

    ; Set up initial stack frame. Stack grows down, so LAST push is at RSP.
    ; When ctx_load jumps to trampoline (via ctx->rip), the stack looks like:
    ;   [RSP]      = entry_fn address  (trampoline pops this first)
    ;   [RSP + 8]  = arg               (trampoline pops this second)
    ;   [RSP + 16] = ctx_exit address  (ret pops this after entry_fn returns)

    ; Push ctx_exit — deepest on stack (will be popped by ret after call)
    mov     rax, .ctx_exit
    sub     rsi, 8
    mov     [rsi], rax

    ; Push arg — second to be popped by trampoline
    sub     rsi, 8
    mov     [rsi], rcx

    ; Push entry_fn — first to be popped by trampoline (top of stack)
    sub     rsi, 8
    mov     [rsi], rdx

    ; Store stack pointer in context
    mov     [rdi], rsi

    ; Store trampoline address as initial RIP (ctx_load jumps here)
    lea     rax, [rel .ctx_trampoline]
    mov     [rdi + 8], rax

    ; Initialize callee-saved registers to zero
    xor     eax, eax
    mov     [rdi + 16], rax        ; RBX = 0
    mov     [rdi + 24], rax        ; RBP = 0
    mov     [rdi + 32], rax        ; R12 = 0
    mov     [rdi + 40], rax        ; R13 = 0
    mov     [rdi + 48], rax        ; R14 = 0
    mov     [rdi + 56], rax        ; R15 = 0

    ret

; Trampoline: called when the new context is first loaded by ctx_load.
; Stack at entry: [RSP]=entry_fn, [RSP+8]=arg, [RSP+16]=ctx_exit
.ctx_trampoline:
    ; Pop entry_fn address and arg from the stack
    pop     rsi                     ; RSI = entry_fn (function to call)
    pop     rdi                     ; RDI = arg (first argument per SysV ABI)
    
    ; Call entry_fn(arg) — when it returns, execution continues below
    call    rsi
    
    ; entry_fn returned — pop ctx_exit address and jump to it
    ret                             ; pops [RSP] = ctx_exit, jumps there

; Called when entry_fn returns — exits the context
.ctx_exit:
    ; This is where we'd clean up the context and yield back
    ; For now, just halt (can be extended with a scheduler callback)
    xor     edi, edi               ; exit code 0
    mov     eax, 60                ; sys_exit on Linux
    syscall
    ; Execution should never reach here
    hlt
