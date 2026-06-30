// AXIOM Runtime — C helper functions for self-hosting
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Read an entire file and return as a null-terminated string.
// Returns NULL on failure. Caller must free() the result.
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

// Get the length of a file (size in bytes).
// Returns -1 on failure.
long axiom_file_size(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fclose(f);
    return size;
}

// Free memory allocated by axiom_read_file
void axiom_free(void* ptr) {
    free(ptr);
}
