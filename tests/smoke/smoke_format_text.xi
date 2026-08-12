// XIOM stdlib smoke test - xiom.format.text
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_format_text
use xiom.format.text;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var left = text_left("ab", 5);
  if left.len() != 5 {
    io.println("text: left pad wrong length");
    return 1;
  }
  var right = text_right("ab", 5);
  if right.len() != 5 {
    io.println("text: right pad wrong length");
    return 2;
  }
  var center = text_center("ab", 5);
  if center.len() != 5 {
    io.println("text: center pad wrong length");
    return 3;
  }
  var justified = text_justify("a b c", 9);
  if justified.len() != 9 {
    io.println("text: justify wrong length");
    return 4;
  }
  var lines = text_wrap("hello world foo bar", 8);
  if lines.len() < 2 {
    io.println("text: wrap produced too few lines");
    return 5;
  }
  var indented = text_indent("x\ny", 2);
  if !string.str_contains(indented, "  x") {
    io.println("text: indent wrong");
    return 6;
  }
  var hanging = text_hanging_indent("x\ny", 2);
  if !string.str_contains(hanging, "  y") {
    io.println("text: hanging indent wrong");
    return 7;
  }
  var ellipsis = text_ellipsis("hello world", 8);
  if ellipsis != "hello..." {
    io.println("text: ellipsis wrong: " + ellipsis);
    return 8;
  }
  var underlined = text_underline("ab");
  if !string.str_contains(underlined, "--") {
    io.println("text: underline wrong");
    return 9;
  }
  var quoted = text_quote("hi");
  if quoted != "\"hi\"" {
    io.println("text: quote wrong");
    return 10;
  }
  if text_measure("ab") != 2 {
    io.println("text: measure wrong");
    return 11;
  }
  var reflowed = text_reflow("a b c d", 4);
  if reflowed.len() < 5 {
    io.println("text: reflow wrong");
    return 12;
  }
  var para = text_paragraph("a b c", 8);
  if para.len() < 3 {
    io.println("text: paragraph wrong");
    return 13;
  }

  io.println("OK");
  return 0;
}
