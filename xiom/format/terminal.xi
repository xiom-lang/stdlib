// XIOM - Format: Terminal
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.terminal

// Depends on: xiom.string

use xiom.convert;
use xiom.io;
use xiom.string;

// ============================================================================
// Terminal UI helpers: progress bars, spinners, ANSI styles, colors (named,
// 256, RGB), cursor control, and screen/line clearing. Pure escape-string and
// text builders. Progress bars use the wall clock (xiom.io.time_now) for ETA
// computation; everything else is a pure string builder.
// ============================================================================

/// A progress bar over `total` units with ETA tracking.
pub type Progress = {
  total: Int;
  done: Int;
  started: Int;
  width: Int;
}

/// Create a progress bar over `total` units (clamped to >= 0).
pub fn progress_new(total: Int) -> Progress {
  var t = total;
  if t < 0 {
    t = 0;
  };
  return Progress{ total: t; done: 0; started: io.time_now(); width: 40; };
}

/// Advance the bar to `done` units (clamped to [0, total]).
pub fn progress_update(p: &mut Progress, done: Int) -> Unit {
  var d = done;
  if d < 0 {
    d = 0;
  };
  if d > p.total {
    d = p.total;
  };
  p.done = d;
}

/// Render the bar to a single line string: "[####----] 50%".
pub fn progress_render(p: &Progress) -> Str {
  var pct = progress_percent(p);
  var filled = 0;
  if p.total > 0 {
    filled = (p.done * p.width) / p.total;
  };
  var bar = "";
  var i = 0;
  while i < filled {
    bar = bar + "#";
    i = i + 1;
  }
  var j = filled;
  while j < p.width {
    bar = bar + "-";
    j = j + 1;
  }
  return "[" + bar + "] " + convert.int_to_string(pct) + "%";
}

/// Finalize the bar: mark it complete (done = total). Rendering after this
/// returns a full bar. No terminal I/O is performed.
pub fn progress_finish(p: &mut Progress) -> Unit {
  p.done = p.total;
}

/// Percent complete, 0..100.
pub fn progress_percent(p: &Progress) -> Int {
  if p.total <= 0 {
    return 100;
  };
  var pct = (p.done * 100) / p.total;
  if pct > 100 {
    pct = 100;
  };
  return pct;
}

/// Estimated seconds remaining, or -1 when unknown (nothing done yet).
pub fn progress_eta(p: &Progress) -> Int {
  if p.done <= 0 {
    return -1;
  };
  if p.total <= 0 {
    return 0;
  };
  var now = io.time_now();
  var elapsed = now - p.started;
  if elapsed < 0 {
    elapsed = 0;
  };
  var remaining_work = p.total - p.done;
  if remaining_work <= 0 {
    return 0;
  };
  return (remaining_work * elapsed) / p.done;
}

/// A spinner with a frame set and a current frame index.
pub type Spinner = {
  frames: Vec[Str];
  index: Int;
}

/// Create a new spinner with the default frame set: | / - \.
pub fn spinner_new() -> Spinner {
  var frames = Vec[Str].new();
  frames.push("|");
  frames.push("/");
  frames.push("-");
  frames.push("\\");
  return Spinner{ frames: frames; index: 0; };
}

/// Advance the spinner and return its frame string.
pub fn spinner_tick(sp: &mut Spinner) -> Str {
  sp.index = sp.index + 1;
  if sp.frames.len() == 0 {
    return " ";
  };
  var i = sp.index % sp.frames.len();
  return sp.frames[i];
}

/// Current frame index of the spinner.
pub fn spinner_frame(sp: &Spinner) -> Int {
  return sp.index;
}

/// ANSI reset attribute sequence.
pub fn ansi_reset() -> Str {
  return "\u{001b}[0m";
}

/// ANSI bold attribute sequence.
pub fn ansi_bold() -> Str {
  return "\u{001b}[1m";
}

/// ANSI dim attribute sequence.
pub fn ansi_dim() -> Str {
  return "\u{001b}[2m";
}

/// ANSI italic attribute sequence.
pub fn ansi_italic() -> Str {
  return "\u{001b}[3m";
}

/// ANSI underline attribute sequence.
pub fn ansi_underline() -> Str {
  return "\u{001b}[4m";
}

/// ANSI blink attribute sequence.
pub fn ansi_blink() -> Str {
  return "\u{001b}[5m";
}

/// ANSI reverse video attribute sequence.
pub fn ansi_reverse() -> Str {
  return "\u{001b}[7m";
}

/// ANSI strikethrough attribute sequence.
pub fn ansi_strike() -> Str {
  return "\u{001b}[9m";
}

/// ANSI black foreground sequence.
pub fn ansi_fg_black() -> Str {
  return "\u{001b}[30m";
}

/// ANSI red foreground sequence.
pub fn ansi_fg_red() -> Str {
  return "\u{001b}[31m";
}

/// ANSI green foreground sequence.
pub fn ansi_fg_green() -> Str {
  return "\u{001b}[32m";
}

/// ANSI yellow foreground sequence.
pub fn ansi_fg_yellow() -> Str {
  return "\u{001b}[33m";
}

/// ANSI blue foreground sequence.
pub fn ansi_fg_blue() -> Str {
  return "\u{001b}[34m";
}

/// ANSI magenta foreground sequence.
pub fn ansi_fg_magenta() -> Str {
  return "\u{001b}[35m";
}

/// ANSI cyan foreground sequence.
pub fn ansi_fg_cyan() -> Str {
  return "\u{001b}[36m";
}

/// ANSI white foreground sequence.
pub fn ansi_fg_white() -> Str {
  return "\u{001b}[37m";
}

/// ANSI black background sequence.
pub fn ansi_bg_black() -> Str {
  return "\u{001b}[40m";
}

/// ANSI red background sequence.
pub fn ansi_bg_red() -> Str {
  return "\u{001b}[41m";
}

/// ANSI green background sequence.
pub fn ansi_bg_green() -> Str {
  return "\u{001b}[42m";
}

/// ANSI yellow background sequence.
pub fn ansi_bg_yellow() -> Str {
  return "\u{001b}[43m";
}

/// ANSI blue background sequence.
pub fn ansi_bg_blue() -> Str {
  return "\u{001b}[44m";
}

/// ANSI magenta background sequence.
pub fn ansi_bg_magenta() -> Str {
  return "\u{001b}[45m";
}

/// ANSI cyan background sequence.
pub fn ansi_bg_cyan() -> Str {
  return "\u{001b}[46m";
}

/// ANSI white background sequence.
pub fn ansi_bg_white() -> Str {
  return "\u{001b}[47m";
}

/// ANSI 256-color foreground escape for code 0..255 (clamped).
pub fn ansi_fg_256(code: Int) -> Str {
  return "\u{001b}[38;5;" + convert.int_to_string(_clamp8(code)) + "m";
}

/// ANSI 256-color background escape for code 0..255 (clamped).
pub fn ansi_bg_256(code: Int) -> Str {
  return "\u{001b}[48;5;" + convert.int_to_string(_clamp8(code)) + "m";
}

/// ANSI 24-bit foreground escape from RGB channels (0-255 each).
pub fn ansi_fg_rgb(r: Int, g: Int, b: Int) -> Str {
  return "\u{001b}[38;2;" + convert.int_to_string(_clamp8(r)) + ";" + convert.int_to_string(_clamp8(g)) + ";" + convert.int_to_string(_clamp8(b)) + "m";
}

/// ANSI 24-bit background escape from RGB channels (0-255 each).
pub fn ansi_bg_rgb(r: Int, g: Int, b: Int) -> Str {
  return "\u{001b}[48;2;" + convert.int_to_string(_clamp8(r)) + ";" + convert.int_to_string(_clamp8(g)) + ";" + convert.int_to_string(_clamp8(b)) + "m";
}

/// Move the cursor up `n` rows (n clamped >= 0).
pub fn ansi_cursor_up(n: Int) -> Str {
  return "\u{001b}[" + convert.int_to_string(_max0(n)) + "A";
}

/// Move the cursor down `n` rows.
pub fn ansi_cursor_down(n: Int) -> Str {
  return "\u{001b}[" + convert.int_to_string(_max0(n)) + "B";
}

/// Move the cursor right `n` columns.
pub fn ansi_cursor_forward(n: Int) -> Str {
  return "\u{001b}[" + convert.int_to_string(_max0(n)) + "C";
}

/// Move the cursor left `n` columns.
pub fn ansi_cursor_back(n: Int) -> Str {
  return "\u{001b}[" + convert.int_to_string(_max0(n)) + "D";
}

/// Move the cursor to the home position (1, 1).
pub fn ansi_cursor_home() -> Str {
  return "\u{001b}[H";
}

/// Move the cursor to the given 1-based row, col.
pub fn ansi_cursor_to(row: Int, col: Int) -> Str {
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

/// Clear the whole screen and home the cursor.
pub fn ansi_clear_screen() -> Str {
  return "\u{001b}[2J\u{001b}[H";
}

/// Clear the current line.
pub fn ansi_clear_line() -> Str {
  return "\u{001b}[2K";
}

/// Erase from the cursor up to the top of the screen.
pub fn ansi_erase_above() -> Str {
  return "\u{001b}[1J";
}

/// Erase from the cursor down to the bottom of the screen.
pub fn ansi_erase_below() -> Str {
  return "\u{001b}[0J";
}

/// Make the cursor visible again.
pub fn ansi_show_cursor() -> Str {
  return "\u{001b}[?25h";
}

/// Hide the cursor.
pub fn ansi_hide_cursor() -> Str {
  return "\u{001b}[?25l";
}

/// Save the current cursor position.
pub fn ansi_save_cursor() -> Str {
  return "\u{001b}[s";
}

/// Restore the last saved cursor position.
pub fn ansi_restore_cursor() -> Str {
  return "\u{001b}[u";
}

/// Convert an xterm-256 index (0..255) to its RGB triple (r, g, b).
/// The 16 base colors use the standard palette, 16..231 the 6x6x6 cube, and
/// 232..255 the grayscale ramp.
pub fn color_256_to_rgb(code: Int) -> (Int, Int, Int) {
  var c = _clamp8(code);
  if c < 16 {
    var idx = c * 3;
    var r = _palette_channel(idx);
    var g = _palette_channel(idx + 1);
    var b = _palette_channel(idx + 2);
    return (r, g, b);
  };
  if c <= 231 {
    var cube = c - 16;
    var rr = cube / 36;
    var gg = (cube / 6) % 6;
    var bb = cube % 6;
    var rv = _cube_level(rr);
    var gv = _cube_level(gg);
    var bv = _cube_level(bb);
    return (rv, gv, bv);
  };
  var gray = 8 + (c - 232) * 10;
  return (gray, gray, gray);
}

/// Channel value of the standard 16-color palette at linear index `i` (0..47).
fn _palette_channel(i: Int) -> Int {
  var base = "0 0 0 128 0 0 0 128 0 128 128 0 0 0 128 128 0 128 0 128 128 192 192 192 128 128 128 255 0 0 0 255 0 255 255 0 0 0 255 255 0 255 0 255 255 255 255 255";
  return _word_at(base, i);
}

/// Cube level for an index 0..5 of the 6x6x6 color cube.
fn _cube_level(i: Int) -> Int {
  var levels = "0 95 135 175 215 255";
  return _word_at(levels, i);
}

/// The nth space-separated integer of `s`, parsed as Int (0 on failure).
fn _word_at(s: Str, n: Int) -> Int {
  var idx = 0;
  var word = "";
  var i = 0;
  var len = s.len();
  while i < len {
    var b = string.byte_at(s, i);
    if b == 32 {
      if word.len() > 0 {
        if idx == n {
          var parsed = convert.str_to_int(word);
          match parsed {
            Ok(v) => { return v; };
            Err(_) => { return 0; };
          }
        };
        word = "";
        idx = idx + 1;
      };
    } else {
      word = word + string.str_slice(s, i, i + 1);
    };
    i = i + 1;
  }
  if word.len() > 0 {
    if idx == n {
      var parsed2 = convert.str_to_int(word);
      match parsed2 {
        Ok(v) => { return v; };
        Err(_) => { return 0; };
      }
    };
  };
  return 0;
}

/// Quantize an RGB triple to the nearest xterm-256 index. Uses the 6-level
/// color cube (index 16..231); the grayscale ramp is not considered.
pub fn rgb_to_ansi256(r: Int, g: Int, b: Int) -> Int {
  var ri = _nearest_level(_clamp8(r));
  var gi = _nearest_level(_clamp8(g));
  var bi = _nearest_level(_clamp8(b));
  return 16 + ri * 36 + gi * 6 + bi;
}

/// Index of the nearest 6-level cube value [0, 95, 135, 175, 215, 255].
fn _nearest_level(v: Int) -> Int {
  if v < 47 {
    return 0;
  };
  if v < 115 {
    return 1;
  };
  if v < 155 {
    return 2;
  };
  if v < 195 {
    return 3;
  };
  if v < 235 {
    return 4;
  };
  return 5;
}

fn _clamp8(v: Int) -> Int {
  var x = v;
  if x < 0 {
    x = 0;
  };
  if x > 255 {
    x = 255;
  };
  return x;
}

fn _max0(v: Int) -> Int {
  if v < 0 {
    return 0;
  };
  return v;
}
