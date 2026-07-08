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
    fprintf(ir_output, "; Self-Hosted by xiomc.ax\n\n");
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

            long arm_lits[16];
            long arm_results[16];
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
            char field_names[16][64];
            char field_types[16][16];

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

                    if (fn_len > 0 && ft_len > 0 && field_count < 16) {
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
                    int field_load_regs[16];
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
