// XIOM -- Terminal Helpers (xiom.os.term)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure terminal escape-sequence helpers plus documented stubs for the
// operations that would require termios/ioctl FFI (not exposed by the
// Xiom runtime).
//
// DEDUP (2026-09-16): the unimplemented queries delegate to xiom.os.terminal
// (single "unknown" policy: isatty -> false, width -> 0) and the four basic
// style sequences delegate to xiom.format.terminal's ansi_* builders (same
// bytes). The clear/cursor/256-color helpers stay local (no canonical
// counterpart). Aliased imports keep the same-leaf "terminal" pair apart.

module xiom.os.term

use xiom.convert;
use xiom.os.terminal as term_os;
use xiom.format.terminal as fmt_term;

// term_is_tty returns true if the given file descriptor refers to a
// terminal. Delegates to xiom.os.terminal.isatty (the runtime does not
// expose an isatty intrinsic, so that is also false until an FFI exists).
/// term_is_tty returns true if the given file descriptor refers to a
/// terminal. Delegates to xiom.os.terminal.isatty (the runtime does not
/// expose an isatty intrinsic, so that is also false until an FFI exists).
pub fn term_is_tty(fd: Int) -> Bool {
  return term_os.isatty(fd);
}

// term_clear_screen returns the ANSI escape sequence that clears the
// screen and homes the cursor.
/// term_clear_screen returns the ANSI escape sequence that clears the
/// screen and homes the cursor.
pub fn term_clear_screen() -> Str {
  return "\x1b[2J\x1b[H";
}

// term_set_foreground returns the ANSI 256-color foreground escape for
// the given color index (0..255).
/// term_set_foreground returns the ANSI 256-color foreground escape for
/// the given color index (0..255).
pub fn term_set_foreground(color: Int) -> Str {
  return "\x1b[38;5;" + convert.int_to_string(color) + "m";
}

// term_reset returns the ANSI sequence that resets all attributes.
/// term_reset returns the ANSI sequence that resets all attributes.
pub fn term_reset() -> Str {
  return fmt_term.ansi_reset();
}

// term_bold returns the ANSI sequence enabling bold.
/// term_bold returns the ANSI sequence enabling bold.
pub fn term_bold() -> Str {
  return fmt_term.ansi_bold();
}

// term_dim returns the ANSI sequence enabling dim intensity.
/// term_dim returns the ANSI sequence enabling dim intensity.
pub fn term_dim() -> Str {
  return fmt_term.ansi_dim();
}

// term_underline returns the ANSI sequence enabling underline.
/// term_underline returns the ANSI sequence enabling underline.
pub fn term_underline() -> Str {
  return fmt_term.ansi_underline();
}

// term_cursor_hide returns the ANSI sequence that hides the cursor.
/// term_cursor_hide returns the ANSI sequence that hides the cursor.
pub fn term_cursor_hide() -> Str {
  return "\x1b[?25l";
}

// term_cursor_show returns the ANSI sequence that shows the cursor.
/// term_cursor_show returns the ANSI sequence that shows the cursor.
pub fn term_cursor_show() -> Str {
  return "\x1b[?25h";
}

// term_cursor_move returns the ANSI sequence that moves the cursor to
// the given 1-based row and column.
/// term_cursor_move returns the ANSI sequence that moves the cursor to
/// the given 1-based row and column.
pub fn term_cursor_move(row: Int, col: Int) -> Str {
  return "\x1b[" + convert.int_to_string(row) + ";" + convert.int_to_string(col) + "H";
}

// term_width returns the terminal width in columns. Delegates to
// xiom.os.terminal.terminal_width; the runtime does not expose
// TIOCGWINSZ/GetConsoleScreenBufferInfo, so 0 means "unknown".
/// term_width returns the terminal width in columns. Delegates to
/// xiom.os.terminal.terminal_width; the runtime does not expose
/// TIOCGWINSZ/GetConsoleScreenBufferInfo, so 0 means "unknown".
pub fn term_width() -> Int {
  return term_os.terminal_width();
}
