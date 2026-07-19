// XIOM Hot Reload Runtime (5e)
// Function pointer table for dynamic code replacement.
// Works with --hot-reload flag: pub fn calls go through this table,
// enabling the host process to swap implementations at runtime.

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define XIOM_HOT_MAX_FUNCTIONS 1024

static void* hot_ptr_table[XIOM_HOT_MAX_FUNCTIONS];
static int   hot_ptr_count = 0;

// Hash a function name to a stable table index (djb2).
static int hot_name_hash(const char* name) {
    unsigned long hash = 5381;
    int c;
    while ((c = *name++)) { hash = ((hash << 5) + hash) + c; }
    return (int)(hash % XIOM_HOT_MAX_FUNCTIONS);
}

// Initialize the hot reload pointer table.
void xiom_hot_init(void) {
    for (int i = 0; i < XIOM_HOT_MAX_FUNCTIONS; i++) {
        hot_ptr_table[i] = NULL;
    }
    hot_ptr_count = 0;
}

// Store a function pointer at a stable index derived from name_hash.
// Returns the assigned index.
int xiom_hot_register(const char* name, void* fn_ptr) {
    int idx = hot_name_hash(name);
    // Linear probe for empty slot
    for (int i = 0; i < XIOM_HOT_MAX_FUNCTIONS; i++) {
        int probe = (idx + i) % XIOM_HOT_MAX_FUNCTIONS;
        if (hot_ptr_table[probe] == NULL) {
            hot_ptr_table[probe] = fn_ptr;
            hot_ptr_count++;
            return probe;
        }
    }
    return -1; // table full
}

// Update a function pointer (called by host on hot reload).
void xiom_hot_set_ptr(int64_t fn_id, int64_t new_ptr) {
    if (fn_id >= 0 && fn_id < XIOM_HOT_MAX_FUNCTIONS) {
        hot_ptr_table[(int)fn_id] = (void*)(intptr_t)new_ptr;
    }
}

// Get a function pointer by index (called by thunks at runtime).
int64_t xiom_hot_get_ptr(int64_t fn_id) {
    if (fn_id >= 0 && fn_id < XIOM_HOT_MAX_FUNCTIONS) {
        return (int64_t)(intptr_t)hot_ptr_table[(int)fn_id];
    }
    return 0;
}
