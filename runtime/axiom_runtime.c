// AXIOM Runtime — C helper functions for self-hosting compiler
// All string operations happen here. The AXIOM compiler works with Int IDs.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ============================================================================
// File I/O
// ============================================================================

char* axiom_read_file(const char* path) {
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

long axiom_file_size(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fclose(f);
    return size;
}

void axiom_free(void* ptr) {
    free(ptr);
}

char axiom_char_at(const char* str, long pos) {
    if (!str) return 0;
    long len = (long)strlen(str);
    if (pos < 0 || pos >= len) return 0;
    return str[pos];
}

long axiom_str_len(const char* str) {
    if (!str) return -1;
    return (long)strlen(str);
}

// ============================================================================
// String interning — AXIOM uses Int IDs for all names
// ============================================================================

#define MAX_STRINGS 1024
static char* string_table[MAX_STRINGS];
static int string_count = 0;

// Intern a string: read from position pos with length len in the source buffer.
// Returns a unique int ID for the string.
long axiom_intern(const char* source, long pos, long len) {
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
const char* axiom_lookup(long id) {
    if (id <= 0 || id > string_count) return NULL;
    return string_table[id - 1];
}

// ============================================================================
// IR Emission — AXIOM passes Int IDs, C prints LLVM IR
// ============================================================================

static FILE* ir_output = NULL;

// Open IR output file. Call before any emit functions.
long axiom_ir_open(const char* path) {
    if (ir_output) fclose(ir_output);
    if (path && strlen(path) > 0) {
        ir_output = fopen(path, "w");
    } else {
        ir_output = stdout;
    }
    return ir_output ? 1 : 0;
}

// Close IR output
void axiom_ir_close(void) {
    if (ir_output && ir_output != stdout) {
        fclose(ir_output);
    }
    ir_output = NULL;
}

// Emit header
void axiom_ir_header(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "; AXIOM Phase 1 — LLVM IR\n");
    fprintf(ir_output, "; Self-Hosted by axiomc.ax\n\n");
    fprintf(ir_output, "target triple = \"x86_64-pc-windows-msvc\"\n\n");
}

// Emit: define {ret_type} @{name_id}({params}...)
void axiom_ir_define(long name_id, long ret_type_id) {
    if (!ir_output) ir_output = stdout;
    const char* name = axiom_lookup(name_id);
    const char* ret_ty = axiom_lookup(ret_type_id);
    if (!name) name = "unknown";
    if (!ret_ty) ret_ty = "i64";
    fprintf(ir_output, "define %s @%s(", ret_ty, name);
}

// Emit parameter: {type} %param{N}
void axiom_ir_param(long type_id, long index) {
    if (!ir_output) ir_output = stdout;
    const char* ty = axiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "%s %%param%ld", ty, index);
}

// End parameter list and start body
void axiom_ir_entry(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, ") {\nentry0:\n");
}

// Emit alloca
void axiom_ir_alloca(long reg, long type_id) {
    if (!ir_output) ir_output = stdout;
    const char* ty = axiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "  %%tmp%ld = alloca %s\n", reg, ty);
}

// Emit store
void axiom_ir_store(long src_reg, long type_id, long dst_reg) {
    if (!ir_output) ir_output = stdout;
    const char* ty = axiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "  store %s %%tmp%ld, %s* %%tmp%ld\n", ty, src_reg, ty, dst_reg);
}

// Emit load
void axiom_ir_load(long dst_reg, long type_id, long src_reg) {
    if (!ir_output) ir_output = stdout;
    const char* ty = axiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "  %%tmp%ld = load %s, %s* %%tmp%ld\n", dst_reg, ty, ty, src_reg);
}

// Emit binary op: add/sub/mul/div
void axiom_ir_binop(const char* op, long dst_reg, long type_id, long left_reg, long right_reg) {
    if (!ir_output) ir_output = stdout;
    const char* ty = axiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "  %%tmp%ld = %s %s %%tmp%ld, %%tmp%ld\n", dst_reg, op, ty, left_reg, right_reg);
}

// Emit call: %tmp{dst} = call {ret_ty} @{fn_id}({args}...)
void axiom_ir_call(long dst_reg, long fn_id, long ret_type_id) {
    if (!ir_output) ir_output = stdout;
    const char* fn_name = axiom_lookup(fn_id);
    const char* ret_ty = axiom_lookup(ret_type_id);
    if (!fn_name) fn_name = "unknown";
    if (!ret_ty) ret_ty = "i64";
    fprintf(ir_output, "  %%tmp%ld = call %s @%s(", dst_reg, ret_ty, fn_name);
}

// Emit call argument
void axiom_ir_call_arg(long type_id, long reg) {
    if (!ir_output) ir_output = stdout;
    const char* ty = axiom_lookup(type_id);
    if (!ty) ty = "i64";
    fprintf(ir_output, "%s %%tmp%ld", ty, reg);
}

// Emit call literal argument
void axiom_ir_call_lit(const char* lit) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "%s", lit);
}

// End call argument list
void axiom_ir_call_end(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, ")\n");
}

// Emit ret
void axiom_ir_ret(long type_id, long reg) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  ret i64 %%tmp%ld\n", reg);
}

// Emit ret void
void axiom_ir_ret_void(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  ret void\n");
}

// Emit function end
void axiom_ir_endfn(void) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "}\n\n");
}

// Emit raw text (for constants, forward declares, etc.)
void axiom_ir_raw(const char* text) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "%s\n", text);
}

// Emit a complete simple program IR.
// This is the MVP: the AXIOM compiler computes return_value and
// delegates full IR generation to C.
void axiom_ir_emit_program(long return_value) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "; AXIOM Self-Hosted Compiler v0.9.3\n");
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

void axiom_ir_define_s(const char* name, const char* ret_type) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "define %s @%s(", ret_type, name);
}

void axiom_ir_param_int(long index) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "i64 %%param%ld", index);
}

void axiom_ir_param_double(long index) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "double %%param%ld", index);
}

void axiom_ir_alloca_s(long reg) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  %%tmp%ld = alloca i64\n", reg);
}

void axiom_ir_store_param(long reg, long param) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  store i64 %%param%ld, i64* %%tmp%ld\n", param, reg);
}

void axiom_ir_load_s(long reg, long from_reg) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  %%tmp%ld = load i64, i64* %%tmp%ld\n", reg, from_reg);
}

void axiom_ir_add(long dst, long left, long right) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  %%tmp%ld = add i64 %%tmp%ld, %%tmp%ld\n", dst, left, right);
}

void axiom_ir_fmul(long dst, long left, long right) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  %%tmp%ld = fmul double %%tmp%ld, %%tmp%ld\n", dst, left, right);
}

void axiom_ir_call_fn(long dst, const char* fn_name, const char* ret_type) {
    if (!ir_output) ir_output = stdout;
    ir_call_arg_count = 0;
    fprintf(ir_output, "  %%tmp%ld = call %s @%s(", dst, ret_type, fn_name);
}

void axiom_ir_call_arg_lit(const char* type, const char* value) {
    if (!ir_output) ir_output = stdout;
    if (ir_call_arg_count > 0) {
        fprintf(ir_output, ", ");
    }
    fprintf(ir_output, "%s %s", type, value);
    ir_call_arg_count++;
}

void axiom_ir_ret_reg(long reg) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  ret i64 %%tmp%ld\n", reg);
}

void axiom_ir_ret_lit(long val) {
    if (!ir_output) ir_output = stdout;
    fprintf(ir_output, "  ret i64 %ld\n", val);
}
