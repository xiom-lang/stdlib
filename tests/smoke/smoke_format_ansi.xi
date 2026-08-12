// XIOM stdlib smoke test - xiom.format.ansi
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_format_ansi
use xiom.format.ansi;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var fg = ansi_fg(1);
  if fg.len() != 5 {
    io.println("ansi: fg wrong length");
    return 1;
  }
  if string.byte_at(fg, 0) != 27 {
    io.println("ansi: missing ESC prefix");
    return 2;
  }
  if !string.str_contains(fg, "31m") {
    io.println("ansi: fg missing 31m");
    return 3;
  }
  var bg = ansi_bg(1);
  if !string.str_contains(bg, "41m") {
    io.println("ansi: bg missing 41m");
    return 4;
  }
  var rgb = ansi_rgb_fg(10, 20, 30);
  if !string.str_contains(rgb, "38;2;10;20;30") {
    io.println("ansi: rgb fg malformed");
    return 5;
  }
  var c256 = ansi_256_fg(196);
  if !string.str_contains(c256, "38;5;196") {
    io.println("ansi: 256 fg malformed");
    return 6;
  }
  if ansi_reset() != "\u{001b}[0m" {
    io.println("ansi: reset wrong");
    return 7;
  }
  if !string.str_contains(ansi_bold(), "1m") {
    io.println("ansi: bold wrong");
    return 8;
  }
  var to = ansi_cursor_to(2, 3);
  if !string.str_contains(to, "2;3H") {
    io.println("ansi: cursor_to wrong");
    return 9;
  }
  var up = ansi_cursor_up(2);
  if !string.str_contains(up, "2A") {
    io.println("ansi: cursor_up wrong");
    return 10;
  }
  if !string.str_contains(ansi_clear_screen(), "2J") {
    io.println("ansi: clear_screen wrong");
    return 11;
  }
  if !string.str_contains(ansi_show_cursor(), "25h") {
    io.println("ansi: show_cursor wrong");
    return 12;
  }

  io.println("OK");
  return 0;
}
