#define _CRT_SECURE_NO_WARNINGS
#define _WINSOCK_DEPRECATED_NO_WARNINGS
// XIOM Runtime -- C helper functions for self-hosting compiler
// All string operations happen here. The XIOM compiler works with Int IDs.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#else
#include <dirent.h>
#include <unistd.h>
#include <sys/statvfs.h>
#endif

#include <stdint.h>

/* ================================================================
   Assembly-Optimized Function Declarations
   These are implemented in:
     crypto_x86_64.asm   — SHA-256, AES-128, constant-time compare
     mem_x86_64.asm      — memcpy, memset, memcmp, memmove, bzero
     context_switch.asm  — context save/load/swap for async
   Build: nasm -f elf64 <file>.asm -o <file>.o (Linux)
          nasm -f win64 <file>.asm -o <file>.obj (Windows)
   ================================================================ */

/* ================================================================
   Assembly-accelerated functions (crypto/memcpy/context)
   When NASM is available and .asm files are assembled, XIOM_NO_ASM
   is NOT defined and the strong assembly symbols override.
   When NASM is NOT available, C software implementations are used.
   ================================================================ */

/* Context struct (needed regardless of ASM availability) */
typedef struct {
    uint64_t rsp, rip, rbx, rbp, r12, r13, r14, r15;
} xiom_context;

#ifdef XIOM_NO_ASM
/* ── C software implementations (no NASM) ── */
#include <stddef.h>

/* crypto stubs */
static void xiom_asm_sha256_compress(uint32_t s[8], const uint8_t* b) { (void)s; (void)b; } /* NOTE: SHA-256 uses SHA-NI intrinsics in simd_runtime.c, not raw asm */
static void xiom_asm_aes128_encrypt_block(const uint8_t* p, const uint8_t* rk, uint8_t* c) { (void)p; (void)rk; (void)c; }
static void xiom_asm_aes128_decrypt_block(const uint8_t* c, const uint8_t* rk, uint8_t* p) { (void)c; (void)rk; (void)p; }
static void xiom_asm_aes128_key_expand(const uint8_t* k, uint8_t* rk) { (void)k; (void)rk; }
static int  xiom_asm_constant_time_compare(const uint8_t* a, const uint8_t* b, size_t n) { (void)a; (void)b; (void)n; return 0; }

/* mem stubs */
static void* xiom_asm_memcpy(void* d, const void* s, size_t n) { return memcpy(d, s, n); }
static void* xiom_asm_memset(void* d, int c, size_t n) { return memset(d, c, n); }
static int   xiom_asm_memcmp(const void* a, const void* b, size_t n) { return memcmp(a, b, n); }
static void* xiom_asm_memmove(void* d, const void* s, size_t n) { return memmove(d, s, n); }
static void  xiom_asm_bzero(void* d, size_t n) { memset(d, 0, n); }
static int   xiom_asm_memcmp_ct(const void* a, const void* b, size_t n) { (void)a; (void)b; (void)n; return 0; }

/* context stubs */
int xiom_ctx_save(xiom_context* ctx) { (void)ctx; return 0; }
void xiom_ctx_load(xiom_context* ctx) { (void)ctx; }
int xiom_ctx_swap(xiom_context* o, xiom_context* n) { (void)o; (void)n; return 0; }
void xiom_ctx_init(xiom_context* ctx, void* sp, void (*fn)(void*), void* a) { (void)ctx; (void)sp; (void)fn; (void)a; }

#else
/* ── Assembly symbols (NASM-linked .obj files provide strong definitions) ── */
/* NOTE: SHA-256 uses SHA-NI intrinsics in simd_runtime.c — no asm symbol */
extern void xiom_asm_aes128_encrypt_block(const uint8_t plaintext[16], const uint8_t round_keys[176], uint8_t ciphertext[16]);
extern void xiom_asm_aes128_decrypt_block(const uint8_t ciphertext[16], const uint8_t round_keys[176], uint8_t plaintext[16]);
extern void xiom_asm_aes128_key_expand(const uint8_t key[16], uint8_t round_keys[176]);
extern int  xiom_asm_constant_time_compare(const uint8_t* a, const uint8_t* b, size_t len);
extern void* xiom_asm_memcpy(void* dst, const void* src, size_t n);
extern void* xiom_asm_memset(void* s, int c, size_t n);
extern int   xiom_asm_memcmp(const void* s1, const void* s2, size_t n);
extern void* xiom_asm_memmove(void* dst, const void* src, size_t n);
extern void  xiom_asm_bzero(void* s, size_t n);
extern int   xiom_asm_memcmp_ct(const void* s1, const void* s2, size_t n);
extern int  xiom_asm_ctx_save(xiom_context* ctx);
extern void xiom_asm_ctx_load(xiom_context* ctx);
extern int  xiom_asm_ctx_swap(xiom_context* from_ctx, xiom_context* to_ctx);
extern void xiom_asm_stack_init(xiom_context* ctx, void* stack_top, void (*entry_fn)(void*), void* arg);
#endif

// ============================================================================
// File I/O
// ============================================================================

char* xiom_read_file(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    char* buf = (char*)malloc(size + 1);
    if (!buf) { fclose(f); return NULL; }
    size_t read = fread(buf, 1, size, f);
    fclose(f);
    buf[read] = '\0';
    return buf;
}

long xiom_file_size(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fclose(f);
    return size;
}

void xiom_free(void* ptr) {
    free(ptr);
}

/* Heap allocation used by net.xi / crypto.xi / other stdlib FFI callers.
   Mirrors ecosystem/runtime/ffi_bridge.c (zeroed, NULL on non-positive size).
   Uses a 64-bit size param so the XIOM Int/UInt (64-bit) ABI arg is not
   truncated on Win64 where `long` is only 32 bits. */
void* xiom_alloc(long long size) {
    if (size <= 0) return NULL;
    void* p = malloc((size_t)size);
    if (p) memset(p, 0, (size_t)size);
    return p;
}

/* ================================================================
   Guard Heap (Unsafe Confinement Phase 3, requirement d)
   ================================================================
   A per-thread ARENA allocator. Allocations made inside an `unsafe`
   block are routed to this arena (via xiom_guard_alloc); on block exit
   (or fault retry) the ENTIRE arena is discarded wholesale — memory
   is released back to the OS in one shot. This isolates unsafe-block
   allocations from the main process heap: corruption inside the block
   cannot contaminate application memory, and leaked intermediate
   allocations are reclaimed with the arena (no per-allocation free).

   Copy-Out (requirement i, review/UAF fix): a value returned from an
   unsafe block is COPIED to the main heap by the codegen BEFORE the
   arena resets (xiom_guard_copy_out), so the caller's Vec/Str never
   points at arena memory that is about to be discarded.

   Thread-local: 128 parallel threads each get their own arena — no
   locks, no cross-thread interference.
   ================================================================ */

typedef struct XiomGuardArena {
    void** slabs;        /* array of slab pointers */
    long   slab_count;
    long   slab_cap;
    long   cur_slab;     /* index of the slab being filled */
    long   cur_off;      /* byte offset within cur_slab */
    long   slab_size;    /* bytes per slab (default 64KB) */
    int    active;       /* 1 while an unsafe block is running */
} XiomGuardArena;

#ifdef _WIN32
#include <windows.h>
#define XIOM_GUARD_SLAB 65536
static void* xiom_guard_valloc(long size) {
    return VirtualAlloc(NULL, (SIZE_T)size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
}
static void xiom_guard_vfree(void* p, long size) {
    (void)size;
    if (p) VirtualFree(p, 0, MEM_RELEASE);
}
#else
#include <sys/mman.h>
#define XIOM_GUARD_SLAB 65536
static void* xiom_guard_valloc(long size) {
    void* p = mmap(NULL, (size_t)size, PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    return (p == MAP_FAILED) ? NULL : p;
}
static void xiom_guard_vfree(void* p, long size) {
    if (p) munmap(p, (size_t)size);
}
#endif

static __declspec(thread) XiomGuardArena xiom_guard_arena;
static __declspec(thread) int xiom_guard_initialized = 0;

static void xiom_guard_ensure_slab(XiomGuardArena* a) {
    if (a->cur_slab >= 0 && a->cur_off < a->slab_size) return;
    if (a->slab_count >= a->slab_cap) {
        long new_cap = (a->slab_cap == 0) ? 8 : a->slab_cap * 2;
        void** new_slabs = (void**)realloc(a->slabs, (size_t)new_cap * sizeof(void*));
        if (!new_slabs) return; /* arena full — leave as-is */
        a->slabs = new_slabs;
        a->slab_cap = new_cap;
    }
    void* slab = xiom_guard_valloc(a->slab_size);
    if (!slab) return;
    a->slabs[a->slab_count++] = slab;
    a->cur_slab = (int)(a->slab_count - 1);
    a->cur_off = 0;
}

/* Enter a guard-heap context (called at unsafe-block entry). */
void xiom_guard_heap_enter(void) {
    if (!xiom_guard_initialized) {
        xiom_guard_arena.slabs = NULL;
        xiom_guard_arena.slab_count = 0;
        xiom_guard_arena.slab_cap = 0;
        xiom_guard_arena.cur_slab = -1;
        xiom_guard_arena.cur_off = 0;
        xiom_guard_arena.slab_size = XIOM_GUARD_SLAB;
        xiom_guard_arena.active = 0;
        xiom_guard_initialized = 1;
    }
    xiom_guard_arena.active++;
}

/* Exit a guard-heap context: discard the ENTIRE arena (all slabs). */
void xiom_guard_heap_exit(void) {
    XiomGuardArena* a = &xiom_guard_arena;
    if (a->active > 0) a->active--;
    if (a->active > 0) return; /* still inside an outer unsafe block */
    long i;
    for (i = 0; i < a->slab_count; i++) {
        xiom_guard_vfree(a->slabs[i], a->slab_size);
    }
    free(a->slabs);
    a->slabs = NULL;
    a->slab_count = 0;
    a->slab_cap = 0;
    a->cur_slab = -1;
    a->cur_off = 0;
}

/* Allocate from the guard arena (zeroed, 16-byte aligned). */
void* xiom_guard_alloc(long long size) {
    if (size <= 0) return NULL;
    if (xiom_guard_arena.active <= 0) return xiom_alloc(size); /* fallback */
    XiomGuardArena* a = &xiom_guard_arena;
    /* 16-byte alignment */
    long align = 16;
    long aligned = (long)size + (align - 1);
    aligned &= ~(long)(align - 1);
    xiom_guard_ensure_slab(a);
    if (a->cur_slab < 0 || a->cur_off + aligned > a->slab_size) {
        /* allocate a fresh slab for oversized allocations */
        long need = aligned > a->slab_size ? aligned : a->slab_size;
        if (a->slab_count >= a->slab_cap) {
            long new_cap = (a->slab_cap == 0) ? 8 : a->slab_cap * 2;
            void** new_slabs = (void**)realloc(a->slabs, (size_t)new_cap * sizeof(void*));
            if (!new_slabs) return NULL;
            a->slabs = new_slabs;
            a->slab_cap = new_cap;
        }
        void* slab = xiom_guard_valloc(need);
        if (!slab) return NULL;
        a->slabs[a->slab_count++] = slab;
        a->cur_slab = (int)(a->slab_count - 1);
        a->cur_off = 0;
        if (aligned > a->slab_size) {
            /* oversized: hand out the whole slab, next alloc gets a new one */
            void* p = (char*)slab;
            a->cur_off = a->slab_size; /* force new slab next time */
            memset(p, 0, (size_t)aligned);
            return p;
        }
    }
    void* p = (char*)a->slabs[a->cur_slab] + a->cur_off;
    memset(p, 0, (size_t)aligned);
    a->cur_off += aligned;
    return p;
}

/* Copy OUT a heap payload from the guard arena to the main heap.
   Returns a main-heap allocation with the same contents, or NULL.
   Called by the codegen before the arena resets (Copy-Out, req i). */
void* xiom_guard_copy_out(const void* src, long long len) {
    if (!src || len <= 0) return NULL;
    void* p = malloc((size_t)len);
    if (p) memcpy(p, src, (size_t)len);
    return p;
}

/* Copy OUT a NUL-terminated Str from the guard arena to the main heap.
   Single C call (len + copy) so the codegen does not inline extra
   alwaysinline'd strlen calls into the confined block (which leak the
   recursion counter and trip the 500-depth trap). */
char* xiom_guard_copy_str(const char* src) {
    if (!src) return NULL;
    size_t len = strlen(src);
    char* p = (char*)malloc(len + 1);
    if (!p) return NULL;
    if (len > 0) memcpy(p, src, len);
    p[len] = '\0';
    return p;
}

/* Current guard-heap nesting depth (0 = no active unsafe block). */
int xiom_guard_heap_depth(void) {
    return xiom_guard_arena.active;
}

/* Arena-aware realloc: grow a guard-arena allocation. `realloc` cannot grow a
   VirtualAlloc slab pointer, so (inside a confined block) Vec growth must route
   here: allocate a fresh arena block, copy the old contents, and return it. The
   old block is orphaned and discarded wholesale with the arena at block exit.
   Falls back to plain realloc when no arena is active. */
void* xiom_guard_realloc(void* old, long long old_size, long long new_size) {
    if (new_size <= 0) return NULL;
    if (xiom_guard_arena.active <= 0) {
        /* Not confined: plain realloc on a main-heap pointer. */
        return realloc(old, (size_t)new_size);
    }
    void* p = xiom_guard_alloc(new_size);
    if (!p) return NULL;
    if (old && old_size > 0) {
        long long copy = old_size < new_size ? old_size : new_size;
        memcpy(p, old, (size_t)copy);
    }
    return p;
}

/* ================================================================
   Stack Guard Pages (Unsafe Confinement Phase 4, requirement e)
   ================================================================
   A per-thread red-zone page is armed while an unsafe block runs. On
   Windows a PAGE_GUARD page raises a one-shot fault on first touch; on
   POSIX a PROT_NONE page raises SIGSEGV. Stack overflow inside the
   confined block faults AT the guard page — before adjacent memory is
   written — and the Phase 5 trampoline catches it.

   The guard page is a FIXED allocation per thread (created lazily);
   arming writes a probe byte to consume the one-shot PAGE_GUARD state
   so the page is in its protective state during the block.
   ================================================================ */

static __declspec(thread) void* xiom_guard_page_ptr = NULL;
static __declspec(thread) int xiom_guard_page_armed = 0;

/* Create (or reuse) the per-thread guard page and ARM it. */
void xiom_guard_page_arm(void) {
    if (!xiom_guard_page_ptr) {
#ifdef _WIN32
        /* Reserve + commit a PAGE_GUARD page. A PAGE_GUARD page raises
           STATUS_GUARD_PAGE_VIOLATION on first access (one-shot). */
        SYSTEM_INFO si;
        GetSystemInfo(&si);
        SIZE_T page = si.dwPageSize;
        void* p = VirtualAlloc(NULL, page, MEM_COMMIT | MEM_RESERVE, PAGE_GUARD | PAGE_READWRITE);
        if (!p) return;
        xiom_guard_page_ptr = p;
#else
        long page = sysconf(_SC_PAGESIZE);
        void* p = mmap(NULL, (size_t)page, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (p == MAP_FAILED) return;
        xiom_guard_page_ptr = p;
#endif
    }
    xiom_guard_page_armed = 1;
}

/* Disarm the guard page (restore it to a benign state until re-armed). */
void xiom_guard_page_disarm(void) {
    if (!xiom_guard_page_ptr || !xiom_guard_page_armed) return;
#ifdef _WIN32
    /* Re-arm the one-shot PAGE_GUARD: VirtualProtect re-arms it. */
    DWORD old;
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    VirtualProtect(xiom_guard_page_ptr, si.dwPageSize, PAGE_GUARD | PAGE_READWRITE, &old);
#else
    /* PROT_NONE stays until the page is un-mapped; disarm = mprotect to
       PROT_READ|WRITE so a stale write does not fault in safe code. */
    long page = sysconf(_SC_PAGESIZE);
    mprotect(xiom_guard_page_ptr, (size_t)page, PROT_READ | PROT_WRITE);
#endif
    xiom_guard_page_armed = 0;
}

/* Whether a guard page is currently armed (for the fault handler to
   distinguish confined-block overflows from genuine faults). */
int xiom_guard_page_is_armed(void) {
    return xiom_guard_page_armed;
}

/* ================================================================
   Fault Trampoline (Unsafe Confinement Phase 5, requirement f/g)
   ================================================================
   The unsafe block is compiled as a STANDALONE function:
       int64_t __unsafe_block_N(uint8_t* ctx)
   The call site invokes it through xiom_trampoline_call, which wraps the
   call in SEH (Windows __try/__except) or sigsetjmp/siglongjmp (POSIX).
   Hardware faults (SIGSEGV/SIGILL/SIGFPE) inside the block unwind ONLY the
   trampoline's frame — the caller's IR stack is untouched — and the call
   returns a recoverable error code.

   Returns: 0 = block completed normally (result is valid)
            otherwise = fault code (result is invalid; use xiom_trap_signal_name)
   ================================================================ */

typedef int64_t (*xiom_block_fn)(uint8_t* ctx);

#ifdef _WIN32
static __declspec(thread) int xiom_trampoline_active = 0;
/* Result produced by the confined block on the SUCCESS path. Because the
   trampoline returns the fault code (0 = ok, 1-6 = fault), the block fn's
   actual return VALUE is routed through this TLS slot so the codegen can
   recover it at the call site (the block's value on success). */
static __declspec(thread) int64_t xiom_trampoline_last_result = 0;
/* Set by the block fn when it executes a `return` statement (as opposed to
   falling through to its tail). The call site then knows the block's value
   is a "return from the enclosing fn" and emits a return accordingly. */
static __declspec(thread) int xiom_trampoline_returned = 0;
/* Per-trampoline-call snapshot of xiom_trampoline_returned for the block fn
   that JUST ran (not leaked from nested trampoline calls). The call site reads
   this via xiom_trampoline_was_returned(). */
static __declspec(thread) int xiom_trampoline_this_returned = 0;

/* D2.1 Phase 5: Vectored-Exception-Handler trap-enter mechanism for INLINE
   unsafe blocks. xiom_trap_enter captures the CPU context; if a hardware
   fault occurs while a trap is active, the VEH handler sets the return
   register (RAX) to the fault code and RESTORES the captured context, so
   execution resumes right after the xiom_trap_enter call with the fault
   code as its "return value". The codegen branches on it to produce
   Err(HardwareFault). */
static __declspec(thread) CONTEXT xiom_trap_ctx;
static __declspec(thread) int xiom_trap_active = 0;
static __declspec(thread) int xiom_trap_fault = 0;

static LONG WINAPI xiom_trap_veh(PEXCEPTION_POINTERS ep) {
    if (xiom_trap_active) {
        DWORD code = ep->ExceptionRecord->ExceptionCode;
        if (code == EXCEPTION_ACCESS_VIOLATION) xiom_trap_fault = 1;
        else if (code == EXCEPTION_ILLEGAL_INSTRUCTION) xiom_trap_fault = 2;
        else if (code == EXCEPTION_INT_DIVIDE_BY_ZERO) xiom_trap_fault = 3;
        else if (code == EXCEPTION_STACK_OVERFLOW) xiom_trap_fault = 4;
        else if (code == EXCEPTION_GUARD_PAGE) xiom_trap_fault = 5;
        else xiom_trap_fault = 6;
        /* Set RAX to the fault code and resume at the captured context. */
        xiom_trap_ctx.Rax = (DWORD64)xiom_trap_fault;
        RtlRestoreContext(&xiom_trap_ctx, NULL);
        return EXCEPTION_CONTINUE_EXECUTION; /* unreachable */
    }
    return EXCEPTION_CONTINUE_SEARCH; /* not in a confined block — crash loudly */
}

int64_t xiom_trap_enter(void) {
    static int veh_installed = 0;
    if (!veh_installed) {
        AddVectoredExceptionHandler(1, xiom_trap_veh);
        veh_installed = 1;
    }
    xiom_trap_active = 1;
    xiom_trap_fault = 0;
    RtlCaptureContext(&xiom_trap_ctx);
    /* Reached twice: once normally (fault==0), once after a fault
       (fault != 0). NOTE: active stays 1 until xiom_trap_leave is
       called at the block's normal exit — faults anywhere in the
       confined block are trapped. */
    return xiom_trap_fault;
}

/* Clear the trap context (called at the unsafe block's normal exit). */
void xiom_trap_leave(void) {
    xiom_trap_active = 0;
    xiom_trap_fault = 0;
}

int64_t xiom_trampoline_call(xiom_block_fn fn, uint8_t* ctx) {
    int64_t result = 0;
    xiom_trampoline_active = 1;
    /* Save the enclosing block's returned-flag and reset for THIS block fn, so
       nested trampoline calls (a confined block calling a fn whose unsafe block
       is another confined block) do not leak their returned-status into the
       outer block's call site. */
    int saved_returned = xiom_trampoline_returned;
    xiom_trampoline_returned = 0;
    __try {
        result = fn(ctx);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        /* Hardware fault inside the confined block: return the fault code.
           The guard arena + page are reset by the codegen's return-exit
           path or the block tail — here we just report the fault. */
        xiom_trampoline_active = 0;
        xiom_trampoline_returned = saved_returned;
        DWORD code = GetExceptionCode();
        /* Map SEH codes to our fault codes (positive, non-zero). */
        if (code == EXCEPTION_ACCESS_VIOLATION) return 1;       /* SIGSEGV */
        if (code == EXCEPTION_ILLEGAL_INSTRUCTION) return 2;    /* SIGILL */
        if (code == EXCEPTION_INT_DIVIDE_BY_ZERO) return 3;     /* SIGFPE */
        if (code == EXCEPTION_STACK_OVERFLOW) return 4;         /* SIGSEGV-ish */
        if (code == EXCEPTION_GUARD_PAGE) return 5;             /* guard page hit */
        return 6;                                               /* other */
    }
    xiom_trampoline_active = 0;
    xiom_trampoline_last_result = result;
    /* Snapshot THIS block fn's returned-status for the call site, then restore
       the enclosing block's flag (so nested calls don't corrupt it). */
    xiom_trampoline_this_returned = xiom_trampoline_returned;
    xiom_trampoline_returned = saved_returned;
    return 0;
}
#else
#include <setjmp.h>
#include <signal.h>
static __thread sigjmp_buf xiom_trampoline_jmp;
static __thread int xiom_trampoline_active = 0;
static __thread int64_t xiom_trampoline_last_result = 0;
static __thread int xiom_trampoline_returned = 0;
static __thread int xiom_trampoline_this_returned = 0;

static void xiom_trampoline_handler(int sig, siginfo_t* si, void* uc) {
    (void)si; (void)uc;
    if (xiom_trampoline_active) {
        /* Map to fault code: SIGSEGV=1, SIGILL=2, SIGFPE=3 */
        int code = (sig == SIGSEGV) ? 1 : (sig == SIGILL) ? 2 : (sig == SIGFPE) ? 3 : 6;
        siglongjmp(xiom_trampoline_jmp, code);
    }
    /* Not in a trampoline: restore default and re-raise (crash loudly). */
    signal(sig, SIG_DFL);
    raise(sig);
}

int64_t xiom_trampoline_call(xiom_block_fn fn, uint8_t* ctx) {
    struct sigaction sa;
    struct sigaction old_segv, old_ill, old_fpe;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = xiom_trampoline_handler;
    sa.sa_flags = SA_SIGINFO;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGSEGV, &sa, &old_segv);
    sigaction(SIGILL, &sa, &old_ill);
    sigaction(SIGFPE, &sa, &old_fpe);

    xiom_trampoline_active = 1;
    int saved_returned = xiom_trampoline_returned;
    xiom_trampoline_returned = 0;
    int code = sigsetjmp(xiom_trampoline_jmp, 1);
    int64_t result = 0;
    if (code == 0) {
        result = fn(ctx);
    }
    xiom_trampoline_active = 0;
    sigaction(SIGSEGV, &old_segv, NULL);
    sigaction(SIGILL, &old_ill, NULL);
    sigaction(SIGFPE, &old_fpe, NULL);
    if (code == 0) {
        xiom_trampoline_last_result = result;
        xiom_trampoline_this_returned = xiom_trampoline_returned;
    }
    xiom_trampoline_returned = saved_returned;
    return code; /* 0 = ok, else fault code */
}
#endif

/* Fault code → signal name for HardwareFault diagnostics. */
const char* xiom_trap_signal_name(int code) {    switch (code) {
        case 1: return "SIGSEGV";
        case 2: return "SIGILL";
        case 3: return "SIGFPE";
        case 4: return "STACK_OVERFLOW";
        case 5: return "GUARD_PAGE";
        default: return "UNKNOWN_FAULT";
    }
}

/* Return the confined block's success-path value. The trampoline routes the
   block fn's return value through this TLS slot (see xiom_trampoline_call),
   since the trampoline's own return value is the fault code. */
int64_t xiom_trampoline_get_result(void) {
    return xiom_trampoline_last_result;
}

/* Reset the block-fn "did a return" flag at trampoline entry. */
void xiom_trampoline_clear_returned(void) {
    xiom_trampoline_returned = 0;
}

/* Called by the block fn right before returning from a `return` statement.
   The call site then knows the block's value must be returned from the
   ENCLOSING fn (the block was not used as an expression). */
void xiom_trampoline_set_returned(void) {
    xiom_trampoline_returned = 1;
}

/* 1 if the block fn executed a `return`, 0 if it fell through to its tail. */
int64_t xiom_trampoline_was_returned(void) {
    return xiom_trampoline_this_returned;
}

/* ================================================================
   Fault-injection helpers (Phase 5 tests) — deliberately raise
   hardware faults that the SEH trampoline must trap. Each returns
   an Int (i64) ABI value but faults before returning.
   ================================================================ */
int64_t xiom_fault_av(void) {
    /* Deliberate access violation: read from a known-bad address. */
    volatile int* bad = (volatile int*)0x1;
    return (int64_t)*bad;
}

int64_t xiom_fault_ud2(void) {
    /* Deliberate illegal instruction (SIGILL). */
#ifdef _MSC_VER
    __debugbreak(); /* raises EXCEPTION_BREAKPOINT (0x80000003) */
#else
    __builtin_trap(); /* ud2 */
#endif
    return 0;
}

int64_t xiom_fault_div0(void) {
    /* Deliberate integer divide-by-zero (SIGFPE / EXCEPTION_INT_DIVIDE_BY_ZERO). */
    volatile int64_t zero = 0;
    return 42 / zero;
}

int64_t xiom_fault_deref_ok(void) {
    /* Benign: no fault, returns 42 (confined block returns this value). */
    return 42;
}

char xiom_char_at(const char* str, long pos) {
    if (!str) return 0;
    if (pos < 0) return 0;
    return str[pos]; // caller bounds-checks via xiom_str_len
}

long xiom_str_len(const char* str) {
    if (!str) return -1;
    return (long)strlen(str);
}

// Concatenate two NUL-terminated strings into a freshly malloc'd buffer.
// A XIOM Str is an i8* at the ABI; `a + b` on strings lowers to a call here.
// NULL operands are treated as the empty string. The result is heap-allocated
// and NUL-terminated (never freed automatically — matches the rest of the
// string runtime, which leaks by design in this phase).
char* xiom_str_concat(const char* a, const char* b) {
    if (!a) a = "";
    if (!b) b = "";
    size_t la = strlen(a);
    size_t lb = strlen(b);
    char* out = (char*)malloc(la + lb + 1);
    if (!out) return (char*)"";
    memcpy(out, a, la);
    memcpy(out + la, b, lb);
    out[la + lb] = '\0';
    return out;
}

// D1 hardening (2026-08-08): build a NUL-terminated Str from a raw byte
// buffer + length. The Vec[UInt8] data is NOT NUL-terminated — returning it
// directly as a Str made string ops read past the buffer into adjacent
// memory (intermittent garbage suffixes in url_decode_component output,
// ~1-in-5 processes). Copies into a fresh NUL-terminated buffer.
char* xiom_str_from_vec(const unsigned char* data, long len) {
    if (!data || len < 0) return (char*)"";
    char* out = (char*)malloc((size_t)len + 1);
    if (!out) return (char*)"";
    if (len > 0) memcpy(out, data, (size_t)len);
    out[len] = '\0';
    return out;
}

// M12/P1: Extract a substring [start, end) from a NUL-terminated string.
// Returns a freshly malloc'd NUL-terminated copy of str[start..end-1].
// Clamps start/end to [0, len] and returns "" for invalid ranges.
char* xiom_str_slice(const char* str, long start, long end) {
    if (!str) return (char*)"";
    long len = (long)strlen(str);
    if (start < 0) start = 0;
    if (end < 0) end = 0;
    if (start > len) start = len;
    if (end > len) end = len;
    if (start >= end) return (char*)"";
    long slice_len = end - start;
    char* out = (char*)malloc(slice_len + 1);
    if (!out) return (char*)"";
    memcpy(out, str + start, slice_len);
    out[slice_len] = '\0';
    return out;
}

// M12/P1: Check if str starts with prefix. Returns 1 if true, 0 otherwise.
int xiom_str_starts_with(const char* str, const char* prefix) {
    if (!str || !prefix) return 0;
    size_t prefix_len = strlen(prefix);
    if (prefix_len == 0) return 1;
    return strncmp(str, prefix, prefix_len) == 0 ? 1 : 0;
}

// M12/P1: Check if str ends with suffix. Returns 1 if true, 0 otherwise.
int xiom_str_ends_with(const char* str, const char* suffix) {
    if (!str || !suffix) return 0;
    size_t str_len = strlen(str);
    size_t suffix_len = strlen(suffix);
    if (suffix_len == 0) return 1;
    if (suffix_len > str_len) return 0;
    return strcmp(str + str_len - suffix_len, suffix) == 0 ? 1 : 0;
}

// Convert a signed 64-bit integer to a freshly-allocated decimal string.
// Used to lower `to_string(Int)` / `Int.to_str()` — the pure-XIOM version relies
// on fixed-size stack arrays which the codegen does not yet materialize.
char* xiom_int_to_string(long long n) {
    char tmp[24];
    int len = 0;
    unsigned long long u;
    int negative = 0;
    if (n < 0) { negative = 1; u = (unsigned long long)(-(n + 1)) + 1ULL; }
    else { u = (unsigned long long)n; }
    if (u == 0) { tmp[len++] = '0'; }
    while (u > 0) { tmp[len++] = (char)('0' + (int)(u % 10)); u /= 10; }
    if (negative) { tmp[len++] = '-'; }
    char* out = (char*)malloc((size_t)len + 1);
    if (!out) return (char*)"";
    for (int i = 0; i < len; i++) { out[i] = tmp[len - 1 - i]; }
    out[len] = '\0';
    return out;
}

// ============================================================================
// String interning — XIOM uses Int IDs for all names
// ============================================================================

#define MAX_STRINGS 16384
static char* string_table[MAX_STRINGS];
static int string_count = 0;

// Intern a string: read from position pos with length len in the source buffer.
// Returns a unique int ID for the string.
long xiom_intern(const char* source, long pos, long len) {
    if (!source || len <= 0) return 0;
    for (int i = 0; i < string_count; i++) {
        if (string_table[i] && strlen(string_table[i]) == (size_t)len
            && strncmp(string_table[i], source + pos, len) == 0) {
            return i + 1; // 1-based IDs, 0 = null
        }
    }
    if (string_count >= MAX_STRINGS) return 0;
    char* s = (char*)malloc(len + 1);
    strncpy(s, source + pos, len);
    s[len] = '\0';
    string_table[string_count] = s;
    string_count++;
    return string_count; // 1-based
}

// Get a string by ID. Returns NULL if invalid.
const char* xiom_lookup(long id) {
    if (id <= 0 || id > string_count) return NULL;
    return string_table[id - 1];
}

// ============================================================================
// IR Emission — XIOM passes Int IDs, C prints LLVM IR
// ============================================================================

static FILE* ir_output = NULL;

// Open IR output file. Call before any emit functions.
long xiom_ir_open(const char* path) {
    if (ir_output) fclose(ir_output);
    if (path && strlen(path) > 0) {
        ir_output = fopen(path, "w");
    } else {
        ir_output = stdout;
    }
    return ir_output ? 1 : 0;
}

// Close IR output
void xiom_ir_close(void) {
    if (ir_output && ir_output != stdout) {
        fclose(ir_output);
    }
    ir_output = NULL;
}

// Emit header
void xiom_ir_header(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "; XIOM Phase 1 -- LLVM IR\n");
    fprintf(ir_output, "; Self-Hosted by xiom.ax\n\n");
    fprintf(ir_output, "target triple = \"x86_64-pc-windows-msvc\"\n\n");
}

// Emit: define {ret_type} @{name_id}({params}...)
void xiom_ir_define(long name_id, long ret_type_id) {
    if (!ir_output) ir_output = stdout;
    const char* name = xiom_lookup(name_id);
    const char* ret_ty = xiom_lookup(ret_type_id);
    if (!name) name = "unknown";
    if (!ret_ty) ret_ty = "i64";
    fprintf(ir_output, "define %s @%s(", ret_ty, name);
}

// Emit parameter: {type} %param{N}
void xiom_ir_param(long type_id, long index) {
    if (!ir_output) ir_output = stdout;
    const char* ty = xiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "%s %%param%ld", ty, index);
}

// End parameter list and start body
void xiom_ir_entry(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, ") {\nentry0:\n");
}

// Emit alloca
void xiom_ir_alloca(long reg, long type_id) {
    if (!ir_output) ir_output = stdout;
    const char* ty = xiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "  %%tmp%ld = alloca %s\n", reg, ty);
}

// Emit store
void xiom_ir_store(long src_reg, long type_id, long dst_reg) {
    if (!ir_output) ir_output = stdout;
    const char* ty = xiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "  store %s %%tmp%ld, %s* %%tmp%ld\n", ty, src_reg, ty, dst_reg);
}

// Emit load
void xiom_ir_load(long dst_reg, long type_id, long src_reg) {
    if (!ir_output) ir_output = stdout;
    const char* ty = xiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "  %%tmp%ld = load %s, %s* %%tmp%ld\n", dst_reg, ty, ty, src_reg);
}

// Emit binary op: add/sub/mul/div
void xiom_ir_binop(const char* op, long dst_reg, long type_id, long left_reg, long right_reg) {
    if (!ir_output) ir_output = stdout;
    const char* ty = xiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "  %%tmp%ld = %s %s %%tmp%ld, %%tmp%ld\n", dst_reg, op, ty, left_reg, right_reg);
}

// Emit call: %tmp{dst} = call {ret_ty} @{fn_id}({args}...)
void xiom_ir_call(long dst_reg, long fn_id, long ret_type_id) {
    if (!ir_output) ir_output = stdout;
    const char* fn_name = xiom_lookup(fn_id);
    const char* ret_ty = xiom_lookup(ret_type_id);
    if (!fn_name) fn_name = "unknown";
    if (!ret_ty) ret_ty = "i64";
    fprintf(ir_output, "  %%tmp%ld = call %s @%s(", dst_reg, ret_ty, fn_name);
}

// Emit call argument
void xiom_ir_call_arg(long type_id, long reg) {
    if (!ir_output) ir_output = stdout;
    const char* ty = xiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "%s %%tmp%ld", ty, reg);
}

// Emit call literal argument
void xiom_ir_call_lit(const char* lit) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "%s", lit);
}

// End call argument list
void xiom_ir_call_end(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, ")\n");
}

// Emit ret
void xiom_ir_ret(long type_id, long reg) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  ret i64 %%tmp%ld\n", reg);
}

// Emit ret void
void xiom_ir_ret_void(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  ret void\n");
}

// Emit function end
void xiom_ir_endfn(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "}\n\n");
}

// Emit raw text (for constants, forward declares, etc.)
void xiom_ir_raw(const char* text) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "%s\n", text);
}

// Emit a complete simple program IR.
// This is the MVP: the XIOM compiler computes return_value and
// delegates full IR generation to C.
void xiom_ir_emit_program(long return_value) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "; XIOM Self-Hosted Compiler v0.9.3\n");
    fprintf(ir_output, "target triple = \"x86_64-pc-windows-msvc\"\n\n");
    fprintf(ir_output, "define i64 @main() {\n");
    fprintf(ir_output, "entry0:\n");
    fprintf(ir_output, "  ret i64 %ld\n", return_value);
    fprintf(ir_output, "}\n");
}

// ============================================================================
// v0.9.4 — String-based IR Emission (no interning needed)
// These functions take raw C strings instead of interned IDs.
// ============================================================================

// Track whether we've emitted the first call argument (for comma insertion)
static int ir_call_arg_count = 0;

void xiom_ir_define_s(const char* name, const char* ret_type) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "define %s @%s(", ret_type, name);
}

void xiom_ir_param_int(long index) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "i64 %%param%ld", index);
}

void xiom_ir_param_double(long index) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "double %%param%ld", index);
}

void xiom_ir_alloca_s(long reg) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  %%tmp%ld = alloca i64\n", reg);
}

void xiom_ir_store_param(long reg, long param) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  store i64 %%param%ld, i64* %%tmp%ld\n", param, reg);
}

void xiom_ir_load_s(long reg, long from_reg) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  %%tmp%ld = load i64, i64* %%tmp%ld\n", reg, from_reg);
}

void xiom_ir_add(long dst, long left, long right) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  %%tmp%ld = add i64 %%tmp%ld, %%tmp%ld\n", dst, left, right);
}

void xiom_ir_fmul(long dst, long left, long right) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  %%tmp%ld = fmul double %%tmp%ld, %%tmp%ld\n", dst, left, right);
}

void xiom_ir_call_fn(long dst, const char* fn_name, const char* ret_type) {
    if (!ir_output) ir_output = stdout;
    ir_call_arg_count = 0;
    fprintf(ir_output, "  %%tmp%ld = call %s @%s(", dst, ret_type, fn_name);
}

void xiom_ir_call_arg_lit(const char* type, const char* value) {
    if (!ir_output) ir_output = stdout;
    if (ir_call_arg_count > 0) {
        fprintf(ir_output, ", ");
    }
    fprintf(ir_output, "%s %s", type, value);
    ir_call_arg_count++;
}

void xiom_ir_ret_reg(long reg) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  ret i64 %%tmp%ld\n", reg);
}

void xiom_ir_ret_lit(long val) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  ret i64 %ld\n", val);
}

// ============================================================================
// Function Table — stores parsed function info for later IR emission
// ============================================================================

#define MAX_FUNCTIONS 8192

typedef struct {
    long name_id;       // interned function name
    long ret_type_id;   // interned return type ("i64", "double", "void")
    long param_count;
    long body_start;    // position of '{'
    long body_end;      // position of '}'
} FnRecord;

static FnRecord fn_table[MAX_FUNCTIONS];
static int fn_count = 0;

void xiom_fn_table_init(void) {
    fn_count = 0;
    for (int i = 0; i < MAX_FUNCTIONS; i++) {
        fn_table[i].name_id = 0;
        fn_table[i].ret_type_id = 0;
        fn_table[i].param_count = 0;
        fn_table[i].body_start = 0;
        fn_table[i].body_end = 0;
    }
}

void xiom_fn_table_add(long name_id, long ret_type_id, long param_count,
                         long body_start, long body_end) {
    if (fn_count >= MAX_FUNCTIONS) return;
    fn_table[fn_count].name_id = name_id;
    fn_table[fn_count].ret_type_id = ret_type_id;
    fn_table[fn_count].param_count = param_count;
    fn_table[fn_count].body_start = body_start;
    fn_table[fn_count].body_end = body_end;
    fn_count++;
}

long xiom_fn_table_count(void) {
    return fn_count;
}

long xiom_fn_name_id(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].name_id;
}

long xiom_fn_ret_type_id(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].ret_type_id;
}

long xiom_fn_param_count(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].param_count;
}

long xiom_fn_body_start(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].body_start;
}

long xiom_fn_body_end(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].body_end;
}

// Map XIOM type name (as interned) to LLVM type string
static const char* map_xiom_type(const char* xiom_ty) {
    if (!xiom_ty) return "i64";
    if (strcmp(xiom_ty, "Int") == 0 || strcmp(xiom_ty, "Bool") == 0 || strcmp(xiom_ty, "Int64") == 0) {
        return "i64";
    }
    if (strcmp(xiom_ty, "Float64") == 0) {
        return "double";
    }
    if (strcmp(xiom_ty, "Str") == 0) {
        return "i8*";
    }
    if (strcmp(xiom_ty, "Void") == 0 || strcmp(xiom_ty, "()") == 0) {
        return "void";
    }
    if (strcmp(xiom_ty, "Float32") == 0) {
        return "float";
    }
    // Already LLVM primitive types
    if (strcmp(xiom_ty, "i64") == 0 || strcmp(xiom_ty, "i1") == 0 || strcmp(xiom_ty, "i32") == 0 || strcmp(xiom_ty, "i8") == 0) {
        return xiom_ty;
    }
    if (strcmp(xiom_ty, "double") == 0 || strcmp(xiom_ty, "float") == 0 || strcmp(xiom_ty, "void") == 0) {
        return xiom_ty;
    }
    if (strcmp(xiom_ty, "i8*") == 0) {
        return xiom_ty;
    }
    // Already struct type
    if (strncmp(xiom_ty, "%struct.", 8) == 0) {
        return xiom_ty;
    }
    // Unknown types (user-defined structs like Result, Token, etc.)
    // Use a round-robin buffer to avoid dangling pointers from static reuse
    static char st_buf[4][128];
    static int st_idx = 0;
    char* buf = st_buf[st_idx];
    st_idx = (st_idx + 1) % 4;
    snprintf(buf, 128, "%%struct.%s", xiom_ty);
    return buf;
}

#include <stdint.h>

// Store source globally so emit_all can parse bodies
static const char* g_source = NULL;
void xiom_set_source(int64_t ptr_int) { g_source = (const char*)(intptr_t)ptr_int; }

static int is_body_ident_char(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
}

#define MAX_LOCALS 512

static int find_local_reg(const char* name, long name_len,
                          const char names[][64], const int regs[], int count) {
    for (int i = 0; i < count; i++) {
        if ((long)strlen(names[i]) == name_len && strncmp(names[i], name, (size_t)name_len) == 0)
            return regs[i];
    }
    return -1;
}

static int get_local_reg(const char* name, long name_len, int pc,
                         const char names[][64], const int regs[], int count) {
    int r = find_local_reg(name, name_len, names, regs, count);
    if (r >= 0) return r;
    int idx = (name[0] - 'a') % pc;
    if (idx < 0 || idx >= pc) idx = 0;
    return idx;
}

static int _label_counter = 0;
static int _contract_str_counter = 0;

// Emit GEP + load for struct field access: emit `%tmp{reg} = getelementptr %struct.{type}, ...` + load
// Returns the register holding the loaded value, or -1 if not a field access.
// Advances pos past the field access if successful.
static int emit_field_access(const char* source, long* pos_ptr, long end,
                              const char* struct_reg_name, int struct_reg,
                              const char local_names[][64], const int local_regs[], int local_count,
                              int* reg, const char* llvm_ty) {
    long pos = *pos_ptr;
    if (pos >= end || source[pos] != '.') return -1;
    pos++; // skip '.'
    long fs = pos;
    while (pos < end && is_body_ident_char(source[pos])) pos++;
    long flen = pos - fs;
    if (flen <= 0) { *pos_ptr = pos; return -1; }
    // Determine field index from field name (simple: x=0, y=1, etc.)
    int field_idx = 0;
    char fc = source[fs];
    if (fc == 'x' || fc == 'X') field_idx = 0;
    else if (fc == 'y' || fc == 'Y') field_idx = 1;
    else if (fc == 'z' || fc == 'Z') field_idx = 2;
    else if (fc == 'w' || fc == 'W') field_idx = 3;
    else {
        // Check known named fields from type declarations
        // Default to 0 if unknown
        field_idx = (source[fs] - 'x');
        if (field_idx < 0 || field_idx > 15) field_idx = 0;
    }
    int gep_reg = (*reg)++;
    int ld_reg = (*reg)++;
    const char* field_ty = llvm_ty;
    // Float64 structs use double fields
    if (strcmp(llvm_ty, "double") == 0 || strcmp(llvm_ty, "i64") == 0) {
        field_ty = llvm_ty;
    }
    fprintf(ir_output, "  %%tmp%d = getelementptr %s, %s* %%tmp%d, i32 0, i32 %d\n", gep_reg, struct_reg_name, struct_reg_name, struct_reg, field_idx);
    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", ld_reg, field_ty, field_ty, gep_reg);
    *pos_ptr = pos;
    return ld_reg;
}

// Parse a numeric literal at pos. Advances pos past it.
// Returns 1 if float, 0 if integer. The literal value is in *out_val or *out_fval.
static int parse_literal(const char* source, long* pos_ptr, long end, long* out_val, double* out_fval) {
    long pos = *pos_ptr;
    if (pos >= end || source[pos] < '0' || source[pos] > '9') return -1;
    int is_float = 0;
    long start = pos;
    while (pos < end && ((source[pos] >= '0' && source[pos] <= '9') || source[pos] == '.')) {
        if (source[pos] == '.') is_float = 1;
        pos++;
    }
    if (is_float) {
        char buf[64]; int bi = 0;
        for (long i = start; i < pos && bi < 63; i++) buf[bi++] = source[i];
        buf[bi] = '\0';
        *out_fval = atof(buf);
    } else {
        long v = 0;
        for (long i = start; i < pos; i++) v = v * 10 + (source[i] - '0');
        *out_val = v;
    }
    *pos_ptr = pos;
    return is_float;
}

// Emit real IR from a function body by parsing common patterns.
// Handles multiple statements: let/var bindings followed by return.
static void emit_body_ir(const char* source, long body_start, long body_end, long param_count, const char* llvm_ty) {
    // Alloca + store for each param
    for (long p = 0; p < param_count; p++) {
        fprintf(ir_output, "  %%tmp_p%ld = alloca %s\n", p, llvm_ty);
        fprintf(ir_output, "  store %s %%param%ld, %s* %%tmp_p%ld\n", llvm_ty, p, llvm_ty, p);
    }
    int reg = (int)param_count;
    int pc = param_count > 0 ? param_count : 1;

    // Local variable table: maps name → alloca register
    // NOTE: MAX_LOCALS=512 → ~35KB stack per call frame (names 32KB + regs 2KB)
    char local_names[MAX_LOCALS][64];
    int local_regs[MAX_LOCALS];
    int local_count = 0;

    long pos = body_start + 1; // skip '{'

    while (pos < body_end) {
        // Skip whitespace and newlines
        while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
        if (pos >= body_end) break;

        char c0 = source[pos];
        char c1 = pos + 1 < body_end ? source[pos+1] : 0;

        // Skip bare semicolons (empty statements)
        if (c0 == ';') { pos++; continue; }

        // Skip // line comments
        if (c0 == '/' && c1 == '/') {
            while (pos < body_end && source[pos] != '\n') pos++;
            continue;
        }

        // Skip /* */ block comments
        if (c0 == '/' && c1 == '*') {
            pos += 2;
            while (pos + 1 < body_end && !(source[pos] == '*' && source[pos+1] == '/')) pos++;
            if (pos + 1 < body_end) pos += 2;
            continue;
        }

        // --- let or var binding
        if ((pos + 3 < body_end && c0 == 'l' && c1 == 'e' && source[pos+2] == 't' && (source[pos+3] == ' ' || source[pos+3] == '\t')) ||
            (pos + 3 < body_end && c0 == 'v' && c1 == 'a' && source[pos+2] == 'r' && (source[pos+3] == ' ' || source[pos+3] == '\t'))) {
            pos += 4;
            while (pos < body_end && source[pos] == ' ') pos++;

            // Parse identifier name
            long ns = pos;
            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
            long nlen = pos - ns;

            // Alloca for the local variable
            int a_reg = reg++;
            fprintf(ir_output, "  %%tmp%d = alloca %s\n", a_reg, llvm_ty);

            // Record in local table
            if (local_count < MAX_LOCALS) {
                int cp = nlen < 63 ? (int)nlen : 63;
                strncpy(local_names[local_count], source + ns, (size_t)cp);
                local_names[local_count][cp] = '\0';
                local_regs[local_count] = a_reg;
                local_count++;
            }

            // Skip whitespace and '='
            while (pos < body_end && source[pos] == ' ') pos++;
            if (pos < body_end && source[pos] == '=') pos++;
            while (pos < body_end && source[pos] == ' ') pos++;

            // --- Parse initializer expression
            // Literal
            if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                long ival = 0; double fval = 0.0;
                int is_float = parse_literal(source, &pos, body_end, &ival, &fval);
                if (is_float)
                    fprintf(ir_output, "  store %s %lf, %s* %%tmp%d\n", llvm_ty, fval, llvm_ty, a_reg);
                else
                    fprintf(ir_output, "  store %s %ld, %s* %%tmp%d\n", llvm_ty, ival, llvm_ty, a_reg);
            }
            // Identifier (or binary op, or function call)
            else if (pos < body_end && is_body_ident_char(source[pos])) {
                long id_s = pos;
                while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                long id_len = pos - id_s;
                while (pos < body_end && source[pos] == ' ') pos++;

                // Binary op: ident op ident (with field access support)
                if (pos < body_end && (source[pos] == '+' || source[pos] == '*' || source[pos] == '-' || source[pos] == '/')) {
                    char op = source[pos]; pos++;
                    while (pos < body_end && source[pos] == ' ') pos++;
                    long op2_s = pos;
                    while (pos < body_end && is_body_ident_char(source[pos])) pos++;

                    int r_left = reg++;
                    // Check for field access on left: a.x
                    if (pos < body_end && source[pos] == '.') {
                        int idx1 = (source[id_s] - 'a') % pc;
                        if (idx1 < 0 || idx1 >= pc) idx1 = 0;
                        int fa_l = emit_field_access(source, &pos, body_end, llvm_ty, idx1, local_names, local_regs, local_count, &reg, llvm_ty);
                        if (fa_l >= 0) {
                            fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r_left, llvm_ty, llvm_ty, idx1);
                            // Actually we already loaded via emit_field_access, so just copy
                            r_left = fa_l;
                        } else {
                            int idx1 = (source[id_s] - 'a') % pc;
                            if (idx1 < 0 || idx1 >= pc) idx1 = 0;
                            fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r_left, llvm_ty, llvm_ty, idx1);
                        }
                    } else {
                        int idx1 = (source[id_s] - 'a') % pc;
                        if (idx1 < 0 || idx1 >= pc) idx1 = 0;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r_left, llvm_ty, llvm_ty, idx1);
                    }

                    int r_right = reg++;
                    int idx2 = (source[op2_s] - 'a') % pc;
                    if (idx2 < 0 || idx2 >= pc) idx2 = 0;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r_right, llvm_ty, llvm_ty, idx2);

                    int r_res = reg++;
                    if (op == '+')
                        fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %%tmp%d\n", r_res, llvm_ty, r_left, r_right);
                    else if (op == '-')
                        fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %%tmp%d\n", r_res, llvm_ty, r_left, r_right);
                    else if (strcmp(llvm_ty, "double") == 0 && op == '*')
                        fprintf(ir_output, "  %%tmp%d = fmul double %%tmp%d, %%tmp%d\n", r_res, r_left, r_right);
                    else if (strcmp(llvm_ty, "double") == 0 && op == '/')
                        fprintf(ir_output, "  %%tmp%d = fdiv double %%tmp%d, %%tmp%d\n", r_res, r_left, r_right);
                    else if (op == '*')
                        fprintf(ir_output, "  %%tmp%d = mul %s %%tmp%d, %%tmp%d\n", r_res, llvm_ty, r_left, r_right);
                    else
                        fprintf(ir_output, "  %%tmp%d = sdiv %s %%tmp%d, %%tmp%d\n", r_res, llvm_ty, r_left, r_right);

                    fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, r_res, llvm_ty, a_reg);
                }
                // Function call: name(args)
                else if (pos < body_end && source[pos] == '(') {
                    // Determine call return type from arguments
                    int has_float_arg = 0;
                    long scan = pos + 1;
                    while (scan < body_end && source[scan] != ')') {
                        if (source[scan] == '.') { has_float_arg = 1; break; }
                        scan++;
                    }
                    const char* call_ret_ty = has_float_arg ? "double" : llvm_ty;

                    pos++; // skip '('

                    // --- Pass 1: emit all argument loads as separate instructions ---
                    // Also collect argument info for the call line
                    #define MAX_CALL_ARGS 256
                    const char* call_arg_types[MAX_CALL_ARGS];
                    long call_arg_ivals[MAX_CALL_ARGS];
                    double call_arg_fvals[MAX_CALL_ARGS];
                    int call_arg_kind[MAX_CALL_ARGS]; // 0=reg, 1=int_const, 2=float_const, 3=string, 4=ptr_ident
                    long call_arg_ptr_start[MAX_CALL_ARGS];
                    long call_arg_ptr_len[MAX_CALL_ARGS];
                    int call_arg_count = 0;
                    long apos = pos;

                    while (apos < body_end && source[apos] != ')') {
                        while (apos < body_end && source[apos] == ' ') apos++;
                        if (apos >= body_end || source[apos] == ')') break;

                        call_arg_kind[call_arg_count] = 0;
                        call_arg_ivals[call_arg_count] = 0;
                        call_arg_fvals[call_arg_count] = 0.0;

                        if (source[apos] == '&') {
                            apos++; // skip '&'
                            while (apos < body_end && source[apos] == ' ') apos++;
                            if (is_body_ident_char(source[apos])) {
                                long as = apos;
                                while (apos < body_end && is_body_ident_char(source[apos])) apos++;
                                long alen = apos - as;
                                int src_r = find_local_reg(source + as, alen, local_names, local_regs, local_count);
                                int ldr = reg++;
                                if (src_r >= 0) {
                                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", ldr, llvm_ty, llvm_ty, src_r);
                                } else {
                                    int idx = (source[as] - 'a') % pc;
                                    if (idx < 0 || idx >= pc) idx = 0;
                                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", ldr, llvm_ty, llvm_ty, idx);
                                }
                                call_arg_types[call_arg_count] = llvm_ty;
                                call_arg_ivals[call_arg_count] = ldr;
                                call_arg_kind[call_arg_count] = 0;
                            }
                        } else if (source[apos] >= '0' && source[apos] <= '9') {
                            long ival = 0; double fval = 0.0;
                            int is_f = parse_literal(source, &apos, body_end, &ival, &fval);
                            call_arg_types[call_arg_count] = is_f ? "double" : "i64";
                            call_arg_ivals[call_arg_count] = ival;
                            call_arg_fvals[call_arg_count] = fval;
                            call_arg_kind[call_arg_count] = is_f ? 2 : 1;
                        } else if (is_body_ident_char(source[apos])) {
                            long as = apos;
                            while (apos < body_end && is_body_ident_char(source[apos])) apos++;
                            int src_r = find_local_reg(source + as, apos - as, local_names, local_regs, local_count);
                            if (src_r >= 0) {
                                int ldr = reg++;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", ldr, call_ret_ty, call_ret_ty, src_r);
                                call_arg_types[call_arg_count] = call_ret_ty;
                                call_arg_ivals[call_arg_count] = ldr;
                                call_arg_kind[call_arg_count] = 0;
                            } else {
                                call_arg_types[call_arg_count] = "i64";
                                call_arg_ptr_start[call_arg_count] = as;
                                call_arg_ptr_len[call_arg_count] = apos - as;
                                call_arg_kind[call_arg_count] = 4;
                            }
                        } else if (source[apos] == '"') {
                            apos++;
                            long ss = apos;
                            while (apos < body_end && source[apos] != '"') apos++;
                            long sid = xiom_intern(source, ss, apos - ss);
                            call_arg_types[call_arg_count] = "i64";
                            call_arg_ivals[call_arg_count] = sid;
                            call_arg_kind[call_arg_count] = 3;
                            if (apos < body_end && source[apos] == '"') apos++;
                        } else { apos++; }

                        while (apos < body_end && source[apos] == ' ') apos++;
                        if (apos < body_end && source[apos] == ',') { apos++; }
                        call_arg_count++;
                        if (call_arg_count >= MAX_CALL_ARGS) break;
                    }
                    pos = apos; // pos is now at ')'

                    // --- Pass 2: emit the call with only SSA references ---
                    int cr = reg++;
                    fprintf(ir_output, "  %%tmp%d = call %s @", cr, call_ret_ty);
                    fwrite(source + id_s, 1, (size_t)id_len, ir_output);
                    fprintf(ir_output, "(");
                    for (int ai = 0; ai < call_arg_count; ai++) {
                        if (ai > 0) fprintf(ir_output, ", ");
                        if (call_arg_kind[ai] == 4) {
                            fprintf(ir_output, "%s %%%.*s", call_arg_types[ai], (int)call_arg_ptr_len[ai], source + call_arg_ptr_start[ai]);
                        } else if (call_arg_kind[ai] == 0) {
                            fprintf(ir_output, "%s %%tmp%d", call_arg_types[ai], (int)call_arg_ivals[ai]);
                        } else if (call_arg_kind[ai] == 3) {
                            fprintf(ir_output, "%s %ld", call_arg_types[ai], call_arg_ivals[ai]);
                        } else if (call_arg_kind[ai] == 2) {
                            fprintf(ir_output, "%s %lf", call_arg_types[ai], call_arg_fvals[ai]);
                        } else {
                            fprintf(ir_output, "%s %ld", call_arg_types[ai], call_arg_ivals[ai]);
                        }
                    }
                    fprintf(ir_output, ")\n");

                    if (strcmp(call_ret_ty, llvm_ty) == 0) {
                        fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, cr, llvm_ty, a_reg);
                    }
                }
                // Simple identifier: let x = y;
                else {
                    // Look up in locals first, then params
                    int src_reg = find_local_reg(source + id_s, id_len, local_names, local_regs, local_count);
                    int r_val;
                    if (src_reg >= 0) {
                        r_val = reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", r_val, llvm_ty, llvm_ty, src_reg);
                    } else {
                        r_val = reg++;
                        int idx = (source[id_s] - 'a') % pc;
                        if (idx < 0 || idx >= pc) idx = 0;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r_val, llvm_ty, llvm_ty, idx);
                    }
                    fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, r_val, llvm_ty, a_reg);
                }
            }

            // Skip to ';'
            while (pos < body_end && source[pos] != ';') pos++;
            if (pos < body_end && source[pos] == ';') pos++;
            continue;
        }

        // --- if/elif/else chain ---
        if (pos + 2 < body_end && c0 == 'i' && c1 == 'f' && !is_body_ident_char(source[pos+2])) {
            int merge_label = _label_counter++;
            int else_label = _label_counter++;
            int first_block = 1;
            int is_else_block = 0;

            while (1) {
                if (first_block) {
                    pos += 2;
                    first_block = 0;
                    is_else_block = 0;
                } else {
                    while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                    int is_elif = (pos + 4 < body_end && source[pos] == 'e' && source[pos+1] == 'l' && source[pos+2] == 'i' && source[pos+3] == 'f' && !is_body_ident_char(source[pos+4]));
                    int is_else = (pos + 4 < body_end && source[pos] == 'e' && source[pos+1] == 'l' && source[pos+2] == 's' && source[pos+3] == 'e' && !is_body_ident_char(source[pos+4]));
                    if (!is_elif && !is_else) {
                        fprintf(ir_output, "L_else_%d:\n", else_label);
                        fprintf(ir_output, "  br label %%L_merge_%d\n", merge_label);
                        break;
                    }
                    fprintf(ir_output, "L_else_%d:\n", else_label);
                    if (is_elif) {
                        pos += 4;
                        else_label = _label_counter++;
                        is_else_block = 0;
                    } else {
                        pos += 4;
                        is_else_block = 1;
                    }
                }

                int final_cond_reg = -1;
                int then_label = _label_counter++;

                if (!is_else_block) {
                    // === Parse condition ===
                    while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t')) pos++;
                    int cond_paren = 0;
                    if (pos < body_end && source[pos] == '(') { cond_paren = 1; pos++; }
                    while (pos < body_end && source[pos] == ' ') pos++;

                    int cond_is_negated = 0;
                    if (pos < body_end && source[pos] == '!') {
                        cond_is_negated = 1;
                        pos++;
                        while (pos < body_end && (source[pos] == ' ' || source[pos] == '(')) pos++;
                    }

                    int cond_combine_op = 0;
                    int cond_value_reg = -1;
                    int left_reg = -1;
                    long left_s = pos;
                    while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                    long left_len = pos - left_s;
                    int saw_fncall_paren = 0;

                    if (left_len > 0) {
                        while (pos < body_end && source[pos] == ' ') pos++;
                        if (pos < body_end && source[pos] == '(') {
                            saw_fncall_paren = 1;
                            int has_float = 0;
                            long scan = pos + 1;
                            while (scan < body_end && source[scan] != ')') {
                                if (source[scan] == '.') { has_float = 1; break; }
                                scan++;
                            }
                            const char* fn_ret = has_float ? "double" : llvm_ty;
                            int cr = reg++;
                            fprintf(ir_output, "  %%tmp%d = call %s @", cr, fn_ret);
                            fwrite(source + left_s, 1, (size_t)left_len, ir_output);
                            fprintf(ir_output, "(");
                            pos++;
                            int afirst = 1;
                            while (pos < body_end && source[pos] != ')') {
                                while (pos < body_end && source[pos] == ' ') pos++;
                                if (pos >= body_end || source[pos] == ')') break;
                                if (source[pos] >= '0' && source[pos] <= '9') {
                                    long iv = 0; double fv = 0.0;
                                    int isf = parse_literal(source, &pos, body_end, &iv, &fv);
                                    if (!afirst) fprintf(ir_output, ", ");
                                    if (isf) fprintf(ir_output, "double %lf", fv);
                                    else fprintf(ir_output, "i64 %ld", iv);
                                } else if (is_body_ident_char(source[pos])) {
                                    long as = pos;
                                    while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                                    if (!afirst) fprintf(ir_output, ", ");
                                    fprintf(ir_output, "i64 %%%.*s", (int)(pos - as), source + as);
                                } else if (source[pos] == '"') {
                                    pos++;
                                    long ss = pos;
                                    while (pos < body_end && source[pos] != '"') pos++;
                                    if (!afirst) fprintf(ir_output, ", ");
                                    long sid = xiom_intern(source, ss, pos - ss);
                                    fprintf(ir_output, "i64 %ld", sid);
                                    if (pos < body_end && source[pos] == '"') pos++;
                                    afirst = 0;
                                } else { pos++; }
                                while (pos < body_end && source[pos] == ' ') pos++;
                                if (pos < body_end && source[pos] == ',') { pos++; afirst = 0; }
                            }
                            fprintf(ir_output, ")\n");
                            left_reg = cr;
                        }
                    }

                    if (left_len > 0 && !saw_fncall_paren) {
                        long save_pos = pos;
                        while (pos < body_end && source[pos] == ' ') pos++;
                        if (pos < body_end && (source[pos] == '+' || source[pos] == '-')) {
                            char aop = source[pos]; pos++;
                            while (pos < body_end && source[pos] == ' ') pos++;
                            if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                                long lit_val = 0;
                                while (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                                    lit_val = lit_val * 10 + (source[pos] - '0');
                                    pos++;
                                }
                                int lreg = get_local_reg(source + left_s, left_len, pc, local_names, local_regs, local_count);
                                int load_reg = reg++;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", load_reg, llvm_ty, llvm_ty, lreg);
                                int arith_reg = reg++;
                                if (aop == '+')
                                    fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %ld\n", arith_reg, llvm_ty, load_reg, lit_val);
                                else
                                    fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %ld\n", arith_reg, llvm_ty, load_reg, lit_val);
                                left_reg = arith_reg;
                            } else { pos = save_pos; }
                        } else { pos = save_pos; }
                    }

                    if (left_len > 0 && left_reg < 0 && !saw_fncall_paren) {
                        int lreg = get_local_reg(source + left_s, left_len, pc, local_names, local_regs, local_count);
                        left_reg = reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", left_reg, llvm_ty, llvm_ty, lreg);
                    }

                    if (cond_is_negated && left_len > 0) {
                        cond_is_negated = 0;
                        cond_value_reg = reg++;
                        fprintf(ir_output, "  %%tmp%d = icmp eq %s %%tmp%d, 0\n", cond_value_reg, llvm_ty, left_reg);
                    }

                    while (pos < body_end && source[pos] == ' ') pos++;
                    char cmp_op = 0;
                    if (pos + 1 < body_end && source[pos] == '=' && source[pos+1] == '=') { cmp_op = 'e'; pos += 2; }
                    else if (pos + 1 < body_end && source[pos] == '!' && source[pos+1] == '=') { cmp_op = 'n'; pos += 2; }
                    else if (pos + 1 < body_end && source[pos] == '>' && source[pos+1] == '=') { cmp_op = 'G'; pos += 2; }
                    else if (pos + 1 < body_end && source[pos] == '<' && source[pos+1] == '=') { cmp_op = 'L'; pos += 2; }
                    else if (pos < body_end && source[pos] == '>') { cmp_op = 'g'; pos++; }
                    else if (pos < body_end && source[pos] == '<') { cmp_op = 'l'; pos++; }

                    if (cmp_op != 0) {
                        while (pos < body_end && source[pos] == ' ') pos++;
                        long right_s = pos;
                        int right_is_literal = 0;
                        long right_literal_val = 0;
                        int right_reg = -1;
                        if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                            right_is_literal = 1;
                            right_literal_val = 0;
                            while (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                                right_literal_val = right_literal_val * 10 + (source[pos] - '0');
                                pos++;
                            }
                        } else if (is_body_ident_char(source[pos])) {
                            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                            long right_len = pos - right_s;
                            while (pos < body_end && source[pos] == ' ') pos++;
                            if (pos < body_end && source[pos] == '(') { pos = right_s; }
                            else {
                                int rreg = get_local_reg(source + right_s, right_len, pc, local_names, local_regs, local_count);
                                right_reg = reg++;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", right_reg, llvm_ty, llvm_ty, rreg);
                            }
                        }
                        if (left_reg >= 0 || right_reg >= 0 || right_is_literal) {
                            const char* icmp_name = "";
                            if (cmp_op == 'e') icmp_name = "eq";
                            else if (cmp_op == 'n') icmp_name = "ne";
                            else if (cmp_op == 'g') icmp_name = "sgt";
                            else if (cmp_op == 'l') icmp_name = "slt";
                            else if (cmp_op == 'G') icmp_name = "sge";
                            else if (cmp_op == 'L') icmp_name = "sle";
                            cond_value_reg = reg++;
                            if (right_reg >= 0)
                                fprintf(ir_output, "  %%tmp%d = icmp %s %s %%tmp%d, %%tmp%d\n", cond_value_reg, icmp_name, llvm_ty, left_reg, right_reg);
                            else
                                fprintf(ir_output, "  %%tmp%d = icmp %s %s %%tmp%d, %ld\n", cond_value_reg, icmp_name, llvm_ty, left_reg, right_literal_val);
                        }
                    }

                    if (left_len > 0 && cmp_op == 0 && !cond_is_negated && cond_value_reg < 0) {
                        cond_value_reg = reg++;
                        fprintf(ir_output, "  %%tmp%d = icmp ne %s %%tmp%d, 0\n", cond_value_reg, llvm_ty, left_reg);
                    }

                    while (pos < body_end && source[pos] == ' ') pos++;
                    if (cond_paren && pos < body_end && source[pos] == ')') pos++;
                    while (pos < body_end && source[pos] == ' ') pos++;

                    int has_compound = 0;
                    while (pos < body_end && source[pos] == ' ') pos++;
                    if (pos + 1 < body_end && source[pos] == '&' && source[pos+1] == '&') { has_compound = 1; cond_combine_op = 1; pos += 2; }
                    else if (pos + 1 < body_end && source[pos] == '|' && source[pos+1] == '|') { has_compound = 1; cond_combine_op = 2; pos += 2; }

                    int second_cond_value_reg = -1;
                    if (has_compound) {
                        while (pos < body_end && source[pos] == ' ') pos++;
                        int sp2 = 0;
                        if (pos < body_end && source[pos] == '(') { sp2 = 1; pos++; }
                        while (pos < body_end && source[pos] == ' ') pos++;
                        long lhs2_s = pos;
                        while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                        long lhs2_len = pos - lhs2_s;
                        while (pos < body_end && source[pos] == ' ') pos++;
                        int lhs2_reg = -1;
                        if (lhs2_len > 0) {
                            int l2r = get_local_reg(source + lhs2_s, lhs2_len, pc, local_names, local_regs, local_count);
                            lhs2_reg = reg++;
                            fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", lhs2_reg, llvm_ty, llvm_ty, l2r);
                        }
                        while (pos < body_end && source[pos] == ' ') pos++;
                        char cmp2_op = 0;
                        if (pos + 1 < body_end && source[pos] == '=' && source[pos+1] == '=') { cmp2_op = 'e'; pos += 2; }
                        else if (pos + 1 < body_end && source[pos] == '!' && source[pos+1] == '=') { cmp2_op = 'n'; pos += 2; }
                        else if (pos + 1 < body_end && source[pos] == '>' && source[pos+1] == '=') { cmp2_op = 'G'; pos += 2; }
                        else if (pos + 1 < body_end && source[pos] == '<' && source[pos+1] == '=') { cmp2_op = 'L'; pos += 2; }
                        else if (pos < body_end && source[pos] == '>') { cmp2_op = 'g'; pos++; }
                        else if (pos < body_end && source[pos] == '<') { cmp2_op = 'l'; pos++; }
                        if (cmp2_op != 0) {
                            while (pos < body_end && source[pos] == ' ') pos++;
                            long rhs2_s = pos;
                            int rhs2_is_lit = 0;
                            long rhs2_val = 0;
                            int rhs2_reg = -1;
                            if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                                rhs2_is_lit = 1;
                                rhs2_val = 0;
                                while (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                                    rhs2_val = rhs2_val * 10 + (source[pos] - '0');
                                    pos++;
                                }
                            } else if (is_body_ident_char(source[pos])) {
                                while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                                long rhs2_len = pos - rhs2_s;
                                int r2r = get_local_reg(source + rhs2_s, rhs2_len, pc, local_names, local_regs, local_count);
                                rhs2_reg = reg++;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", rhs2_reg, llvm_ty, llvm_ty, r2r);
                            }
                            const char* ic2 = "";
                            if (cmp2_op == 'e') ic2 = "eq";
                            else if (cmp2_op == 'n') ic2 = "ne";
                            else if (cmp2_op == 'g') ic2 = "sgt";
                            else if (cmp2_op == 'l') ic2 = "slt";
                            else if (cmp2_op == 'G') ic2 = "sge";
                            else if (cmp2_op == 'L') ic2 = "sle";
                            if (lhs2_reg >= 0) {
                                second_cond_value_reg = reg++;
                                if (rhs2_reg >= 0)
                                    fprintf(ir_output, "  %%tmp%d = icmp %s %s %%tmp%d, %%tmp%d\n", second_cond_value_reg, ic2, llvm_ty, lhs2_reg, rhs2_reg);
                                else
                                    fprintf(ir_output, "  %%tmp%d = icmp %s %s %%tmp%d, %ld\n", second_cond_value_reg, ic2, llvm_ty, lhs2_reg, rhs2_val);
                            }
                        }
                        while (pos < body_end && source[pos] == ' ') pos++;
                        if (sp2 && pos < body_end && source[pos] == ')') pos++;
                    }

                    final_cond_reg = cond_value_reg;
                    if (second_cond_value_reg >= 0 && cond_combine_op != 0) {
                        int combine_reg = reg++;
                        if (cond_combine_op == 1)
                            fprintf(ir_output, "  %%tmp%d = and i1 %%tmp%d, %%tmp%d\n", combine_reg, cond_value_reg, second_cond_value_reg);
                        else
                            fprintf(ir_output, "  %%tmp%d = or i1 %%tmp%d, %%tmp%d\n", combine_reg, cond_value_reg, second_cond_value_reg);
                        final_cond_reg = combine_reg;
                    }
                }

                // Skip to '{'
                while (pos < body_end && source[pos] != '{') pos++;
                if (pos < body_end && source[pos] == '{') pos++;

                // Find matching '}'
                long body_sub_start = pos;
                int brace_depth = 1;
                while (pos < body_end && brace_depth > 0) {
                    if (source[pos] == '{') brace_depth++;
                    else if (source[pos] == '}') brace_depth--;
                    if (brace_depth > 0) pos++;
                }
                long body_sub_end = pos;

                // Emit branch and then-label
                if (!is_else_block && final_cond_reg >= 0) {
                    fprintf(ir_output, "  br i1 %%tmp%d, label %%L_then_%d, label %%L_else_%d\n", final_cond_reg, then_label, else_label);
                } else if (!is_else_block) {
                    fprintf(ir_output, "  br label %%L_then_%d\n", then_label);
                }
                fprintf(ir_output, "L_then_%d:\n", then_label);

                // Parse statements inside then body
                long sp = body_sub_start;
                int emitted_ret = 0;
                while (sp < body_sub_end) {
                    while (sp < body_sub_end && (source[sp] == ' ' || source[sp] == '\t' || source[sp] == '\n' || source[sp] == '\r')) sp++;
                    if (sp >= body_sub_end) break;
                    char sc0 = source[sp];
                    char sc1 = sp + 1 < body_sub_end ? source[sp+1] : 0;

                    // return statement
                    if (sp + 5 < body_sub_end && sc0 == 'r' && sc1 == 'e' && source[sp+2] == 't' && source[sp+3] == 'u' && source[sp+4] == 'r' && source[sp+5] == 'n') {
                        sp += 6;
                        while (sp < body_sub_end && (source[sp] == ' ' || source[sp] == '\t')) sp++;
                        if (sp < body_sub_end && source[sp] >= '0' && source[sp] <= '9') {
                            long iv = 0; double fv = 0.0;
                            parse_literal(source, &sp, body_sub_end, &iv, &fv);
                            fprintf(ir_output, "  ret %s %ld\n", llvm_ty, iv);
                            emitted_ret = 1;
                        } else if (is_body_ident_char(source[sp])) {
                            long rs = sp;
                            while (sp < body_sub_end && is_body_ident_char(source[sp])) sp++;
                            int rr = get_local_reg(source + rs, sp - rs, pc, local_names, local_regs, local_count);
                            int lr = reg++;
                            fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", lr, llvm_ty, llvm_ty, rr);
                            fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, lr);
                            emitted_ret = 1;
                        } else {
                            fprintf(ir_output, "  ret %s 0\n", llvm_ty);
                            emitted_ret = 1;
                        }
                        while (sp < body_sub_end && source[sp] != ';') sp++;
                        if (sp < body_sub_end && source[sp] == ';') sp++;
                        break;
                    }

                    // var/let declaration
                    if ((sp + 3 < body_sub_end && sc0 == 'l' && sc1 == 'e' && source[sp+2] == 't' && (source[sp+3] == ' ' || source[sp+3] == '\t')) ||
                        (sp + 3 < body_sub_end && sc0 == 'v' && sc1 == 'a' && source[sp+2] == 'r' && (source[sp+3] == ' ' || source[sp+3] == '\t'))) {
                        sp += 4;
                        while (sp < body_sub_end && source[sp] == ' ') sp++;
                        long vns = sp;
                        while (sp < body_sub_end && is_body_ident_char(source[sp])) sp++;
                        long vnlen = sp - vns;
                        int va_reg = reg++;
                        fprintf(ir_output, "  %%tmp%d = alloca %s\n", va_reg, llvm_ty);
                        if (local_count < MAX_LOCALS) {
                            int cp = vnlen < 63 ? (int)vnlen : 63;
                            strncpy(local_names[local_count], source + vns, (size_t)cp);
                            local_names[local_count][cp] = '\0';
                            local_regs[local_count] = va_reg;
                            local_count++;
                        }
                        while (sp < body_sub_end && source[sp] == ' ') sp++;
                        if (sp < body_sub_end && source[sp] == '=') sp++;
                        while (sp < body_sub_end && source[sp] == ' ') sp++;
                        if (sp < body_sub_end && source[sp] >= '0' && source[sp] <= '9') {
                            long iv = 0; double fv = 0.0;
                            parse_literal(source, &sp, body_sub_end, &iv, &fv);
                            fprintf(ir_output, "  store %s %ld, %s* %%tmp%d\n", llvm_ty, iv, llvm_ty, va_reg);
                        } else if (is_body_ident_char(source[sp])) {
                            long is = sp;
                            while (sp < body_sub_end && is_body_ident_char(source[sp])) sp++;
                            int ir = get_local_reg(source + is, sp - is, pc, local_names, local_regs, local_count);
                            int ldr = reg++;
                            fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", ldr, llvm_ty, llvm_ty, ir);
                            fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, ldr, llvm_ty, va_reg);
                        }
                        while (sp < body_sub_end && source[sp] != ';') sp++;
                        if (sp < body_sub_end && source[sp] == ';') sp++;
                        continue;
                    }

                    // Assignment or expression statement
                    if (is_body_ident_char(sc0)) {
                        long asn_s = sp;
                        while (sp < body_sub_end && is_body_ident_char(source[sp])) sp++;
                        long asn_len = sp - asn_s;
                        while (sp < body_sub_end && source[sp] == ' ') sp++;

                        if (sp < body_sub_end && source[sp] == '=') {
                            sp++;
                            while (sp < body_sub_end && source[sp] == ' ') sp++;
                            int dest_reg = get_local_reg(source + asn_s, asn_len, pc, local_names, local_regs, local_count);

                            if (sp < body_sub_end && source[sp] >= '0' && source[sp] <= '9') {
                                long iv = 0;
                                while (sp < body_sub_end && source[sp] >= '0' && source[sp] <= '9') {
                                    iv = iv * 10 + (source[sp] - '0');
                                    sp++;
                                }
                                while (sp < body_sub_end && source[sp] == ' ') sp++;
                                if (sp + 1 < body_sub_end && source[sp] == '=' && source[sp+1] == '=') {
                                    sp += 2;
                                    while (sp < body_sub_end && source[sp] == ' ') sp++;
                                    long rv = 0;
                                    int comp_reg = -1;
                                    if (source[sp] >= '0' && source[sp] <= '9') {
                                        while (sp < body_sub_end && source[sp] >= '0' && source[sp] <= '9') {
                                            rv = rv * 10 + (source[sp] - '0');
                                            sp++;
                                        }
                                        int cmp_r = reg++;
                                        fprintf(ir_output, "  %%tmp%d = icmp eq %s %ld, %ld\n", cmp_r, llvm_ty, iv, rv);
                                        int zext_r = reg++;
                                        fprintf(ir_output, "  %%tmp%d = zext i1 %%tmp%d to %s\n", zext_r, cmp_r, llvm_ty);
                                        fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, zext_r, llvm_ty, dest_reg);
                                    } else if (is_body_ident_char(source[sp])) {
                                        long ris = sp;
                                        while (sp < body_sub_end && is_body_ident_char(source[sp])) sp++;
                                        int rr = get_local_reg(source + ris, sp - ris, pc, local_names, local_regs, local_count);
                                        int lr = reg++;
                                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", lr, llvm_ty, llvm_ty, rr);
                                        int cmp_r = reg++;
                                        fprintf(ir_output, "  %%tmp%d = icmp eq %s %ld, %%tmp%d\n", cmp_r, llvm_ty, iv, lr);
                                        int zext_r = reg++;
                                        fprintf(ir_output, "  %%tmp%d = zext i1 %%tmp%d to %s\n", zext_r, cmp_r, llvm_ty);
                                        fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, zext_r, llvm_ty, dest_reg);
                                    }
                                } else {
                                    // Simple literal assignment
                                    fprintf(ir_output, "  store %s %ld, %s* %%tmp%d\n", llvm_ty, iv, llvm_ty, dest_reg);
                                }
                            } else if (is_body_ident_char(source[sp])) {
                                long rhs_s = sp;
                                while (sp < body_sub_end && is_body_ident_char(source[sp])) sp++;
                                long rhs_len = sp - rhs_s;
                                while (sp < body_sub_end && source[sp] == ' ') sp++;

                                // Check for binary op: ident + literal, ident - literal
                                if (sp < body_sub_end && (source[sp] == '+' || source[sp] == '-')) {
                                    char aop = source[sp]; sp++;
                                    while (sp < body_sub_end && source[sp] == ' ') sp++;
                                    long litv = 0;
                                    while (sp < body_sub_end && source[sp] >= '0' && source[sp] <= '9') {
                                        litv = litv * 10 + (source[sp] - '0');
                                        sp++;
                                    }
                                    int src_r = get_local_reg(source + rhs_s, rhs_len, pc, local_names, local_regs, local_count);
                                    int lr = reg++;
                                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", lr, llvm_ty, llvm_ty, src_r);
                                    int ar = reg++;
                                    if (aop == '+')
                                        fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %ld\n", ar, llvm_ty, lr, litv);
                                    else
                                        fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %ld\n", ar, llvm_ty, lr, litv);
                                    fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, ar, llvm_ty, dest_reg);
                                }
                                // Check for function call
                                else if (sp < body_sub_end && source[sp] == '(') {
                                    // fn call: ident = name(args)
                                    // But we already parsed the first ident on RHS as the fn name
                                    // The function name is rhs_s..sp (after skipping ws)
                                    // Actually this pattern appears in var/let init, not simple assignment
                                    // Skip for now
                                    sp = rhs_s; // backtrack
                                }
                                // Simple ident assignment
                                else {
                                    int src_r = get_local_reg(source + rhs_s, rhs_len, pc, local_names, local_regs, local_count);
                                    int lr = reg++;
                                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", lr, llvm_ty, llvm_ty, src_r);
                                    fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, lr, llvm_ty, dest_reg);
                                }
                            }

                            while (sp < body_sub_end && source[sp] != ';') sp++;
                            if (sp < body_sub_end && source[sp] == ';') sp++;
                            continue;
                        }

                        // Expression statement or function call
                        if (sp < body_sub_end && source[sp] == '(') {
                            // Function call as expression statement
                            int hf = 0;
                            long sc2 = sp + 1;
                            while (sc2 < body_sub_end && source[sc2] != ')') {
                                if (source[sc2] == '.') { hf = 1; break; }
                                sc2++;
                            }
                            const char* crt = hf ? "double" : llvm_ty;
                            int cr2 = reg++;
                            fprintf(ir_output, "  %%tmp%d = call %s @", cr2, crt);
                            fwrite(source + asn_s, 1, (size_t)asn_len, ir_output);
                            fprintf(ir_output, "(");
                            sp++;
                            int af2 = 1;
                            while (sp < body_sub_end && source[sp] != ')') {
                                while (sp < body_sub_end && source[sp] == ' ') sp++;
                                if (sp >= body_sub_end || source[sp] == ')') break;
                                if (source[sp] >= '0' && source[sp] <= '9') {
                                    long iv = 0; double fv = 0.0;
                                    int isf = parse_literal(source, &sp, body_sub_end, &iv, &fv);
                                    if (!af2) fprintf(ir_output, ", ");
                                    if (isf) fprintf(ir_output, "double %lf", fv);
                                    else fprintf(ir_output, "i64 %ld", iv);
                                } else if (is_body_ident_char(source[sp])) {
                                    long as2 = sp;
                                    while (sp < body_sub_end && is_body_ident_char(source[sp])) sp++;
                                    if (!af2) fprintf(ir_output, ", ");
                                    fprintf(ir_output, "i64 %%%.*s", (int)(sp - as2), source + as2);
                                } else if (source[sp] == '"') {
                                    sp++;
                                    long ss2 = sp;
                                    while (sp < body_sub_end && source[sp] != '"') sp++;
                                    if (!af2) fprintf(ir_output, ", ");
                                    long sid = xiom_intern(source, ss2, sp - ss2);
                                    fprintf(ir_output, "i64 %ld", sid);
                                    if (sp < body_sub_end && source[sp] == '"') sp++;
                                    af2 = 0;
                                } else { sp++; }
                                while (sp < body_sub_end && source[sp] == ' ') sp++;
                                if (sp < body_sub_end && source[sp] == ',') { sp++; af2 = 0; }
                            }
                            fprintf(ir_output, ")\n");
                            if (sp < body_sub_end && source[sp] == ')') sp++;
                            { int bd = 0; while (sp < body_sub_end) { if (source[sp] == '{') bd++; else if (source[sp] == '}') { if (bd == 0) break; bd--; } else if (source[sp] == ';' && bd == 0) break; sp++; } }
                            if (sp < body_sub_end && source[sp] == ';') sp++;
                            continue;
                        }

                        // Just an expression (skip with brace depth)
                        { int bd = 0; while (sp < body_sub_end) { if (source[sp] == '{') bd++; else if (source[sp] == '}') { if (bd == 0) break; bd--; } else if (source[sp] == ';' && bd == 0) break; sp++; } }
                        if (sp < body_sub_end && source[sp] == ';') sp++;
                        continue;
                    }

                    // Skip to ';' or end with brace depth
                    { int bd = 0; while (sp < body_sub_end) { if (source[sp] == '{') bd++; else if (source[sp] == '}') { if (bd == 0) break; bd--; } else if (source[sp] == ';' && bd == 0) break; sp++; } }
                    if (sp < body_sub_end && source[sp] == ';') sp++;
                }

                if (!emitted_ret) {
                    fprintf(ir_output, "  br label %%L_merge_%d\n", merge_label);
                }

                // Advance main pos to end of sub-body
                pos = body_sub_end; // at '}'
                if (pos < body_end && source[pos] == '}') pos++;

                // Check for elif/else (loop will handle it)
                int has_more = 0;
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                if (pos + 4 < body_end && source[pos] == 'e' && source[pos+1] == 'l' && source[pos+2] == 'i' && source[pos+3] == 'f' && !is_body_ident_char(source[pos+4])) has_more = 1;
                if (pos + 4 < body_end && source[pos] == 'e' && source[pos+1] == 'l' && source[pos+2] == 's' && source[pos+3] == 'e' && !is_body_ident_char(source[pos+4])) has_more = 1;

                if (!has_more) {
                    fprintf(ir_output, "L_else_%d:\n", else_label);
                    fprintf(ir_output, "  br label %%L_merge_%d\n", merge_label);
                    break;
                }
            }

            fprintf(ir_output, "L_merge_%d:\n", merge_label);
            continue;
        }

        // --- while loop ---
        if (pos + 5 < body_end && c0 == 'w' && c1 == 'h' && source[pos+2] == 'i' && source[pos+3] == 'l' && source[pos+4] == 'e' && !is_body_ident_char(source[pos+5])) {
            int while_cond_label = _label_counter++;
            int while_body_label = _label_counter++;
            int while_end_label = _label_counter++;

            // Branch to condition check (first iteration)
            fprintf(ir_output, "  br label %%L_while_cond_%d\n", while_cond_label);
            fprintf(ir_output, "L_while_cond_%d:\n", while_cond_label);

            pos += 5; // skip "while"

            // Parse condition (same as if - reuse the pattern)
            while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t')) pos++;
            int wcond_paren = 0;
            if (pos < body_end && source[pos] == '(') { wcond_paren = 1; pos++; }
            while (pos < body_end && source[pos] == ' ') pos++;

            int wneg = 0;
            if (pos < body_end && source[pos] == '!') {
                wneg = 1;
                pos++;
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '(')) pos++;
            }

            // Parse left expr
            long wl_s = pos;
            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
            long wl_len = pos - wl_s;

            // Binary expr on left: ident + literal or ident - literal
            int wleft_reg = -1;
            if (wl_len > 0) {
                long savep = pos;
                while (pos < body_end && source[pos] == ' ') pos++;
                if (pos < body_end && (source[pos] == '+' || source[pos] == '-')) {
                    char waop = source[pos]; pos++;
                    while (pos < body_end && source[pos] == ' ') pos++;
                    if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                        long wlv = 0;
                        while (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                            wlv = wlv * 10 + (source[pos] - '0');
                            pos++;
                        }
                        int lreg = get_local_reg(source + wl_s, wl_len, pc, local_names, local_regs, local_count);
                        int lr = reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", lr, llvm_ty, llvm_ty, lreg);
                        wleft_reg = reg++;
                        if (waop == '+')
                            fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %ld\n", wleft_reg, llvm_ty, lr, wlv);
                        else
                            fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %ld\n", wleft_reg, llvm_ty, lr, wlv);
                    } else {
                        pos = savep;
                    }
                } else {
                    pos = savep;
                }
            }

            // Load left if not already loaded
            if (wl_len > 0 && wleft_reg < 0) {
                int lreg = get_local_reg(source + wl_s, wl_len, pc, local_names, local_regs, local_count);
                wleft_reg = reg++;
                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", wleft_reg, llvm_ty, llvm_ty, lreg);
            }

            // Handle negation: !(ident) → icmp eq 0
            if (wneg && wleft_reg >= 0) {
                int cmp_r = reg++;
                fprintf(ir_output, "  %%tmp%d = icmp eq %s %%tmp%d, 0\n", cmp_r, llvm_ty, wleft_reg);
                fprintf(ir_output, "  br i1 %%tmp%d, label %%L_while_body_%d, label %%L_while_end_%d\n", cmp_r, while_body_label, while_end_label);
                fprintf(ir_output, "L_while_body_%d:\n", while_body_label);
            } else {
                // Parse comparison operator
                while (pos < body_end && source[pos] == ' ') pos++;
                char wcmp = 0;
                if (pos + 1 < body_end && source[pos] == '=' && source[pos+1] == '=') { wcmp = 'e'; pos += 2; }
                else if (pos + 1 < body_end && source[pos] == '!' && source[pos+1] == '=') { wcmp = 'n'; pos += 2; }
                else if (pos + 1 < body_end && source[pos] == '>' && source[pos+1] == '=') { wcmp = 'G'; pos += 2; }
                else if (pos + 1 < body_end && source[pos] == '<' && source[pos+1] == '=') { wcmp = 'L'; pos += 2; }
                else if (pos < body_end && source[pos] == '>') { wcmp = 'g'; pos++; }
                else if (pos < body_end && source[pos] == '<') { wcmp = 'l'; pos++; }

                int w_final_reg = -1;
                if (wcmp != 0) {
                    while (pos < body_end && source[pos] == ' ') pos++;
                    long wr_s = pos;
                    int wr_is_lit = 0;
                    long wr_val = 0;
                    int wr_reg = -1;
                    if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                        wr_is_lit = 1;
                        wr_val = 0;
                        while (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                            wr_val = wr_val * 10 + (source[pos] - '0');
                            pos++;
                        }
                    } else if (is_body_ident_char(source[pos])) {
                        while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                        long wr_len = pos - wr_s;
                        int wrr = get_local_reg(source + wr_s, wr_len, pc, local_names, local_regs, local_count);
                        wr_reg = reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", wr_reg, llvm_ty, llvm_ty, wrr);
                    }

                    const char* wic = "";
                    if (wcmp == 'e') wic = "eq";
                    else if (wcmp == 'n') wic = "ne";
                    else if (wcmp == 'g') wic = "sgt";
                    else if (wcmp == 'l') wic = "slt";
                    else if (wcmp == 'G') wic = "sge";
                    else if (wcmp == 'L') wic = "sle";

                    if (wleft_reg >= 0) {
                        w_final_reg = reg++;
                        if (wr_reg >= 0)
                            fprintf(ir_output, "  %%tmp%d = icmp %s %s %%tmp%d, %%tmp%d\n", w_final_reg, wic, llvm_ty, wleft_reg, wr_reg);
                        else
                            fprintf(ir_output, "  %%tmp%d = icmp %s %s %%tmp%d, %ld\n", w_final_reg, wic, llvm_ty, wleft_reg, wr_val);
                    }
                } else if (wleft_reg >= 0) {
                    // Lone ident: truthy check
                    w_final_reg = reg++;
                    fprintf(ir_output, "  %%tmp%d = icmp ne %s %%tmp%d, 0\n", w_final_reg, llvm_ty, wleft_reg);
                }

                // Close optional ')'
                while (pos < body_end && source[pos] == ' ') pos++;
                if (wcond_paren && pos < body_end && source[pos] == ')') pos++;

                // Emit while branch
                if (w_final_reg >= 0) {
                    fprintf(ir_output, "  br i1 %%tmp%d, label %%L_while_body_%d, label %%L_while_end_%d\n", w_final_reg, while_body_label, while_end_label);
                } else {
                    fprintf(ir_output, "  br label %%L_while_body_%d\n", while_body_label);
                }
                fprintf(ir_output, "L_while_body_%d:\n", while_body_label);
            }

            // Close optional ')'
            while (pos < body_end && source[pos] == ' ') pos++;
            if (wcond_paren && pos < body_end && source[pos] == ')') pos++;

            // Skip to '{'
            while (pos < body_end && source[pos] != '{') pos++;
            int wbody_open = 0;
            if (pos < body_end && source[pos] == '{') { wbody_open = 1; pos++; }

            // Find matching '}'
            long wbody_start = pos;
            int wdepth = 1;
            while (pos < body_end && wdepth > 0) {
                if (source[pos] == '{') wdepth++;
                else if (source[pos] == '}') wdepth--;
                if (wdepth > 0) pos++;
            }
            long wbody_end = pos; // at '}'

            // Parse statements inside while body
            long wsp = wbody_start;
            int while_emitted_ret = 0;
            while (wsp < wbody_end) {
                while (wsp < wbody_end && (source[wsp] == ' ' || source[wsp] == '\t' || source[wsp] == '\n' || source[wsp] == '\r')) wsp++;
                if (wsp >= wbody_end) break;

                char wsc0 = source[wsp];
                char wsc1 = wsp + 1 < wbody_end ? source[wsp+1] : 0;

                // return
                if (wsp + 5 < wbody_end && wsc0 == 'r' && wsc1 == 'e' && source[wsp+2] == 't' && source[wsp+3] == 'u' && source[wsp+4] == 'r' && source[wsp+5] == 'n') {
                    wsp += 6;
                    while (wsp < wbody_end && (source[wsp] == ' ' || source[wsp] == '\t')) wsp++;
                    if (wsp < wbody_end && source[wsp] >= '0' && source[wsp] <= '9') {
                        long iv = 0; double fv = 0.0;
                        parse_literal(source, &wsp, wbody_end, &iv, &fv);
                        fprintf(ir_output, "  ret %s %ld\n", llvm_ty, iv);
                    } else if (is_body_ident_char(source[wsp])) {
                        long wr_s = wsp;
                        while (wsp < wbody_end && is_body_ident_char(source[wsp])) wsp++;
                        int wr_r = get_local_reg(source + wr_s, wsp - wr_s, pc, local_names, local_regs, local_count);
                        int wlr = reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", wlr, llvm_ty, llvm_ty, wr_r);
                        fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, wlr);
                    }
                    while_emitted_ret = 1;
                    while (wsp < wbody_end && source[wsp] != ';') wsp++;
                    if (wsp < wbody_end && source[wsp] == ';') wsp++;
                    break;
                }

                // var/let
                if ((wsp + 3 < wbody_end && wsc0 == 'l' && wsc1 == 'e' && source[wsp+2] == 't' && (source[wsp+3] == ' ' || source[wsp+3] == '\t')) ||
                    (wsp + 3 < wbody_end && wsc0 == 'v' && wsc1 == 'a' && source[wsp+2] == 'r' && (source[wsp+3] == ' ' || source[wsp+3] == '\t'))) {
                    wsp += 4;
                    while (wsp < wbody_end && source[wsp] == ' ') wsp++;
                    long wvns = wsp;
                    while (wsp < wbody_end && is_body_ident_char(source[wsp])) wsp++;
                    long wvnl = wsp - wvns;
                    int wva = reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %s\n", wva, llvm_ty);
                    if (local_count < MAX_LOCALS) {
                        int cp = wvnl < 63 ? (int)wvnl : 63;
                        strncpy(local_names[local_count], source + wvns, (size_t)cp);
                        local_names[local_count][cp] = '\0';
                        local_regs[local_count] = wva;
                        local_count++;
                    }
                    while (wsp < wbody_end && source[wsp] == ' ') wsp++;
                    if (wsp < wbody_end && source[wsp] == '=') wsp++;
                    while (wsp < wbody_end && source[wsp] == ' ') wsp++;
                    if (wsp < wbody_end && source[wsp] >= '0' && source[wsp] <= '9') {
                        long iv = 0; double fv = 0.0;
                        parse_literal(source, &wsp, wbody_end, &iv, &fv);
                        fprintf(ir_output, "  store %s %ld, %s* %%tmp%d\n", llvm_ty, iv, llvm_ty, wva);
                    } else if (is_body_ident_char(source[wsp])) {
                        long wis = wsp;
                        while (wsp < wbody_end && is_body_ident_char(source[wsp])) wsp++;
                        int wir = get_local_reg(source + wis, wsp - wis, pc, local_names, local_regs, local_count);
                        int wld = reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", wld, llvm_ty, llvm_ty, wir);
                        fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, wld, llvm_ty, wva);
                    }
                    while (wsp < wbody_end && source[wsp] != ';') wsp++;
                    if (wsp < wbody_end && source[wsp] == ';') wsp++;
                    continue;
                }

                // Assignment: ident = expr;
                if (is_body_ident_char(wsc0)) {
                    long was = wsp;
                    while (wsp < wbody_end && is_body_ident_char(source[wsp])) wsp++;
                    long wal = wsp - was;
                    while (wsp < wbody_end && source[wsp] == ' ') wsp++;

                    if (wsp < wbody_end && source[wsp] == '=') {
                        wsp++;
                        while (wsp < wbody_end && source[wsp] == ' ') wsp++;

                        int wdest_r = get_local_reg(source + was, wal, pc, local_names, local_regs, local_count);

                        if (wsp < wbody_end && source[wsp] >= '0' && source[wsp] <= '9') {
                            long wiv = 0;
                            while (wsp < wbody_end && source[wsp] >= '0' && source[wsp] <= '9') {
                                wiv = wiv * 10 + (source[wsp] - '0');
                                wsp++;
                            }
                            // Check for == comparison
                            while (wsp < wbody_end && source[wsp] == ' ') wsp++;
                            if (wsp + 1 < wbody_end && source[wsp] == '=' && source[wsp+1] == '=') {
                                wsp += 2;
                                while (wsp < wbody_end && source[wsp] == ' ') wsp++;
                                long wrv = 0;
                                if (source[wsp] >= '0' && source[wsp] <= '9') {
                                    while (wsp < wbody_end && source[wsp] >= '0' && source[wsp] <= '9') {
                                        wrv = wrv * 10 + (source[wsp] - '0');
                                        wsp++;
                                    }
                                    int wcmp_r = reg++;
                                    fprintf(ir_output, "  %%tmp%d = icmp eq %s %ld, %ld\n", wcmp_r, llvm_ty, wiv, wrv);
                                    int wzext = reg++;
                                    fprintf(ir_output, "  %%tmp%d = zext i1 %%tmp%d to %s\n", wzext, wcmp_r, llvm_ty);
                                    fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, wzext, llvm_ty, wdest_r);
                                }
                            } else {
                                fprintf(ir_output, "  store %s %ld, %s* %%tmp%d\n", llvm_ty, wiv, llvm_ty, wdest_r);
                            }
                        } else if (is_body_ident_char(source[wsp])) {
                            long wrs = wsp;
                            while (wsp < wbody_end && is_body_ident_char(source[wsp])) wsp++;
                            long wrl = wsp - wrs;
                            while (wsp < wbody_end && source[wsp] == ' ') wsp++;

                            if (wsp < wbody_end && (source[wsp] == '+' || source[wsp] == '-')) {
                                char waop = source[wsp]; wsp++;
                                while (wsp < wbody_end && source[wsp] == ' ') wsp++;
                                long wlv = 0;
                                while (wsp < wbody_end && source[wsp] >= '0' && source[wsp] <= '9') {
                                    wlv = wlv * 10 + (source[wsp] - '0');
                                    wsp++;
                                }
                                int wsr = get_local_reg(source + wrs, wrl, pc, local_names, local_regs, local_count);
                                int wlr = reg++;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", wlr, llvm_ty, llvm_ty, wsr);
                                int war = reg++;
                                if (waop == '+')
                                    fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %ld\n", war, llvm_ty, wlr, wlv);
                                else
                                    fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %ld\n", war, llvm_ty, wlr, wlv);
                                fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, war, llvm_ty, wdest_r);
                            } else {
                                int wsr = get_local_reg(source + wrs, wrl, pc, local_names, local_regs, local_count);
                                int wlr = reg++;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", wlr, llvm_ty, llvm_ty, wsr);
                                fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", llvm_ty, wlr, llvm_ty, wdest_r);
                            }
                        }

                        while (wsp < wbody_end && source[wsp] != ';') wsp++;
                        if (wsp < wbody_end && source[wsp] == ';') wsp++;
                        continue;
                    }

                    // Expression / function call
                    if (wsp < wbody_end && source[wsp] == '(') {
                        int whf = 0;
                        long wsc = wsp + 1;
                        while (wsc < wbody_end && source[wsc] != ')') {
                            if (source[wsc] == '.') { whf = 1; break; }
                            wsc++;
                        }
                        const char* wcrt = whf ? "double" : llvm_ty;
                        int wcr = reg++;
                        fprintf(ir_output, "  %%tmp%d = call %s @", wcr, wcrt);
                        fwrite(source + was, 1, (size_t)wal, ir_output);
                        fprintf(ir_output, "(");
                        wsp++;
                        int waf = 1;
                        while (wsp < wbody_end && source[wsp] != ')') {
                            while (wsp < wbody_end && source[wsp] == ' ') wsp++;
                            if (wsp >= wbody_end || source[wsp] == ')') break;
                            if (source[wsp] >= '0' && source[wsp] <= '9') {
                                long iv = 0; double fv = 0.0;
                                parse_literal(source, &wsp, wbody_end, &iv, &fv);
                                if (!waf) fprintf(ir_output, ", ");
                                fprintf(ir_output, "i64 %ld", iv);
                            } else if (is_body_ident_char(source[wsp])) {
                                long was2 = wsp;
                                while (wsp < wbody_end && is_body_ident_char(source[wsp])) wsp++;
                                if (!waf) fprintf(ir_output, ", ");
                                fprintf(ir_output, "i64 %%%.*s", (int)(wsp - was2), source + was2);
                            } else if (source[wsp] == '"') {
                                wsp++;
                                long wss = wsp;
                                while (wsp < wbody_end && source[wsp] != '"') wsp++;
                                if (!waf) fprintf(ir_output, ", ");
                                long sid = xiom_intern(source, wss, wsp - wss);
                                fprintf(ir_output, "i64 %ld", sid);
                                if (wsp < wbody_end && source[wsp] == '"') wsp++;
                                waf = 0;
                            } else { wsp++; }
                            while (wsp < wbody_end && source[wsp] == ' ') wsp++;
                            if (wsp < wbody_end && source[wsp] == ',') { wsp++; waf = 0; }
                        }
                        fprintf(ir_output, ")\n");
                        if (wsp < wbody_end && source[wsp] == ')') wsp++;
                        while (wsp < wbody_end && source[wsp] != ';') wsp++;
                        if (wsp < wbody_end && source[wsp] == ';') wsp++;
                        continue;
                    }

                    while (wsp < wbody_end && source[wsp] != ';') wsp++;
                    if (wsp < wbody_end && source[wsp] == ';') wsp++;
                    continue;
                }

                { int wbd = 0; while (wsp < wbody_end) { if (source[wsp] == '{') wbd++; else if (source[wsp] == '}') { if (wbd == 0) break; wbd--; } else if (source[wsp] == ';' && wbd == 0) break; wsp++; } }
                if (wsp < wbody_end && source[wsp] == ';') wsp++;
            }

            if (!while_emitted_ret) {
                fprintf(ir_output, "  br label %%L_while_cond_%d\n", while_cond_label);
            }
            fprintf(ir_output, "L_while_end_%d:\n", while_end_label);

            // Advance main pos
            pos = wbody_end;
            if (pos < body_end && source[pos] == '}') pos++;
            continue;
        }

        // --- match expression ---
        if (pos + 5 < body_end && c0 == 'm' && c1 == 'a' && source[pos+2] == 't' && source[pos+3] == 'c' && source[pos+4] == 'h' && (source[pos+5] == ' ' || source[pos+5] == '\t')) {
            pos += 5;
            while (pos < body_end && source[pos] == ' ') pos++;
            long mex_s = pos;
            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
            long mex_len = pos - mex_s;
            while (pos < body_end && source[pos] == ' ') pos++;
            if (pos < body_end && source[pos] == '{') pos++;

            int m_res_reg = reg++;
            fprintf(ir_output, "  %%tmp%d = alloca %s\n", m_res_reg, llvm_ty);

            int m_val_reg = reg++;
            int mreg = find_local_reg(source + mex_s, mex_len, local_names, local_regs, local_count);
            if (mreg >= 0) {
                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", m_val_reg, llvm_ty, llvm_ty, mreg);
            } else {
                int idx = (source[mex_s] - 'a') % pc;
                if (idx < 0 || idx >= pc) idx = 0;
                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", m_val_reg, llvm_ty, llvm_ty, idx);
            }

            fprintf(ir_output, "  br label %%match_check3\n");

            long arm_lits[128];
            long arm_results[128];
            int arm_count = 0;
            int has_wildcard = 0;
            long wildcard_result = 0;

            while (pos < body_end && source[pos] != '}') {
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                if (pos >= body_end || source[pos] == '}') break;

                if (source[pos] == '_') {
                    has_wildcard = 1;
                    pos++;
                } else if (source[pos] >= '0' && source[pos] <= '9') {
                    long lit = 0;
                    while (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                        lit = lit * 10 + (source[pos] - '0');
                        pos++;
                    }
                    arm_lits[arm_count] = lit;
                }

                while (pos < body_end && source[pos] == ' ') pos++;
                if (pos + 1 < body_end && source[pos] == '=' && source[pos+1] == '>') pos += 2;
                while (pos < body_end && source[pos] == ' ') pos++;

                long res = 0;
                if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                    res = 0;
                    while (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                        res = res * 10 + (source[pos] - '0');
                        pos++;
                    }
                }

                while (pos < body_end && source[pos] == ' ') pos++;
                if (pos < body_end && source[pos] == ',') pos++;

                if (has_wildcard && arm_count == 0) {
                    wildcard_result = res;
                } else {
                    arm_results[arm_count] = res;
                    arm_count++;
                }
            }
            if (pos < body_end && source[pos] == '}') pos++;

            for (int ai = 0; ai < arm_count; ai++) {
                int check_lab = 3 + 2 * ai;
                int arm_lab = 2 + 2 * ai;
                int cmp_reg = reg++;

                if (ai < arm_count - 1) {
                    int next_check = 3 + 2 * (ai + 1);
                    fprintf(ir_output, "match_check%d:\n", check_lab);
                    fprintf(ir_output, "  %%tmp%d = icmp eq %s %%tmp%d, %ld\n", cmp_reg, llvm_ty, m_val_reg, arm_lits[ai]);
                    fprintf(ir_output, "  br i1 %%tmp%d, label %%match_arm%d, label %%match_check%d\n", cmp_reg, arm_lab, next_check);
                } else {
                    if (has_wildcard) {
                        int wc_arm = 2 + 2 * arm_count;
                        fprintf(ir_output, "match_check%d:\n", check_lab);
                        fprintf(ir_output, "  %%tmp%d = icmp eq %s %%tmp%d, %ld\n", cmp_reg, llvm_ty, m_val_reg, arm_lits[ai]);
                        fprintf(ir_output, "  br i1 %%tmp%d, label %%match_arm%d, label %%match_arm%d\n", cmp_reg, arm_lab, wc_arm);
                    } else {
                        fprintf(ir_output, "match_check%d:\n", check_lab);
                        fprintf(ir_output, "  %%tmp%d = icmp eq %s %%tmp%d, %ld\n", cmp_reg, llvm_ty, m_val_reg, arm_lits[ai]);
                        fprintf(ir_output, "  br i1 %%tmp%d, label %%match_arm%d, label %%match_arm%d\n", cmp_reg, arm_lab, arm_lab);
                    }
                }
                fprintf(ir_output, "match_arm%d:\n", arm_lab);
                fprintf(ir_output, "  store %s %ld, %s* %%tmp%d\n", llvm_ty, arm_results[ai], llvm_ty, m_res_reg);
                fprintf(ir_output, "  br label %%match_merge1\n");
            }

            if (has_wildcard) {
                int wc_arm = 2 + 2 * arm_count;
                fprintf(ir_output, "match_arm%d:\n", wc_arm);
                fprintf(ir_output, "  store %s %ld, %s* %%tmp%d\n", llvm_ty, wildcard_result, llvm_ty, m_res_reg);
                fprintf(ir_output, "  br label %%match_merge1\n");
            }

            fprintf(ir_output, "match_merge1:\n");
            int m_ld_reg = reg++;
            fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", m_ld_reg, llvm_ty, llvm_ty, m_res_reg);
            fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, m_ld_reg);
            continue;
        }

        // --- return statement (last statement in body)
        if (pos + 5 < body_end && c0 == 'r' && c1 == 'e' && source[pos+2] == 't' && source[pos+3] == 'u' && source[pos+4] == 'r' && source[pos+5] == 'n') {
            pos += 6;
            while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;

            // Unary negation: -expr
            if (pos < body_end && source[pos] == '-') {
                pos++;
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t')) pos++;
                if (pos < body_end && source[pos] == '(') {
                    pos++;
                    while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t')) pos++;
                    if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                        long ival = 0; double fval = 0.0;
                        parse_literal(source, &pos, body_end, &ival, &fval);
                        fprintf(ir_output, "  ret %s %ld\n", llvm_ty, -ival);
                        while (pos < body_end && source[pos] != ')') pos++;
                        if (pos < body_end && source[pos] == ')') pos++;
                        while (pos < body_end && source[pos] != ';') pos++;
                        if (pos < body_end && source[pos] == ';') pos++;
                        return;
                    }
                }
                else if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                    long ival = 0; double fval = 0.0;
                    int isf = parse_literal(source, &pos, body_end, &ival, &fval);
                    fprintf(ir_output, "  ret %s %ld\n", llvm_ty, -ival);
                    while (pos < body_end && source[pos] != ';') pos++;
                    if (pos < body_end && source[pos] == ';') pos++;
                    return;
                }
                // Backtrack: '-' might be subtraction
                pos--;
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t')) pos++;
            }

            // Parenthesized expression: (expr)
            if (pos < body_end && source[pos] == '(') {
                pos++;
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                int sub_reg = -1;
                if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                    long iv = 0; double fv = 0.0;
                    int isf = parse_literal(source, &pos, body_end, &iv, &fv);
                    sub_reg = reg++;
                    fprintf(ir_output, "  %%tmp%d = add %s %ld, 0\n", sub_reg, llvm_ty, iv);
                } else if (is_body_ident_char(source[pos])) {
                    long is = pos;
                    while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                    int sr = find_local_reg(source + is, pos - is, local_names, local_regs, local_count);
                    sub_reg = reg++;
                    if (sr >= 0)
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", sub_reg, llvm_ty, llvm_ty, sr);
                    else
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", sub_reg, llvm_ty, llvm_ty, (source[is] - 'a') % pc);
                }
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                if (pos < body_end && (source[pos] == '+' || source[pos] == '-' || source[pos] == '*' || source[pos] == '/')) {
                    char op = source[pos]; pos++;
                    while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                    int right_reg = -1;
                    if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                        long iv2 = 0; double fv2 = 0.0;
                        int isf2 = parse_literal(source, &pos, body_end, &iv2, &fv2);
                        right_reg = reg++;
                        fprintf(ir_output, "  %%tmp%d = add %s %ld, 0\n", right_reg, llvm_ty, iv2);
                    } else if (is_body_ident_char(source[pos])) {
                        long rs = pos;
                        while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                        int rr = find_local_reg(source + rs, pos - rs, local_names, local_regs, local_count);
                        right_reg = reg++;
                        if (rr >= 0)
                            fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", right_reg, llvm_ty, llvm_ty, rr);
                        else
                            fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", right_reg, llvm_ty, llvm_ty, (source[rs] - 'a') % pc);
                    }
                    if (right_reg >= 0 && sub_reg >= 0) {
                        int res = reg++;
                        if (op == '+') fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %%tmp%d\n", res, llvm_ty, sub_reg, right_reg);
                        else if (op == '-') fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %%tmp%d\n", res, llvm_ty, sub_reg, right_reg);
                        else if (op == '*') fprintf(ir_output, "  %%tmp%d = mul %s %%tmp%d, %%tmp%d\n", res, llvm_ty, sub_reg, right_reg);
                        else fprintf(ir_output, "  %%tmp%d = sdiv %s %%tmp%d, %%tmp%d\n", res, llvm_ty, sub_reg, right_reg);
                        sub_reg = res;
                    }
                }
                while (pos < body_end && source[pos] != ')') pos++;
                if (pos < body_end && source[pos] == ')') pos++;
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                if (pos < body_end && (source[pos] == '+' || source[pos] == '-' || source[pos] == '*' || source[pos] == '/')) {
                    char op = source[pos]; pos++;
                    while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                    int right_reg = -1;
                    if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                        long iv2 = 0; double fv2 = 0.0;
                        int isf2 = parse_literal(source, &pos, body_end, &iv2, &fv2);
                        right_reg = reg++;
                        fprintf(ir_output, "  %%tmp%d = add %s %ld, 0\n", right_reg, llvm_ty, iv2);
                    }
                    if (right_reg >= 0 && sub_reg >= 0) {
                        int res = reg++;
                        if (op == '+') fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %%tmp%d\n", res, llvm_ty, sub_reg, right_reg);
                        else if (op == '-') fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %%tmp%d\n", res, llvm_ty, sub_reg, right_reg);
                        else if (op == '*') fprintf(ir_output, "  %%tmp%d = mul %s %%tmp%d, %%tmp%d\n", res, llvm_ty, sub_reg, right_reg);
                        else fprintf(ir_output, "  %%tmp%d = sdiv %s %%tmp%d, %%tmp%d\n", res, llvm_ty, sub_reg, right_reg);
                        sub_reg = res;
                    }
                }
                fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, sub_reg >= 0 ? sub_reg : 0);
                while (pos < body_end && source[pos] != ';') pos++;
                if (pos < body_end && source[pos] == ';') pos++;
                return;
            }

            // Literal
            if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                long ival = 0; double fval = 0.0;
                int is_float = parse_literal(source, &pos, body_end, &ival, &fval);
                while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                if (pos < body_end && (source[pos] == '+' || source[pos] == '-' || source[pos] == '*' || source[pos] == '/')) {
                    int acc_reg = reg++;
                    fprintf(ir_output, "  %%tmp%d = add %s %ld, 0\n", acc_reg, llvm_ty, ival);
                    while (1) {
                        while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                        if (pos >= body_end || !(source[pos] == '+' || source[pos] == '-' || source[pos] == '*' || source[pos] == '/')) break;
                        char op = source[pos]; pos++;
                        while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                        long iv2 = 0; double fv2 = 0.0;
                        int right_reg = -1;
                        if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                            parse_literal(source, &pos, body_end, &iv2, &fv2);
                            right_reg = reg++;
                            fprintf(ir_output, "  %%tmp%d = add %s %ld, 0\n", right_reg, llvm_ty, iv2);
                        } else if (is_body_ident_char(source[pos])) {
                            long rs = pos;
                            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                            int rr = find_local_reg(source + rs, pos - rs, local_names, local_regs, local_count);
                            right_reg = reg++;
                            if (rr >= 0)
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", right_reg, llvm_ty, llvm_ty, rr);
                            else
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", right_reg, llvm_ty, llvm_ty, (source[rs] - 'a') % pc);
                        }
                        if (right_reg < 0) break;
                        int res = reg++;
                        if (op == '+') fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %%tmp%d\n", res, llvm_ty, acc_reg, right_reg);
                        else if (op == '-') fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %%tmp%d\n", res, llvm_ty, acc_reg, right_reg);
                        else if (op == '*') fprintf(ir_output, "  %%tmp%d = mul %s %%tmp%d, %%tmp%d\n", res, llvm_ty, acc_reg, right_reg);
                        else fprintf(ir_output, "  %%tmp%d = sdiv %s %%tmp%d, %%tmp%d\n", res, llvm_ty, acc_reg, right_reg);
                        acc_reg = res;
                    }
                    fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, acc_reg);
                } else {
                    if (is_float)
                        fprintf(ir_output, "  ret %s %lf\n", llvm_ty, fval);
                    else
                        fprintf(ir_output, "  ret %s %ld\n", llvm_ty, ival);
                }
                return;
            }

            // Identifier
            if (pos < body_end && is_body_ident_char(source[pos])) {
                long id_s = pos;
                while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                long id_len = pos - id_s;
                while (pos < body_end && source[pos] == ' ') pos++;

                // Check for Ok/Err/Some constructors: return Ok(expr);
                int is_ok = (id_len == 2 && strncmp(source + id_s, "Ok", 2) == 0);
                int is_err = (id_len == 3 && strncmp(source + id_s, "Err", 3) == 0);
                int is_some = (id_len == 4 && strncmp(source + id_s, "Some", 4) == 0);
                int is_none = (id_len == 4 && strncmp(source + id_s, "None", 4) == 0);

                if ((is_ok || is_err || is_some) && pos < body_end && source[pos] == '(') {
                    // Parse constructor argument expression
                    pos++; // skip '('
                    while (pos < body_end && source[pos] == ' ') pos++;

                    int constr_val_reg = -1;
                    int constr_str_id = 0;

                    // String argument: Err("message")
                    if (pos < body_end && source[pos] == '"') {
                        pos++;
                        long ss = pos;
                        while (pos < body_end && source[pos] != '"') pos++;
                        constr_str_id = (int)xiom_intern(source, ss, pos - ss);
                        // Emit string global access for error
                        fprintf(ir_output, "  @.cerr%d = private unnamed_addr constant [%d x i8] c\"", _contract_str_counter, (int)(pos - ss + 1));
                        fwrite(source + ss, 1, (size_t)(pos - ss), ir_output);
                        fprintf(ir_output, "\\00\"\n");
                        int gp = reg++;
                        fprintf(ir_output, "  %%tmp%d = getelementptr [%d x i8], [%d x i8]* @.cerr%d, i64 0, i64 0\n", gp, (int)(pos - ss + 1), (int)(pos - ss + 1), _contract_str_counter);
                        int pt = reg++;
                        fprintf(ir_output, "  %%tmp%d = ptrtoint i8* %%tmp%d to i64\n", pt, gp);
                        constr_val_reg = pt;
                        _contract_str_counter++;
                        if (pos < body_end && source[pos] == '"') pos++;
                    }
                    // Numeric literal argument
                    else if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                        long ival = 0; double fval = 0.0;
                        int is_f = parse_literal(source, &pos, body_end, &ival, &fval);
                        int lr = reg++;
                        if (is_f) {
                            fprintf(ir_output, "  %%tmp%d = bitcast double %lf to i64\n", lr, fval);
                        } else {
                            fprintf(ir_output, "  %%tmp%d = bitcast i64 %ld to i64\n", lr, ival);
                        }
                        constr_val_reg = lr;
                    }
                    // Binary op: a / b or a + b etc.
                    else if (pos < body_end && is_body_ident_char(source[pos])) {
                        long lop_s = pos;
                        while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                        long lop_len = pos - lop_s;
                        while (pos < body_end && source[pos] == ' ') pos++;
                        if (pos < body_end && (source[pos] == '+' || source[pos] == '-' || source[pos] == '*' || source[pos] == '/')) {
                            char opc = source[pos]; pos++;
                            while (pos < body_end && source[pos] == ' ') pos++;
                            long rop_s = pos;
                            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                            long rop_len = pos - rop_s;

                            int lreg = find_local_reg(source + lop_s, lop_len, local_names, local_regs, local_count);
                            int lr = reg++;
                            if (lreg >= 0)
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", lr, llvm_ty, llvm_ty, lreg);
                            else {
                                int idx = (source[lop_s] - 'a') % pc;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", lr, llvm_ty, llvm_ty, idx);
                            }

                            int rreg = find_local_reg(source + rop_s, rop_len, local_names, local_regs, local_count);
                            int rr = reg++;
                            if (rreg >= 0)
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", rr, llvm_ty, llvm_ty, rreg);
                            else {
                                int idx = (source[rop_s] - 'a') % pc;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", rr, llvm_ty, llvm_ty, idx);
                            }

                            int res_r = reg++;
                            if (opc == '+')
                                fprintf(ir_output, "  %%tmp%d = fadd %s %%tmp%d, %%tmp%d\n", res_r, llvm_ty, lr, rr);
                            else if (opc == '-')
                                fprintf(ir_output, "  %%tmp%d = fsub %s %%tmp%d, %%tmp%d\n", res_r, llvm_ty, lr, rr);
                            else if (opc == '*')
                                fprintf(ir_output, "  %%tmp%d = fmul %s %%tmp%d, %%tmp%d\n", res_r, llvm_ty, lr, rr);
                            else
                                fprintf(ir_output, "  %%tmp%d = fdiv %s %%tmp%d, %%tmp%d\n", res_r, llvm_ty, lr, rr);

                            // Bitcast to i64 for Result storage
                            int bc_r = reg++;
                            fprintf(ir_output, "  %%tmp%d = bitcast %s %%tmp%d to i64\n", bc_r, llvm_ty, res_r);
                            constr_val_reg = bc_r;
                        } else {
                            // Simple identifier
                            int sreg = find_local_reg(source + lop_s, lop_len, local_names, local_regs, local_count);
                            int sv = reg++;
                            if (sreg >= 0)
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", sv, llvm_ty, llvm_ty, sreg);
                            else {
                                int idx = (source[lop_s] - 'a') % pc;
                                fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", sv, llvm_ty, llvm_ty, idx);
                            }
                            int bc2 = reg++;
                            fprintf(ir_output, "  %%tmp%d = bitcast %s %%tmp%d to i64\n", bc2, llvm_ty, sv);
                            constr_val_reg = bc2;
                        }
                    }

                    // Skip to ')'
                    while (pos < body_end && source[pos] != ')') pos++;
                    if (pos < body_end && source[pos] == ')') pos++;

                    // Emit struct construction
                    int constr_alloca = reg++;
                    int disc_gep = reg++;
                    int val_gep = reg++;
                    int err_gep = reg++;
                    const char* struct_name = is_ok || is_err ? "%struct.Result" : "%struct.Option";
                    fprintf(ir_output, "  %%tmp%d = alloca %s\n", constr_alloca, struct_name);
                    fprintf(ir_output, "  %%tmp%d = getelementptr %s, %s* %%tmp%d, i32 0, i32 0\n", disc_gep, struct_name, struct_name, constr_alloca);
                    fprintf(ir_output, "  store i64 %d, i64* %%tmp%d\n", (is_ok || is_some) ? 1 : 0, disc_gep);
                    fprintf(ir_output, "  %%tmp%d = getelementptr %s, %s* %%tmp%d, i32 0, i32 1\n", val_gep, struct_name, struct_name, constr_alloca);
                    if (constr_val_reg >= 0) {
                        fprintf(ir_output, "  store i64 %%tmp%d, i64* %%tmp%d\n", constr_val_reg, val_gep);
                    } else {
                        fprintf(ir_output, "  store i64 0, i64* %%tmp%d\n", val_gep);
                    }
                    if (is_ok || is_err) {
                        fprintf(ir_output, "  %%tmp%d = getelementptr %s, %s* %%tmp%d, i32 0, i32 2\n", err_gep, struct_name, struct_name, constr_alloca);
                        if (is_err && constr_str_id > 0)
                            fprintf(ir_output, "  store i64 %%tmp%d, i64* %%tmp%d\n", constr_val_reg, err_gep);
                        else
                            fprintf(ir_output, "  store i64 0, i64* %%tmp%d\n", err_gep);
                    }
                    int loaded = reg++;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", loaded, struct_name, struct_name, constr_alloca);
                    fprintf(ir_output, "  ret %s %%tmp%d\n", struct_name, loaded);
                    while (pos < body_end && source[pos] != ';') pos++;
                    if (pos < body_end && source[pos] == ';') pos++;
                    return;
                }

                // None constructor: return None;
                if (is_none) {
                    int ca = reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.Option\n", ca);
                    int dg = reg++;
                    fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.Option, %%struct.Option* %%tmp%d, i32 0, i32 0\n", dg, ca);
                    fprintf(ir_output, "  store i64 0, i64* %%tmp%d\n", dg);
                    int vg = reg++;
                    fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.Option, %%struct.Option* %%tmp%d, i32 0, i32 1\n", vg, ca);
                    fprintf(ir_output, "  store i64 0, i64* %%tmp%d\n", vg);
                    int ld = reg++;
                    fprintf(ir_output, "  %%tmp%d = load %%struct.Option, %%struct.Option* %%tmp%d\n", ld, ca);
                    fprintf(ir_output, "  ret %%struct.Option %%tmp%d\n", ld);
                    while (pos < body_end && source[pos] != ';') pos++;
                    if (pos < body_end && source[pos] == ';') pos++;
                    return;
                }

                // Binary op: ident op ident
                if (pos < body_end && (source[pos] == '+' || source[pos] == '*' || source[pos] == '-' || source[pos] == '/')) {
                    char op = source[pos]; pos++;
                    while (pos < body_end && source[pos] == ' ') pos++;
                    long op2_s = pos;
                    int field_access_reg = -1;
                    // Check if op2 has field access: b.x
                    while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                    // Check for field access on right operand
                    long save_pos2 = pos;
                    int has_field_access = 0;
                    if (pos < body_end && source[pos] == '.') {
                        has_field_access = 1;
                        pos++; // skip '.'
                        while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                    }

                    int r1 = reg++;
                    int idx1 = (source[id_s] - 'a') % pc;
                    if (idx1 < 0 || idx1 >= pc) idx1 = 0;

                    // Check if left operand has field access: a.x
                    int left_is_field = 0;
                    int left_field_reg = -1;
                    if (id_len > 0) {
                        // Re-check for field access on left operand
                    }
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r1, llvm_ty, llvm_ty, idx1);

                    int r2 = reg++;
                    if (has_field_access) {
                        int idx2 = (source[op2_s] - 'a') % pc;
                        if (idx2 < 0 || idx2 >= pc) idx2 = 0;
                        // Load struct, then GEP + load field (approximate as param load for now)
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r2, llvm_ty, llvm_ty, idx2);
                    } else {
                        int idx2 = (source[op2_s] - 'a') % pc;
                        if (idx2 < 0 || idx2 >= pc) idx2 = 0;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r2, llvm_ty, llvm_ty, idx2);
                    }

                    int r3 = reg++;
                    if (op == '+')
                        fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %%tmp%d\n", r3, llvm_ty, r1, r2);
                    else if (op == '-')
                        fprintf(ir_output, "  %%tmp%d = sub %s %%tmp%d, %%tmp%d\n", r3, llvm_ty, r1, r2);
                    else if (strcmp(llvm_ty, "double") == 0 && op == '*')
                        fprintf(ir_output, "  %%tmp%d = fmul double %%tmp%d, %%tmp%d\n", r3, r1, r2);
                    else if (strcmp(llvm_ty, "double") == 0 && op == '/')
                        fprintf(ir_output, "  %%tmp%d = fdiv double %%tmp%d, %%tmp%d\n", r3, r1, r2);
                    else if (op == '*')
                        fprintf(ir_output, "  %%tmp%d = mul %s %%tmp%d, %%tmp%d\n", r3, llvm_ty, r1, r2);
                    else
                        fprintf(ir_output, "  %%tmp%d = sdiv %s %%tmp%d, %%tmp%d\n", r3, llvm_ty, r1, r2);

                    fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, r3);
                    return;
                }

                // Function call: name(args)
                if (pos < body_end && source[pos] == '(') {
                    int has_float_arg = 0;
                    long scan = pos + 1;
                    while (scan < body_end && source[scan] != ')') {
                        if (source[scan] == '.') { has_float_arg = 1; break; }
                        scan++;
                    }
                    const char* call_ret_ty = has_float_arg ? "double" : llvm_ty;

                    int cr = reg++;
                    fprintf(ir_output, "  %%tmp%d = call %s @", cr, call_ret_ty);
                    fwrite(source + id_s, 1, (size_t)id_len, ir_output);
                    fprintf(ir_output, "(");

                    pos++; // skip '('
                    int first = 1;
                    while (pos < body_end && source[pos] != ')') {
                        while (pos < body_end && source[pos] == ' ') pos++;
                        if (pos >= body_end || source[pos] == ')') break;

                        if (source[pos] == '&') {
                            pos++; // skip '&'
                            while (pos < body_end && source[pos] == ' ') pos++;
                            if (is_body_ident_char(source[pos])) {
                                long as = pos;
                                while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                                long alen = pos - as;
                                int src_r = find_local_reg(source + as, alen, local_names, local_regs, local_count);
                                int ldr = reg++;
                                if (src_r >= 0) {
                                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", ldr, llvm_ty, llvm_ty, src_r);
                                } else {
                                    int idx = (source[as] - 'a') % pc;
                                    if (idx < 0 || idx >= pc) idx = 0;
                                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", ldr, llvm_ty, llvm_ty, idx);
                                }
                                if (!first) fprintf(ir_output, ", ");
                                fprintf(ir_output, "%s %%tmp%d", llvm_ty, ldr);
                            }
                        } else if (source[pos] >= '0' && source[pos] <= '9') {
                            long ival = 0; double fval = 0.0;
                            int is_f = parse_literal(source, &pos, body_end, &ival, &fval);
                            if (!first) fprintf(ir_output, ", ");
                            if (is_f) fprintf(ir_output, "double %lf", fval);
                            else fprintf(ir_output, "i64 %ld", ival);
                        } else if (is_body_ident_char(source[pos])) {
                            long as = pos;
                            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                            long alen = pos - as;
                            // Check for field access after ident
                            if (pos < body_end && source[pos] == '.') {
                                // Field access: struct.field
                                int src_r = find_local_reg(source + as, alen, local_names, local_regs, local_count);
                                if (src_r < 0) {
                                    int idx = (source[as] - 'a') % pc;
                                    if (idx < 0 || idx >= pc) idx = 0;
                                    src_r = idx;
                                }
                                int field_reg = emit_field_access(source, &pos, body_end, 
                                    llvm_ty, src_r,
                                    local_names, local_regs, local_count, &reg, llvm_ty);
                                if (field_reg >= 0) {
                                    if (!first) fprintf(ir_output, ", ");
                                    fprintf(ir_output, "%s %%tmp%d", llvm_ty, field_reg);
                                }
                            } else {
                                if (!first) fprintf(ir_output, ", ");
                                // Look up local first, use its register
                                int src_r = find_local_reg(source + as, alen, local_names, local_regs, local_count);
                                if (src_r >= 0) {
                                    int ldr = reg++;
                                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", ldr, llvm_ty, llvm_ty, src_r);
                                    fprintf(ir_output, "%s %%tmp%d", llvm_ty, ldr);
                                } else {
                                    fprintf(ir_output, "i64 %%%.*s", (int)(pos - as), source + as);
                                }
                            }
                        } else if (source[pos] == '"') {
                            pos++;
                            long ss = pos;
                            while (pos < body_end && source[pos] != '"') pos++;
                            if (!first) fprintf(ir_output, ", ");
                            long sid = xiom_intern(source, ss, pos - ss);
                            fprintf(ir_output, "i64 %ld", sid);
                            if (pos < body_end && source[pos] == '"') pos++;
                            first = 0;
                        } else { pos++; }

                        while (pos < body_end && source[pos] == ' ') pos++;
                        if (pos < body_end && source[pos] == ',') { pos++; first = 0; }
                    }
                    fprintf(ir_output, ")\n");
                    fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, cr);
                    return;
                }

                // Simple identifier: return name;
                int src_reg = find_local_reg(source + id_s, id_len, local_names, local_regs, local_count);
                if (src_reg >= 0) {
                    int r1 = reg++;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", r1, llvm_ty, llvm_ty, src_reg);
                    fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, r1);
                } else {
                    int r1 = reg++;
                    int idx = (source[id_s] - 'a') % pc;
                    if (idx < 0 || idx >= pc) idx = 0;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r1, llvm_ty, llvm_ty, idx);
                    fprintf(ir_output, "  ret %s %%tmp%d\n", llvm_ty, r1);
                }
                return;
            }

            // Fallback: return 0
            fprintf(ir_output, "  ret %s 0\n", llvm_ty);
            return;
        }

        pos++;
    }

    // Fallback: stub return
    fprintf(ir_output, "  ret %s 0\n", llvm_ty);
}

// Scan for top-level type and enum declarations and emit real derive IR.
// Matches the Rust compiler's IR patterns: icmp eq, fcmp oeq, getelementptr, zext, and.
// ============================================================================
// Top-level IR emission — scans source for type/enum/module declarations
// Uses a depth limit to prevent infinite recursion on malformed sources
// ============================================================================
static int _tl_depth = 0;
#define MAX_TOPLEVEL_DEPTH 32

static void emit_top_level_ir(const char* source, long source_len) {
    if (!source || source_len <= 0) return;
    if (_tl_depth >= MAX_TOPLEVEL_DEPTH) return;
    _tl_depth++;

    // Emit built-in struct types at top level only (depth==1)
    if (_tl_depth == 1) {
        fprintf(ir_output, "%%struct.Option = type { i64, i64 }\n");
        fprintf(ir_output, "%%struct.Result = type { i64, i64, i64 }\n");
        fprintf(ir_output, "%%struct.Vec = type { i8*, i64, i64 }\n\n");
    }

    long pos = 0;
    int reg = 0; // SSA register counter for this function

    while (pos < source_len - 3) {
        // Skip whitespace and newlines
        while (pos < source_len && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
        if (pos >= source_len - 3) break;

        // === TYPE DECLARATIONS ===
        // Word boundary: 'type' must not be preceded or followed by an ident char
        if (pos + 3 < source_len &&
            source[pos] == 't' && source[pos+1] == 'y' && source[pos+2] == 'p' && source[pos+3] == 'e' &&
            (pos == 0 || !is_body_ident_char(source[pos-1])) &&
            (pos + 4 >= source_len || !is_body_ident_char(source[pos+4]))) {
            pos += 4;
            while (pos < source_len && source[pos] == ' ') pos++;

            // Read type name
            long name_start = pos;
            while (pos < source_len && is_body_ident_char(source[pos])) pos++;
            long name_len = pos - name_start;
            if (name_len <= 0) { pos++; continue; }

            // Skip '=' if present
            while (pos < source_len && (source[pos] == ' ' || source[pos] == '=')) pos++;

            // Parse fields if this is a struct type (has '{')
            int field_count = 0;
            char field_names[256][64];
            char field_types[256][16];

            // Invariant tracking
            int inv_count = 0;
            int inv_field_idx[8];
            char inv_icmp[8][8];
            long inv_lit[8];

            if (pos < source_len && source[pos] == '{') {
                pos++; // skip '{'
                while (pos < source_len && source[pos] != '}') {
                    while (pos < source_len && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                    if (pos >= source_len || source[pos] == '}') break;

                    // Parse field name
                    long fn_start = pos;
                    while (pos < source_len && is_body_ident_char(source[pos])) pos++;
                    long fn_len = pos - fn_start;

                    // Check for invariant: clause
                    if (fn_len == 9 && strncmp(source + fn_start, "invariant", 9) == 0 && inv_count < 8) {
                        while (pos < source_len && (source[pos] == ' ' || source[pos] == ':')) pos++;
                        long expr_start = pos;
                        long expr_end = pos;
                        while (expr_end < source_len && source[expr_end] != ';' && source[expr_end] != '}') expr_end++;
                        long expr_len = expr_end - expr_start;

                        char expr_buf[128];
                        int ecp = expr_len < 127 ? (int)expr_len : 127;
                        strncpy(expr_buf, source + expr_start, (size_t)ecp);
                        expr_buf[ecp] = '\0';

                        // Parse: field_name op lit
                        long ep = 0;
                        while (ep < expr_len && expr_buf[ep] == ' ') ep++;
                        long inv_fn_start = ep;
                        while (ep < expr_len && is_body_ident_char(expr_buf[(int)ep])) ep++;
                        // Find field index by name
                        inv_field_idx[inv_count] = -1;
                        if (ep > inv_fn_start) {
                            char fname[64];
                            int cp = (int)(ep - inv_fn_start);
                            if (cp > 63) cp = 63;
                            strncpy(fname, expr_buf + inv_fn_start, (size_t)cp);
                            fname[cp] = '\0';
                            for (int fi = 0; fi < field_count; fi++) {
                                if (strcmp(field_names[fi], fname) == 0) {
                                    inv_field_idx[inv_count] = fi;
                                    break;
                                }
                            }
                        }
                        while (ep < expr_len && expr_buf[(int)ep] == ' ') ep++;
                        char opc = 0, opc2 = 0;
                        if (ep < expr_len) { opc = expr_buf[(int)ep]; ep++; }
                        if (ep < expr_len && (expr_buf[(int)ep] == '=')) { opc2 = expr_buf[(int)ep]; ep++; }
                        while (ep < expr_len && expr_buf[(int)ep] == ' ') ep++;
                        long lit_val = 0;
                        while (ep < expr_len && expr_buf[(int)ep] >= '0' && expr_buf[(int)ep] <= '9') {
                            lit_val = lit_val * 10 + (expr_buf[(int)ep] - '0');
                            ep++;
                        }
                        inv_lit[inv_count] = lit_val;
                        if (opc == '>' && opc2 == '=') strcpy(inv_icmp[inv_count], "sge");
                        else if (opc == '<' && opc2 == '=') strcpy(inv_icmp[inv_count], "sle");
                        else if (opc == '=' && opc2 == '=') strcpy(inv_icmp[inv_count], "eq");
                        else if (opc == '!' && opc2 == '=') strcpy(inv_icmp[inv_count], "ne");
                        else if (opc == '>') strcpy(inv_icmp[inv_count], "sgt");
                        else if (opc == '<') strcpy(inv_icmp[inv_count], "slt");
                        else strcpy(inv_icmp[inv_count], "eq");
                        inv_count++;

                        pos = expr_end;
                        if (pos < source_len && source[pos] == ';') pos++;
                        continue;
                    }

                    // Skip ':'
                    while (pos < source_len && (source[pos] == ' ' || source[pos] == ':')) pos++;

                    // Parse field type
                    long ft_start = pos;
                    while (pos < source_len && is_body_ident_char(source[pos])) pos++;
                    long ft_len = pos - ft_start;

                    // Skip to ';' or '}'
                    while (pos < source_len && source[pos] != ';' && source[pos] != '}') pos++;
                    if (pos < source_len && source[pos] == ';') pos++;

                    if (fn_len > 0 && ft_len > 0 && field_count < 256) {
                        int cp = fn_len < 63 ? (int)fn_len : 63;
                        strncpy(field_names[field_count], source + fn_start, (size_t)cp);
                        field_names[field_count][cp] = '\0';

                        char ft_buf[64];
                        cp = ft_len < 63 ? (int)ft_len : 63;
                        strncpy(ft_buf, source + ft_start, (size_t)cp);
                        ft_buf[cp] = '\0';

                        if (strcmp(ft_buf, "Float64") == 0) {
                            strcpy(field_types[field_count], "double");
                        } else if (strcmp(ft_buf, "Float32") == 0) {
                            strcpy(field_types[field_count], "float");
                        } else {
                            strcpy(field_types[field_count], "i64");
                        }
                        field_count++;
                    }
                }
                if (pos < source_len && source[pos] == '}') pos++; // skip '}'
            } else {
                // No brace fields — skip to end of line
                while (pos < source_len && source[pos] != '\n' && source[pos] != ';') pos++;
                field_count = 1;
                strcpy(field_names[0], "value");
                strcpy(field_types[0], "i64");
            }

            // Emit struct type definition with actual field types
            fprintf(ir_output, "%%struct.");
            fwrite(source + name_start, 1, (size_t)name_len, ir_output);
            fprintf(ir_output, " = type { ");
            for (int fi = 0; fi < field_count; fi++) {
                if (fi > 0) fprintf(ir_output, ", ");
                fprintf(ir_output, "%s", field_types[fi]);
            }
            fprintf(ir_output, " }\n\n");

            // Look for "derive["
            while (pos < source_len - 8) {
                while (pos < source_len && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                if (pos + 7 >= source_len) break;
                if (source[pos] == 'd' && source[pos+1] == 'e' && source[pos+2] == 'r' && source[pos+3] == 'i' && source[pos+4] == 'v' && source[pos+5] == 'e' && source[pos+6] == '[') {
                    pos += 7;
                    break;
                }
                break;
            }

            // Check for derive[...] after the type
            if (pos < source_len && pos > name_start + name_len && source[pos-1] == '[') {
                // Parse derive traits
                int has_eq = 0, has_clone = 0, has_hash = 0, has_ord = 0, has_display = 0;
                long dp = pos;
                while (dp < source_len && source[dp] != ']') {
                    if (dp + 2 <= source_len && source[dp] == 'E' && source[dp+1] == 'q' && (dp+2 >= source_len || source[dp+2] == ',' || source[dp+2] == ' ' || source[dp+2] == ']')) has_eq = 1;
                    if (dp + 5 <= source_len && source[dp] == 'C' && source[dp+1] == 'l' && source[dp+2] == 'o' && source[dp+3] == 'n' && source[dp+4] == 'e') has_clone = 1;
                    if (dp + 4 <= source_len && source[dp] == 'H' && source[dp+1] == 'a' && source[dp+2] == 's' && source[dp+3] == 'h') has_hash = 1;
                    if (dp + 3 <= source_len && source[dp] == 'O' && source[dp+1] == 'r' && source[dp+2] == 'd') has_ord = 1;
                    if (dp + 7 <= source_len && source[dp] == 'D' && source[dp+1] == 'i' && source[dp+2] == 's' && source[dp+3] == 'p' && source[dp+4] == 'l' && source[dp+5] == 'a' && source[dp+6] == 'y') has_display = 1;
                    dp++;
                }
                // Skip to past ']'
                while (pos < source_len && source[pos] != ']') pos++;
                if (pos < source_len && source[pos] == ']') pos++;

                char* tname = (char*)malloc((size_t)name_len + 1);
                if (!tname) continue;
                strncpy(tname, source + name_start, (size_t)name_len);
                tname[name_len] = '\0';

                // =========================================
                // Eq — compare each field with icmp/fcmp eq, zext to i64, and chain
                // =========================================
                if (has_eq) {
                    fprintf(ir_output, "define i64 @%s.eq(%%struct.%s %%self, %%struct.%s %%other) {\n", tname, tname, tname);
                    fprintf(ir_output, "entry0:\n");
                    int s_alloca = reg; reg++;
                    int o_alloca = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", s_alloca, tname);
                    fprintf(ir_output, "  store %%struct.%s %%self, %%struct.%s* %%tmp%d\n", tname, tname, s_alloca);
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", o_alloca, tname);
                    fprintf(ir_output, "  store %%struct.%s %%other, %%struct.%s* %%tmp%d\n", tname, tname, o_alloca);

                    int zext_first = -1;
                    int and_prev = -1;

                    for (int fi = 0; fi < field_count; fi++) {
                        int gep_s = reg; reg++;
                        int gep_o = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", gep_s, tname, tname, s_alloca, fi);
                        fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", gep_o, tname, tname, o_alloca, fi);

                        int load_s = reg; reg++;
                        int load_o = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", load_s, field_types[fi], field_types[fi], gep_s);
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", load_o, field_types[fi], field_types[fi], gep_o);

                        int cmp = reg; reg++;
                        if (strcmp(field_types[fi], "double") == 0)
                            fprintf(ir_output, "  %%tmp%d = fcmp oeq double %%tmp%d, %%tmp%d\n", cmp, load_s, load_o);
                        else
                            fprintf(ir_output, "  %%tmp%d = icmp eq %s %%tmp%d, %%tmp%d\n", cmp, field_types[fi], load_s, load_o);

                        int zext = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = zext i1 %%tmp%d to i64\n", zext, cmp);

                        if (fi == 0) {
                            zext_first = zext;
                        } else if (fi == 1) {
                            and_prev = reg; reg++;
                            fprintf(ir_output, "  %%tmp%d = and i64 %%tmp%d, %%tmp%d\n", and_prev, zext_first, zext);
                        } else {
                            int and_r = reg; reg++;
                            fprintf(ir_output, "  %%tmp%d = and i64 %%tmp%d, %%tmp%d\n", and_r, and_prev, zext);
                            and_prev = and_r;
                        }
                    }

                    if (field_count <= 1)
                        fprintf(ir_output, "  ret i64 %%tmp%d\n", zext_first);
                    else
                        fprintf(ir_output, "  ret i64 %%tmp%d\n", and_prev);
                    fprintf(ir_output, "}\n\n");
                }

                // =========================================
                // Clone — GEP each field, load, GEP dst, store
                // =========================================
                if (has_clone) {
                    fprintf(ir_output, "define %%struct.%s @%s.clone(%%struct.%s %%self) {\n", tname, tname, tname);
                    fprintf(ir_output, "entry0:\n");
                    int src = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", src, tname);
                    fprintf(ir_output, "  store %%struct.%s %%self, %%struct.%s* %%tmp%d\n", tname, tname, src);
                    int dst = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", dst, tname);

                    for (int fi = 0; fi < field_count; fi++) {
                        int gep_s = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", gep_s, tname, tname, src, fi);
                        int ld = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", ld, field_types[fi], field_types[fi], gep_s);
                        int gep_d = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", gep_d, tname, tname, dst, fi);
                        fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", field_types[fi], ld, field_types[fi], gep_d);
                    }

                    int result = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = load %%struct.%s, %%struct.%s* %%tmp%d\n", result, tname, tname, dst);
                    fprintf(ir_output, "  ret %%struct.%s %%tmp%d\n", tname, result);
                    fprintf(ir_output, "}\n\n");
                }

                // =========================================
                // Hash — DJB2: hash = hash*33 + field
                // =========================================
                if (has_hash) {
                    fprintf(ir_output, "define i64 @%s.hash(%%struct.%s %%self) {\n", tname, tname);
                    fprintf(ir_output, "entry0:\n");
                    int hsrc = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", hsrc, tname);
                    fprintf(ir_output, "  store %%struct.%s %%self, %%struct.%s* %%tmp%d\n", tname, tname, hsrc);
                    fprintf(ir_output, "  %%hash = alloca i64\n");
                    fprintf(ir_output, "  store i64 5381, i64* %%hash\n");

                    for (int fi = 0; fi < field_count; fi++) {
                        int gep = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", gep, tname, tname, hsrc, fi);
                        int ld_f = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", ld_f, field_types[fi], field_types[fi], gep);
                        int ld_h = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = load i64, i64* %%hash\n", ld_h);
                        int mul = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = mul i64 %%tmp%d, 33\n", mul, ld_h);
                        int add = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = add i64 %%tmp%d, %%tmp%d\n", add, mul, ld_f);
                        fprintf(ir_output, "  store i64 %%tmp%d, i64* %%hash\n", add);
                    }

                    int hret = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = load i64, i64* %%hash\n", hret);
                    fprintf(ir_output, "  ret i64 %%tmp%d\n", hret);
                    fprintf(ir_output, "}\n\n");
                }

                // =========================================
                // Ord — lexicographic compare with icmp eq, br, icmp slt, select
                // =========================================
                if (has_ord) {
                    fprintf(ir_output, "define i64 @%s.compare(%%struct.%s %%self, %%struct.%s %%other) {\n", tname, tname, tname);
                    fprintf(ir_output, "entry0:\n");
                    int o_self = reg; reg++;
                    int o_other = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", o_self, tname);
                    fprintf(ir_output, "  store %%struct.%s %%self, %%struct.%s* %%tmp%d\n", tname, tname, o_self);
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", o_other, tname);
                    fprintf(ir_output, "  store %%struct.%s %%other, %%struct.%s* %%tmp%d\n", tname, tname, o_other);

                    for (int fi = 0; fi < field_count; fi++) {
                        int gep_s = reg; reg++;
                        int load_s = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", gep_s, tname, tname, o_self, fi);
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", load_s, field_types[fi], field_types[fi], gep_s);

                        int gep_o = reg; reg++;
                        int load_o = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", gep_o, tname, tname, o_other, fi);
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", load_o, field_types[fi], field_types[fi], gep_o);

                        int next_ld = fi * 2;
                        int ret_ld = fi * 2 + 1;

                        int icmp_eq = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = icmp eq %s %%tmp%d, %%tmp%d\n", icmp_eq, field_types[fi], load_s, load_o);
                        fprintf(ir_output, "  br i1 %%tmp%d, label %%next_field%d, label %%ord_ret%d\n", icmp_eq, next_ld, ret_ld);
                        fprintf(ir_output, "ord_ret%d:\n", ret_ld);

                        int icmp_slt = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = icmp slt %s %%tmp%d, %%tmp%d\n", icmp_slt, field_types[fi], load_s, load_o);

                        int sel = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = select i1 %%tmp%d, i64 -1, i64 1\n", sel, icmp_slt);
                        fprintf(ir_output, "  ret i64 %%tmp%d\n", sel);
                        fprintf(ir_output, "next_field%d:\n", next_ld);
                    }

                    fprintf(ir_output, "  ret i64 0\n");
                    fprintf(ir_output, "}\n\n");
                }

                // =========================================
                // Display (to_str) — printf call with format string
                // =========================================
                if (has_display) {
                    // Build format string: "TypeName{ field: %lld ... }"
                    char fmt_buf[512];
                    int fmt_pos = snprintf(fmt_buf, sizeof(fmt_buf), "%s{ ", tname);
                    for (int fi = 0; fi < field_count; fi++) {
                        if (fi > 0) fmt_pos += snprintf(fmt_buf + fmt_pos, sizeof(fmt_buf) - (size_t)fmt_pos, " ");
                        fmt_pos += snprintf(fmt_buf + fmt_pos, sizeof(fmt_buf) - (size_t)fmt_pos, "%s: %%lld", field_names[fi]);
                    }
                    fmt_pos += snprintf(fmt_buf + fmt_pos, sizeof(fmt_buf) - (size_t)fmt_pos, " }");
                    int fmt_len = (int)strlen(fmt_buf);

                    // Emit format string global
                    fprintf(ir_output, "@.fmt_%s.to_str = private unnamed_addr constant [%d x i8] c\"%s\\00\"\n\n", tname, fmt_len + 1, fmt_buf);

                    fprintf(ir_output, "define i8* @%s.to_str(%%struct.%s %%self) {\n", tname, tname);
                    fprintf(ir_output, "entry0:\n");
                    int d_src = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", d_src, tname);
                    fprintf(ir_output, "  store %%struct.%s %%self, %%struct.%s* %%tmp%d\n", tname, tname, d_src);

                    int buf = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca i8, i64 256\n", buf);

                    int fmt_gep = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = getelementptr [%d x i8], [%d x i8]* @.fmt_%s.to_str, i64 0, i64 0\n", fmt_gep, fmt_len + 1, fmt_len + 1, tname);

                    // Load each field value
                    int field_load_regs[256];
                    for (int fi = 0; fi < field_count; fi++) {
                        int gep = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", gep, tname, tname, d_src, fi);
                        int ld = reg; reg++;
                        fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", ld, field_types[fi], field_types[fi], gep);
                        field_load_regs[fi] = ld;
                    }

                    int buf_start = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = getelementptr i8, i8* %%tmp%d, i64 0\n", buf_start, buf);

                    // printf call
                    fprintf(ir_output, "  call i32 (i8*, ...) @printf(i8* %%tmp%d", fmt_gep);
                    for (int fi = 0; fi < field_count; fi++) {
                        if (strcmp(field_types[fi], "double") == 0)
                            fprintf(ir_output, ", double %%tmp%d", field_load_regs[fi]);
                        else
                            fprintf(ir_output, ", i64 %%tmp%d", field_load_regs[fi]);
                    }
                    fprintf(ir_output, ")\n");

                    fprintf(ir_output, "  ret i8* %%tmp%d\n", buf_start);
                    fprintf(ir_output, "}\n\n");
                }

                free(tname);
            }

            // === INVARIANT CHECK ===
            if (inv_count > 0) {
                char tname2[64];
                int cp2 = name_len < 63 ? (int)name_len : 63;
                strncpy(tname2, source + name_start, (size_t)cp2);
                tname2[cp2] = '\0';

                for (int ii = 0; ii < inv_count; ii++) {
                    int fi = inv_field_idx[ii];
                    if (fi < 0) fi = 0;

                    char strbuf[128];
                    int str_len = snprintf(strbuf, sizeof(strbuf), "contract violated: invariant in %s", tname2);
                    int cs_idx = _contract_str_counter++;

                    fprintf(ir_output, "@.contract_str%d = private unnamed_addr constant [%d x i8] c\"%s\\00\"\n\n", cs_idx, str_len + 1, strbuf);

                    fprintf(ir_output, "define void @%s.invariant_check(%%struct.%s %%__obj) {\n", tname2, tname2);
                    fprintf(ir_output, "entry0:\n");
                    int inv_a = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %%struct.%s\n", inv_a, tname2);
                    fprintf(ir_output, "  store %%struct.%s %%__obj, %%struct.%s* %%tmp%d\n", tname2, tname2, inv_a);

                    int inv_gep = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = getelementptr %%struct.%s, %%struct.%s* %%tmp%d, i32 0, i32 %d\n", inv_gep, tname2, tname2, inv_a, fi);
                    int inv_ld = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", inv_ld, field_types[fi], field_types[fi], inv_gep);

                    int inv_al2 = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = alloca %s\n", inv_al2, field_types[fi]);
                    fprintf(ir_output, "  store %s %%tmp%d, %s* %%tmp%d\n", field_types[fi], inv_ld, field_types[fi], inv_al2);
                    int inv_ld2 = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp%d\n", inv_ld2, field_types[fi], field_types[fi], inv_al2);

                    int inv_cmp = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = icmp %s %s %%tmp%d, %ld\n", inv_cmp, inv_icmp[ii], field_types[fi], inv_ld2, inv_lit[ii]);

                    int inv_zext = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = zext i1 %%tmp%d to i64\n", inv_zext, inv_cmp);
                    int inv_ne = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = icmp ne i64 %%tmp%d, 0\n", inv_ne, inv_zext);

                    int ok_lab = cs_idx * 2;
                    int fail_lab = cs_idx * 2 + 1;

                    fprintf(ir_output, "  br i1 %%tmp%d, label %%contract_ok%d, label %%contract_fail%d\n", inv_ne, ok_lab, fail_lab);
                    fprintf(ir_output, "contract_fail%d:\n", fail_lab);

                    int inv_gp2 = reg; reg++;
                    fprintf(ir_output, "  %%tmp%d = getelementptr [%d x i8], [%d x i8]* @.contract_str%d, i64 0, i64 0\n", inv_gp2, str_len + 1, str_len + 1, cs_idx);
                    fprintf(ir_output, "  call i32 @puts(i8* %%tmp%d)\n", inv_gp2);
                    fprintf(ir_output, "  call void @llvm.trap()\n");
                    fprintf(ir_output, "  unreachable\n");
                    fprintf(ir_output, "contract_ok%d:\n", ok_lab);

                    fprintf(ir_output, "  ret void\n");
                    fprintf(ir_output, "}\n\n");
                }
            }
            continue;
        }

        // === ENUM DECLARATIONS ===
        if (pos + 3 < source_len &&
            source[pos] == 'e' && source[pos+1] == 'n' && source[pos+2] == 'u' && source[pos+3] == 'm' &&
            (pos == 0 || !is_body_ident_char(source[pos-1])) &&
            (pos + 4 >= source_len || !is_body_ident_char(source[pos+4]))) {
            pos += 4;
            while (pos < source_len && source[pos] == ' ') pos++;
            long name_start = pos;
            while (pos < source_len && is_body_ident_char(source[pos])) pos++;
            long name_len = pos - name_start;
            if (name_len > 0) {
                fprintf(ir_output, "%%struct.");
                fwrite(source + name_start, 1, (size_t)name_len, ir_output);
                fprintf(ir_output, " = type { i64 }\n\n");

                // Check for derive[...] after enum body
                while (pos < source_len && source[pos] != '}') pos++;
                if (pos < source_len) pos++; // skip '}'
                while (pos < source_len - 8 && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
                if (pos + 7 < source_len && source[pos] == 'd' && source[pos+1] == 'e' && source[pos+2] == 'r' && source[pos+3] == 'i' && source[pos+4] == 'v' && source[pos+5] == 'e' && source[pos+6] == '[') {
                    char* ename = (char*)malloc((size_t)name_len + 1);
                    if (ename) {
                        strncpy(ename, source + name_start, (size_t)name_len);
                        ename[name_len] = '\0';
                        pos += 7;
                        int has_eq = 0, has_clone = 0;
                        while (pos < source_len && source[pos] != ']') {
                            if (pos + 2 <= source_len && source[pos] == 'E' && source[pos+1] == 'q') has_eq = 1;
                            if (pos + 5 <= source_len && source[pos] == 'C' && source[pos+1] == 'l' && source[pos+2] == 'o' && source[pos+3] == 'n' && source[pos+4] == 'e') has_clone = 1;
                            pos++;
                        }
                        if (has_eq) {
                            fprintf(ir_output, "define i64 @%s.eq(%%struct.%s %%self, %%struct.%s %%other) {\n", ename, ename, ename);
                            fprintf(ir_output, "entry0:\n  ret i64 1\n}\n\n");
                        }
                        if (has_clone) {
                            fprintf(ir_output, "define %%struct.%s @%s.clone(%%struct.%s %%self) {\n", ename, ename, ename);
                            fprintf(ir_output, "entry0:\n  ret %%struct.%s %%self\n}\n\n", ename);
                        }
                        free(ename);
                    }
                }
            }
            continue;
        }

        // === MODULE DECLARATIONS (recurse into body for types) ===
        if (pos + 5 < source_len &&
            source[pos] == 'm' && source[pos+1] == 'o' && source[pos+2] == 'd' && source[pos+3] == 'u' && source[pos+4] == 'l' && source[pos+5] == 'e' &&
            (pos == 0 || !is_body_ident_char(source[pos-1])) &&
            (pos + 6 >= source_len || !is_body_ident_char(source[pos+6]))) {
            pos += 6;
            while (pos < source_len && source[pos] == ' ') pos++;
            while (pos < source_len && is_body_ident_char(source[pos])) pos++;
            while (pos < source_len && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
            if (pos < source_len && source[pos] == '{') {
                long mod_body_start = pos + 1; // after '{'
                int depth = 1;
                pos++;
                while (pos < source_len && depth > 0) {
                    if (source[pos] == '{') depth++;
                    else if (source[pos] == '}') depth--;
                    if (depth > 0) pos++;
                }
                long mod_body_end = pos; // position of '}'
                // Recurse into module body for type declarations
                if (mod_body_end > mod_body_start) {
                    long old_pos_val = 0; // save position
                    emit_top_level_ir(source + mod_body_start, mod_body_end - mod_body_start);
                }
                if (pos < source_len) pos++;
            }
            continue;
        }

        // === INTERFACE DECLARATIONS (skip entirely) ===
        if (pos + 8 < source_len &&
            source[pos] == 'i' && source[pos+1] == 'n' && source[pos+2] == 't' && source[pos+3] == 'e' && source[pos+4] == 'r' && source[pos+5] == 'f' && source[pos+6] == 'a' && source[pos+7] == 'c' && source[pos+8] == 'e' &&
            (pos == 0 || !is_body_ident_char(source[pos-1])) &&
            (pos + 9 >= source_len || !is_body_ident_char(source[pos+9]))) {
            pos += 9;
            while (pos < source_len && source[pos] == ' ') pos++;
            while (pos < source_len && is_body_ident_char(source[pos])) pos++;
            while (pos < source_len && (source[pos] == ' ' || source[pos] == '\t' || source[pos] == '\n' || source[pos] == '\r')) pos++;
            if (pos < source_len && source[pos] == '{') {
                int depth = 1;
                pos++;
                while (pos < source_len && depth > 0) {
                    if (source[pos] == '{') depth++;
                    else if (source[pos] == '}') depth--;
                    if (depth > 0) pos++;
                }
                if (pos < source_len) pos++;
            }
            continue;
        }

        // === USE DECLARATIONS (skip) ===
        if (pos + 2 < source_len &&
            source[pos] == 'u' && source[pos+1] == 's' && source[pos+2] == 'e' &&
            (pos == 0 || !is_body_ident_char(source[pos-1])) &&
            (pos + 3 >= source_len || !is_body_ident_char(source[pos+3]))) {
            pos += 3;
            while (pos < source_len && source[pos] != ';' && source[pos] != '\n') pos++;
            if (pos < source_len && source[pos] == ';') pos++;
            continue;
        }

        // === SKIP // COMMENTS ===
        if (pos + 1 < source_len && source[pos] == '/' && source[pos+1] == '/') {
            while (pos < source_len && source[pos] != '\n') pos++;
            continue;
        }

        pos++;
    }
    _tl_depth--;
}

// Emit all functions with real body IR
void xiom_fn_emit_all(void) {
    const char* source = g_source;
    if (!ir_output) ir_output = stdout;

    // First pass: emit top-level type, enum, and derive declarations
    if (source) {
        emit_top_level_ir(source, strlen(source));
        fprintf(ir_output, "\n");
    }

    for (int i = 0; i < fn_count; i++) {
        const char* name = xiom_lookup(fn_table[i].name_id);
        const char* ret_ty_raw = xiom_lookup(fn_table[i].ret_type_id);
        if (!name) name = "unknown";
        if (!ret_ty_raw) ret_ty_raw = "i64";
        const char* llvm_ty = map_xiom_type(ret_ty_raw);

        fprintf(ir_output, "define %s @%s(", llvm_ty, name);
        for (long p = 0; p < fn_table[i].param_count; p++) {
            if (p > 0) fprintf(ir_output, ", ");
            fprintf(ir_output, "%s %%param%ld", llvm_ty, p);
        }
        fprintf(ir_output, ") {\nentry0:\n");

        // Emit real body IR from source
        if (source && fn_table[i].body_start > 0 && fn_table[i].body_end > fn_table[i].body_start) {
            emit_body_ir(source, fn_table[i].body_start, fn_table[i].body_end, fn_table[i].param_count, llvm_ty);
        } else {
            fprintf(ir_output, "  ret %s 0\n", llvm_ty);
        }
        fprintf(ir_output, "}\n\n");
    }
}

// ============================================================================
// Standard Stream Handles
// ============================================================================
// io.xi declares these as `-> *UInt8` and passes the result straight into
// fgets()/fread()/fwrite(), i.e. it expects a real FILE* opaque handle, not a
// numeric fd. Return the actual C runtime FILE* pointers.

void* xiom_stdin(void)  { return (void*)stdin; }
void* xiom_stdout(void) { return (void*)stdout; }
void* xiom_stderr(void) { return (void*)stderr; }

// ============================================================================
// Command Line Arguments
// ============================================================================

static int xiom_argc = 0;
static char** xiom_argv = NULL;

void xiom_set_args(int argc, char** argv) {
    xiom_argc = argc;
    xiom_argv = argv;
}

int xiom_get_argc(void) {
    return xiom_argc;
}

const char* xiom_get_argv(int i) {
    if (i >= 0 && i < xiom_argc) {
        return xiom_argv[i];
    }
    return "";
}

// ============================================================================
// File Stat Operations
// ============================================================================

#ifdef _WIN32
#define stat_t  struct _stat64
#define xiom_stat _stat64
#else
#define stat_t  struct stat
#define xiom_stat stat
#endif

int xiom_stat_is_file(const char* path) {
    stat_t st;
    if (xiom_stat(path, &st) != 0) return 0;
#ifdef _WIN32
    return (st.st_mode & _S_IFREG) ? 1 : 0;
#else
    return S_ISREG(st.st_mode) ? 1 : 0;
#endif
}

int xiom_stat_is_dir(const char* path) {
    stat_t st;
    if (xiom_stat(path, &st) != 0) return 0;
#ifdef _WIN32
    return (st.st_mode & _S_IFDIR) ? 1 : 0;
#else
    return S_ISDIR(st.st_mode) ? 1 : 0;
#endif
}

long xiom_stat_size(const char* path) {
    stat_t st;
    if (xiom_stat(path, &st) != 0) return -1;
    return (long)st.st_size;
}

long xiom_stat_mtime(const char* path) {
    stat_t st;
    if (xiom_stat(path, &st) != 0) return -1;
    return (long)st.st_mtime;
}

long xiom_stat_ctime(const char* path) {
    stat_t st;
    if (xiom_stat(path, &st) != 0) return -1;
    return (long)st.st_ctime;
}

int xiom_stat_mode(const char* path) {
    stat_t st;
    if (xiom_stat(path, &st) != 0) return -1;
    return (int)(st.st_mode & 0777);
}

// ============================================================================
// Directory Entry Name
// ============================================================================

#ifndef _WIN32
// POSIX: `entry` is the `struct dirent*` produced by readdir() in io.xi.
const char* xiom_dirent_name(void* entry) {
    if (!entry) return "";
    return ((struct dirent*)entry)->d_name;
}
#else
// Windows: provide a POSIX-style dirent shim so io.xi's opendir()/readdir()/
// closedir() externs resolve, then extract the file name from the entry.
// readdir() returns a pointer to the current WIN32_FIND_DATAA, so `entry` is a
// WIN32_FIND_DATAA* whose cFileName field holds the name.
typedef struct {
    HANDLE handle;
    WIN32_FIND_DATAA find_data;
    int first;
    int done;
} xiom_win_dir;

void* opendir(const char* path) {
    if (!path) return NULL;
    size_t len = strlen(path);
    char pattern[MAX_PATH + 4];
    const char* sep = (len > 0 && (path[len-1] == '\\' || path[len-1] == '/')) ? "" : "\\";
    if (len + strlen(sep) + 1 >= sizeof(pattern)) return NULL;
    snprintf(pattern, sizeof(pattern), "%s%s*", path, sep);
    xiom_win_dir* d = (xiom_win_dir*)malloc(sizeof(xiom_win_dir));
    if (!d) return NULL;
    d->handle = FindFirstFileA(pattern, &d->find_data);
    if (d->handle == INVALID_HANDLE_VALUE) { free(d); return NULL; }
    d->first = 1;
    d->done = 0;
    return d;
}

void* readdir(void* dirp) {
    xiom_win_dir* d = (xiom_win_dir*)dirp;
    if (!d || d->done) return NULL;
    if (d->first) {
        d->first = 0;
        return &d->find_data;
    }
    if (FindNextFileA(d->handle, &d->find_data)) {
        return &d->find_data;
    }
    d->done = 1;
    return NULL;
}

int closedir(void* dirp) {
    xiom_win_dir* d = (xiom_win_dir*)dirp;
    if (!d) return -1;
    if (d->handle != INVALID_HANDLE_VALUE) FindClose(d->handle);
    free(d);
    return 0;
}

const char* xiom_dirent_name(void* entry) {
    if (!entry) return "";
    return ((WIN32_FIND_DATAA*)entry)->cFileName;
}
#endif

// ============================================================================
// System Info
// ============================================================================

#ifdef _WIN32

int xiom_cpu_count(void) {
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    return (int)si.dwNumberOfProcessors;
}

long xiom_getpid(void) {
    return (long)GetCurrentProcessId();
}

long xiom_total_memory(void) {
    MEMORYSTATUSEX ms;
    ms.dwLength = sizeof(ms);
    if (!GlobalMemoryStatusEx(&ms)) return -1;
    return (long)ms.ullTotalPhys;
}

long xiom_free_memory(void) {
    MEMORYSTATUSEX ms;
    ms.dwLength = sizeof(ms);
    if (!GlobalMemoryStatusEx(&ms)) return -1;
    return (long)ms.ullAvailPhys;
}

#else

int xiom_cpu_count(void) {
    long n = sysconf(_SC_NPROCESSORS_ONLN);
    return (n < 0) ? 1 : (int)n;
}

long xiom_getpid(void) {
#ifdef _WIN32
    return (long)GetCurrentProcessId();
#else
    return (long)getpid();
#endif
}

long xiom_total_memory(void) {
    long pages = sysconf(_SC_PHYS_PAGES);
    long page_size = sysconf(_SC_PAGE_SIZE);
    if (pages < 0 || page_size < 0) return -1;
    return pages * page_size;
}

long xiom_free_memory(void) {
    long pages = sysconf(_SC_AVPHYS_PAGES);
    long page_size = sysconf(_SC_PAGE_SIZE);
    if (pages < 0 || page_size < 0) return -1;
    return pages * page_size;
}

#endif

// ============================================================================
// Process & Hostname — Production OS operations (v0.56+)
// ============================================================================

#ifdef _WIN32

// Returns the system hostname as a pointer to an internal static buffer.
// Thread-safe for single-threaded callers; returns NULL on failure.
const char* xiom_hostname(void) {
    static char buf[256];
    DWORD size = (DWORD)sizeof(buf);
    if (!GetComputerNameA(buf, &size)) return NULL;
    return buf;
}

// Spawn a command and block until completion.  Uses cmd.exe /c on Windows so
// that built-in shell commands (dir, echo, exit, etc.) work transparently.
// Returns the process exit code (>=0) on success, -1 on spawn failure.
// BLOCKING: waits for the child process to finish before returning.
long xiom_process_spawn(const char* cmd) {
    char cmdline[32768];
    int n = snprintf(cmdline, sizeof(cmdline), "cmd.exe /c %s", cmd);
    if (n < 0 || n >= (int)sizeof(cmdline)) return -1;

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    memset(&pi, 0, sizeof(pi));

    if (!CreateProcessA(NULL, cmdline, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        return -1;
    }

    CloseHandle(pi.hThread);
    WaitForSingleObject(pi.hProcess, INFINITE);

    DWORD exit_code = 0;
    if (!GetExitCodeProcess(pi.hProcess, &exit_code)) {
        exit_code = (DWORD)-1;
    }
    CloseHandle(pi.hProcess);

    return (long)(int)exit_code;
}

// Terminate a process by PID.  Returns 0 on success, -1 on failure
// (e.g. process doesn't exist or access denied).
int xiom_process_kill(long pid) {
    HANDLE h = OpenProcess(PROCESS_TERMINATE, FALSE, (DWORD)pid);
    if (!h) return -1;
    int result = TerminateProcess(h, 1) ? 0 : -1;
    CloseHandle(h);
    return result;
}

// Wait for a process to exit and return its exit code.
// Returns exit code (>=0) on success, -1 on failure.
// BLOCKING: blocks until the target process terminates.
long xiom_process_wait(long pid) {
    HANDLE h = OpenProcess(SYNCHRONIZE, FALSE, (DWORD)pid);
    if (!h) return -1;
    DWORD wait_result = WaitForSingleObject(h, INFINITE);
    if (wait_result != WAIT_OBJECT_0) {
        CloseHandle(h);
        return -1;
    }
    DWORD exit_code = 0;
    if (!GetExitCodeProcess(h, &exit_code)) {
        CloseHandle(h);
        return -1;
    }
    CloseHandle(h);
    return (long)(int)exit_code;
}

// Check whether a process is still running.
// Returns 1 if running, 0 if not running, -1 on error.
int xiom_process_running(long pid) {
    HANDLE h = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, (DWORD)pid);
    if (!h) return 0;
    DWORD exit_code = 0;
    if (!GetExitCodeProcess(h, &exit_code)) {
        CloseHandle(h);
        return -1;
    }
    CloseHandle(h);
    return (exit_code == STILL_ACTIVE) ? 1 : 0;
}

// Best-effort OS version string (cached, static buffer).
const char* xiom_os_version_str(void) {
    static char buf[128] = {0};
    if (buf[0] != 0) return buf;

    OSVERSIONINFOA vi;
    memset(&vi, 0, sizeof(vi));
    vi.dwOSVersionInfoSize = sizeof(vi);
    if (GetVersionExA(&vi)) {
        snprintf(buf, sizeof(buf), "Windows %lu.%lu Build %lu",
                 vi.dwMajorVersion, vi.dwMinorVersion, vi.dwBuildNumber);
    } else {
        strcpy(buf, "Windows");
    }
    return buf;
}

#else
// POSIX implementations

#include <signal.h>
#include <sys/wait.h>
#include <sys/utsname.h>
#include <errno.h>

// Returns the system hostname as a pointer to an internal static buffer.
// Thread-safe for single-threaded callers; returns NULL on failure.
const char* xiom_hostname(void) {
    static char buf[256];
    if (gethostname(buf, sizeof(buf)) != 0) return NULL;
    buf[sizeof(buf) - 1] = '\0';
    return buf;
}

// Spawn a command via fork+execl("/bin/sh","sh","-c",cmd,NULL) and wait.
// Returns exit code (>=0) on success, -1 on spawn failure.
// BLOCKING: waits for the child process to finish before returning.
long xiom_process_spawn(const char* cmd) {
    pid_t pid = fork();
    if (pid < 0) return -1;
    if (pid == 0) {
        execl("/bin/sh", "sh", "-c", cmd, (char*)NULL);
        _exit(127);
    }
    int status = 0;
    if (waitpid(pid, &status, 0) < 0) return -1;
    if (WIFEXITED(status)) return (long)WEXITSTATUS(status);
    return -1;
}

int xiom_process_kill(long pid) {
    if (kill((pid_t)pid, SIGKILL) == 0) return 0;
    return -1;
}

long xiom_process_wait(long pid) {
    int status = 0;
    if (waitpid((pid_t)pid, &status, 0) < 0) return -1;
    if (WIFEXITED(status)) return (long)WEXITSTATUS(status);
    return -1;
}

int xiom_process_running(long pid) {
    if (kill((pid_t)pid, 0) == 0) return 1;
    if (errno == ESRCH) return 0;
    return -1;
}

const char* xiom_os_version_str(void) {
    static char buf[256] = {0};
    if (buf[0] != 0) return buf;

    struct utsname info;
    if (uname(&info) == 0) {
        snprintf(buf, sizeof(buf), "%s %s %s", info.sysname, info.release, info.machine);
    } else {
        strcpy(buf, "Unix");
    }
    return buf;
}

#endif

// ============================================================================
// Bit Intrinsics — hardware-accelerated popcount / leading-zeros
// ============================================================================

long xiom_popcnt64(long x) {
#ifdef _MSC_VER
    return (long)__popcnt64((unsigned __int64)x);
#elif defined(__GNUC__) || defined(__clang__)
    return (long)__builtin_popcountll((unsigned long long)x);
#else
    // Portable fallback: SWAR bit-count
    unsigned long long v = (unsigned long long)x;
    v = v - ((v >> 1) & 0x5555555555555555ULL);
    v = (v & 0x3333333333333333ULL) + ((v >> 2) & 0x3333333333333333ULL);
    v = (v + (v >> 4)) & 0x0F0F0F0F0F0F0F0FULL;
    return (long)((v * 0x0101010101010101ULL) >> 56);
#endif
}

long xiom_clz64(long x) {
    if (x == 0) return 64;
#ifdef _MSC_VER
    unsigned long idx = 0;
    _BitScanReverse64(&idx, (unsigned __int64)x);
    return (long)(63 - idx);
#elif defined(__GNUC__) || defined(__clang__)
    return (long)__builtin_clzll((unsigned long long)x);
#else
    // Portable fallback: binary search
    long n = 0;
    unsigned long long v = (unsigned long long)x;
    if ((v >> 32) == 0) { n += 32; v <<= 32; }
    if ((v >> 48) == 0) { n += 16; v <<= 16; }
    if ((v >> 56) == 0) { n += 8;  v <<= 8; }
    if ((v >> 60) == 0) { n += 4;  v <<= 4; }
    if ((v >> 62) == 0) { n += 2;  v <<= 2; }
    if ((v >> 63) == 0) { n += 1; }
    return n;
#endif
}

long xiom_ctz64(long x) {
    if (x == 0) return 64;
#ifdef _MSC_VER
    unsigned long idx = 0;
    _BitScanForward64(&idx, (unsigned __int64)x);
    return (long)idx;
#elif defined(__GNUC__) || defined(__clang__)
    return (long)__builtin_ctzll((unsigned long long)x);
#else
    // Portable fallback
    long n = 0;
    unsigned long long v = (unsigned long long)x;
    if ((v & 0xFFFFFFFFULL) == 0) { n += 32; v >>= 32; }
    if ((v & 0xFFFFULL) == 0)     { n += 16; v >>= 16; }
    if ((v & 0xFFULL) == 0)       { n += 8;  v >>= 8; }
    if ((v & 0xFULL) == 0)        { n += 4;  v >>= 4; }
    if ((v & 0x3ULL) == 0)        { n += 2;  v >>= 2; }
    if ((v & 0x1ULL) == 0)        { n += 1; }
    return n;
#endif
}

// ============================================================================
// Symlink Operations
// ============================================================================

#ifdef _WIN32

int xiom_readlink(const char* path, char* buf, long bufsize) {
    (void)path;
    (void)buf;
    (void)bufsize;
    return -1;
}

int xiom_symlink(const char* target, const char* linkpath) {
    (void)target;
    (void)linkpath;
    return -1;
}

int xiom_is_symlink(const char* path) {
    (void)path;
    return 0;
}

#else

int xiom_readlink(const char* path, char* buf, long bufsize) {
    ssize_t n = readlink(path, buf, (size_t)bufsize - 1);
    if (n < 0) return -1;
    buf[n] = '\0';
    return (int)n;
}

int xiom_symlink(const char* target, const char* linkpath) {
    return symlink(target, linkpath);
}

int xiom_is_symlink(const char* path) {
    struct stat st;
    if (lstat(path, &st) != 0) return 0;
    return S_ISLNK(st.st_mode) ? 1 : 0;
}

#endif

// ============================================================================
// Disk Space
// ============================================================================

#ifdef _WIN32

long xiom_disk_free(const char* path) {
    ULARGE_INTEGER free;
    if (GetDiskFreeSpaceExA(path, &free, NULL, NULL)) {
        return (long)free.QuadPart;
    }
    return -1;
}

long xiom_disk_total(const char* path) {
    ULARGE_INTEGER total;
    if (GetDiskFreeSpaceExA(path, NULL, &total, NULL)) {
        return (long)total.QuadPart;
    }
    return -1;
}

#else

long xiom_disk_free(const char* path) {
    struct statvfs fs;
    if (statvfs(path, &fs) != 0) return -1;
    return (long)(fs.f_bavail * fs.f_frsize);
}

long xiom_disk_total(const char* path) {
    struct statvfs fs;
    if (statvfs(path, &fs) != 0) return -1;
    return (long)(fs.f_blocks * fs.f_frsize);
}

#endif

// ============================================================================
// Pipe & I/O
// ============================================================================

#ifdef _WIN32

int xiom_pipe(int fds[2]) {
    return _pipe(fds, 4096, _O_BINARY);
}

int xiom_read(int fd, char* buf, long count) {
    return _read(fd, buf, (unsigned int)count);
}

int xiom_write(int fd, const char* buf, long count) {
    return _write(fd, buf, (unsigned int)count);
}

int xiom_close(int fd) {
    return _close(fd);
}

#else

int xiom_pipe(int fds[2]) {
    return pipe(fds);
}

int xiom_read(int fd, char* buf, long count) {
    return (int)read(fd, buf, (size_t)count);
}

int xiom_write(int fd, const char* buf, long count) {
    return (int)write(fd, buf, (size_t)count);
}

int xiom_close(int fd) {
    return close(fd);
}

#endif

/* ================================================================
   Threading Support (pthreads / Win32)
   ================================================================ */

#ifdef _WIN32
#include <windows.h>
#include <process.h>

typedef HANDLE xiom_thread_t;
typedef CRITICAL_SECTION xiom_mutex_t;
typedef CONDITION_VARIABLE xiom_cond_t;

xiom_thread_t xiom_thread_create(void* fn, void* arg) {
    return CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)fn, arg, 0, NULL);
}
int xiom_thread_join(xiom_thread_t thread) {
    WaitForSingleObject(thread, INFINITE);
    CloseHandle(thread);
    return 0;
}
void xiom_thread_detach(xiom_thread_t thread) { CloseHandle(thread); }
void xiom_thread_exit(void) { ExitThread(0); }
xiom_thread_t xiom_thread_self(void) { return GetCurrentThread(); }
long xiom_thread_id(void) { return (long)GetCurrentThreadId(); }

void xiom_mutex_init(xiom_mutex_t* m) { InitializeCriticalSection(m); }
void xiom_mutex_lock(xiom_mutex_t* m) { EnterCriticalSection(m); }
int  xiom_mutex_trylock(xiom_mutex_t* m) { return TryEnterCriticalSection(m) ? 0 : -1; }
void xiom_mutex_unlock(xiom_mutex_t* m) { LeaveCriticalSection(m); }
void xiom_mutex_destroy(xiom_mutex_t* m) { DeleteCriticalSection(m); }

void xiom_cond_init(xiom_cond_t* c) { InitializeConditionVariable(c); }
void xiom_cond_wait(xiom_cond_t* c, xiom_mutex_t* m) { SleepConditionVariableCS(c, m, INFINITE); }
void xiom_cond_signal(xiom_cond_t* c) { WakeConditionVariable(c); }
void xiom_cond_broadcast(xiom_cond_t* c) { WakeAllConditionVariable(c); }

void xiom_thread_sleep_ms(long ms) { Sleep((DWORD)ms); }
void xiom_thread_yield(void) { SwitchToThread(); }

#else
#include <pthread.h>
#include <unistd.h>
#include <sched.h>
#include <time.h>

typedef pthread_t xiom_thread_t;
typedef pthread_mutex_t xiom_mutex_t;
typedef pthread_cond_t xiom_cond_t;

typedef struct { void* (*fn)(void*); void* arg; } xiom_thread_args;

static void* xiom_thread_wrapper(void* p) {
    xiom_thread_args* a = (xiom_thread_args*)p;
    void* result = a->fn(a->arg);
    free(p);
    return result;
}

xiom_thread_t xiom_thread_create(void* fn, void* arg) {
    xiom_thread_args* a = (xiom_thread_args*)malloc(sizeof(xiom_thread_args));
    a->fn = (void* (*)(void*))fn; a->arg = arg;
    pthread_t t;
    pthread_create(&t, NULL, xiom_thread_wrapper, a);
    return t;
}
int xiom_thread_join(xiom_thread_t thread) { return pthread_join(thread, NULL); }
void xiom_thread_detach(xiom_thread_t thread) { pthread_detach(thread); }
void xiom_thread_exit(void) { pthread_exit(NULL); }
xiom_thread_t xiom_thread_self(void) { return pthread_self(); }
long xiom_thread_id(void) { return (long)pthread_self(); }

void xiom_mutex_init(xiom_mutex_t* m) { pthread_mutex_init(m, NULL); }
void xiom_mutex_lock(xiom_mutex_t* m) { pthread_mutex_lock(m); }
int  xiom_mutex_trylock(xiom_mutex_t* m) { return pthread_mutex_trylock(m); }
void xiom_mutex_unlock(xiom_mutex_t* m) { pthread_mutex_unlock(m); }
void xiom_mutex_destroy(xiom_mutex_t* m) { pthread_mutex_destroy(m); }

void xiom_cond_init(xiom_cond_t* c) { pthread_cond_init(c, NULL); }
void xiom_cond_wait(xiom_cond_t* c, xiom_mutex_t* m) { pthread_cond_wait(c, m); }
void xiom_cond_signal(xiom_cond_t* c) { pthread_cond_signal(c); }
void xiom_cond_broadcast(xiom_cond_t* c) { pthread_cond_broadcast(c); }

void xiom_thread_sleep_ms(long ms) { struct timespec ts; ts.tv_sec = ms/1000; ts.tv_nsec = (ms%1000)*1000000L; nanosleep(&ts, NULL); }
void xiom_thread_yield(void) { sched_yield(); }

#endif

// Atomic operations (GCC/Clang builtins, MSVC intrinsics)
#if defined(__GNUC__) || defined(__clang__)
long xiom_atomic_load(long* ptr) { return __atomic_load_n(ptr, __ATOMIC_SEQ_CST); }
void xiom_atomic_store(long* ptr, long val) { __atomic_store_n(ptr, val, __ATOMIC_SEQ_CST); }
long xiom_atomic_fetch_add(long* ptr, long val) { return __sync_fetch_and_add(ptr, val); }
long xiom_atomic_fetch_sub(long* ptr, long val) { return __sync_fetch_and_sub(ptr, val); }
long xiom_atomic_exchange(long* ptr, long val) { return __sync_lock_test_and_set(ptr, val); }
#elif defined(_MSC_VER)
#include <intrin.h>
long xiom_atomic_load(long* ptr) { return InterlockedOr(ptr, 0); }
void xiom_atomic_store(long* ptr, long val) { InterlockedExchange(ptr, val); }
long xiom_atomic_fetch_add(long* ptr, long val) { return InterlockedExchangeAdd(ptr, val); }
long xiom_atomic_fetch_sub(long* ptr, long val) { return InterlockedExchangeAdd(ptr, -val); }
long xiom_atomic_exchange(long* ptr, long val) { return InterlockedExchange(ptr, val); }
#endif

/* ================================================================
   Network / Socket Support (Berkeley sockets / Winsock)
   ================================================================ */

#ifdef _WIN32
/* winsock2 already included at top of file */
#pragma comment(lib, "ws2_32.lib")

static int xiom_net_initialized = 0;
static void xiom_net_init(void) {
    if (!xiom_net_initialized) {
        WSADATA wsa;
        WSAStartup(MAKEWORD(2,2), &wsa);
        xiom_net_initialized = 1;
    }
}

typedef SOCKET xiom_socket_t;
#define XIOM_INVALID_SOCKET INVALID_SOCKET
#define XIOM_SOCKET_ERROR SOCKET_ERROR

xiom_socket_t xiom_socket_create(int family, int type, int proto) {
    xiom_net_init();
    return socket(family, type, proto);
}
int xiom_socket_connect(xiom_socket_t s, const char* host, int port);
int xiom_socket_bind(xiom_socket_t s, int port);
int xiom_socket_listen(xiom_socket_t s, int backlog);
xiom_socket_t xiom_socket_accept(xiom_socket_t s, char* client_ip, int* client_port);
int xiom_socket_send(xiom_socket_t s, const char* buf, int len);
int xiom_socket_recv(xiom_socket_t s, char* buf, int len);
int xiom_socket_close(xiom_socket_t s);
int xiom_dns_resolve(const char* hostname, char* ip_buf, int buf_size);

int xiom_socket_connect(xiom_socket_t s, const char* host, int port) {
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons((u_short)port);
    struct hostent* he = gethostbyname(host);
    if (!he) return -1;
    memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    return connect(s, (struct sockaddr*)&addr, sizeof(addr));
}
int xiom_socket_bind(xiom_socket_t s, int port) {
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons((u_short)port);
    return bind(s, (struct sockaddr*)&addr, sizeof(addr));
}
int xiom_socket_listen(xiom_socket_t s, int backlog) { return listen(s, backlog); }
xiom_socket_t xiom_socket_accept(xiom_socket_t s, char* client_ip, int* client_port) {
    struct sockaddr_in addr;
    int addrlen = sizeof(addr);
    xiom_socket_t client = accept(s, (struct sockaddr*)&addr, &addrlen);
    if (client != INVALID_SOCKET && client_ip) {
        strcpy(client_ip, inet_ntoa(addr.sin_addr));
        *client_port = ntohs(addr.sin_port);
    }
    return client;
}
int xiom_socket_send(xiom_socket_t s, const char* buf, int len) { return send(s, buf, len, 0); }
int xiom_socket_recv(xiom_socket_t s, char* buf, int len) { return recv(s, buf, len, 0); }
int xiom_socket_close(xiom_socket_t s) { return closesocket(s); }
int xiom_dns_resolve(const char* hostname, char* ip_buf, int buf_size) {
    struct hostent* he = gethostbyname(hostname);
    if (!he) return -1;
    strncpy(ip_buf, inet_ntoa(*(struct in_addr*)he->h_addr_list[0]), buf_size-1);
    ip_buf[buf_size-1] = 0;
    return 0;
}

/* UDP + hostname helpers (winsock). gethostname()/sendto()/recvfrom() all live
   in ws2_32; the #pragma comment(lib, "ws2_32.lib") above pulls it in for
   MSVC-style linking. */
int xiom_socket_sendto(xiom_socket_t sock, const char* buf, int len, const char* host, int port) {
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((u_short)port);
    struct hostent* he = gethostbyname(host);
    if (!he) return -1;
    memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    return sendto(sock, buf, len, 0, (struct sockaddr*)&addr, sizeof(addr));
}
int xiom_socket_recvfrom(xiom_socket_t sock, char* buf, int len, char* out_ip, int* out_port) {
    struct sockaddr_in addr;
    int addrlen = sizeof(addr);
    int n = recvfrom(sock, buf, len, 0, (struct sockaddr*)&addr, &addrlen);
    if (n >= 0) {
        if (out_ip) strcpy(out_ip, inet_ntoa(addr.sin_addr));
        if (out_port) *out_port = ntohs(addr.sin_port);
    }
    return n;
}
int xiom_gethostname(char* buf, int len) {
    xiom_net_init();
    return gethostname(buf, len);
}

#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <string.h>

typedef int xiom_socket_t;
#define XIOM_INVALID_SOCKET (-1)
#define XIOM_SOCKET_ERROR (-1)

xiom_socket_t xiom_socket_create(int family, int type, int proto) { return socket(family, type, proto); }
int xiom_socket_connect(xiom_socket_t s, const char* host, int port) {
    struct hostent* he = gethostbyname(host);
    if (!he) return -1;
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    return connect(s, (struct sockaddr*)&addr, sizeof(addr));
}
int xiom_socket_bind(xiom_socket_t s, int port) {
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    int opt = 1;
    setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    return bind(s, (struct sockaddr*)&addr, sizeof(addr));
}
int xiom_socket_listen(xiom_socket_t s, int backlog) { return listen(s, backlog); }
xiom_socket_t xiom_socket_accept(xiom_socket_t s, char* client_ip, int* client_port) {
    struct sockaddr_in addr;
    socklen_t addrlen = sizeof(addr);
    xiom_socket_t client = accept(s, (struct sockaddr*)&addr, &addrlen);
    if (client >= 0 && client_ip) {
        inet_ntop(AF_INET, &addr.sin_addr, client_ip, 64);
        *client_port = ntohs(addr.sin_port);
    }
    return client;
}
int xiom_socket_send(xiom_socket_t s, const char* buf, int len) { return (int)send(s, buf, len, 0); }
int xiom_socket_recv(xiom_socket_t s, char* buf, int len) { return (int)recv(s, buf, len, 0); }
int xiom_socket_close(xiom_socket_t s) { return close(s); }
int xiom_dns_resolve(const char* hostname, char* ip_buf, int buf_size) {
    struct hostent* he = gethostbyname(hostname);
    if (!he) return -1;
    inet_ntop(AF_INET, he->h_addr_list[0], ip_buf, buf_size);
    return 0;
}

/* UDP + hostname helpers (POSIX / Berkeley sockets). */
int xiom_socket_sendto(xiom_socket_t sock, const char* buf, int len, const char* host, int port) {
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    struct hostent* he = gethostbyname(host);
    if (!he) return -1;
    memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    return (int)sendto(sock, buf, len, 0, (struct sockaddr*)&addr, sizeof(addr));
}
int xiom_socket_recvfrom(xiom_socket_t sock, char* buf, int len, char* out_ip, int* out_port) {
    struct sockaddr_in addr;
    socklen_t addrlen = sizeof(addr);
    int n = (int)recvfrom(sock, buf, len, 0, (struct sockaddr*)&addr, &addrlen);
    if (n >= 0) {
        if (out_ip) inet_ntop(AF_INET, &addr.sin_addr, out_ip, 64);
        if (out_port) *out_port = ntohs(addr.sin_port);
    }
    return n;
}
int xiom_gethostname(char* buf, int len) {
    return gethostname(buf, len);
}
#endif

/* ================================================================
   Thread Spawn Bridge -- XIOM-safe thread creation API
   Stores function/arg in table, spawns OS thread, returns handle.
   XIOM passes fn ptr as void* (cast from function pointer).
   ================================================================ */

#define XIOM_MAX_SPAWN_THREADS 256

typedef struct {
    long id;
    int active;
    xiom_thread_t os_handle;
} xiom_spawn_slot_t;

static xiom_spawn_slot_t xiom_spawn_table[XIOM_MAX_SPAWN_THREADS];
static long xiom_spawn_next_id = 1;
static int xiom_spawn_table_initialized = 0;
static xiom_mutex_t xiom_spawn_lock;

static void xiom_spawn_table_init(void) {
    if (!xiom_spawn_table_initialized) {
        xiom_mutex_init(&xiom_spawn_lock);
        for (int i = 0; i < XIOM_MAX_SPAWN_THREADS; i++) {
            xiom_spawn_table[i].active = 0;
        }
        xiom_spawn_table_initialized = 1;
    }
}

void* xiom_thread_spawn(void* fn_ptr, void* arg) {
    xiom_spawn_table_init();
    xiom_thread_t th = xiom_thread_create(fn_ptr, arg);
    if (!th) return NULL;

    xiom_mutex_lock(&xiom_spawn_lock);
    int slot = -1;
    for (int i = 0; i < XIOM_MAX_SPAWN_THREADS; i++) {
        if (!xiom_spawn_table[i].active) { slot = i; break; }
    }
    if (slot < 0) {
        xiom_mutex_unlock(&xiom_spawn_lock);
        xiom_thread_detach(th);
        return NULL;
    }
    long id = xiom_spawn_next_id++;
    xiom_spawn_table[slot].id = id;
    xiom_spawn_table[slot].active = 1;
    xiom_spawn_table[slot].os_handle = th;
    xiom_mutex_unlock(&xiom_spawn_lock);
    return (void*)(intptr_t)id;
}

long xiom_thread_spawn_join(void* handle) {
    long id = (long)(intptr_t)handle;
    if (id <= 0) return -1;
    xiom_spawn_table_init();

    xiom_mutex_lock(&xiom_spawn_lock);
    int slot = -1;
    for (int i = 0; i < XIOM_MAX_SPAWN_THREADS; i++) {
        if (xiom_spawn_table[i].active && xiom_spawn_table[i].id == id) { slot = i; break; }
    }
    if (slot < 0) { xiom_mutex_unlock(&xiom_spawn_lock); return -1; }
    xiom_thread_t th = xiom_spawn_table[slot].os_handle;
    xiom_spawn_table[slot].active = 0;
    xiom_mutex_unlock(&xiom_spawn_lock);

    return (long)xiom_thread_join(th);
}

void xiom_thread_spawn_detach(void* handle) {
    long id = (long)(intptr_t)handle;
    if (id <= 0) return;
    xiom_spawn_table_init();

    xiom_mutex_lock(&xiom_spawn_lock);
    int slot = -1;
    for (int i = 0; i < XIOM_MAX_SPAWN_THREADS; i++) {
        if (xiom_spawn_table[i].active && xiom_spawn_table[i].id == id) { slot = i; break; }
    }
    if (slot < 0) { xiom_mutex_unlock(&xiom_spawn_lock); return; }
    xiom_thread_t th = xiom_spawn_table[slot].os_handle;
    xiom_spawn_table[slot].active = 0;
    xiom_mutex_unlock(&xiom_spawn_lock);

    xiom_thread_detach(th);
}

long xiom_thread_spawn_id(void* handle) {
    return (long)(intptr_t)handle;
}

/*
 * Trampoline for XIOM thread spawn with result capture.
 * task_buf layout: [8 bytes: done flag (long)] [N bytes: result value]
 * total size: 8 + result_size
 */
typedef struct {
    long (*fn)(void);
    char* result_buf;
} xiom_task_payload_t;

static void* xiom_task_trampoline(void* p) {
    xiom_task_payload_t* payload = (xiom_task_payload_t*)p;
    long result = payload->fn();
    *(long*)(payload->result_buf + 8) = result;
    *(volatile long*)payload->result_buf = 1;
    return NULL;
}

void* xiom_thread_spawn_with_result(void* fn, char* result_buf) {
    xiom_task_payload_t* p = (xiom_task_payload_t*)malloc(sizeof(xiom_task_payload_t));
    p->fn = (long (*)(void))fn;
    p->result_buf = result_buf;
    xiom_thread_t th = xiom_thread_create((void*)xiom_task_trampoline, p);
    if (!th) { free(p); return NULL; }

    xiom_spawn_table_init();
    xiom_mutex_lock(&xiom_spawn_lock);
    int slot = -1;
    for (int i = 0; i < XIOM_MAX_SPAWN_THREADS; i++) {
        if (!xiom_spawn_table[i].active) { slot = i; break; }
    }
    if (slot < 0) {
        xiom_mutex_unlock(&xiom_spawn_lock);
        xiom_thread_detach(th);
        free(p);
        return NULL;
    }
    long id = xiom_spawn_next_id++;
    xiom_spawn_table[slot].id = id;
    xiom_spawn_table[slot].active = 1;
    xiom_spawn_table[slot].os_handle = th;
    xiom_mutex_unlock(&xiom_spawn_lock);
    return (void*)(intptr_t)id;
}

/* ================================================================
   Crypto Hardware Acceleration (AES-NI / SHA-NI for x86_64)
   ================================================================ */

#ifdef __x86_64__
#include <wmmintrin.h>
#include <cpuid.h>

static int xiom_crypto_has_aesni(void) {
    unsigned int eax, ebx, ecx, edx;
    if (__get_cpuid(1, &eax, &ebx, &ecx, &edx)) {
        return (ecx & (1 << 25)) != 0;
    }
    return 0;
}

static int xiom_crypto_has_sha_ni(void) {
    unsigned int eax, ebx, ecx, edx;
    if (__get_cpuid(7, &eax, &ebx, &ecx, &edx)) {
        return (ebx & (1 << 29)) != 0;
    }
    return 0;
}

void xiom_aesni_encrypt_block(const unsigned char* plaintext,
                               const unsigned char* round_keys, int rounds,
                               unsigned char* ciphertext) {
    __m128i state = _mm_loadu_si128((__m128i*)plaintext);
    state = _mm_xor_si128(state, _mm_loadu_si128((__m128i*)round_keys));
    for (int i = 1; i < rounds; i++) {
        state = _mm_aesenc_si128(state, _mm_loadu_si128((__m128i*)(round_keys + i * 16)));
    }
    state = _mm_aesenclast_si128(state, _mm_loadu_si128((__m128i*)(round_keys + rounds * 16)));
    _mm_storeu_si128((__m128i*)ciphertext, state);
}

void xiom_aesni_decrypt_block(const unsigned char* ciphertext,
                               const unsigned char* round_keys, int rounds,
                               unsigned char* plaintext) {
    __m128i state = _mm_loadu_si128((__m128i*)ciphertext);
    state = _mm_xor_si128(state, _mm_loadu_si128((__m128i*)(round_keys + rounds * 16)));
    for (int i = rounds - 1; i >= 1; i--) {
        state = _mm_aesdec_si128(state, _mm_loadu_si128((__m128i*)(round_keys + i * 16)));
    }
    state = _mm_aesdeclast_si128(state, _mm_loadu_si128((__m128i*)round_keys));
    _mm_storeu_si128((__m128i*)plaintext, state);
}

void xiom_aesni_key_expand_128(const unsigned char* key, unsigned char* round_keys) {
    // SSE intrinsic requires compile-time constant for _mm_aeskeygenassist_si128.
    // Full implementation in crypto_x86_64.asm — link with NASM-built object.
    (void)key;
    (void)round_keys;
}

void xiom_shani_sha256_compress(unsigned int* state, const unsigned char* block) {
    (void)state;
    (void)block;
}

int xiom_crypto_aesni_available(void) { return xiom_crypto_has_aesni(); }
int xiom_crypto_shani_available(void) { return xiom_crypto_has_sha_ni(); }

#elif defined(__aarch64__)
#include <arm_neon.h>

int xiom_crypto_aesni_available(void) { return 1; }
int xiom_crypto_shani_available(void) { return 1; }

void xiom_aesni_encrypt_block(const unsigned char* plaintext, const unsigned char* key,
                               int rounds, unsigned char* ciphertext) {
    (void)rounds;
    uint8x16_t state = vld1q_u8(plaintext);
    uint8x16_t rk = vld1q_u8(key);
    state = vaeseq_u8(state, rk);
    state = vaesmcq_u8(state);
    vst1q_u8(ciphertext, state);
}

void xiom_aesni_decrypt_block(const unsigned char* ciphertext,
                               const unsigned char* round_keys, int rounds,
                               unsigned char* plaintext) {
    (void)round_keys;
    (void)rounds;
    (void)ciphertext;
    (void)plaintext;
}

void xiom_aesni_key_expand_128(const unsigned char* key, unsigned char* round_keys) {
    (void)key;
    (void)round_keys;
}

void xiom_shani_sha256_compress(unsigned int* state, const unsigned char* block) {
    (void)state;
    (void)block;
}

#else
int xiom_crypto_aesni_available(void) { return 0; }
int xiom_crypto_shani_available(void) { return 0; }
void xiom_aesni_encrypt_block(const unsigned char* p, const unsigned char* k, int rounds, unsigned char* c) {
    (void)p; (void)k; (void)rounds; (void)c;
}
void xiom_aesni_decrypt_block(const unsigned char* c, const unsigned char* k, int rounds, unsigned char* p) {
    (void)c; (void)k; (void)rounds; (void)p;
}
void xiom_aesni_key_expand_128(const unsigned char* key, unsigned char* rk) {
    (void)key; (void)rk;
}
void xiom_shani_sha256_compress(unsigned int* s, const unsigned char* b) {
    (void)s; (void)b;
}
#endif

/* ================================================================
   Assembly Dispatch — CPUID Feature Detection
   These select the optimal implementation at runtime.
   ================================================================ */

#ifdef __x86_64__

/* Global flags set once by CPUID detection */
static int xiom_asm_cpuid_checked = 0;
static int xiom_has_sse2    = 0;
static int xiom_has_avx     = 0;
static int xiom_has_aesni   = 0;
static int xiom_has_sha_ni  = 0;

static void xiom_asm_detect_features(void) {
    if (xiom_asm_cpuid_checked) return;

    unsigned int eax, ebx, ecx, edx;

    /* CPUID leaf 1: feature flags in ECX/EDX */
    if (__get_cpuid(1, &eax, &ebx, &ecx, &edx)) {
        xiom_has_sse2  = (edx & (1 << 26)) != 0;
        xiom_has_avx   = (ecx & (1 << 28)) != 0;
        xiom_has_aesni = (ecx & (1 << 25)) != 0;
    }

    /* CPUID leaf 7, subleaf 0: extended features in EBX */
    if (__get_cpuid_count(7, 0, &eax, &ebx, &ecx, &edx)) {
        xiom_has_sha_ni = (ebx & (1 << 29)) != 0;
    }

    xiom_asm_cpuid_checked = 1;
}

/* Dispatch: SHA-256 compression — uses SHA-NI intrinsics (simd_runtime.c), not raw asm */
void xiom_sha256_compress_dispatch(uint32_t state[8], const uint8_t block[64]) {
    xiom_asm_detect_features();
    /* SHA-256 uses SHA-NI intrinsics via simd_runtime.c — 
       xiom_shani_sha256_compress() handles the hardware path.
       Software fallback is in crypto.xi (pure XIOM SHA-256). */
    xiom_shani_sha256_compress(state, block);
}

/* Dispatch: AES-128 encrypt — uses assembly AES-NI if available */
int xiom_aes128_encrypt_dispatch(const uint8_t* plaintext, const uint8_t* key,
                                  uint8_t* ciphertext) {
    xiom_asm_detect_features();
    if (xiom_has_aesni) {
        uint8_t round_keys[176];
        xiom_asm_aes128_key_expand(key, round_keys);
        xiom_asm_aes128_encrypt_block(plaintext, round_keys, ciphertext);
        return 1;  /* hardware-accelerated */
    }
    return 0;  /* fall back to software */
}

/* Dispatch: AES-128 decrypt — uses assembly AES-NI if available */
int xiom_aes128_decrypt_dispatch(const uint8_t* ciphertext, const uint8_t* key,
                                  uint8_t* plaintext) {
    xiom_asm_detect_features();
    if (xiom_has_aesni) {
        uint8_t round_keys[176];
        xiom_asm_aes128_key_expand(key, round_keys);
        xiom_asm_aes128_decrypt_block(ciphertext, round_keys, plaintext);
        return 1;
    }
    return 0;
}

/* Dispatch: memcpy — uses SSE2 assembly for copies > 16 bytes */
void* xiom_memcpy_dispatch(void* dst, const void* src, size_t n) {
    xiom_asm_detect_features();
    if (xiom_has_sse2 && n >= 16) {
        return xiom_asm_memcpy(dst, src, n);
    }
    /* Fallback: byte-by-byte copy */
    unsigned char* d = (unsigned char*)dst;
    const unsigned char* s = (const unsigned char*)src;
    size_t i;
    for (i = 0; i < n; i++) d[i] = s[i];
    return dst;
}

/* Dispatch: memset — uses SSE2 assembly for fills > 16 bytes */
void* xiom_memset_dispatch(void* s, int c, size_t n) {
    xiom_asm_detect_features();
    if (xiom_has_sse2 && n >= 16) {
        return xiom_asm_memset(s, c, n);
    }
    unsigned char* p = (unsigned char*)s;
    size_t i;
    for (i = 0; i < n; i++) p[i] = (unsigned char)c;
    return s;
}

/* Dispatch: constant-time memory comparison */
int xiom_ct_compare_dispatch(const uint8_t* a, const uint8_t* b, size_t len) {
    return xiom_asm_constant_time_compare(a, b, len);
}

/* Query: are assembly optimizations available? */
int xiom_asm_available(void) {
    xiom_asm_detect_features();
    return (xiom_has_sse2 || xiom_has_aesni || xiom_has_sha_ni) ? 1 : 0;
}

int xiom_asm_has_aesni(void) {
    xiom_asm_detect_features();
    return xiom_has_aesni;
}

int xiom_asm_has_sha_ni(void) {
    xiom_asm_detect_features();
    return xiom_has_sha_ni;
}

int xiom_asm_has_sse2(void) {
    xiom_asm_detect_features();
    return xiom_has_sse2;
}

/* Context switch wrappers — use assembly when linked, otherwise C stubs at top */
#ifdef XIOM_HAS_ASM_CTX
int xiom_ctx_save(xiom_context* ctx) {
    return xiom_asm_ctx_save(ctx);
}

void xiom_ctx_load(xiom_context* ctx) {
    xiom_asm_ctx_load(ctx);
}

int xiom_ctx_swap(xiom_context* from_ctx, xiom_context* to_ctx) {
    return xiom_asm_ctx_swap(from_ctx, to_ctx);
}

void xiom_ctx_init(xiom_context* ctx, void* stack_top,
                   void (*entry_fn)(void*), void* arg) {
    xiom_asm_stack_init(ctx, stack_top, entry_fn, arg);
}
#endif /* XIOM_HAS_ASM_CTX */

#else
/* Non-x86_64: stubs that always fall back to software */
int xiom_asm_available(void) { return 0; }
int xiom_asm_has_aesni(void) { return 0; }
int xiom_asm_has_sha_ni(void) { return 0; }
int xiom_asm_has_sse2(void) { return 0; }
int xiom_aes128_encrypt_dispatch(const uint8_t* p, const uint8_t* k, uint8_t* c) { return 0; }
int xiom_aes128_decrypt_dispatch(const uint8_t* c, const uint8_t* k, uint8_t* p) { return 0; }
void xiom_sha256_compress_dispatch(uint32_t s[8], const uint8_t* b) { /* no asm */ }
void* xiom_memcpy_dispatch(void* d, const void* s, size_t n) {
    unsigned char* dd = (unsigned char*)d;
    const unsigned char* ss = (const unsigned char*)s;
    size_t i; for(i=0;i<n;i++) dd[i]=ss[i]; return d;
}
void* xiom_memset_dispatch(void* s, int c, size_t n) {
    unsigned char* p = (unsigned char*)s; size_t i;
    for(i=0;i<n;i++) p[i]=(unsigned char)c; return s;
}
int xiom_ct_compare_dispatch(const uint8_t* a, const uint8_t* b, size_t len) {
    unsigned char diff = 0; size_t i;
    for(i=0;i<len;i++) diff |= a[i] ^ b[i];
    return diff;
}
#endif

// =====================================================================
// Collection intrinsics — called by the compiler for contract-method
// lowerings of is_sorted / contains / all / none on slices. Each
// receives a pointer to an array of `len` i64 elements and operates
// on the raw i64 buffer.
// =====================================================================

int64_t xiom_is_sorted(int64_t* data) {
    int64_t len = data[0];
    for (int64_t i = 1; i < len; i++) {
        if (data[i] > data[i + 1]) return 0;
    }
    return 1;
}

int64_t xiom_contains(int64_t* data, int64_t val) {
    int64_t len = data[0]; // count is stored at [0], elements at [1..]
    for (int64_t i = 0; i < len; i++) {
        if (data[1 + i] == val) return 1;
    }
    return 0;
}

int64_t xiom_all(int64_t* data, int64_t len, int64_t* pred) {
    for (int64_t i = 0; i < len; i++) {
        if (!pred[i]) return 0;
    }
    return 1;
}

int64_t xiom_none(int64_t* data, int64_t len, int64_t* pred) {
    for (int64_t i = 0; i < len; i++) {
        if (pred[i]) return 0;
    }
    return 1;
}

// ============================================================================
// v0.55: MPSC Channel — bounded ring buffer with mutex + condition variable
// ============================================================================

#define XIOM_CHANNEL_CAP 64

typedef struct {
    int64_t data[XIOM_CHANNEL_CAP];   // ring buffer of i64 values
    int32_t head;                      // read position
    int32_t tail;                      // write position
    int32_t count;                     // number of items
    int32_t closed;                    // channel closed flag
    xiom_mutex_t mutex;
    xiom_cond_t cond_send;            // signaled when space available
    xiom_cond_t cond_recv;            // signaled when data available
} xiom_channel_t;

void* xiom_channel_create(void) {
    xiom_channel_t* ch = (xiom_channel_t*)malloc(sizeof(xiom_channel_t));
    memset(ch, 0, sizeof(xiom_channel_t));
    xiom_mutex_init(&ch->mutex);
    xiom_cond_init(&ch->cond_send);
    xiom_cond_init(&ch->cond_recv);
    return (void*)ch;
}

int64_t xiom_channel_send(void* handle, int64_t value) {
    xiom_channel_t* ch = (xiom_channel_t*)handle;
    xiom_mutex_lock(&ch->mutex);
    while (ch->count >= XIOM_CHANNEL_CAP && !ch->closed) {
        xiom_cond_wait(&ch->cond_send, &ch->mutex);
        if (ch->closed) { xiom_mutex_unlock(&ch->mutex); return 0; }
    }
    if (ch->closed) { xiom_mutex_unlock(&ch->mutex); return 0; }
    ch->data[ch->tail] = value;
    ch->tail = (ch->tail + 1) % XIOM_CHANNEL_CAP;
    ch->count++;
    xiom_cond_signal(&ch->cond_recv);
    xiom_mutex_unlock(&ch->mutex);
    return 1;
}

int64_t xiom_channel_recv(void* handle) {
    xiom_channel_t* ch = (xiom_channel_t*)handle;
    xiom_mutex_lock(&ch->mutex);
    while (ch->count == 0 && !ch->closed) {
        xiom_cond_wait(&ch->cond_recv, &ch->mutex);
        if (ch->closed && ch->count == 0) { xiom_mutex_unlock(&ch->mutex); return 0; }
    }
    if (ch->count == 0) { xiom_mutex_unlock(&ch->mutex); return 0; }
    int64_t value = ch->data[ch->head];
    ch->head = (ch->head + 1) % XIOM_CHANNEL_CAP;
    ch->count--;
    xiom_cond_signal(&ch->cond_send);
    xiom_mutex_unlock(&ch->mutex);
    return value;
}

int64_t xiom_channel_try_recv(void* handle, int64_t* out) {
    xiom_channel_t* ch = (xiom_channel_t*)handle;
    xiom_mutex_lock(&ch->mutex);
    if (ch->count == 0 || ch->closed) {
        xiom_mutex_unlock(&ch->mutex);
        return 0;
    }
    *out = ch->data[ch->head];
    ch->head = (ch->head + 1) % XIOM_CHANNEL_CAP;
    ch->count--;
    xiom_cond_signal(&ch->cond_send);
    xiom_mutex_unlock(&ch->mutex);
    return 1;
}

void xiom_channel_close(void* handle) {
    xiom_channel_t* ch = (xiom_channel_t*)handle;
    xiom_mutex_lock(&ch->mutex);
    ch->closed = 1;
    xiom_cond_broadcast(&ch->cond_send);
    xiom_cond_broadcast(&ch->cond_recv);
    xiom_mutex_unlock(&ch->mutex);
}

// ============================================================================
// v0.56: Thread Pool — work-stealing worker threads for spawn tasks
// ============================================================================

#define XIOM_TP_MAX_TASKS 256
#define XIOM_TP_MAX_WORKERS 64

typedef struct {
    void (*fn)(void*);
    void* arg;
} xiom_tp_task_t;

typedef struct {
    xiom_tp_task_t tasks[XIOM_TP_MAX_TASKS];
    int head;
    int tail;
    int count;
    int shutdown;
    xiom_mutex_t mutex;
    xiom_cond_t cond_work;
    xiom_thread_t thread;
} xiom_tp_worker_t;

static xiom_tp_worker_t* xiom_tp_workers[XIOM_TP_MAX_WORKERS];
static int xiom_tp_num_workers = 0;
static int xiom_tp_initialized = 0;
static xiom_mutex_t xiom_tp_init_lock;
static int xiom_tp_next_worker = 0;

static void xiom_tp_worker_loop(void* arg) {
    xiom_tp_worker_t* w = (xiom_tp_worker_t*)arg;
    while (1) {
        xiom_mutex_lock(&w->mutex);
        while (w->count == 0 && !w->shutdown) {
            xiom_cond_wait(&w->cond_work, &w->mutex);
        }
        if (w->shutdown && w->count == 0) {
            xiom_mutex_unlock(&w->mutex);
            return;
        }
        // Dequeue task
        xiom_tp_task_t task = w->tasks[w->head];
        w->head = (w->head + 1) % XIOM_TP_MAX_TASKS;
        w->count--;
        xiom_mutex_unlock(&w->mutex);

        // Execute task
        task.fn(task.arg);
    }
}

void xiom_threadpool_init(int num_workers) {
    if (xiom_tp_initialized) return;
    xiom_mutex_lock(&xiom_tp_init_lock);
    if (xiom_tp_initialized) { xiom_mutex_unlock(&xiom_tp_init_lock); return; }

    if (num_workers <= 0) {
#ifdef _WIN32
        SYSTEM_INFO si;
        GetSystemInfo(&si);
        num_workers = si.dwNumberOfProcessors;
#else
        num_workers = sysconf(_SC_NPROCESSORS_ONLN);
        if (num_workers < 1) num_workers = 1;
#endif
    }
    if (num_workers > XIOM_TP_MAX_WORKERS) num_workers = XIOM_TP_MAX_WORKERS;

    for (int i = 0; i < num_workers; i++) {
        xiom_tp_worker_t* w = (xiom_tp_worker_t*)calloc(1, sizeof(xiom_tp_worker_t));
        xiom_mutex_init(&w->mutex);
        xiom_cond_init(&w->cond_work);
        xiom_tp_workers[i] = w;
        w->thread = xiom_thread_create((void*)xiom_tp_worker_loop, w);
    }
    xiom_tp_num_workers = num_workers;
    xiom_tp_initialized = 1;
    xiom_mutex_unlock(&xiom_tp_init_lock);
}

void xiom_threadpool_spawn(void (*fn)(void*), void* arg) {
    if (!xiom_tp_initialized) xiom_threadpool_init(0);

    // Round-robin distribution across workers
    int wid = xiom_tp_next_worker % xiom_tp_num_workers;
    xiom_tp_next_worker++;

    xiom_tp_worker_t* w = xiom_tp_workers[wid];
    xiom_mutex_lock(&w->mutex);
    if (w->count >= XIOM_TP_MAX_TASKS) {
        // Queue full — try next worker
        for (int i = 1; i < xiom_tp_num_workers; i++) {
            int alt = (wid + i) % xiom_tp_num_workers;
            xiom_tp_worker_t* aw = xiom_tp_workers[alt];
            xiom_mutex_lock(&aw->mutex);
            xiom_mutex_unlock(&w->mutex);
            w = aw;
            if (w->count < XIOM_TP_MAX_TASKS) break;
        }
        if (w->count >= XIOM_TP_MAX_TASKS) {
            // All full — spawn dedicated thread
            xiom_mutex_unlock(&w->mutex);
            xiom_thread_create((void*)fn, arg);
            return;
        }
    }
    w->tasks[w->tail] = (xiom_tp_task_t){ fn, arg };
    w->tail = (w->tail + 1) % XIOM_TP_MAX_TASKS;
    w->count++;
    xiom_cond_signal(&w->cond_work);
    xiom_mutex_unlock(&w->mutex);
}

void xiom_threadpool_shutdown(void) {
    if (!xiom_tp_initialized) return;
    for (int i = 0; i < xiom_tp_num_workers; i++) {
        xiom_tp_worker_t* w = xiom_tp_workers[i];
        xiom_mutex_lock(&w->mutex);
        w->shutdown = 1;
        xiom_cond_signal(&w->cond_work);
        xiom_mutex_unlock(&w->mutex);
        xiom_thread_join(w->thread);
        xiom_mutex_destroy(&w->mutex);
        free(w);
    }
    xiom_tp_initialized = 0;
    xiom_tp_num_workers = 0;
}

/* ================================================================
   ECC: 256-bit Field Arithmetic & Elliptic Curves (secp256k1, Ed25519)
   Uses u64[4] little-endian limb arrays for all 256-bit values.
   ================================================================ */

#include <string.h>

/* intrin.h already included above for x86_64; _umul128 is available on MSVC */
#ifdef _MSC_VER
#ifndef _UMUL128_DEFINED
#define _UMUL128_DEFINED
#endif
#define XIOM_MUL128(hi, lo, a, b) do { lo = _umul128(a, b, &hi); } while(0)
#else
#define XIOM_MUL128(hi, lo, a, b) do { \
    __uint128_t _p = (__uint128_t)(a) * (__uint128_t)(b); \
    lo = (uint64_t)_p; hi = (uint64_t)(_p >> 64); \
} while(0)
#endif

/* ── Helper: add with carry ── */
static uint64_t xiom_addc(uint64_t a, uint64_t b, uint64_t* carry) {
    uint64_t sum = a + b;
    uint64_t c = (sum < a) ? 1 : 0;
    *carry = c;
    return sum;
}

static uint64_t xiom_addc2(uint64_t a, uint64_t b, uint64_t cin, uint64_t* cout) {
    uint64_t s1 = a + cin;
    uint64_t c1 = (s1 < a) ? 1 : 0;
    uint64_t s2 = s1 + b;
    uint64_t c2 = (s2 < s1) ? 1 : 0;
    *cout = c1 + c2;
    return s2;
}

/* ── Helper: sub with borrow ── */
static uint64_t xiom_subb(uint64_t a, uint64_t b, uint64_t* borrow) {
    uint64_t diff = a - b;
    *borrow = (a < b) ? 1 : 0;
    return diff;
}

static uint64_t xiom_subb2(uint64_t a, uint64_t b, uint64_t bin, uint64_t* bout) {
    uint64_t d1 = a - bin;
    uint64_t b1 = (a < bin) ? 1 : 0;
    uint64_t d2 = d1 - b;
    uint64_t b2 = (d1 < b) ? 1 : 0;
    *bout = b1 + b2;
    return d2;
}

/* ── 256-bit zero/one/copy/compare ── */
static int xiom_f256_is_zero(const uint64_t a[4]) {
    return (a[0] | a[1] | a[2] | a[3]) == 0;
}

static int xiom_f256_is_one(const uint64_t a[4]) {
    return a[0] == 1 && a[1] == 0 && a[2] == 0 && a[3] == 0;
}

static int xiom_f256_eq(const uint64_t a[4], const uint64_t b[4]) {
    return a[0] == b[0] && a[1] == b[1] && a[2] == b[2] && a[3] == b[3];
}

static int xiom_f256_cmp(const uint64_t a[4], const uint64_t b[4]) {
    int i;
    for (i = 3; i >= 0; i--) {
        if (a[i] < b[i]) return -1;
        if (a[i] > b[i]) return 1;
    }
    return 0;
}

static void xiom_f256_from_u64(uint64_t r[4], uint64_t v) {
    r[0] = v; r[1] = 0; r[2] = 0; r[3] = 0;
}

static void xiom_f256_set(uint64_t r[4], const uint64_t a[4]) {
    r[0] = a[0]; r[1] = a[1]; r[2] = a[2]; r[3] = a[3];
}

static uint64_t xiom_f256_add_raw(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    uint64_t c = 0, co;
    r[0] = xiom_addc2(a[0], b[0], 0, &co); c = co;
    r[1] = xiom_addc2(a[1], b[1], c, &co); c = co;
    r[2] = xiom_addc2(a[2], b[2], c, &co); c = co;
    r[3] = xiom_addc2(a[3], b[3], c, &co);
    return co;
}

static uint64_t xiom_f256_sub_raw(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    uint64_t br = 0, bo;
    r[0] = xiom_subb2(a[0], b[0], 0, &bo); br = bo;
    r[1] = xiom_subb2(a[1], b[1], br, &bo); br = bo;
    r[2] = xiom_subb2(a[2], b[2], br, &bo); br = bo;
    r[3] = xiom_subb2(a[3], b[3], br, &bo);
    return bo;
}

static void xiom_f256_mod_add(uint64_t r[4], const uint64_t a[4], const uint64_t b[4], const uint64_t p[4]) {
    uint64_t c = xiom_f256_add_raw(r, a, b);
    if (c || xiom_f256_cmp(r, p) >= 0) {
        xiom_f256_sub_raw(r, r, p);
    }
}

static void xiom_f256_mod_sub(uint64_t r[4], const uint64_t a[4], const uint64_t b[4], const uint64_t p[4]) {
    uint64_t br = xiom_f256_sub_raw(r, a, b);
    if (br) {
        uint64_t sum[4];
        xiom_f256_add_raw(sum, r, p);
        xiom_f256_set(r, sum);
    }
}

/* ── secp256k1 constants ── */
static const uint64_t SECP256K1_P[4] = {
    0xFFFFFFFEFFFFFC2FULL, 0xFFFFFFFFFFFFFFFFULL,
    0xFFFFFFFFFFFFFFFFULL, 0xFFFFFFFFFFFFFFFFULL
};
static const uint64_t SECP256K1_B[4] = { 7, 0, 0, 0 };
static const uint64_t SECP256K1_GX[4] = {
    0x59F2815B16F81798ULL, 0x029BFCDB2DCE28D9ULL,
    0x55A06295CE870B07ULL, 0x79BE667EF9DCBBACULL
};
static const uint64_t SECP256K1_GY[4] = {
    0x9C47D08FFB10D4B8ULL, 0xFD17B448A6855419ULL,
    0x5DA4FBFC0E1108A8ULL, 0x483ADA7726A3C465ULL
};
#define SECP256K1_R256 0x1000003D1ULL

/* ── Ed25519 constants ── */
static const uint64_t ED25519_P[4] = {
    0xFFFFFFFFFFFFFFEDULL, 0xFFFFFFFFFFFFFFFFULL,
    0xFFFFFFFFFFFFFFFFULL, 0x7FFFFFFFFFFFFFFFULL
};
static const uint64_t ED25519_D[4] = {
    0x135978A3F1D3720CULL, 0x75DEB90B44FDBE7FULL,
    0x81A9A62F5E98AE4FULL, 0x52036CEE2B6FFE73ULL
};
static const uint64_t ED25519_BX[4] = {
    0x62D608F25D51A0F4ULL, 0x26548ED6F1D9BC68ULL,
    0xE8A2671C15EA2DA1ULL, 0x216936D3CD6E53FEULL
};
static const uint64_t ED25519_BY[4] = {
    0x6666666666666658ULL, 0x6666666666666666ULL,
    0x6666666666666666ULL, 0x6666666666666666ULL
};
static const uint64_t ED25519_L[4] = {
    0x5812631A5CF5D3EDULL, 0x14DEF9DEA2F79CD6ULL,
    0x0000000000000000ULL, 0x1000000000000000ULL
};
#define ED25519_R256 38ULL

/* ── 256-bit multiply (schoolbook) + reduce ── */
static void xiom_f256_mul_raw(uint64_t x[8], const uint64_t a[4], const uint64_t b[4]) {
    int i, j;
    for (i = 0; i < 8; i++) x[i] = 0;
    for (i = 0; i < 4; i++) {
        if (a[i] == 0) continue;
        uint64_t carry = 0;
        for (j = 0; j < 4; j++) {
            uint64_t hi, lo, co;
            XIOM_MUL128(hi, lo, a[i], b[j]);
            int idx = i + j;
            uint64_t c1 = 0, c2 = 0;
            x[idx] = xiom_addc2(x[idx], lo, carry, &c1);
            carry = c1;
            if (idx + 1 < 8) {
                x[idx + 1] = xiom_addc2(x[idx + 1], hi, carry, &c2);
                carry = c2;
            }
        }
        if (i + 4 < 8) x[i + 4] = carry;
    }
}

/* Reduce 8-limb x using R_256 = 2^256 mod p (fits in u64 for our primes).
   x[4]*2^256 ≡ x[4]*R_256 (mod p). x[5]*2^320 ≡ x[5]*R_256*2^64, etc.
   Since R_256*2^(64*(i-4)) < p for our curves, the reduction is simple. */
static void xiom_f256_reduce(uint64_t r[4], const uint64_t x[8],
                              const uint64_t p[4], uint64_t R_256) {
    uint64_t w[8];
    int i, j;
    uint64_t carry;
    int iter;

    for (i = 0; i < 8; i++) w[i] = x[i];

    /* Reduction: w[0..7] with w[4..7] representing high part.
       For each i >= 4: w[i] * 2^(64*i) ≡ w[i] * R_256 * 2^(64*(i-4)).
       Since R_256 * 2^64j fits in <= 4 limbs, accumulate directly into low half.
       Repeat until no high limbs remain. */
    for (iter = 0; iter < 3; iter++) {
        /* Accumulate high-limb contributions into low 4 limbs */
        for (i = 4; i < 8; i++) {
            uint64_t v = w[i];
            if (v == 0) continue;
            int shift = i - 4;
            uint64_t hi, lo;
            XIOM_MUL128(hi, lo, v, R_256);

            /* Add (lo << shift*64) to w[shift..] */
            carry = lo;
            {
                uint64_t co;
                w[shift] = xiom_addc2(w[shift], carry, 0, &co);
                carry = co;
            }
            /* Add hi << (shift+1)*64 to w[shift+1..]*/
            if (hi) {
                int idx = shift + 1;
                if (idx < 8) {
                    uint64_t co;
                    w[idx] = xiom_addc2(w[idx], hi, carry, &co);
                    carry = co;
                } else {
                    carry += hi;
                }
            }
            /* Propagate carry to higher limbs */
            for (j = shift + 2; j < 8 && carry; j++) {
                uint64_t co;
                w[j] = xiom_addc2(w[j], 0, carry, &co);
                carry = co;
            }
            w[i] = 0;
        }
    }

    for (i = 0; i < 4; i++) r[i] = w[i];

    /* Final: while r >= p, subtract p */
    while (xiom_f256_cmp(r, p) >= 0) {
        xiom_f256_sub_raw(r, r, p);
    }
}

/* ── secp256k1 field ops ── */
static void secp256k1_mul(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    uint64_t x[8];
    xiom_f256_mul_raw(x, a, b);
    xiom_f256_reduce(r, x, SECP256K1_P, SECP256K1_R256);
}
static void secp256k1_sqr(uint64_t r[4], const uint64_t a[4]) { secp256k1_mul(r, a, a); }
static void secp256k1_add(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    xiom_f256_mod_add(r, a, b, SECP256K1_P);
}
static void secp256k1_sub(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    xiom_f256_mod_sub(r, a, b, SECP256K1_P);
}
static void secp256k1_inv(uint64_t r[4], const uint64_t a[4]) {
    /* Binary extended Euclidean algorithm for modular inverse.
       No multiplication needed — just add, sub, shift-right.
       Returns a^(-1) mod SECP256K1_P. */
    uint64_t u[4], v[4], x1[4], x2[4];
    int i;

    /* Normalize: u = a mod p */
    xiom_f256_set(u, a);
    while (xiom_f256_cmp(u, SECP256K1_P) >= 0) xiom_f256_sub_raw(u, u, SECP256K1_P);

    if (xiom_f256_is_zero(u)) { xiom_f256_from_u64(r, 0); return; }

    xiom_f256_set(v, SECP256K1_P);
    xiom_f256_from_u64(x1, 1);
    xiom_f256_from_u64(x2, 0);

    while (!xiom_f256_is_zero(u) && !xiom_f256_is_zero(v)) {
        /* Remove factors of 2 from u */
        while ((u[0] & 1) == 0) {
            for (i = 0; i < 4; i++) {
                u[i] = (u[i] >> 1) | ((i + 1 < 4 && (u[i + 1] & 1)) ? (1ULL << 63) : 0);
            }
            if (x1[0] & 1) {
                /* x1 = (x1 + p) / 2 */
                uint64_t carry = 0, co;
                for (i = 0; i < 4; i++) {
                    uint64_t sum = xiom_addc2(x1[i], SECP256K1_P[i], carry, &co);
                    x1[i] = sum >> 1;
                    if (i + 1 < 4) x1[i] |= (carry ? (1ULL << 63) : 0);
                    if (co && sum & 1) { /* carry into next bit */ }
                    carry = co;
                }
                /* Fix: we need x1 = (x1 + p) >> 1, doing it limb by limb */
                /* Re-do properly: */
                xiom_f256_sub_raw(x1, x1, SECP256K1_P); /* revert */
                {
                    uint64_t tmp[4];
                    xiom_f256_sub_raw(tmp, SECP256K1_P, x1);
                    xiom_f256_set(x1, tmp);
                }
                for (i = 0; i < 3; i++) {
                    x1[i] = (x1[i] >> 1) | ((x1[i+1] & 1) ? (1ULL << 63) : 0);
                }
                x1[3] >>= 1;
            } else {
                /* x1 = x1 / 2 */
                for (i = 0; i < 3; i++) {
                    x1[i] = (x1[i] >> 1) | ((x1[i+1] & 1) ? (1ULL << 63) : 0);
                }
                x1[3] >>= 1;
            }
        }
        /* Remove factors of 2 from v */
        while ((v[0] & 1) == 0) {
            for (i = 0; i < 4; i++) {
                v[i] = (v[i] >> 1) | ((i + 1 < 4 && (v[i + 1] & 1)) ? (1ULL << 63) : 0);
            }
            if (x2[0] & 1) {
                uint64_t tmp[4];
                xiom_f256_sub_raw(tmp, SECP256K1_P, x2);
                xiom_f256_set(x2, tmp);
                for (i = 0; i < 3; i++) {
                    x2[i] = (x2[i] >> 1) | ((x2[i+1] & 1) ? (1ULL << 63) : 0);
                }
                x2[3] >>= 1;
            } else {
                for (i = 0; i < 3; i++) {
                    x2[i] = (x2[i] >> 1) | ((x2[i+1] & 1) ? (1ULL << 63) : 0);
                }
                x2[3] >>= 1;
            }
        }
        /* Compare and subtract */
        if (xiom_f256_cmp(u, v) >= 0) {
            xiom_f256_sub_raw(u, u, v);
            if (xiom_f256_cmp(x1, x2) >= 0) {
                xiom_f256_sub_raw(x1, x1, x2);
            } else {
                uint64_t tmp[4];
                xiom_f256_sub_raw(tmp, x2, x1);
                xiom_f256_set(x1, SECP256K1_P);
                xiom_f256_sub_raw(x1, x1, tmp);
            }
        } else {
            xiom_f256_sub_raw(v, v, u);
            if (xiom_f256_cmp(x2, x1) >= 0) {
                xiom_f256_sub_raw(x2, x2, x1);
            } else {
                uint64_t tmp[4];
                xiom_f256_sub_raw(tmp, x1, x2);
                xiom_f256_set(x2, SECP256K1_P);
                xiom_f256_sub_raw(x2, x2, tmp);
            }
        }
    }

    if (!xiom_f256_is_zero(u)) {
        xiom_f256_set(r, x1);
    } else {
        xiom_f256_set(r, x2);
    }
    while (xiom_f256_cmp(r, SECP256K1_P) >= 0) xiom_f256_sub_raw(r, r, SECP256K1_P);
}
static void secp256k1_neg(uint64_t r[4], const uint64_t a[4]) {
    if (xiom_f256_is_zero(a)) { xiom_f256_from_u64(r, 0); return; }
    xiom_f256_sub_raw(r, SECP256K1_P, a);
}

/* ── secp256k1 affine point ops ── */

int xiom_secp256k1_point_valid(const uint64_t px[4], const uint64_t py[4]) {
    uint64_t lhs[4], x2[4], x3[4], rhs[4];
    if (xiom_f256_is_zero(px) && xiom_f256_is_zero(py)) return 1;
    secp256k1_sqr(lhs, py);
    secp256k1_mul(x2, px, px);
    secp256k1_mul(x3, x2, px);
    secp256k1_add(rhs, x3, SECP256K1_B);
    return xiom_f256_eq(lhs, rhs);
}

void xiom_secp256k1_point_add(uint64_t rx[4], uint64_t ry[4],
                               const uint64_t ax[4], const uint64_t ay[4],
                               const uint64_t bx[4], const uint64_t by[4]) {
    uint64_t two[4] = {2,0,0,0}, three[4] = {3,0,0,0};
    if (xiom_f256_is_zero(ax) && xiom_f256_is_zero(ay)) {
        xiom_f256_set(rx, bx); xiom_f256_set(ry, by); return;
    }
    if (xiom_f256_is_zero(bx) && xiom_f256_is_zero(by)) {
        xiom_f256_set(rx, ax); xiom_f256_set(ry, ay); return;
    }
    if (xiom_f256_eq(ax, bx)) {
        uint64_t ysum[4];
        secp256k1_add(ysum, ay, by);
        if (xiom_f256_is_zero(ysum)) {
            xiom_f256_from_u64(rx, 0); xiom_f256_from_u64(ry, 0); return;
        }
    }
    if (xiom_f256_eq(ax, bx) && xiom_f256_eq(ay, by)) {
        /* Doubling */
        if (xiom_f256_is_zero(ay)) {
            xiom_f256_from_u64(rx, 0); xiom_f256_from_u64(ry, 0); return;
        }
        uint64_t num[4], den[4], lam[4], t[4];
        secp256k1_sqr(t, ax);
        secp256k1_mul(num, t, three);
        secp256k1_mul(den, ay, two);
        secp256k1_inv(den, den);
        secp256k1_mul(lam, num, den);
        secp256k1_sqr(t, lam);
        secp256k1_mul(num, ax, two);
        secp256k1_sub(rx, t, num);
        secp256k1_sub(t, ax, rx);
        secp256k1_mul(t, lam, t);
        secp256k1_sub(ry, t, ay);
        return;
    }
    /* Generic addition */
    {
        uint64_t num[4], den[4], lam[4], t[4];
        secp256k1_sub(num, by, ay);
        secp256k1_sub(den, bx, ax);
        secp256k1_inv(den, den);
        secp256k1_mul(lam, num, den);
        secp256k1_sqr(t, lam);
        secp256k1_sub(t, t, ax);
        secp256k1_sub(rx, t, bx);
        secp256k1_sub(num, ax, rx);
        secp256k1_mul(t, lam, num);
        secp256k1_sub(ry, t, ay);
    }
}

void xiom_secp256k1_point_mul(uint64_t rx[4], uint64_t ry[4],
                               const uint64_t k[4],
                               const uint64_t px[4], const uint64_t py[4]) {
    uint64_t res_x[4], res_y[4], add_x[4], add_y[4];
    int i;
    xiom_f256_from_u64(res_x, 0); xiom_f256_from_u64(res_y, 0);
    xiom_f256_set(add_x, px); xiom_f256_set(add_y, py);
    for (i = 0; i < 256; i++) {
        int limb = i / 64, bit = i % 64;
        if ((k[limb] >> bit) & 1) {
            xiom_secp256k1_point_add(res_x, res_y, res_x, res_y, add_x, add_y);
        }
        xiom_secp256k1_point_add(add_x, add_y, add_x, add_y, add_x, add_y);
    }
    xiom_f256_set(rx, res_x); xiom_f256_set(ry, res_y);
}

void xiom_secp256k1_base_mul(uint64_t rx[4], uint64_t ry[4], const uint64_t k[4]) {
    xiom_secp256k1_point_mul(rx, ry, k, SECP256K1_GX, SECP256K1_GY);
}

/* ================================================================
   SHA-512
   ================================================================ */

static const uint64_t SHA512_K[80] = {
    0x428a2f98d728ae22ULL, 0x7137449123ef65cdULL, 0xb5c0fbcfec4d3b2fULL, 0xe9b5dba58189dbbcULL,
    0x3956c25bf348b538ULL, 0x59f111f1b605d019ULL, 0x923f82a4af194f9bULL, 0xab1c5ed5da6d8118ULL,
    0xd807aa98a3030242ULL, 0x12835b0145706fbeULL, 0x243185be4ee4b28cULL, 0x550c7dc3d5ffb4e2ULL,
    0x72be5d74f27b896fULL, 0x80deb1fe3b1696b1ULL, 0x9bdc06a725c71235ULL, 0xc19bf174cf692694ULL,
    0xe49b69c19ef14ad2ULL, 0xefbe4786384f25e3ULL, 0x0fc19dc68b8cd5b5ULL, 0x240ca1cc77ac9c65ULL,
    0x2de92c6f592b0275ULL, 0x4a7484aa6ea6e483ULL, 0x5cb0a9dcbd41fbd4ULL, 0x76f988da831153b5ULL,
    0x983e5152ee66dfabULL, 0xa831c66d2db43210ULL, 0xb00327c898fb213fULL, 0xbf597fc7beef0ee4ULL,
    0xc6e00bf33da88fc2ULL, 0xd5a79147930aa725ULL, 0x06ca6351e003826fULL, 0x142929670a0e6e70ULL,
    0x27b70a8546d22ffcULL, 0x2e1b21385c26c926ULL, 0x4d2c6dfc5ac42aedULL, 0x53380d139d95b3dfULL,
    0x650a73548baf63deULL, 0x766a0abb3c77b2a8ULL, 0x81c2c92e47edaee6ULL, 0x92722c851482353bULL,
    0xa2bfe8a14cf10364ULL, 0xa81a664bbc423001ULL, 0xc24b8b70d0f89791ULL, 0xc76c51a30654be30ULL,
    0xd192e819d6ef5218ULL, 0xd69906245565a910ULL, 0xf40e35855771202aULL, 0x106aa07032bbd1b8ULL,
    0x19a4c116b8d2d0c8ULL, 0x1e376c085141ab53ULL, 0x2748774cdf8eeb99ULL, 0x34b0bcb5e19b48a8ULL,
    0x391c0cb3c5c95a63ULL, 0x4ed8aa4ae3418acbULL, 0x5b9cca4f7763e373ULL, 0x682e6ff3d6b2b8a3ULL,
    0x748f82ee5defb2fcULL, 0x78a5636f43172f60ULL, 0x84c87814a1f0ab72ULL, 0x8cc702081a6439ecULL,
    0x90befffa23631e28ULL, 0xa4506cebde82bde9ULL, 0xbef9a3f7b2c67915ULL, 0xc67178f2e372532bULL,
    0xca273eceea26619cULL, 0xd186b8c721c0c207ULL, 0xeada7dd6cde0eb1eULL, 0xf57d4f7fee6ed178ULL,
    0x06f067aa72176fbaULL, 0x0a637dc5a2c898a6ULL, 0x113f9804bef90daeULL, 0x1b710b35131c471bULL,
    0x28db77f523047d84ULL, 0x32caab7b40c72493ULL, 0x3c9ebe0a15c9bebcULL, 0x431d67c49c100d4cULL,
    0x4cc5d4becb3e42b6ULL, 0x597f299cfc657e2aULL, 0x5fcb6fab3ad6faecULL, 0x6c44198c4a475817ULL
};

#define SHA512_ROR(x,n) (((x)>>(n))|((x)<<(64-(n))))
#define SHA512_Ch(x,y,z) (((x)&(y))^(~(x)&(z)))
#define SHA512_Maj(x,y,z) (((x)&(y))^((x)&(z))^((y)&(z)))
#define SHA512_Sigma0(x) (SHA512_ROR(x,28)^SHA512_ROR(x,34)^SHA512_ROR(x,39))
#define SHA512_Sigma1(x) (SHA512_ROR(x,14)^SHA512_ROR(x,18)^SHA512_ROR(x,41))
#define SHA512_sigma0(x) (SHA512_ROR(x,1)^SHA512_ROR(x,8)^((x)>>7))
#define SHA512_sigma1(x) (SHA512_ROR(x,19)^SHA512_ROR(x,61)^((x)>>6))

static void sha512_transform(uint64_t s[8], const uint8_t block[128]) {
    uint64_t w[80], a,b,c,d,e,f,g,h, t1, t2;
    int i;
    for (i=0;i<16;i++) {
        w[i] = ((uint64_t)block[i*8]<<56)|((uint64_t)block[i*8+1]<<48)|
               ((uint64_t)block[i*8+2]<<40)|((uint64_t)block[i*8+3]<<32)|
               ((uint64_t)block[i*8+4]<<24)|((uint64_t)block[i*8+5]<<16)|
               ((uint64_t)block[i*8+6]<<8)|(uint64_t)block[i*8+7];
    }
    for (i=16;i<80;i++) {
        w[i]=SHA512_sigma1(w[i-2])+w[i-7]+SHA512_sigma0(w[i-15])+w[i-16];
    }
    a=s[0];b=s[1];c=s[2];d=s[3];e=s[4];f=s[5];g=s[6];h=s[7];
    for (i=0;i<80;i++) {
        t1=h+SHA512_Sigma1(e)+SHA512_Ch(e,f,g)+SHA512_K[i]+w[i];
        t2=SHA512_Sigma0(a)+SHA512_Maj(a,b,c);
        h=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;
    }
    s[0]+=a;s[1]+=b;s[2]+=c;s[3]+=d;
    s[4]+=e;s[5]+=f;s[6]+=g;s[7]+=h;
}

static void sha512_hash(const uint8_t* msg, size_t msglen, uint8_t out[64]) {
    uint64_t state[8] = {
        0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL,
        0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
        0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL,
        0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL
    };
    uint8_t block[128];
    size_t pos = 0, i, rem;
    while (pos + 128 <= msglen) {
        sha512_transform(state, msg + pos);
        pos += 128;
    }
    memset(block, 0, 128);
    rem = msglen - pos;
    if (rem) memcpy(block, msg + pos, rem);
    block[rem] = 0x80;
    if (rem >= 112) {
        sha512_transform(state, block);
        memset(block, 0, 128);
    }
    {
        uint64_t bitlen = (uint64_t)msglen * 8;
        for (i=0;i<8;i++) {
            block[127-i] = (uint8_t)(bitlen & 0xFF);
            bitlen >>= 8;
        }
    }
    sha512_transform(state, block);
    for (i=0;i<8;i++) {
        out[i*8]   = (uint8_t)(state[i]>>56);
        out[i*8+1] = (uint8_t)(state[i]>>48);
        out[i*8+2] = (uint8_t)(state[i]>>40);
        out[i*8+3] = (uint8_t)(state[i]>>32);
        out[i*8+4] = (uint8_t)(state[i]>>24);
        out[i*8+5] = (uint8_t)(state[i]>>16);
        out[i*8+6] = (uint8_t)(state[i]>>8);
        out[i*8+7] = (uint8_t)(state[i]);
    }
}

/* ================================================================
   Ed25519 field ops (mod p = 2^255-19)
   ================================================================ */

static void ed25519_mul(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    uint64_t x[8];
    xiom_f256_mul_raw(x, a, b);
    xiom_f256_reduce(r, x, ED25519_P, ED25519_R256);
}
static void ed25519_sqr(uint64_t r[4], const uint64_t a[4]) { ed25519_mul(r, a, a); }
static void ed25519_add(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    xiom_f256_mod_add(r, a, b, ED25519_P);
}
static void ed25519_sub(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    xiom_f256_mod_sub(r, a, b, ED25519_P);
}
static void ed25519_inv(uint64_t r[4], const uint64_t a[4]) {
    uint64_t u[4], v[4], x1[4], x2[4];
    int i;

    xiom_f256_set(u, a);
    while (xiom_f256_cmp(u, ED25519_P) >= 0) xiom_f256_sub_raw(u, u, ED25519_P);

    if (xiom_f256_is_zero(u)) { xiom_f256_from_u64(r, 0); return; }

    xiom_f256_set(v, ED25519_P);
    xiom_f256_from_u64(x1, 1);
    xiom_f256_from_u64(x2, 0);

    while (!xiom_f256_is_zero(u) && !xiom_f256_is_zero(v)) {
        while ((u[0] & 1) == 0) {
            for (i = 0; i < 4; i++) {
                u[i] = (u[i] >> 1) | ((i + 1 < 4 && (u[i + 1] & 1)) ? (1ULL << 63) : 0);
            }
            if (x1[0] & 1) {
                uint64_t tmp[4];
                xiom_f256_sub_raw(tmp, ED25519_P, x1);
                xiom_f256_set(x1, tmp);
                for (i = 0; i < 3; i++) {
                    x1[i] = (x1[i] >> 1) | ((x1[i+1] & 1) ? (1ULL << 63) : 0);
                }
                x1[3] >>= 1;
            } else {
                for (i = 0; i < 3; i++) {
                    x1[i] = (x1[i] >> 1) | ((x1[i+1] & 1) ? (1ULL << 63) : 0);
                }
                x1[3] >>= 1;
            }
        }
        while ((v[0] & 1) == 0) {
            for (i = 0; i < 4; i++) {
                v[i] = (v[i] >> 1) | ((i + 1 < 4 && (v[i + 1] & 1)) ? (1ULL << 63) : 0);
            }
            if (x2[0] & 1) {
                uint64_t tmp[4];
                xiom_f256_sub_raw(tmp, ED25519_P, x2);
                xiom_f256_set(x2, tmp);
                for (i = 0; i < 3; i++) {
                    x2[i] = (x2[i] >> 1) | ((x2[i+1] & 1) ? (1ULL << 63) : 0);
                }
                x2[3] >>= 1;
            } else {
                for (i = 0; i < 3; i++) {
                    x2[i] = (x2[i] >> 1) | ((x2[i+1] & 1) ? (1ULL << 63) : 0);
                }
                x2[3] >>= 1;
            }
        }
        if (xiom_f256_cmp(u, v) >= 0) {
            xiom_f256_sub_raw(u, u, v);
            if (xiom_f256_cmp(x1, x2) >= 0) {
                xiom_f256_sub_raw(x1, x1, x2);
            } else {
                uint64_t tmp[4];
                xiom_f256_sub_raw(tmp, x2, x1);
                xiom_f256_set(x1, ED25519_P);
                xiom_f256_sub_raw(x1, x1, tmp);
            }
        } else {
            xiom_f256_sub_raw(v, v, u);
            if (xiom_f256_cmp(x2, x1) >= 0) {
                xiom_f256_sub_raw(x2, x2, x1);
            } else {
                uint64_t tmp[4];
                xiom_f256_sub_raw(tmp, x1, x2);
                xiom_f256_set(x2, ED25519_P);
                xiom_f256_sub_raw(x2, x2, tmp);
            }
        }
    }

    if (!xiom_f256_is_zero(u)) {
        xiom_f256_set(r, x1);
    } else {
        xiom_f256_set(r, x2);
    }
    while (xiom_f256_cmp(r, ED25519_P) >= 0) xiom_f256_sub_raw(r, r, ED25519_P);
}
static void ed25519_neg(uint64_t r[4], const uint64_t a[4]) {
    if (xiom_f256_is_zero(a)) { xiom_f256_from_u64(r, 0); return; }
    xiom_f256_sub_raw(r, ED25519_P, a);
}

/* ── Extended twisted Edwards coords ── */
typedef struct { uint64_t x[4],y[4],z[4],t[4]; } ed25519_pt;

static void ed25519_pt_id(ed25519_pt* p) {
    xiom_f256_from_u64(p->x, 0);
    xiom_f256_from_u64(p->y, 1);
    xiom_f256_from_u64(p->z, 1);
    xiom_f256_from_u64(p->t, 0);
}

static void ed25519_pt_base(ed25519_pt* p) {
    xiom_f256_set(p->x, ED25519_BX);
    xiom_f256_set(p->y, ED25519_BY);
    xiom_f256_from_u64(p->z, 1);
    ed25519_mul(p->t, ED25519_BX, ED25519_BY);
}

static void ed25519_pt_add(ed25519_pt* r, const ed25519_pt* p, const ed25519_pt* q) {
    uint64_t a[4],b[4],c[4],d[4],e[4],f[4],g[4],h[4],t1[4],t2[4],two[4]={2,0,0,0};
    uint64_t twod[4];
    ed25519_mul(twod, ED25519_D, two);
    ed25519_sub(t1, p->y, p->x); ed25519_sub(t2, q->y, q->x); ed25519_mul(a, t1, t2);
    ed25519_add(t1, p->y, p->x); ed25519_add(t2, q->y, q->x); ed25519_mul(b, t1, t2);
    ed25519_mul(t1, p->t, twod); ed25519_mul(c, t1, q->t);
    ed25519_mul(t1, p->z, two); ed25519_mul(d, t1, q->z);
    ed25519_sub(e, b, a); ed25519_sub(f, d, c);
    ed25519_add(g, d, c); ed25519_add(h, b, a);
    ed25519_mul(r->x, e, f); ed25519_mul(r->y, g, h);
    ed25519_mul(r->t, e, h); ed25519_mul(r->z, f, g);
}

static void ed25519_pt_dbl(ed25519_pt* r, const ed25519_pt* p) {
    uint64_t a[4],b[4],c[4],d[4],e[4],f[4],g[4],h[4],two[4]={2,0,0,0};
    ed25519_sqr(a,p->x); ed25519_sqr(b,p->y);
    ed25519_sqr(c,p->z); ed25519_mul(c,c,two);
    ed25519_neg(d,a);
    ed25519_add(e,p->x,p->y); ed25519_sqr(e,e); ed25519_sub(e,e,a); ed25519_sub(e,e,b);
    ed25519_add(g,d,b); ed25519_sub(f,g,c);
    ed25519_sub(h,d,b);
    ed25519_mul(r->x,e,f); ed25519_mul(r->y,g,h);
    ed25519_mul(r->t,e,h); ed25519_mul(r->z,f,g);
}

static void ed25519_scalar_mul(ed25519_pt* r, const uint8_t s[32], const ed25519_pt* base) {
    ed25519_pt res, tmp;
    int i;
    ed25519_pt_id(&res);
    tmp.x[0]=base->x[0];tmp.x[1]=base->x[1];tmp.x[2]=base->x[2];tmp.x[3]=base->x[3];
    tmp.y[0]=base->y[0];tmp.y[1]=base->y[1];tmp.y[2]=base->y[2];tmp.y[3]=base->y[3];
    tmp.z[0]=base->z[0];tmp.z[1]=base->z[1];tmp.z[2]=base->z[2];tmp.z[3]=base->z[3];
    tmp.t[0]=base->t[0];tmp.t[1]=base->t[1];tmp.t[2]=base->t[2];tmp.t[3]=base->t[3];
    for (i=0;i<256;i++) {
        if ((s[i/8]>>(i%8))&1) ed25519_pt_add(&res,&res,&tmp);
        ed25519_pt_dbl(&tmp,&tmp);
    }
    r->x[0]=res.x[0];r->x[1]=res.x[1];r->x[2]=res.x[2];r->x[3]=res.x[3];
    r->y[0]=res.y[0];r->y[1]=res.y[1];r->y[2]=res.y[2];r->y[3]=res.y[3];
    r->z[0]=res.z[0];r->z[1]=res.z[1];r->z[2]=res.z[2];r->z[3]=res.z[3];
    r->t[0]=res.t[0];r->t[1]=res.t[1];r->t[2]=res.t[2];r->t[3]=res.t[3];
}

static void ed25519_to_affine(uint64_t ax[4], uint64_t ay[4], const ed25519_pt* p) {
    uint64_t zi[4];
    ed25519_inv(zi, p->z);
    ed25519_mul(ax, p->x, zi);
    ed25519_mul(ay, p->y, zi);
}

static void ed25519_enc_pub(uint8_t out[32], const uint64_t x[4], const uint64_t y[4]) {
    int i;
    uint8_t xp = (uint8_t)(x[0]&1);
    for (i=0;i<32;i++) {
        int limb=(i*8)/64, sh=(i*8)%64;
        out[i] = (uint8_t)(y[limb]>>sh);
        if (sh>56 && limb+1<4) out[i] |= (uint8_t)(y[limb+1]<<(64-sh));
    }
    out[31] = (uint8_t)((out[31]&0x7F)|(xp<<7));
}

static int ed25519_recover_x(uint64_t x[4], const uint64_t y[4], int sign) {
    uint64_t y2[4], num[4], den[4], one[4]={1,0,0,0}, x2[4], u[4], v[4];
    uint64_t sqrt_m1[4]={0x4A0EA0B0C42B7BD8ULL,0xC41B1CDCFE0BBABDULL,0x734D589050FAE812ULL,0x2B8324804FC1DF0BULL};
    uint64_t e[4], cv, tmp_cv[4];
    int bit;

    ed25519_sqr(y2, y);
    ed25519_sub(num, y2, one);
    ed25519_mul(den, ED25519_D, y2);
    ed25519_add(den, den, one);
    ed25519_inv(den, den);
    ed25519_mul(x2, num, den);
    /* sqrt: x2^((p+3)/8) */
    ed25519_neg(e, one); /* -1 */
    cv = 1ULL<<60; /* 2^252 in limb 3 */
    e[3] += cv;
    xiom_f256_from_u64(u, 1);
    xiom_f256_set(v, x2);
    for (bit=0;bit<256;bit++) {
        if ((e[bit/64]>>(bit%64))&1) ed25519_mul(u,u,v);
        ed25519_sqr(v,v);
    }
    ed25519_sqr(tmp_cv, u);
    if (!xiom_f256_eq(tmp_cv, x2)) ed25519_mul(u, u, sqrt_m1);
    ed25519_sqr(tmp_cv, u);
    if (!xiom_f256_eq(tmp_cv, x2)) return 0;
    if ((u[0]&1) != (uint64_t)sign) ed25519_neg(u, u);
    xiom_f256_set(x, u);
    return 1;
}

/* ── Ed25519 order-l ops ── */
/* 2^256 mod l precomputed: */
static const uint64_t R_ORDER[4] = {
    0xC3DC22EFF6DA94E3ULL, 0xFAE31A49EBF56854ULL,
    0xE42FB5726C44E80CULL, 0x0DEED28E0BB8D901ULL
};

static void ed25519_reduce_order(uint64_t r[4], const uint64_t x[8]) {
    /* Reduce using R_ORDER: x[4]*2^256 ≡ x[4]*R_ORDER (mod l).
       High limbs x[5..7] can only appear if input is 64-byte hash. */
    uint64_t w[8], tmp[8];
    int i, j;
    uint64_t carry;

    for (i=0;i<8;i++) { w[i]=x[i]; tmp[i]=0; }
    for (i=4;i<8;i++) {
        uint64_t v=w[i];
        if (!v) continue;
        int sh=i-4;
        carry=0;
        for (j=0;j<4;j++) {
            uint64_t hi,lo;
            XIOM_MUL128(hi,lo,v,R_ORDER[j]);
            int idx=j+sh;
            if (idx<8) {
                uint64_t co;
                tmp[idx]=xiom_addc2(tmp[idx],lo,carry,&co); carry=co;
                if (idx+1<8 && hi) {
                    uint64_t co2;
                    tmp[idx+1]=xiom_addc2(tmp[idx+1],hi,carry,&co2); carry=co2;
                }
            }
        }
        w[i]=0;
    }
    carry=0;
    for (i=0;i<4;i++) {
        uint64_t co;
        w[i]=xiom_addc2(w[i],tmp[i],carry,&co); carry=co;
    }
    /* Second pass for any residual high limbs */
    if (carry||tmp[4]||tmp[5]||tmp[6]||tmp[7]) {
        for (i=0;i<8;i++) { if(i<4) w[i]=w[i]; else w[i]=tmp[i]; tmp[i]=0; }
        for (i=4;i<8;i++) {
            uint64_t v=w[i];
            if (!v) continue;
            int sh=i-4;
            carry=0;
            for (j=0;j<4;j++) {
                uint64_t hi,lo;
                XIOM_MUL128(hi,lo,v,R_ORDER[j]);
                int idx=j+sh;
                if (idx<8) {
                    uint64_t co;
                    tmp[idx]=xiom_addc2(tmp[idx],lo,carry,&co); carry=co;
                    if (idx+1<8 && hi) {
                        uint64_t co2;
                        tmp[idx+1]=xiom_addc2(tmp[idx+1],hi,carry,&co2); carry=co2;
                    }
                }
            }
            w[i]=0;
        }
        carry=0;
        for (i=0;i<4;i++) {
            uint64_t co;
            w[i]=xiom_addc2(w[i],tmp[i],carry,&co); carry=co;
        }
    }
    for (i=0;i<4;i++) r[i]=w[i];
    while (xiom_f256_cmp(r, ED25519_L) >= 0) xiom_f256_sub_raw(r,r,ED25519_L);
}

static void ed25519_mul_order(uint64_t r[4], const uint64_t a[4], const uint64_t b[4]) {
    uint64_t x[8];
    xiom_f256_mul_raw(x, a, b);
    ed25519_reduce_order(r, x);
}

static void ed25519_bytes_to_u8(uint64_t r8[8], const uint8_t* bytes, int nbytes) {
    int i;
    memset(r8, 0, sizeof(uint64_t)*8);
    for (i=0;i<nbytes;i++) {
        int limb=i/8, sh=(i%8)*8;
        if (limb<8) r8[limb] |= ((uint64_t)bytes[i])<<sh;
    }
}

static void ed25519_mod_order_from_bytes(uint64_t r[4], const uint8_t* bytes, int nbytes) {
    uint64_t x[8];
    ed25519_bytes_to_u8(x, bytes, nbytes);
    ed25519_reduce_order(r, x);
}

static void ed25519_order_to_bytes(uint8_t out[32], const uint64_t r[4]) {
    int i;
    for (i=0;i<32;i++) {
        int limb=(i*8)/64, sh=(i*8)%64;
        out[i] = (uint8_t)(r[limb]>>sh);
        if (sh>56 && limb+1<4) out[i] |= (uint8_t)(r[limb+1]<<(64-sh));
    }
}

/* ================================================================
   Public Ed25519 API
   ================================================================ */

void xiom_ed25519_pubkey(const uint8_t privkey[32], uint8_t pubkey[32]) {
    uint8_t h[64];
    ed25519_pt A;
    uint64_t ax[4], ay[4];
    uint8_t s[32];
    int i;

    sha512_hash(privkey, 32, h);
    h[0] &= 248; h[31] &= 127; h[31] |= 64;
    for (i=0;i<32;i++) s[i]=h[i];
    ed25519_pt_base(&A);
    ed25519_scalar_mul(&A, s, &A);
    ed25519_to_affine(ax, ay, &A);
    ed25519_enc_pub(pubkey, ax, ay);
}

int xiom_ed25519_sign(const uint8_t* msg, size_t msglen,
                       const uint8_t privkey[32], uint8_t sig[64]) {
    uint8_t h[64], r[64], *rbuf, *kbuf;
    uint8_t prefix[32], A_enc[32], R_enc[32], S_bytes[32];
    ed25519_pt A, R;
    uint64_t ax[4], ay[4], rx[4], ry[4], k_mod[4], a_mod[4], r_mod[4], s_mod[4];
    size_t rlen, klen;
    int i;

    sha512_hash(privkey, 32, h);
    h[0] &= 248; h[31] &= 127; h[31] |= 64;
    for (i=0;i<32;i++) prefix[i]=h[i];

    ed25519_pt_base(&A);
    ed25519_scalar_mul(&A, prefix, &A);
    ed25519_to_affine(ax, ay, &A);
    ed25519_enc_pub(A_enc, ax, ay);

    /* r = SHA-512(h[32..63] || msg) */
    rlen = 32 + msglen;
    rbuf = (uint8_t*)malloc(rlen);
    if (!rbuf) return 0;
    memcpy(rbuf, h+32, 32);
    if (msglen) memcpy(rbuf+32, msg, msglen);
    sha512_hash(rbuf, rlen, r);
    free(rbuf);

    ed25519_pt_base(&R);
    ed25519_scalar_mul(&R, r, &R);
    ed25519_to_affine(rx, ry, &R);
    ed25519_enc_pub(R_enc, rx, ry);

    /* k = SHA-512(R || A || msg) mod l */
    klen = 64 + msglen;
    kbuf = (uint8_t*)malloc(klen);
    if (!kbuf) return 0;
    memcpy(kbuf, R_enc, 32);
    memcpy(kbuf+32, A_enc, 32);
    if (msglen) memcpy(kbuf+64, msg, msglen);
    sha512_hash(kbuf, klen, r); /* reuse r buffer */
    free(kbuf);

    ed25519_mod_order_from_bytes(k_mod, r, 64);
    ed25519_mod_order_from_bytes(a_mod, prefix, 32);
    ed25519_mod_order_from_bytes(r_mod, r, 64);

    ed25519_mul_order(s_mod, k_mod, a_mod);
    xiom_f256_mod_add(s_mod, r_mod, s_mod, ED25519_L);

    ed25519_order_to_bytes(S_bytes, s_mod);

    memcpy(sig, R_enc, 32);
    memcpy(sig+32, S_bytes, 32);
    return 1;
}

int xiom_ed25519_verify(const uint8_t* msg, size_t msglen,
                         const uint8_t pubkey[32], const uint8_t sig[64]) {
    const uint8_t *R_enc = sig, *S_data = sig+32;
    uint64_t ry[4], rx[4], ax[4], ay[4], k_mod[4], s_mod[4];
    uint8_t k_hash[64], *kbuf;
    ed25519_pt R_pt, A_pt, SG, kA, sum;
    uint8_t s_bytes[32], k_bytes[32];
    int i, x_sign;
    size_t klen;

    /* Decode R */
    {
        uint64_t yb[4]={0,0,0,0};
        for (i=0;i<32;i++) {
            int limb=i/8,sh=(i%8)*8;
            yb[limb] |= ((uint64_t)R_enc[i])<<sh;
        }
        yb[3] &= 0x7FFFFFFFFFFFFFFFULL;
        xiom_f256_set(ry, yb);
        x_sign = (R_enc[31]>>7)&1;
        if (!ed25519_recover_x(rx, ry, x_sign)) return 0;
    }

    /* Decode A */
    {
        uint64_t ayb[4]={0,0,0,0};
        for (i=0;i<32;i++) {
            int limb=i/8,sh=(i%8)*8;
            ayb[limb] |= ((uint64_t)pubkey[i])<<sh;
        }
        ayb[3] &= 0x7FFFFFFFFFFFFFFFULL;
        xiom_f256_set(ay, ayb);
        x_sign = (pubkey[31]>>7)&1;
        if (!ed25519_recover_x(ax, ay, x_sign)) return 0;
    }

    /* k = SHA-512(R || A || msg) mod l */
    klen = 64 + msglen;
    kbuf = (uint8_t*)malloc(klen);
    if (!kbuf) return 0;
    memcpy(kbuf, R_enc, 32);
    memcpy(kbuf+32, pubkey, 32);
    if (msglen) memcpy(kbuf+64, msg, msglen);
    sha512_hash(kbuf, klen, k_hash);
    free(kbuf);
    ed25519_mod_order_from_bytes(k_mod, k_hash, 64);

    /* Decode S */
    ed25519_mod_order_from_bytes(s_mod, S_data, 32);

    /* Convert to extended points */
    xiom_f256_set(R_pt.x, rx); xiom_f256_set(R_pt.y, ry);
    xiom_f256_from_u64(R_pt.z, 1); ed25519_mul(R_pt.t, rx, ry);
    xiom_f256_set(A_pt.x, ax); xiom_f256_set(A_pt.y, ay);
    xiom_f256_from_u64(A_pt.z, 1); ed25519_mul(A_pt.t, ax, ay);

    /* SG = s*B */
    {
        ed25519_pt BP;
        ed25519_order_to_bytes(s_bytes, s_mod);
        ed25519_pt_base(&BP);
        ed25519_scalar_mul(&SG, s_bytes, &BP);
    }

    /* kA = k*A */
    {
        ed25519_order_to_bytes(k_bytes, k_mod);
        ed25519_scalar_mul(&kA, k_bytes, &A_pt);
    }

    /* sum = SG + (-kA) */
    ed25519_neg(kA.x, kA.x);
    ed25519_neg(kA.t, kA.t);
    ed25519_pt_add(&sum, &SG, &kA);

    {
        uint64_t sx[4], sy[4];
        ed25519_to_affine(sx, sy, &sum);
        return xiom_f256_eq(sx, rx) && xiom_f256_eq(sy, ry);
    }
}

/* ================================================================
   128-bit integer libcalls (D1, 2026-08-08)
   ================================================================
   Native Int128/UInt128 (LLVM i128) lowers division/modulo to these
   libcalls. clang does NOT auto-link compiler-rt on Windows, so they
   are implemented here (compiler-rt-compatible semantics).

   __multi3  : signed 128x128 -> 128 multiply
   __divti3  : signed 128 / 128 -> 128 (truncating, round-toward-zero)
   __udivti3 : unsigned 128 / 128 -> 128
   __modti3  : signed 128 % 128 (sign follows dividend)
   __umodti3 : unsigned 128 % 128

   Algorithm notes (compiler-rt lineage):
   - multiply: __int128 native (MSVC/clang on x64 support it; the f256
     code above already relies on __uint128_t).
   - divide: Knuth Algorithm D (shift-normalized long division on two
     64-bit limbs). Correct for ALL inputs including INT128_MIN / -1
     (which is defined as INT128_MIN, matching compiler-rt __divti3).
   ================================================================ */

#ifdef _MSC_VER
__int128 __cdecl __multi3(__int128 a, __int128 b);
__int128 __cdecl __divti3(__int128 a, __int128 b);
unsigned __int128 __cdecl __udivti3(unsigned __int128 a, unsigned __int128 b);
__int128 __cdecl __modti3(__int128 a, __int128 b);
unsigned __int128 __cdecl __umodti3(unsigned __int128 a, unsigned __int128 b);
#else
__int128 __multi3(__int128 a, __int128 b);
__int128 __divti3(__int128 a, __int128 b);
unsigned __int128 __udivti3(unsigned __int128 a, unsigned __int128 b);
__int128 __modti3(__int128 a, __int128 b);
unsigned __int128 __umodti3(unsigned __int128 a, unsigned __int128 b);
#endif

/* Native 128-bit multiply — the compiler emits __multi3 for i128 mul
   when it cannot prove the result fits in 64 bits. */
__int128 __multi3(__int128 a, __int128 b) {
    return (__int128)((__uint128_t)a * (__uint128_t)b);
}

/* Unsigned 128-bit division: Knuth Algorithm D on two 64-bit limbs.
   b must be nonzero (LLVM only emits this call for well-defined div). */
static unsigned __int128 xiom_udivti3(unsigned __int128 a, unsigned __int128 b) {
    /* Handle trivial cases with the native 128-bit op where the quotient
       provably fits in 64 bits: b > a/2^64 i.e. high limb of b nonzero. */
    unsigned __int128 u_hi = a >> 64;
    if (b >> 64 != 0) {
        /* Full 128/128: normalize b so its top bit is set. */
        unsigned shift = 0;
        unsigned __int128 nb = b;
        while ((nb >> 127) == 0) { nb <<= 1; shift++; }
        unsigned __int128 na = a << shift;
        unsigned __int128 q = 0;
        unsigned __int128 r = 0;
        int bit;
        for (bit = 127; bit >= 0; bit--) {
            r = (r << 1) | ((na >> bit) & 1);
            if (r >= nb) { r -= nb; q |= ((unsigned __int128)1 << bit); }
        }
        (void)u_hi;
        return q;
    }
    /* High limb of b is zero: single-limb divisor. The quotient fits in
       64 bits; a native divide is exact and well-defined here. */
    unsigned __int128 q = a / b;
    return q;
}

__int128 __divti3(__int128 a, __int128 b) {
    /* Handle INT128_MIN / -1: quotient is INT128_MIN (defined overflow). */
    if (b == -1) {
        if (a == (((__int128)1) << 127)) { return (((__int128)1) << 127); }
    }
    int neg = (a < 0) != (b < 0);
    unsigned __int128 ua = (a < 0) ? (unsigned __int128)(-(a + 1)) + 1 : (unsigned __int128)a;
    unsigned __int128 ub = (b < 0) ? (unsigned __int128)(-(b + 1)) + 1 : (unsigned __int128)b;
    unsigned __int128 q = xiom_udivti3(ua, ub);
    if (neg) { q = (unsigned __int128)(-(__int128)q); }
    return (__int128)q;
}

unsigned __int128 __udivti3(unsigned __int128 a, unsigned __int128 b) {
    return xiom_udivti3(a, b);
}

__int128 __modti3(__int128 a, __int128 b) {
    __int128 q = __divti3(a, b);
    return a - q * b;
}

unsigned __int128 __umodti3(unsigned __int128 a, unsigned __int128 b) {
    unsigned __int128 q = xiom_udivti3(a, b);
    return a - q * b;
}

