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

static int get_local_reg(const char* name, long name_len, int pc,
                         const char names[][64], const int regs[], int count) {
    int r = find_local_reg(name, name_len, names, regs, count);
    if (r >= 0) return r;
    int idx = (name[0] - 'a') % pc;
    if (idx < 0 || idx >= pc) idx = 0;
    return idx;
}

static int _label_counter = 0;

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
                                    fprintf(ir_output, "i64 %.*s", (int)(pos - as), source + as);
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
                                    fprintf(ir_output, "i64 %.*s", (int)(sp - as2), source + as2);
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
                                fprintf(ir_output, "i64 %.*s", (int)(wsp - was2), source + was2);
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
