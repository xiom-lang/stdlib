// XIOM stdlib smoke test - xiom.format.terminal
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_format_terminal
use xiom.format.terminal;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var red = ansi_fg_red();
  if !string.str_contains(red, "31m") {
    io.println("terminal: fg_red wrong");
    return 1;
  }
  var bg = ansi_bg_green();
  if !string.str_contains(bg, "42m") {
    io.println("terminal: bg_green wrong");
    return 2;
  }
  var fg256 = ansi_fg_256(196);
  if !string.str_contains(fg256, "38;5;196") {
    io.println("terminal: fg_256 wrong");
    return 3;
  }
  var rgbf = ansi_fg_rgb(1, 2, 3);
  if !string.str_contains(rgbf, "38;2;1;2;3") {
    io.println("terminal: fg_rgb wrong");
    return 4;
  }
  if ansi_reset() != "\u{001b}[0m" {
    io.println("terminal: reset wrong");
    return 5;
  }
  var to = ansi_cursor_to(2, 3);
  if !string.str_contains(to, "2;3H") {
    io.println("terminal: cursor_to wrong");
    return 6;
  }

  var p = progress_new(100);
  progress_update(&mut p, 50);
  var bar = progress_render(&p);
  if !string.str_contains(bar, "%") {
    io.println("terminal: progress missing percent");
    return 7;
  }
  if progress_percent(&p) != 50 {
    io.println("terminal: progress percent wrong");
    return 8;
  }
  progress_finish(&mut p);
  if progress_percent(&p) != 100 {
    io.println("terminal: progress finish wrong");
    return 9;
  }
  var eta = progress_eta(&p);
  if eta != 0 {
    io.println("terminal: progress eta wrong");
    return 10;
  }

  var sp = spinner_new();
  var f1 = spinner_tick(&mut sp);
  var f2 = spinner_tick(&mut sp);
  if f1 == f2 {
    io.println("terminal: spinner did not advance");
    return 11;
  }
  if spinner_frame(&sp) != 2 {
    io.println("terminal: spinner frame index wrong");
    return 12;
  }

  var rgb = color_256_to_rgb(196);
  if rgb.0 != 255 || rgb.1 != 0 || rgb.2 != 0 {
    io.println("terminal: color_256_to_rgb wrong");
    return 13;
  }
  var idx = rgb_to_ansi256(255, 0, 0);
  if idx != 196 {
    io.println("terminal: rgb_to_ansi256 wrong");
    return 14;
  }
  if !string.str_contains(ansi_clear_screen(), "2J") {
    io.println("terminal: clear_screen wrong");
    return 15;
  }
  if !string.str_contains(ansi_clear_line(), "2K") {
    io.println("terminal: clear_line wrong");
    return 16;
  }

  io.println("OK");
  return 0;
}
