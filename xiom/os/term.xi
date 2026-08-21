// XIOM -- Terminal Helpers (xiom.os.term)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Pure terminal escape-sequence helpers plus documented stubs for the
// operations that would require termios/ioctl FFI (not exposed by the
// Xiom runtime).

module xiom.os.term

use xiom.convert;

// term_is_tty returns true if the given file descriptor refers to a
// terminal. The Xiom runtime does not expose an isatty intrinsic, so
// this always returns false until such an FFI exists.
pub fn term_is_tty(fd: Int) -> Bool {
  // requires isatty FFI in xiom_runtime.c; not currently available
  return false;
}

// term_clear_screen returns the ANSI escape sequence that clears the
// screen and homes the cursor.
pub fn term_clear_screen() -> Str {
  return "\x1b[2J\x1b[H";
}

// term_set_foreground returns the ANSI 256-color foreground escape for
// the given color index (0..255).
pub fn term_set_foreground(color: Int) -> Str {
  return "\x1b[38;5;" + convert.int_to_string(color) + "m";
}

// term_reset returns the ANSI sequence that resets all attributes.
pub fn term_reset() -> Str {
  return "\x1b[0m";
}

// term_bold returns the ANSI sequence enabling bold.
pub fn term_bold() -> Str {
  return "\x1b[1m";
}

// term_dim returns the ANSI sequence enabling dim intensity.
pub fn term_dim() -> Str {
  return "\x1b[2m";
}

// term_underline returns the ANSI sequence enabling underline.
pub fn term_underline() -> Str {
  return "\x1b[4m";
}

// term_cursor_hide returns the ANSI sequence that hides the cursor.
pub fn term_cursor_hide() -> Str {
  return "\x1b[?25l";
}

// term_cursor_show returns the ANSI sequence that shows the cursor.
pub fn term_cursor_show() -> Str {
  return "\x1b[?25h";
}

// term_cursor_move returns the ANSI sequence that moves the cursor to
// the given 1-based row and column.
pub fn term_cursor_move(row: Int, col: Int) -> Str {
  return "\x1b[" + convert.int_to_string(row) + ";" + convert.int_to_string(col) + "H";
}

// term_width returns the terminal width in columns. The Xiom runtime
// does not expose TIOCGWINSZ/GetConsoleScreenBufferInfo, so the width
// is unknown; 0 means "unknown".
pub fn term_width() -> Int {
  // requires termios FFI; 0 = unknown
  return 0;
}
