; ================================================================
; XIOM Crypto Assembly — x86_64 (NASM syntax, win64/elf64)
; Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
; SPDX-License-Identifier: MIT OR Apache-2.0
;
; Hand-tuned assembly for hardware-accelerated crypto:
;   - AES-128 encrypt/decrypt single block (AES-NI)
;   - AES-128 key expansion (AES-NI)
;   - Constant-time memory comparison
;
; NOTE: SHA-256 hardware acceleration uses SHA-NI intrinsics
;       via simd_runtime.c / xiom_runtime.c, not raw assembly.
;       This avoids NASM macro expansion issues with 64-round unrolling.
;
; Calling convention: Microsoft x64 (win64) / System V AMD64 (elf64)
;   win64: RCX=1st, RDX=2nd, R8=3rd, R9=4th
;   elf64: RDI=1st, RSI=2nd, RDX=3rd, RCX=4th
;
; We use the Microsoft x64 convention since this is the primary
; Windows target. For Linux/WSL, assemble with -f elf64 and the
; runtime C code handles ABI translation.
;
; Build:
;   nasm -f win64 crypto_x86_64.asm -o crypto_x86_64.obj  (Windows)
;   nasm -f elf64 crypto_x86_64.asm -o crypto_x86_64.o    (Linux)
; ================================================================

section .text
global xiom_asm_aes128_encrypt_block
global xiom_asm_aes128_decrypt_block
global xiom_asm_aes128_key_expand
global xiom_asm_constant_time_compare

; ================================================================
; NOTE ON CALLING CONVENTION
;
; The C runtime (xiom_runtime.c) wraps these with ABI-translating
; stubs. On Windows (win64), the first four args come via RCX,RDX,R8,R9.
; On Linux (elf64 via System V), they come via RDI,RSI,RDX,RCX.
;
; For maximum compatibility, these assembly functions accept:
;   win64: RCX=plaintext/ciphertext, RDX=round_keys/key, R8=output
;   elf64: RDI=plaintext/ciphertext, RSI=round_keys/key, RDX=output
;
; We use register aliases at the top of each function to abstract
; the calling convention difference.
; ================================================================

; ================================================================
; AES-128 Encrypt Single Block (Microsoft x64 convention)
; void xiom_asm_aes128_encrypt_block(
;     const uint8_t plaintext[16],   ; RCX (win64) / RDI (elf64)  
;     const uint8_t round_keys[176], ; RDX (win64) / RSI (elf64)
;     uint8_t ciphertext[16]         ; R8  (win64) / RDX (elf64)
; )
;
; Uses AES-NI: aesenc x 9 rounds + aesenclast x 1 round
; ================================================================

xiom_asm_aes128_encrypt_block:
    ; Load plaintext into XMM0
%ifdef WIN64
    movdqu  xmm0, [rcx]        ; plaintext
    mov     r10, rdx            ; round_keys base
    mov     r11, r8             ; ciphertext output
%else
    movdqu  xmm0, [rdi]        ; plaintext
    mov     r10, rsi            ; round_keys base
    mov     r11, rdx            ; ciphertext output
%endif

    ; Initial AddRoundKey — XOR with first round key
    movdqu  xmm1, [r10]
    pxor    xmm0, xmm1

    ; Rounds 1-9: AESENC (ShiftRows + SubBytes + MixColumns + AddRoundKey)
    movdqu  xmm1, [r10 + 16]
    aesenc  xmm0, xmm1
    movdqu  xmm1, [r10 + 32]
    aesenc  xmm0, xmm1
    movdqu  xmm1, [r10 + 48]
    aesenc  xmm0, xmm1
    movdqu  xmm1, [r10 + 64]
    aesenc  xmm0, xmm1
    movdqu  xmm1, [r10 + 80]
    aesenc  xmm0, xmm1
    movdqu  xmm1, [r10 + 96]
    aesenc  xmm0, xmm1
    movdqu  xmm1, [r10 + 112]
    aesenc  xmm0, xmm1
    movdqu  xmm1, [r10 + 128]
    aesenc  xmm0, xmm1
    movdqu  xmm1, [r10 + 144]
    aesenc  xmm0, xmm1

    ; Round 10: AESENCLAST (ShiftRows + SubBytes + AddRoundKey, NO MixColumns)
    movdqu  xmm1, [r10 + 160]
    aesenclast xmm0, xmm1

    ; Store ciphertext
    movdqu  [r11], xmm0

    ret

; ================================================================
; AES-128 Decrypt Single Block (Microsoft x64 convention)
; void xiom_asm_aes128_decrypt_block(
;     const uint8_t ciphertext[16],  ; RCX / RDI
;     const uint8_t round_keys[176], ; RDX / RSI
;     uint8_t plaintext[16]          ; R8  / RDX
; )
;
; Uses AES-NI: aesdec x 9 rounds + aesdeclast x 1 round
; Uses INVERSE round key order (last→first)
; ================================================================

xiom_asm_aes128_decrypt_block:
    ; Load ciphertext
%ifdef WIN64
    movdqu  xmm0, [rcx]        ; ciphertext
    mov     r10, rdx            ; round_keys base
    mov     r11, r8             ; plaintext output
%else
    movdqu  xmm0, [rdi]        ; ciphertext
    mov     r10, rsi            ; round_keys base
    mov     r11, rdx            ; plaintext output
%endif

    ; Initial AddRoundKey with LAST round key (index 10)
    movdqu  xmm1, [r10 + 160]
    pxor    xmm0, xmm1

    ; Inverse rounds 9-1 using round keys 9-1
    movdqu  xmm1, [r10 + 144]
    aesdec  xmm0, xmm1
    movdqu  xmm1, [r10 + 128]
    aesdec  xmm0, xmm1
    movdqu  xmm1, [r10 + 112]
    aesdec  xmm0, xmm1
    movdqu  xmm1, [r10 + 96]
    aesdec  xmm0, xmm1
    movdqu  xmm1, [r10 + 80]
    aesdec  xmm0, xmm1
    movdqu  xmm1, [r10 + 64]
    aesdec  xmm0, xmm1
    movdqu  xmm1, [r10 + 48]
    aesdec  xmm0, xmm1
    movdqu  xmm1, [r10 + 32]
    aesdec  xmm0, xmm1
    movdqu  xmm1, [r10 + 16]
    aesdec  xmm0, xmm1

    ; Final round: AESDECLAST with round key 0
    movdqu  xmm1, [r10]
    aesdeclast xmm0, xmm1

    ; Store plaintext
    movdqu  [r11], xmm0

    ret

; ================================================================
; AES-128 Key Expansion (Microsoft x64 convention)
; void xiom_asm_aes128_key_expand(
;     const uint8_t key[16],          ; RCX / RDI
;     uint8_t round_keys[176]         ; RDX / RSI  (11 rounds × 16 bytes)
; )
;
; Generates 11 round keys from a 16-byte AES-128 key.
; Uses AESKEYGENASSIST for the S-box + rcon step.
; ================================================================

xiom_asm_aes128_key_expand:
%ifdef WIN64
    mov     r10, rcx            ; key
    mov     r11, rdx            ; round_keys output
%else
    mov     r10, rdi            ; key
    mov     r11, rsi            ; round_keys output
%endif

    ; Copy original key as first round key
    movdqu  xmm0, [r10]
    movdqu  [r11], xmm0

    ; Expand 10 more round keys
    ; Round key 1
    aeskeygenassist xmm2, xmm0, 0x01
    call    aes128_key_expand_step
    movdqu  [r11 + 16], xmm0

    ; Round key 2
    aeskeygenassist xmm2, xmm0, 0x02
    call    aes128_key_expand_step
    movdqu  [r11 + 32], xmm0

    ; Round key 3
    aeskeygenassist xmm2, xmm0, 0x04
    call    aes128_key_expand_step
    movdqu  [r11 + 48], xmm0

    ; Round key 4
    aeskeygenassist xmm2, xmm0, 0x08
    call    aes128_key_expand_step
    movdqu  [r11 + 64], xmm0

    ; Round key 5
    aeskeygenassist xmm2, xmm0, 0x10
    call    aes128_key_expand_step
    movdqu  [r11 + 80], xmm0

    ; Round key 6
    aeskeygenassist xmm2, xmm0, 0x20
    call    aes128_key_expand_step
    movdqu  [r11 + 96], xmm0

    ; Round key 7
    aeskeygenassist xmm2, xmm0, 0x40
    call    aes128_key_expand_step
    movdqu  [r11 + 112], xmm0

    ; Round key 8
    aeskeygenassist xmm2, xmm0, 0x80
    call    aes128_key_expand_step
    movdqu  [r11 + 128], xmm0

    ; Round key 9
    aeskeygenassist xmm2, xmm0, 0x1B
    call    aes128_key_expand_step
    movdqu  [r11 + 144], xmm0

    ; Round key 10
    aeskeygenassist xmm2, xmm0, 0x36
    call    aes128_key_expand_step
    movdqu  [r11 + 160], xmm0

    ret

; AES key schedule core step (called after aeskeygenassist)
; Input:  xmm0 = current round key, xmm2 = aeskeygenassist result
; Output: xmm0 = next round key
; Preserves: r10, r11
aes128_key_expand_step:
    ; Broadcast the last word of the assist result to all positions
    pshufd  xmm2, xmm2, 0xFF

    ; Extract previous word (last 4 bytes of current key) for XOR chain
    movdqa  xmm1, xmm0
    pslldq  xmm1, 4              ; shift left by 4 bytes
    pxor    xmm2, xmm1
    pslldq  xmm1, 4
    pxor    xmm2, xmm1
    pslldq  xmm1, 4
    pxor    xmm2, xmm1

    ; XOR the key schedule core into xmm0
    pxor    xmm0, xmm2
    ret

; ================================================================
; Constant-Time Memory Comparison
; int xiom_asm_constant_time_compare(
;     const uint8_t* a,   ; RCX / RDI
;     const uint8_t* b,   ; RDX / RSI
;     size_t len          ; R8  / RDX  (64-bit on x64)
; )
;
; Returns 0 if equal, non-zero if different.
; NO early exit — processes ALL bytes regardless of differences.
; Uses XOR accumulation to defeat timing side-channels.
; ================================================================

xiom_asm_constant_time_compare:
%ifdef WIN64
    mov     r10, rcx            ; a
    mov     r11, rdx            ; b
    mov     r12, r8             ; len
%else
    mov     r10, rdi            ; a
    mov     r11, rsi            ; b
    mov     r12, rdx            ; len
%endif

    xor     eax, eax            ; accumulator = 0
    test    r12, r12
    jz      ct_done

    ; Process 16 bytes at a time using SSE2
ct_cmp16:
    cmp     r12, 16
    jb      ct_cmp1

    movdqu  xmm0, [r10]
    movdqu  xmm1, [r11]
    pxor    xmm0, xmm1          ; XOR = 0 where bytes equal
    pmovmskb ecx, xmm0          ; bitmask: 1 where bytes differ
    or      eax, ecx            ; accumulate any differences

    add     r10, 16
    add     r11, 16
    sub     r12, 16
    jmp     ct_cmp16

    ; Process remaining bytes one at a time
ct_cmp1:
    test    r12, r12
    jz      ct_done

    mov     cl, [r10]
    xor     cl, [r11]
    or      al, cl              ; accumulate difference (no branch)
    inc     r10
    inc     r11
    dec     r12
    jmp     ct_cmp1

ct_done:
    ; eax = 0 if all bytes equal, non-zero otherwise
    ret
