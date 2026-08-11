// XIOM - Format: ANSI Escape Codes
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.ansi

// Depends on: xiom.string

// ============================================================================
// ANSI SGR styling, 8/16/256/RGB colors, and cursor/screen control sequences.
// NOTE: current implementation lives in fmt.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn ansi_fg(code: Int) -> Str - foreground SGR sequence for a base color code. TODO(compiler): implement.
// fn ansi_bg(code: Int) -> Str - background SGR sequence for a base color code. TODO(compiler): implement.
// fn ansi_rgb_fg(r, g, b) -> Str - 24-bit foreground SGR sequence. TODO(compiler): implement.
// fn ansi_rgb_bg(r, g, b) -> Str - 24-bit background SGR sequence. TODO(compiler): implement.
// fn ansi_256_fg(code) -> Str - 256-color foreground SGR sequence. TODO(compiler): implement.
// fn ansi_256_bg(code) -> Str - 256-color background SGR sequence. TODO(compiler): implement.
// fn ansi_reset() -> Str - reset all attributes. TODO(compiler): implement.
// fn ansi_bold() -> Str - enable bold. TODO(compiler): implement.
// fn ansi_dim() -> Str - enable dim intensity. TODO(compiler): implement.
// fn ansi_italic() -> Str - enable italic. TODO(compiler): implement.
// fn ansi_underline() -> Str - enable underline. TODO(compiler): implement.
// fn ansi_blink() -> Str - enable blink. TODO(compiler): implement.
// fn ansi_reverse() -> Str - enable reverse video. TODO(compiler): implement.
// fn ansi_strike() -> Str - enable strikethrough. TODO(compiler): implement.
// fn ansi_cursor_to(row, col) -> Str - move the cursor to an absolute row/column. TODO(compiler): implement.
// fn ansi_cursor_up(n) -> Str - move the cursor up n lines. TODO(compiler): implement.
// fn ansi_cursor_down(n) -> Str - move the cursor down n lines. TODO(compiler): implement.
// fn ansi_cursor_right(n) -> Str - move the cursor right n columns. TODO(compiler): implement.
// fn ansi_cursor_left(n) -> Str - move the cursor left n columns. TODO(compiler): implement.
// fn ansi_clear_screen() -> Str - clear the whole screen and home the cursor. TODO(compiler): implement.
// fn ansi_clear_line() -> Str - clear the current line. TODO(compiler): implement.
// fn ansi_save_cursor() -> Str - save the cursor position. TODO(compiler): implement.
// fn ansi_restore_cursor() -> Str - restore the saved cursor position. TODO(compiler): implement.
// fn ansi_hide_cursor() -> Str - make the cursor invisible. TODO(compiler): implement.
// fn ansi_show_cursor() -> Str - make the cursor visible. TODO(compiler): implement.
