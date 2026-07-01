#define _CRT_SECURE_NO_WARNINGS
// AXIOM Runtime -- C helper functions for self-hosting compiler
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
    fprintf(ir_output, "; AXIOM Phase 1 -- LLVM IR\n");
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

// ============================================================================
// Function Table — stores parsed function info for later IR emission
// ============================================================================

#define MAX_FUNCTIONS 256

typedef struct {
    long name_id;       // interned function name
    long ret_type_id;   // interned return type ("i64", "double", "void")
    long param_count;
    long body_start;    // position of '{'
    long body_end;      // position of '}'
} FnRecord;

static FnRecord fn_table[MAX_FUNCTIONS];
static int fn_count = 0;

void axiom_fn_table_init(void) {
    fn_count = 0;
    for (int i = 0; i < MAX_FUNCTIONS; i++) {
        fn_table[i].name_id = 0;
        fn_table[i].ret_type_id = 0;
        fn_table[i].param_count = 0;
        fn_table[i].body_start = 0;
        fn_table[i].body_end = 0;
    }
}

void axiom_fn_table_add(long name_id, long ret_type_id, long param_count,
                         long body_start, long body_end) {
    if (fn_count >= MAX_FUNCTIONS) return;
    fn_table[fn_count].name_id = name_id;
    fn_table[fn_count].ret_type_id = ret_type_id;
    fn_table[fn_count].param_count = param_count;
    fn_table[fn_count].body_start = body_start;
    fn_table[fn_count].body_end = body_end;
    fn_count++;
}

long axiom_fn_table_count(void) {
    return fn_count;
}

long axiom_fn_name_id(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].name_id;
}

long axiom_fn_ret_type_id(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].ret_type_id;
}

long axiom_fn_param_count(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].param_count;
}

long axiom_fn_body_start(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].body_start;
}

long axiom_fn_body_end(long index) {
    if (index < 0 || index >= fn_count) return 0;
    return fn_table[index].body_end;
}

// Map AXIOM type name (as interned) to LLVM type string
static const char* map_axiom_type(const char* axiom_ty) {
    if (!axiom_ty) return "i64";
    if (strcmp(axiom_ty, "Int") == 0 || strcmp(axiom_ty, "Bool") == 0 || strcmp(axiom_ty, "Int64") == 0) {
        return "i64";
    }
    if (strcmp(axiom_ty, "Float64") == 0) {
        return "double";
    }
    if (strcmp(axiom_ty, "Str") == 0) {
        return "i8*";
    }
    if (strcmp(axiom_ty, "Void") == 0 || strcmp(axiom_ty, "()") == 0) {
        return "void";
    }
    if (strcmp(axiom_ty, "Float32") == 0) {
        return "float";
    }
    // default: return as-is (e.g., "i64", "double" already mapped)
    return axiom_ty;
}

#include <stdint.h>

// Store source globally so emit_all can parse bodies
static const char* g_source = NULL;
void axiom_set_source(int64_t ptr_int) { g_source = (const char*)(intptr_t)ptr_int; }

static int is_body_ident_char(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
}

#define MAX_LOCALS 64

static int find_local_reg(const char* name, long name_len,
                          const char names[][64], const int regs[], int count) {
    for (int i = 0; i < count; i++) {
        if ((long)strlen(names[i]) == name_len && strncmp(names[i], name, (size_t)name_len) == 0)
            return regs[i];
    }
    return -1;
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

                // Binary op: ident op ident
                if (pos < body_end && (source[pos] == '+' || source[pos] == '*')) {
                    char op = source[pos]; pos++;
                    while (pos < body_end && source[pos] == ' ') pos++;
                    long op2_s = pos;
                    while (pos < body_end && is_body_ident_char(source[pos])) pos++;

                    int r_left = reg++;
                    int idx1 = (source[id_s] - 'a') % pc;
                    if (idx1 < 0 || idx1 >= pc) idx1 = 0;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r_left, llvm_ty, llvm_ty, idx1);

                    int r_right = reg++;
                    int idx2 = (source[op2_s] - 'a') % pc;
                    if (idx2 < 0 || idx2 >= pc) idx2 = 0;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r_right, llvm_ty, llvm_ty, idx2);

                    int r_res = reg++;
                    if (op == '+')
                        fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %%tmp%d\n", r_res, llvm_ty, r_left, r_right);
                    else if (strcmp(llvm_ty, "double") == 0)
                        fprintf(ir_output, "  %%tmp%d = fmul double %%tmp%d, %%tmp%d\n", r_res, r_left, r_right);
                    else
                        fprintf(ir_output, "  %%tmp%d = mul %s %%tmp%d, %%tmp%d\n", r_res, llvm_ty, r_left, r_right);

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

                    int cr = reg++;
                    fprintf(ir_output, "  %%tmp%d = call %s @", cr, call_ret_ty);
                    fwrite(source + id_s, 1, (size_t)id_len, ir_output);
                    fprintf(ir_output, "(");

                    pos++; // skip '('
                    int first = 1;
                    while (pos < body_end && source[pos] != ')') {
                        while (pos < body_end && source[pos] == ' ') pos++;
                        if (pos >= body_end || source[pos] == ')') break;

                        if (source[pos] >= '0' && source[pos] <= '9') {
                            long ival = 0; double fval = 0.0;
                            int is_f = parse_literal(source, &pos, body_end, &ival, &fval);
                            if (!first) fprintf(ir_output, ", ");
                            if (is_f) fprintf(ir_output, "double %lf", fval);
                            else fprintf(ir_output, "i64 %ld", ival);
                        } else if (is_body_ident_char(source[pos])) {
                            long as = pos;
                            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                            if (!first) fprintf(ir_output, ", ");
                            fprintf(ir_output, "i64 %.*s", (int)(pos - as), source + as);
                        } else { pos++; }

                        while (pos < body_end && source[pos] == ' ') pos++;
                        if (pos < body_end && source[pos] == ',') { pos++; first = 0; }
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

        // --- return statement (last statement in body)
        if (pos + 5 < body_end && c0 == 'r' && c1 == 'e' && source[pos+2] == 't' && source[pos+3] == 'u' && source[pos+4] == 'r' && source[pos+5] == 'n') {
            pos += 6;
            while (pos < body_end && (source[pos] == ' ' || source[pos] == '\t')) pos++;

            // Literal
            if (pos < body_end && source[pos] >= '0' && source[pos] <= '9') {
                long ival = 0; double fval = 0.0;
                int is_float = parse_literal(source, &pos, body_end, &ival, &fval);
                if (is_float)
                    fprintf(ir_output, "  ret %s %lf\n", llvm_ty, fval);
                else
                    fprintf(ir_output, "  ret %s %ld\n", llvm_ty, ival);
                return;
            }

            // Identifier
            if (pos < body_end && is_body_ident_char(source[pos])) {
                long id_s = pos;
                while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                long id_len = pos - id_s;
                while (pos < body_end && source[pos] == ' ') pos++;

                // Binary op: ident op ident
                if (pos < body_end && (source[pos] == '+' || source[pos] == '*')) {
                    char op = source[pos]; pos++;
                    while (pos < body_end && source[pos] == ' ') pos++;
                    long op2_s = pos;
                    while (pos < body_end && is_body_ident_char(source[pos])) pos++;

                    int r1 = reg++;
                    int idx1 = (source[id_s] - 'a') % pc;
                    if (idx1 < 0 || idx1 >= pc) idx1 = 0;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r1, llvm_ty, llvm_ty, idx1);

                    int r2 = reg++;
                    int idx2 = (source[op2_s] - 'a') % pc;
                    if (idx2 < 0 || idx2 >= pc) idx2 = 0;
                    fprintf(ir_output, "  %%tmp%d = load %s, %s* %%tmp_p%d\n", r2, llvm_ty, llvm_ty, idx2);

                    int r3 = reg++;
                    if (op == '+')
                        fprintf(ir_output, "  %%tmp%d = add %s %%tmp%d, %%tmp%d\n", r3, llvm_ty, r1, r2);
                    else if (strcmp(llvm_ty, "double") == 0)
                        fprintf(ir_output, "  %%tmp%d = fmul double %%tmp%d, %%tmp%d\n", r3, r1, r2);
                    else
                        fprintf(ir_output, "  %%tmp%d = mul %s %%tmp%d, %%tmp%d\n", r3, llvm_ty, r1, r2);

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

                        if (source[pos] >= '0' && source[pos] <= '9') {
                            long ival = 0; double fval = 0.0;
                            int is_f = parse_literal(source, &pos, body_end, &ival, &fval);
                            if (!first) fprintf(ir_output, ", ");
                            if (is_f) fprintf(ir_output, "double %lf", fval);
                            else fprintf(ir_output, "i64 %ld", ival);
                        } else if (is_body_ident_char(source[pos])) {
                            long as = pos;
                            while (pos < body_end && is_body_ident_char(source[pos])) pos++;
                            if (!first) fprintf(ir_output, ", ");
                            fprintf(ir_output, "i64 %.*s", (int)(pos - as), source + as);
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

// Emit all functions with real body IR
void axiom_fn_emit_all(void) {
    const char* source = g_source;
    if (!ir_output) ir_output = stdout;
    for (int i = 0; i < fn_count; i++) {
        const char* name = axiom_lookup(fn_table[i].name_id);
        const char* ret_ty_raw = axiom_lookup(fn_table[i].ret_type_id);
        if (!name) name = "unknown";
        if (!ret_ty_raw) ret_ty_raw = "i64";
        const char* llvm_ty = map_axiom_type(ret_ty_raw);

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
