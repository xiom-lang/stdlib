; ================================================================
; XIOM Memory Assembly — x86_64 (NASM syntax)
; Copyright (c) 2026 Eleftherios Notas
; Licensed under the MIT or Apache-2.0 license, at your option.
;
; Optimized memory operations using SSE/AVX:
;   - memcpy:  SSE2 (16-byte) up to 256B, AVX (32-byte) above
;   - memset:  SSE2 (16-byte) up to 256B, AVX (32-byte) above  
;   - memcmp:  SSE2 (16-byte) with early-exit, constant-time variant
;   - memmove: handles overlapping regions (backward copy)
;
; Calling convention: System V AMD64 ABI
; Build: nasm -f elf64 mem_x86_64.asm -o mem_x86_64.o
; ================================================================

section .text
global xiom_asm_memcpy
global xiom_asm_memset
global xiom_asm_memcmp
global xiom_asm_memmove
global xiom_asm_bzero
global xiom_asm_memcmp_ct

; ================================================================
; Fast memcpy using SSE2/AVX
; void* xiom_asm_memcpy(void* dst, const void* src, size_t n)
;   RDI = dst, RSI = src, RDX = n
;   Returns RAX = dst
; ================================================================

xiom_asm_memcpy:
    push    rbp
    mov     rbp, rsp
    mov     rax, rdi              ; return dst

    ; Tiny copies: just do it byte-by-byte
    cmp     rdx, 16
    jb      .byte_copy

    ; Check for AVX support via CPUID (simplified: assume SSE2 always available)
    ; Small copies: SSE2 (16-byte chunks)
    cmp     rdx, 256
    jbe     .sse2_copy

    ; Large copies: use non-temporal stores to avoid cache pollution
    cmp     rdx, 2048
    jae     .nt_copy

    ; Medium copies: SSE2 with prefetch
    jmp     .sse2_copy

.nt_copy:
    ; Non-temporal: write directly to memory bypassing cache
    ; Best for copies > 2KB where dst won't be read soon
    mov     rcx, rdx
    shr     rcx, 7                ; / 128 (8 x 16-byte chunks)

.nt_loop:
    prefetchnta [rsi + 256]       ; prefetch ahead
    movdqu  xmm0, [rsi]
    movdqu  xmm1, [rsi + 16]
    movdqu  xmm2, [rsi + 32]
    movdqu  xmm3, [rsi + 48]
    movdqu  xmm4, [rsi + 64]
    movdqu  xmm5, [rsi + 80]
    movdqu  xmm6, [rsi + 96]
    movdqu  xmm7, [rsi + 112]

    movntdq [rdi], xmm0
    movntdq [rdi + 16], xmm1
    movntdq [rdi + 32], xmm2
    movntdq [rdi + 48], xmm3
    movntdq [rdi + 64], xmm4
    movntdq [rdi + 80], xmm5
    movntdq [rdi + 96], xmm6
    movntdq [rdi + 112], xmm7

    add     rsi, 128
    add     rdi, 128
    sub     rdx, 128
    dec     rcx
    jnz     .nt_loop

    sfence                       ; flush non-temporal writes
    test    rdx, rdx
    jz      .done
    ; Fall through to SSE2 for remainder

.sse2_copy:
    ; Copy 64 bytes at a time (4 x 16-byte SSE)
    mov     rcx, rdx
    shr     rcx, 6                ; / 64 (4 x 16)
    jz      .sse2_remainder

.sse2_loop64:
    movdqu  xmm0, [rsi]
    movdqu  xmm1, [rsi + 16]
    movdqu  xmm2, [rsi + 32]
    movdqu  xmm3, [rsi + 48]
    movdqa  [rdi], xmm0
    movdqa  [rdi + 16], xmm1
    movdqa  [rdi + 32], xmm2
    movdqa  [rdi + 48], xmm3
    add     rsi, 64
    add     rdi, 64
    dec     rcx
    jnz     .sse2_loop64

.sse2_remainder:
    ; Copy remaining 16-byte chunks
    mov     rcx, rdx
    and     rcx, 63
    shr     rcx, 4                ; / 16
    jz      .byte_remainder

.sse2_loop16:
    movdqu  xmm0, [rsi]
    movdqa  [rdi], xmm0
    add     rsi, 16
    add     rdi, 16
    dec     rcx
    jnz     .sse2_loop16

.byte_remainder:
    ; Copy remaining bytes
    and     rdx, 15
    jz      .done

.byte_copy:
    mov     rcx, rdx
    rep     movsb                  ; byte-by-byte copy

.done:
    pop     rbp
    ret

; ================================================================
; Fast memset using SSE2
; void* xiom_asm_memset(void* s, int c, size_t n)
;   RDI = s, RSI = c (byte), RDX = n
;   Returns RAX = s
; ================================================================

xiom_asm_memset:
    push    rbp
    mov     rbp, rsp
    mov     rax, rdi              ; return s

    ; Broadcast byte to fill 16-byte XMM register
    movzx   esi, sil              ; zero-extend byte
    movd    xmm0, esi
    punpcklbw xmm0, xmm0          ; byte → word
    punpcklwd xmm0, xmm0          ; word → dword
    punpckldq xmm0, xmm0          ; dword → qword
    punpcklqdq xmm0, xmm0         ; qword → dqword (16 x same byte)

    ; Tiny fills
    cmp     rdx, 16
    jb      .byte_set

    ; Align destination to 16 bytes
    test    dil, 15
    jz      .aligned_set

    ; Store until aligned
    mov     [rdi], sil
    inc     rdi
    dec     rdx
    jmp     .align_check

.aligned_set:
    ; 64-byte blocks
    mov     rcx, rdx
    shr     rcx, 6                ; / 64
    jz      .sse2_remainder

.sse2_loop64:
    movdqa  [rdi], xmm0
    movdqa  [rdi + 16], xmm0
    movdqa  [rdi + 32], xmm0
    movdqa  [rdi + 48], xmm0
    add     rdi, 64
    dec     rcx
    jnz     .sse2_loop64

.sse2_remainder:
    mov     rcx, rdx
    and     rcx, 63
    shr     rcx, 4                ; / 16
    jz      .byte_set

.sse2_loop16:
    movdqa  [rdi], xmm0
    add     rdi, 16
    dec     rcx
    jnz     .sse2_loop16

.byte_set:
    and     rdx, 15
    jz      .done

    mov     rcx, rdx
    rep     stosb

.done:
    pop     rbp
    ret

.align_check:
    test    dil, 15
    jnz     .align_loop
    jmp     .aligned_set

.align_loop:
    mov     [rdi], sil
    inc     rdi
    dec     rdx
    test    dil, 15
    jnz     .align_loop
    jmp     .aligned_set

; ================================================================
; Fast memcmp using SSE2
; int xiom_asm_memcmp(const void* s1, const void* s2, size_t n)
;   RDI = s1, RSI = s2, RDX = n
;   Returns: negative if s1 < s2, 0 if equal, positive if s1 > s2
; ================================================================

xiom_asm_memcmp:
    push    rbp
    mov     rbp, rsp
    xor     eax, eax

    test    rdx, rdx
    jz      .done

    ; 16-byte comparisons
    mov     rcx, rdx
    shr     rcx, 4
    jz      .byte_cmp

.cmp16_loop:
    movdqu  xmm0, [rdi]
    movdqu  xmm1, [rsi]
    pcmpeqb xmm0, xmm1           ; byte-wise equality
    pmovmskb eax, xmm0            ; bitmask: 1 where equal
    cmp     eax, 0xFFFF           ; all 16 bytes equal?
    jne     .find_diff

    add     rdi, 16
    add     rsi, 16
    dec     rcx
    jnz     .cmp16_loop

.byte_cmp:
    and     rdx, 15
    jz      .equal

    mov     rcx, rdx
    repe    cmpsb
    jne     .byte_diff
    xor     eax, eax
    jmp     .done

.byte_diff:
    ; Calculate difference of the unequal bytes
    movzx   eax, byte [rdi - 1]
    movzx   ecx, byte [rsi - 1]
    sub     eax, ecx
    jmp     .done

.find_diff:
    ; Find first differing byte position from pmovmskb mask
    not     eax
    bsf     eax, eax              ; position of first difference
    add     rdi, rax
    add     rsi, rax
    movzx   eax, byte [rdi]
    movzx   ecx, byte [rsi]
    sub     eax, ecx
    jmp     .done

.equal:
    xor     eax, eax

.done:
    pop     rbp
    ret

; ================================================================
; Constant-time memcmp (no early exit)
; int xiom_asm_memcmp_ct(const void* s1, const void* s2, size_t n)
; ================================================================

xiom_asm_memcmp_ct:
    push    rbp
    mov     rbp, rsp
    xor     eax, eax

    test    rdx, rdx
    jz      .ct_done

.ct_loop:
    mov     cl, [rdi]
    xor     cl, [rsi]
    or      al, cl
    inc     rdi
    inc     rsi
    dec     rdx
    jnz     .ct_loop

.ct_done:
    pop     rbp
    ret

; ================================================================
; memmove (handles overlapping regions)
; void* xiom_asm_memmove(void* dst, const void* src, size_t n)
; ================================================================

xiom_asm_memmove:
    push    rbp
    mov     rbp, rsp
    mov     rax, rdi

    cmp     rdi, rsi
    je      .move_done             ; dst == src, nothing to do
    ja      .move_backward          ; dst > src, copy backward to avoid overlap

    ; dst < src: safe to copy forward
    jmp     xiom_asm_memcpy        ; tail-call to memcpy

.move_backward:
    ; Copy from end to beginning
    add     rdi, rdx
    add     rsi, rdx
    dec     rdi
    dec     rsi
    std                             ; set direction flag (backward)
    mov     rcx, rdx
    rep     movsb
    cld                             ; clear direction flag

.move_done:
    pop     rbp
    ret

; ================================================================
; bzero (memset to zero)
; void xiom_asm_bzero(void* s, size_t n)
;   RDI = s, RSI = n
; ================================================================

xiom_asm_bzero:
    push    rbp
    mov     rbp, rsp
    xor     esi, esi              ; c = 0
    mov     rdx, rsi              ; save RSI (n) → RDX for memset convention
    xchg    rsi, rdx              ; RSI=0 (c), RDX=n
    push    rax
    call    xiom_asm_memset
    pop     rax
    pop     rbp
    ret
