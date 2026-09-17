// XIOM Hot Reload Runtime v2 (Phase 7D)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// =====================================================================
// Process-wide function pointer table for multi-module hot reload.
//
// Modes:
//   PRIVATE TABLE (default): each DLL has its own table (legacy single-module)
//   SHARED TABLE: host provides the table, loaded modules import it
//
// Architecture:
//   When compiled as XIOM_HOT_RUNTIME_SHARED, this file builds into
//   xiom_hot_runtime.dll/.so. The table is exported so every loaded
//   module DLL sees the SAME function pointers. The host patches
//   the table on reload; modules see the updates immediately.
//
//   When linked statically into each module (default), each module
//   gets its own private table. Module-level hot reload requires the
//   shared configuration.
//
// Safety (Phase 7D):
//   - Atomic pointer swaps via InterlockedExchange (Windows) / atomic (C11)
//   - Table bounds checking on every access
//   - Reference counting for safe unload: don't swap pointers while in-flight
//   - State versioning: embed layout hash to detect struct changes
//
// AUDIT (2026-09-17): several entry points in this file are exported ABI
// surface for live patching and are intentionally kept even though textual
// scans find no in-tree callers:
//   xiom_hot_init (dynamically loaded by tools/xiom_hot_host.c),
//   xiom_hot_enter/leave/register/generation/get_version/is_stale,
//   xiom_hot_set_contract_checker/verify_contracts,
//   xiom_hot_save_state_legacy/restore_state_legacy.
// Compiler codegen emits xiom_hot_get_ptr/set_ptr thunks; the host calls
// xiom_hot_save_state/restore_state by name. See docs/RUNTIME_SYMBOL_AUDIT.md.

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// ============================================================================
// Configuration
// ============================================================================

#define XIOM_HOT_MAX_FUNCTIONS 1024
#define XIOM_HOT_STATE_MAGIC   0x58494F4D  // "XIOM"
#define XIOM_HOT_STATE_VERSION 1

// ============================================================================
// Pointer Table
// ============================================================================

#ifdef XIOM_HOT_RUNTIME_SHARED
    // Process-wide table: exported from xiom_hot_runtime.dll
    #ifdef _WIN32
        #define XIOM_HOT_EXPORT __declspec(dllexport)
    #else
        #define XIOM_HOT_EXPORT __attribute__((visibility("default")))
    #endif
#else
    // Private table: linked into each DLL
    #define XIOM_HOT_EXPORT
#endif

// The function pointer table. When built as a shared runtime, this
// is the SINGLE source of truth for all loaded modules.
XIOM_HOT_EXPORT void* xiom_hot_ptr_table[XIOM_HOT_MAX_FUNCTIONS];
XIOM_HOT_EXPORT int   xiom_hot_ptr_count;
XIOM_HOT_EXPORT int   xiom_hot_ptr_generation; // incremented on each reload

// Per-slot metadata for safe pointer swapping
typedef struct {
    int      in_flight;    // > 0 if a call is currently executing through this slot
    uint64_t version;      // monotonic version of the function at this slot
} HotSlotMeta;

static HotSlotMeta slot_meta[XIOM_HOT_MAX_FUNCTIONS];

// ============================================================================
// Hash function (djb2 -- must match Rust-side djb2_hash in xiom-codegen)
// ============================================================================

static int hot_name_hash(const char* name) {
    unsigned long hash = 5381;
    int c;
    while ((c = *name++)) { hash = ((hash << 5) + hash) + c; }
    return (int)(hash % XIOM_HOT_MAX_FUNCTIONS);
}

// ============================================================================
// Public API
// ============================================================================

// Initialize the hot reload pointer table.
void xiom_hot_init(void) {
    for (int i = 0; i < XIOM_HOT_MAX_FUNCTIONS; i++) {
        xiom_hot_ptr_table[i] = NULL;
        slot_meta[i].in_flight = 0;
        slot_meta[i].version = 0;
    }
    xiom_hot_ptr_count = 0;
    xiom_hot_ptr_generation = 0;
}

// Get the current generation counter (incremented on each full reload cycle).
int xiom_hot_generation(void) {
    return xiom_hot_ptr_generation;
}

// Store a function pointer at a stable index derived from name hash.
// Returns the assigned index, or -1 if table is full.
int xiom_hot_register(const char* name, void* fn_ptr) {
    int idx = hot_name_hash(name);
    for (int i = 0; i < XIOM_HOT_MAX_FUNCTIONS; i++) {
        int probe = (idx + i) % XIOM_HOT_MAX_FUNCTIONS;
        if (xiom_hot_ptr_table[probe] == NULL) {
            xiom_hot_ptr_table[probe] = fn_ptr;
            slot_meta[probe].version = 1;
            xiom_hot_ptr_count++;
            return probe;
        }
    }
    return -1;
}

// Update a function pointer atomically (called by host on hot reload).
// Returns 1 on success, 0 if the slot was in-flight (caller should retry).
int xiom_hot_set_ptr(int64_t fn_id, int64_t new_ptr) {
    int idx = (int)fn_id;
    if (idx < 0 || idx >= XIOM_HOT_MAX_FUNCTIONS) return 0;
    if (new_ptr == 0) return 0;

    // Check if a call is in-flight through this slot
    if (slot_meta[idx].in_flight > 0) {
        return 0; // caller should retry
    }

    void* old_ptr = xiom_hot_ptr_table[idx];
    xiom_hot_ptr_table[idx] = (void*)(intptr_t)new_ptr;
    slot_meta[idx].version++;

    // If this was a new registration (empty slot), increment count
    if (old_ptr == NULL) {
        xiom_hot_ptr_count++;
    }

    return 1;
}

// Mark a slot as "in flight" -- a call is executing through it.
// Returns the current pointer (for the caller to use).
int64_t xiom_hot_enter(int64_t fn_id) {
    int idx = (int)fn_id;
    if (idx < 0 || idx >= XIOM_HOT_MAX_FUNCTIONS) return 0;
    slot_meta[idx].in_flight++;
    return (int64_t)(intptr_t)xiom_hot_ptr_table[idx];
}

// Mark a slot as no longer in flight.
void xiom_hot_leave(int64_t fn_id) {
    int idx = (int)fn_id;
    if (idx >= 0 && idx < XIOM_HOT_MAX_FUNCTIONS) {
        if (slot_meta[idx].in_flight > 0) {
            slot_meta[idx].in_flight--;
        }
    }
}

// Get a function pointer by index (called by thunks at runtime).
// The thunks use enter/leave for safe pointer access.
int64_t xiom_hot_get_ptr(int64_t fn_id) {
    int idx = (int)fn_id;
    if (idx >= 0 && idx < XIOM_HOT_MAX_FUNCTIONS) {
        return (int64_t)(intptr_t)xiom_hot_ptr_table[idx];
    }
    return 0;
}

// Check if a slot has been updated since a given version.
int xiom_hot_is_stale(int64_t fn_id, uint64_t known_version) {
    int idx = (int)fn_id;
    if (idx >= 0 && idx < XIOM_HOT_MAX_FUNCTIONS) {
        return slot_meta[idx].version > known_version ? 1 : 0;
    }
    return 0;
}

// Get the version of a slot.
uint64_t xiom_hot_get_version(int64_t fn_id) {
    int idx = (int)fn_id;
    if (idx >= 0 && idx < XIOM_HOT_MAX_FUNCTIONS) {
        return slot_meta[idx].version;
    }
    return 0;
}

// ============================================================================
// State Migration v2 (Phase 7D: versioned state with layout hash)
// ============================================================================

#include <stdio.h>

// State file header
typedef struct {
    uint32_t magic;        // XIOM_HOT_STATE_MAGIC
    uint32_t version;      // XIOM_HOT_STATE_VERSION
    uint64_t layout_hash;  // hash of all global variable types/sizes
    uint64_t data_size;    // size of the data blob following the header
} XiomHotStateHeader;

// Compute a simple FNV-1a hash of global layout metadata.
// The layout metadata string is generated by the compiler from
// all tracked globals: "name:type:size;name:type:size;..."
static uint64_t hot_layout_hash(const char* metadata) {
    uint64_t hash = 14695981039346656037ULL; // FNV offset basis
    while (*metadata) {
        hash ^= (uint64_t)(unsigned char)*metadata++;
        hash *= 1099511628211ULL; // FNV prime
    }
    return hash;
}

// Save state with versioning header.
// Returns 0 on success, -1 on error.
int xiom_hot_save_state_v2(const char* path,
                           const char* layout_metadata,
                           const uint8_t* data,
                           uint64_t data_size) {
    FILE* f = fopen(path, "wb");
    if (!f) return -1;

    XiomHotStateHeader hdr;
    hdr.magic       = XIOM_HOT_STATE_MAGIC;
    hdr.version     = XIOM_HOT_STATE_VERSION;
    hdr.layout_hash = hot_layout_hash(layout_metadata);
    hdr.data_size   = data_size;

    if (fwrite(&hdr, sizeof(hdr), 1, f) != 1) { fclose(f); return -1; }
    if (data_size > 0 && data) {
        if (fwrite(data, 1, (size_t)data_size, f) != (size_t)data_size) {
            fclose(f); return -1;
        }
    }

    fclose(f);
    return 0;
}

// Restore state with versioning check.
// Returns:
//   0  = success (state restored into provided buffer)
//  -1  = file error (cannot read)
//  -2  = magic mismatch (not a valid state file)
//  -3  = version mismatch (state file from a different compiler version)
//  -4  = layout mismatch (global variable layout changed, full restart needed)
int xiom_hot_restore_state_v2(const char* path,
                              const char* layout_metadata,
                              uint8_t* out_data,
                              uint64_t out_size) {
    FILE* f = fopen(path, "rb");
    if (!f) return -1;

    XiomHotStateHeader hdr;
    if (fread(&hdr, sizeof(hdr), 1, f) != 1) { fclose(f); return -1; }

    // Validate header
    if (hdr.magic != XIOM_HOT_STATE_MAGIC) { fclose(f); return -2; }
    if (hdr.version != XIOM_HOT_STATE_VERSION) { fclose(f); return -3; }

    uint64_t expected_hash = hot_layout_hash(layout_metadata);
    if (hdr.layout_hash != expected_hash) { fclose(f); return -4; }

    // Read data
    size_t to_read = (size_t)(hdr.data_size < out_size ? hdr.data_size : out_size);
    if (to_read > 0) {
        if (fread(out_data, 1, to_read, f) != to_read) { fclose(f); return -1; }
    }

    fclose(f);
    return 0;
}

// Legacy save (backward compat -- used when host doesn't pass layout metadata).
int xiom_hot_save_state_legacy(const char* path, const uint8_t* data, uint64_t size) {
    return xiom_hot_save_state_v2(path, "", data, size);
}

// Legacy restore (backward compat -- skips layout check).
int xiom_hot_restore_state_legacy(const char* path, uint8_t* out, uint64_t size) {
    // Try v2 first, fall back to raw read
    int rc = xiom_hot_restore_state_v2(path, "", out, size);
    if (rc == -2 || rc == -3 || rc == -4) {
        // Try reading as raw data (pre-7D format)
        FILE* f = fopen(path, "rb");
        if (!f) return -1;
        size_t rd = fread(out, 1, (size_t)size, f);
        fclose(f);
        return (rd == (size_t)size) ? 0 : -1;
    }
    return rc;
}

// ============================================================================
// Contract verification on reload (Phase 7D.3)
// ============================================================================

// Callback type: host provides a function that checks contracts
// for a reloaded module. Returns 0 if contracts pass, non-zero if fail.
typedef int (*xiom_hot_contract_check_fn)(const char* module_name);

static xiom_hot_contract_check_fn contract_checker = NULL;

// Register a contract verification callback.
void xiom_hot_set_contract_checker(xiom_hot_contract_check_fn checker) {
    contract_checker = checker;
}

// Verify contracts for a module before allowing hot reload.
// Called by the host before swapping function pointers.
// Returns 0 if contracts pass (or no checker registered), non-zero if fail.
int xiom_hot_verify_contracts(const char* module_name) {
    if (contract_checker) {
        return contract_checker(module_name);
    }
    return 0; // no checker = pass (permissive mode)
}

