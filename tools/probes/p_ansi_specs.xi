// p_ansi_specs.xi -- validate the ESC-prefix contract across all ANSI builders.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_ansi_specs
use xiom.format.ansi;
use xiom.io;

fn chk(tag: Str, s: Str) -> Int {
  if s.len() < 2 {
    io.println("short " + tag);
    return 1;
  };
  if s.byte_at(0) != 27 {
    io.println("no esc " + tag);
    return 2;
  };
  0
}

fn main() -> Int {
  var r = 0;
  r = r + chk("fg", ansi.ansi_fg(1));
  if r != 0 { return r; };
  r = r + chk("fg-neg", ansi.ansi_fg(-5));
  if r != 0 { return r; };
  r = r + chk("fg-big", ansi.ansi_fg(99));
  if r != 0 { return r; };
  r = r + chk("bg", ansi.ansi_bg(2));
  if r != 0 { return r; };
  r = r + chk("rgb-fg", ansi.ansi_rgb_fg(10, 20, 30));
  if r != 0 { return r; };
  r = r + chk("rgb-bg", ansi.ansi_rgb_bg(255, 0, 128));
  if r != 0 { return r; };
  r = r + chk("256-fg", ansi.ansi_256_fg(200));
  if r != 0 { return r; };
  r = r + chk("256-bg", ansi.ansi_256_bg(-1));
  if r != 0 { return r; };
  r = r + chk("reset", ansi.ansi_reset());
  if r != 0 { return r; };
  r = r + chk("bold", ansi.ansi_bold());
  if r != 0 { return r; };
  r = r + chk("dim", ansi.ansi_dim());
  if r != 0 { return r; };
  r = r + chk("italic", ansi.ansi_italic());
  if r != 0 { return r; };
  r = r + chk("underline", ansi.ansi_underline());
  if r != 0 { return r; };
  r = r + chk("blink", ansi.ansi_blink());
  if r != 0 { return r; };
  r = r + chk("reverse", ansi.ansi_reverse());
  if r != 0 { return r; };
  r = r + chk("strike", ansi.ansi_strike());
  if r != 0 { return r; };
  r = r + chk("cursor-to", ansi.ansi_cursor_to(3, 7));
  if r != 0 { return r; };
  r = r + chk("cursor-up", ansi.ansi_cursor_up(2));
  if r != 0 { return r; };
  r = r + chk("cursor-down", ansi.ansi_cursor_down(2));
  if r != 0 { return r; };
  r = r + chk("cursor-right", ansi.ansi_cursor_right(2));
  if r != 0 { return r; };
  r = r + chk("cursor-left", ansi.ansi_cursor_left(2));
  if r != 0 { return r; };
  r = r + chk("clear-screen", ansi.ansi_clear_screen());
  if r != 0 { return r; };
  r = r + chk("clear-line", ansi.ansi_clear_line());
  if r != 0 { return r; };
  r = r + chk("save-cursor", ansi.ansi_save_cursor());
  if r != 0 { return r; };
  r = r + chk("restore-cursor", ansi.ansi_restore_cursor());
  if r != 0 { return r; };
  r = r + chk("hide-cursor", ansi.ansi_hide_cursor());
  if r != 0 { return r; };
  r = r + chk("show-cursor", ansi.ansi_show_cursor());
  if r != 0 { return r; };

  io.println("P_ANSI_SPECS OK");
  io.flush_stdout();
  0
}
