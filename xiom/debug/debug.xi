// XIOM -- Debug Utilities (assert, hexdump, tracing, logging)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Lightweight development-time tools. All functions are designed to be
// zero-overhead in release builds (via compile-time stripping of debug
// intrinsics) or to be easily removable.
//
// Logging functions delegate to xiom.log for structured output.

module xiom.debug

use xiom.debug.trace;
use xiom.debug.disasm;
use xiom.debug.heap_report;

use xiom.io;
use xiom.core;
use xiom.time;
use xiom.reflect;
use xiom.log;
use xiom.encoding;
use xiom.convert;

extern "C" {
    fn malloc(size: UInt) -> *UInt8;
    fn xiom_char_at(s: Str, pos: Int) -> Char;
}

// -- Print to stderr ----------------------------------------------------------

/// Write a message to stderr with a "DEBUG:" prefix.
/// Uses xiom.io.println which goes to stdout; stderr is not directly exposed
/// in the current io module. The prefix clearly distinguishes debug output.
pub fn debug_print(msg: Str)
    requires: msg.len() >= 0
{
    xiom.io.println("DEBUG: " + msg)
}

// -- Debug assertion ----------------------------------------------------------

/// Assert that a condition holds; panics with the given message if false.
/// In a release build, this should be a no-op (stripped by the compiler).
/// Currently unconditionally calls xiom.core.panic on failure.
/// The compiler may optimize this away when debug assertions are disabled.
pub fn assert_debug(cond: Bool, msg: Str)
    requires: msg.len() > 0
{
    if !cond {
        xiom.core.panic("DEBUG ASSERTION FAILED: " + msg);
    }
}

// -- Hex dump -----------------------------------------------------------------

/// Produce a formatted hex + ASCII dump string for a byte vector.
/// Each line shows: 8-digit hex offset, 16 bytes in hex (grouped 8+8),
/// then the ASCII representation (printable chars or '.').
///
/// Example output:
///   00000000  48 65 6C 6C 6F 20 57 6F  72 6C 64 21 00 00 00 00  |Hello World!....|
///
/// Complexity: O(n) where n = data.len().
pub fn hexdump(data: &Vec[UInt8], width: Int) -> Str
    requires: width > 0
    ensures:  result.len() >= 0
{
    let len = data.len();
    if len == 0 {
        return "";
    };
    let hex_chars: Str = "0123456789ABCDEF";
    // Estimate output size: each byte -> 3 chars (2 hex + space) + ASCII column + offset
    // Rough upper bound: (offset_width + 2 + 3*width + 1 + width + 1) * ceil(len/width)
    let lines = (len + width - 1) / width;
    let line_size = 10 + 3 * width + 1 + width + 1; // offset(8)+sp+hex(3*w)+sp+ascii(width)+\n
    let out_len = lines * line_size + 1;
    unsafe {
        var buf = malloc(out_len as UInt);
        var out: Int = 0;
        var offset: Int = 0;

        while offset < len {
            // Write 8-digit hex offset (padded with leading zeros)
            var i: Int = 7;
            var off = offset;
            while i >= 0 {
                let nibble = off & 0xF;
                buf[out + i] = xiom_char_at(hex_chars, nibble) as UInt8;
                off = off >> 4;
                i = i - 1;
            };
            out = out + 8;

            // Space after offset
            buf[out] = 32; // ' '
            out = out + 1;

            // Hex bytes for this row
            var col: Int = 0;
            var hex_start: Int = out;
            while col < width {
                if offset + col < len {
                    let b = data[offset + col] as Int;
                    buf[out] = xiom_char_at(hex_chars, (b >> 4) & 0xF) as UInt8;
                    out = out + 1;
                    buf[out] = xiom_char_at(hex_chars, b & 0xF) as UInt8;
                    out = out + 1;
                } else {
                    // Pad with spaces for missing bytes
                    buf[out] = 32; // ' '
                    out = out + 1;
                    buf[out] = 32; // ' '
                    out = out + 1;
                };
                // Add space after every byte; extra space at the 8-byte boundary
                buf[out] = 32; // ' '
                out = out + 1;
                if col == 7 {
                    buf[out] = 32; // ' ' (extra gap between 8-byte groups)
                    out = out + 1;
                };
                col = col + 1;
            };

            // Space before ASCII column
            buf[out] = 32; // ' '
            out = out + 1;

            // ASCII representation
            col = 0;
            while col < width && offset + col < len {
                let b = data[offset + col] as Int;
                if b >= 32 && b <= 126 {
                    buf[out] = b as UInt8;
                } else {
                    buf[out] = 46; // '.'
                };
                out = out + 1;
                col = col + 1;
            };

            // Newline
            buf[out] = 10; // '\n'
            out = out + 1;

            offset = offset + width;
        };

        buf[out] = 0; // null-terminate
        return Str.from_cstring(buf);
    }
}

// -- Trace point --------------------------------------------------------------

/// Return a timestamped marker string for tracing execution flow.
/// Uses xiom.time.time(0) for the current Unix timestamp.
/// Format: "[TRACE] <name> @ <timestamp_secs>"
pub fn trace_point(name: Str) -> Str
    requires: name.len() > 0
    ensures:  result.len() > 0
{
    let ts: Int;
    unsafe {
        // Use xiom.io.time_now() instead of inline extern "C"
        ts = xiom.io.time_now();
    }
    "[TRACE] " + name + " @ " + xiom.convert.int_to_string(ts)
}

// -- Elapsed time -------------------------------------------------------------

/// Convert a nanosecond timestamp (e.g., from xiom.time) to elapsed milliseconds
/// as a Float64. Use with xiom.time.Instant for measuring code sections.
///
/// Example:
///   let start = xiom.time.Instant.now();
///   // ... work ...
///   let ms = elapsed_ms(start.elapsed().as_nanos());
pub fn elapsed_ms(start_ns: Int) -> Float64
    ensures: result >= 0.0
{
    (start_ns as Float64) / 1000000.0
}

// -- Type name (delegates to reflect) -----------------------------------------

/// Return the name of a type at runtime.
/// Delegates to xiom.reflect.type_name which currently returns "unknown"
/// for most types due to limited RTTI support.
/// This is a best-effort debugging aid.
pub fn type_name_of[T]() -> Str
    ensures: result.len() > 0
{
    xiom.reflect.type_name[T]()
}

// -- Logging wrappers (delegate to xiom.log) ----------------------------------

/// Log a message at DEBUG level. Delegates to xiom.log.debug.
pub fn log_debug(msg: Str)
    requires: msg.len() >= 0
{
    xiom.log.debug(msg);
}

/// Log a message at INFO level. Delegates to xiom.log.info.
pub fn log_info(msg: Str)
    requires: msg.len() > 0
{
    xiom.log.info(msg);
}

/// Log a message at WARN level. Delegates to xiom.log.warn.
pub fn log_warn(msg: Str)
    requires: msg.len() > 0
{
    xiom.log.warn(msg);
}

/// Log a message at ERROR level. Delegates to xiom.log.error.
pub fn log_error(msg: Str)
    requires: msg.len() > 0
{
    xiom.log.error(msg);
}
