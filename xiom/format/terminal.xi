// XIOM - Format: Terminal
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.terminal

// Depends on: xiom.string

// ============================================================================
// Terminal UI helpers: progress bars, spinners, ANSI styles, colors (named,
// 256, RGB), cursor control, and screen/line clearing. Pure escape-string
// builders with zero external dependencies.
// ============================================================================

// fn progress_new(total: Int) -> Progress - create a progress bar over total units. TODO(compiler): implement.
// fn progress_update(p: Progress, done: Int) -> Unit - advance the bar to done units. TODO(compiler): implement.
// fn progress_render(p: Progress) -> Str - render the bar to a single line string. TODO(compiler): implement.
// fn progress_finish(p: Progress) -> Unit - finalize the bar (full, newline). TODO(compiler): implement.
// fn progress_percent(p: Progress) -> Int - percent complete, 0..100. TODO(compiler): implement.
// fn progress_eta(p: Progress) -> Int - estimated seconds remaining, or -1 if unknown. TODO(compiler): implement.
// fn spinner_new() -> Spinner - create a new spinner with the default frame set. TODO(compiler): implement.
// fn spinner_tick(sp: Spinner) -> Str - advance the spinner and return its frame string. TODO(compiler): implement.
// fn spinner_frame(sp: Spinner) -> Int - current frame index of the spinner. TODO(compiler): implement.
// fn ansi_reset() -> Str - ANSI reset attribute sequence. TODO(compiler): implement.
// fn ansi_bold() -> Str - ANSI bold attribute sequence. TODO(compiler): implement.
// fn ansi_dim() -> Str - ANSI dim attribute sequence. TODO(compiler): implement.
// fn ansi_italic() -> Str - ANSI italic attribute sequence. TODO(compiler): implement.
// fn ansi_underline() -> Str - ANSI underline attribute sequence. TODO(compiler): implement.
// fn ansi_blink() -> Str - ANSI blink attribute sequence. TODO(compiler): implement.
// fn ansi_reverse() -> Str - ANSI reverse video attribute sequence. TODO(compiler): implement.
// fn ansi_strike() -> Str - ANSI strikethrough attribute sequence. TODO(compiler): implement.
// fn ansi_fg_black() -> Str - ANSI black foreground sequence. TODO(compiler): implement.
// fn ansi_fg_red() -> Str - ANSI red foreground sequence. TODO(compiler): implement.
// fn ansi_fg_green() -> Str - ANSI green foreground sequence. TODO(compiler): implement.
// fn ansi_fg_yellow() -> Str - ANSI yellow foreground sequence. TODO(compiler): implement.
// fn ansi_fg_blue() -> Str - ANSI blue foreground sequence. TODO(compiler): implement.
// fn ansi_fg_magenta() -> Str - ANSI magenta foreground sequence. TODO(compiler): implement.
// fn ansi_fg_cyan() -> Str - ANSI cyan foreground sequence. TODO(compiler): implement.
// fn ansi_fg_white() -> Str - ANSI white foreground sequence. TODO(compiler): implement.
// fn ansi_bg_black() -> Str - ANSI black background sequence. TODO(compiler): implement.
// fn ansi_bg_red() -> Str - ANSI red background sequence. TODO(compiler): implement.
// fn ansi_bg_green() -> Str - ANSI green background sequence. TODO(compiler): implement.
// fn ansi_bg_yellow() -> Str - ANSI yellow background sequence. TODO(compiler): implement.
// fn ansi_bg_blue() -> Str - ANSI blue background sequence. TODO(compiler): implement.
// fn ansi_bg_magenta() -> Str - ANSI magenta background sequence. TODO(compiler): implement.
// fn ansi_bg_cyan() -> Str - ANSI cyan background sequence. TODO(compiler): implement.
// fn ansi_bg_white() -> Str - ANSI white background sequence. TODO(compiler): implement.
// fn ansi_fg_256(code: Int) -> Str - ANSI 256-color foreground escape for code 0..255. TODO(compiler): implement.
// fn ansi_bg_256(code: Int) -> Str - ANSI 256-color background escape for code 0..255. TODO(compiler): implement.
// fn ansi_fg_rgb(r: Int, g: Int, b: Int) -> Str - ANSI 24-bit foreground escape from RGB channels. TODO(compiler): implement.
// fn ansi_bg_rgb(r: Int, g: Int, b: Int) -> Str - ANSI 24-bit background escape from RGB channels. TODO(compiler): implement.
// fn ansi_cursor_up(n: Int) -> Str - move the cursor up n rows. TODO(compiler): implement.
// fn ansi_cursor_down(n: Int) -> Str - move the cursor down n rows. TODO(compiler): implement.
// fn ansi_cursor_forward(n: Int) -> Str - move the cursor right n columns. TODO(compiler): implement.
// fn ansi_cursor_back(n: Int) -> Str - move the cursor left n columns. TODO(compiler): implement.
// fn ansi_cursor_home() -> Str - move the cursor to the home position (1, 1). TODO(compiler): implement.
// fn ansi_cursor_to(row: Int, col: Int) -> Str - move the cursor to the given 1-based row, col. TODO(compiler): implement.
// fn ansi_clear_screen() -> Str - clear the whole screen and home the cursor. TODO(compiler): implement.
// fn ansi_clear_line() -> Str - clear the current line. TODO(compiler): implement.
// fn ansi_erase_above() -> Str - erase from the cursor up to the top of the screen. TODO(compiler): implement.
// fn ansi_erase_below() -> Str - erase from the cursor down to the bottom of the screen. TODO(compiler): implement.
// fn ansi_show_cursor() -> Str - make the cursor visible again. TODO(compiler): implement.
// fn ansi_hide_cursor() -> Str - hide the cursor. TODO(compiler): implement.
// fn ansi_save_cursor() -> Str - save the current cursor position. TODO(compiler): implement.
// fn ansi_restore_cursor() -> Str - restore the last saved cursor position. TODO(compiler): implement.
// fn color_256_to_rgb(code: Int) -> (Int, Int, Int) - convert an xterm-256 index to its RGB triple (r, g, b). TODO(compiler): implement.
// fn rgb_to_ansi256(r: Int, g: Int, b: Int) -> Int - quantize an RGB triple to the nearest xterm-256 index. TODO(compiler): implement.
