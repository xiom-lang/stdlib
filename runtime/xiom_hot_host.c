// XIOM Hot Reload Host (5e.5b)
// Windows DLL host: compiles XIOM source to shared library,
// loads it, and watches for changes to recompile/reload.
//
// Compile: cl xiom_hot_host.c /Fe:xiom_hot_host.exe /link user32.lib
//
// Usage: xiom_hot_host.exe <source.xi> [xiomc args...]
//
// Workflow:
//   1. Compile source.xi → source.dll (via xiomc --shared --hot-reload)
//   2. Load source.dll, call xiom_hot_init(), then main()
//   3. Watch source.xi for changes (poll 500ms)
//   4. On change: recompile → FreeLibrary old DLL → LoadLibrary new DLL
//   5. Thunks in new DLL self-register via xiom_hot_get_ptr on first call
//   6. Ctrl+C to exit

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------

static volatile int g_running = 1;    // Ctrl+C sets to 0
static HMODULE        g_dll = NULL;   // Currently loaded DLL handle
static char           g_dll_path[MAX_PATH];

// ---------------------------------------------------------------------------
// Signal handler — graceful shutdown on Ctrl+C
// ---------------------------------------------------------------------------

static BOOL WINAPI ctrl_handler(DWORD ctrl_type) {
    (void)ctrl_type;
    g_running = 0;
    return TRUE;
}

// ---------------------------------------------------------------------------
// Compile a .xi source to a .dll using xiomc.
// Returns 0 on success, non-zero on failure.
// ---------------------------------------------------------------------------

static int compile_to_dll(const char* src_path, const char* dll_path,
                          int argc, char** argv) {
    // Build the xiomc command line: xiomc --shared --hot-reload <src> [extra args]
    // We pass the user's extra args (e.g. --release) through.
    char cmd[8192];
    int off = snprintf(cmd, sizeof(cmd), "xiomc --shared --hot-reload \"%s\"", src_path);
    if (off < 0 || (size_t)off >= sizeof(cmd)) return 1;

    for (int i = 2; i < argc; i++) {  // argv[0]=host, argv[1]=source
        int rem = (int)sizeof(cmd) - off - 1;
        if (rem <= 0) break;
        off += snprintf(cmd + off, (size_t)rem, " %s", argv[i]);
    }

    // Also pass an explicit output path so the DLL lands next to the source
    if (strlen(dll_path) > 0) {
        int rem = (int)sizeof(cmd) - off - 1;
        if (rem > 0) {
            off += snprintf(cmd + off, (size_t)rem, " -o \"%s\"", dll_path);
        }
    }

    printf("[HOST] Compiling: %s\n", cmd);

    STARTUPINFOA si = { sizeof(si) };
    PROCESS_INFORMATION pi = { 0 };
    si.dwFlags = STARTF_USESTDHANDLES;
    // Inherit our console so user sees compiler output
    si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    si.hStdError  = GetStdHandle(STD_ERROR_HANDLE);

    if (!CreateProcessA(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
        fprintf(stderr, "[HOST] ERROR: Failed to launch xiomc (is it on PATH?): %lu\n", GetLastError());
        return 1;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);

    DWORD exit_code = 1;
    GetExitCodeProcess(pi.hProcess, &exit_code);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    if (exit_code != 0) {
        fprintf(stderr, "[HOST] Compilation failed (exit %lu). Keeping old DLL.\n", exit_code);
        return 1;
    }
    return 0;
}

// ---------------------------------------------------------------------------
// Load a compiled DLL and return its module handle.
// ---------------------------------------------------------------------------

static HMODULE load_dll(const char* dll_path) {
    HMODULE mod = LoadLibraryA(dll_path);
    if (!mod) {
        fprintf(stderr, "[HOST] ERROR: LoadLibrary(%s) failed: %lu\n", dll_path, GetLastError());
    }
    return mod;
}

// ---------------------------------------------------------------------------
// Unload the currently loaded DLL.
// ---------------------------------------------------------------------------

static void unload_dll(HMODULE mod) {
    if (mod) {
        FreeLibrary(mod);
    }
}

// ---------------------------------------------------------------------------
// Call a named function from the loaded DLL.
// Returns 1 on success, 0 on failure.
// ---------------------------------------------------------------------------

typedef int64_t (*fn_main_t)(void);
typedef void    (*fn_init_t)(void);

static int call_main(HMODULE mod) {
    fn_main_t main_fn = (fn_main_t)GetProcAddress(mod, "main");
    if (!main_fn) {
        fprintf(stderr, "[HOST] ERROR: DLL has no 'main' export.\n");
        return 0;
    }
    printf("[HOST] Calling main()...\n");
    int64_t ret = main_fn();
    printf("[HOST] main() returned %lld\n", (long long)ret);
    return 1;
}

static void call_xiom_hot_init(HMODULE mod) {
    fn_init_t init_fn = (fn_init_t)GetProcAddress(mod, "xiom_hot_init");
    if (init_fn) {
        init_fn();
    }
}

// ---------------------------------------------------------------------------
// Get file modification time (seconds since epoch). Returns 0 on error.
// ---------------------------------------------------------------------------

static uint64_t file_mtime(const char* path) {
    HANDLE h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                           NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return 0;

    FILETIME ft;
    uint64_t t = 0;
    if (GetFileTime(h, NULL, NULL, &ft)) {
        t = ((uint64_t)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
    }
    CloseHandle(h);
    return t;
}

// ---------------------------------------------------------------------------
// Build the DLL output path from the source path.
// "src\foo.xi" → "src\foo.dll"
// ---------------------------------------------------------------------------

static void make_dll_path(const char* src, char* out, size_t out_sz) {
    strncpy(out, src, out_sz - 1);
    out[out_sz - 1] = '\0';

    // Strip .xi extension, append .dll
    size_t len = strlen(out);
    if (len > 3 && _stricmp(out + len - 3, ".xi") == 0) {
        out[len - 3] = '\0';
        len -= 3;
    }
    if (len + 5 < out_sz) {
        strcat(out, ".dll");
    }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "XIOM Hot Reload Host v0.1 (5e.5b)\n");
        fprintf(stderr, "Usage: xiom_hot_host.exe <source.xi> [xiomc flags...]\n");
        fprintf(stderr, "\n");
        fprintf(stderr, "Compiles source.xi to a DLL, loads it, runs main(),\n");
        fprintf(stderr, "and watches for changes to recompile/reload.\n");
        fprintf(stderr, "Press Ctrl+C to exit.\n");
        return 1;
    }

    SetConsoleCtrlHandler(ctrl_handler, TRUE);

    const char* src_path = argv[1];
    char dll_path[MAX_PATH];
    make_dll_path(src_path, dll_path, sizeof(dll_path));

    printf("[HOST] === XIOM Hot Reload Host ===\n");
    printf("[HOST] Source: %s\n", src_path);
    printf("[HOST] DLL:    %s\n", dll_path);
    printf("[HOST] Press Ctrl+C to stop.\n\n");

    // --- Initial compile & load ---
    if (compile_to_dll(src_path, dll_path, argc, argv) != 0) {
        fprintf(stderr, "[HOST] Initial compilation failed.\n");
        return 1;
    }

    g_dll = load_dll(dll_path);
    if (!g_dll) return 1;

    call_xiom_hot_init(g_dll);
    call_main(g_dll);

    uint64_t last_mtime = file_mtime(src_path);
    int reload_count = 0;

    // --- Watch loop ---
    while (g_running) {
        Sleep(500);  // 500ms poll interval

        if (!g_running) break;

        uint64_t current_mtime = file_mtime(src_path);
        if (current_mtime == 0) {
            // File disappeared — keep waiting
            continue;
        }

        if (current_mtime != last_mtime) {
            last_mtime = current_mtime;
            reload_count++;
            printf("\n[HOST] === Reload #%d: %s changed ===\n", reload_count, src_path);

            // Recompile
            if (compile_to_dll(src_path, dll_path, argc, argv) != 0) {
                printf("[HOST] Recompilation failed. Keeping old DLL.\n");
                continue;
            }

            // Swap DLLs
            HMODULE old_dll = g_dll;
            g_dll = load_dll(dll_path);
            if (!g_dll) {
                g_dll = old_dll;  // Restore old DLL
                printf("[HOST] Failed to load new DLL. Keeping old DLL.\n");
                continue;
            }

            unload_dll(old_dll);
            call_xiom_hot_init(g_dll);
            call_main(g_dll);
        }
    }

    // --- Cleanup ---
    printf("\n[HOST] Shutting down.\n");
    unload_dll(g_dll);
    g_dll = NULL;

    return 0;
}
