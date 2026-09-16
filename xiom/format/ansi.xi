// XIOM - Format: ANSI Escape Codes
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.ansi

// Depends on: xiom.string

use xiom.convert;

// ============================================================================
// ANSI SGR styling, 8/16/256/RGB colors, and cursor/screen control sequences.
// Every function returns the pure escape sequence string; nothing is written
// to the terminal. SGR codes: 30-37 foreground, 40-47 background, 38/48
// extended (256 or 24-bit), 1-9 attributes. Sequences use the ESC prefix
// (\u{001b}) followed by a parameter string and a final letter.
// ============================================================================

/// SGR foreground sequence for a base color code (0-7, clamped): ansi_fg(1)
/// == "\u{001b}[31m" (red). Complexity: O(1).
pub fn ansi_fg(code: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  var c = code;
  if c < 0 {
    c = 0;
  };
  if c > 7 {
    c = 7;
  };
  return "\u{001b}[3" + convert.int_to_string(c) + "m";
}

/// SGR background sequence for a base color code (0-7, clamped): ansi_bg(1)
/// == "\u{001b}[41m". Complexity: O(1).
pub fn ansi_bg(code: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  var c = code;
  if c < 0 {
    c = 0;
  };
  if c > 7 {
    c = 7;
  };
  return "\u{001b}[4" + convert.int_to_string(c) + "m";
}

/// 24-bit foreground SGR sequence from RGB channels (0-255 each, clamped).
/// Format: "\u{001b}[38;2;r;g;bm". Complexity: O(1).
pub fn ansi_rgb_fg(r: Int, g: Int, b: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[38;2;" + convert.int_to_string(clamp8(r)) + ";" + convert.int_to_string(clamp8(g)) + ";" + convert.int_to_string(clamp8(b)) + "m";
}

/// 24-bit background SGR sequence from RGB channels (0-255 each, clamped).
/// Format: "\u{001b}[48;2;r;g;bm". Complexity: O(1).
pub fn ansi_rgb_bg(r: Int, g: Int, b: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[48;2;" + convert.int_to_string(clamp8(r)) + ";" + convert.int_to_string(clamp8(g)) + ";" + convert.int_to_string(clamp8(b)) + "m";
}

/// 256-color foreground SGR sequence for code 0-255 (clamped).
/// Format: "\u{001b}[38;5;Xm". Complexity: O(1).
pub fn ansi_256_fg(code: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[38;5;" + convert.int_to_string(clamp8(code)) + "m";
}

/// 256-color background SGR sequence for code 0-255 (clamped).
/// Format: "\u{001b}[48;5;Xm". Complexity: O(1).
pub fn ansi_256_bg(code: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[48;5;" + convert.int_to_string(clamp8(code)) + "m";
}

/// Reset all SGR attributes: "\u{001b}[0m".
pub fn ansi_reset() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[0m";
}

/// Enable bold: "\u{001b}[1m".
pub fn ansi_bold() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[1m";
}

/// Enable dim intensity: "\u{001b}[2m".
pub fn ansi_dim() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[2m";
}

/// Enable italic: "\u{001b}[3m".
pub fn ansi_italic() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[3m";
}

/// Enable underline: "\u{001b}[4m".
pub fn ansi_underline() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[4m";
}

/// Enable blink: "\u{001b}[5m".
pub fn ansi_blink() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[5m";
}

/// Enable reverse video: "\u{001b}[7m".
pub fn ansi_reverse() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[7m";
}

/// Enable strikethrough: "\u{001b}[9m".
pub fn ansi_strike() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[9m";
}

/// Move the cursor to an absolute 1-based (row, column): "\u{001b}[r;cH".
/// Non-positive values clamp to 1.
pub fn ansi_cursor_to(row: Int, col: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  var r = row;
  if r < 1 {
    r = 1;
  };
  var c = col;
  if c < 1 {
    c = 1;
  };
  return "\u{001b}[" + convert.int_to_string(r) + ";" + convert.int_to_string(c) + "H";
}

/// Move the cursor up `n` lines (n clamped >= 0): "\u{001b}[nA".
pub fn ansi_cursor_up(n: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[" + convert.int_to_string(max0(n)) + "A";
}

/// Move the cursor down `n` lines: "\u{001b}[nB".
pub fn ansi_cursor_down(n: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[" + convert.int_to_string(max0(n)) + "B";
}

/// Move the cursor right `n` columns: "\u{001b}[nC".
pub fn ansi_cursor_right(n: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[" + convert.int_to_string(max0(n)) + "C";
}

/// Move the cursor left `n` columns: "\u{001b}[nD".
pub fn ansi_cursor_left(n: Int) -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[" + convert.int_to_string(max0(n)) + "D";
}

/// Clear the whole screen and home the cursor: "\u{001b}[2J\u{001b}[H".
pub fn ansi_clear_screen() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[2J\u{001b}[H";
}

/// Clear the current line: "\u{001b}[2K".
pub fn ansi_clear_line() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[2K";
}

/// Save the cursor position: "\u{001b}[s".
pub fn ansi_save_cursor() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[s";
}

/// Restore the saved cursor position: "\u{001b}[u".
pub fn ansi_restore_cursor() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[u";
}

/// Make the cursor invisible: "\u{001b}[?25l".
pub fn ansi_hide_cursor() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[?25l";
}

/// Make the cursor visible: "\u{001b}[?25h".
pub fn ansi_show_cursor() -> Str
  ensures: result.byte_at(0) == 27
{
  return "\u{001b}[?25h";
}

/// Clamp v to [0, 255].
fn clamp8(v: Int) -> Int {
  var x = v;
  if x < 0 {
    x = 0;
  };
  if x > 255 {
    x = 255;
  };
  return x;
}

/// Clamp v to >= 0.
fn max0(v: Int) -> Int {
  if v < 0 {
    return 0;
  };
  return v;
}
