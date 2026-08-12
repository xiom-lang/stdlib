// XIOM stdlib smoke test - xiom.format.markup
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_format_markup
use xiom.format.markup;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var m = markup_parse("*bold* and _it_ and `code` and [link](url) and ~strike~");
  if m.is_err {
    io.println("markup: parse failed");
    return 1;
  }
  var nodes = Vec[MarkupNode].new();
  match m {
    Ok(v) => { nodes = v; };
    Err(_) => { nodes = Vec[MarkupNode].new(); };
  }
  if nodes.len() != 9 {
    io.println("markup: unexpected node count");
    return 2;
  }
  var plain = markup_render_plain(&nodes);
  if !string.str_contains(plain, "bold") {
    io.println("markup: plain missing text");
    return 3;
  }
  var html = markup_render_html(&nodes);
  if !string.str_contains(html, "<b>bold</b>") {
    io.println("markup: html bold wrong");
    return 4;
  }
  if !string.str_contains(html, "<a href=\"url\">link</a>") {
    io.println("markup: html link wrong");
    return 5;
  }
  var rendered = markup_render(&nodes);
  if !string.str_contains(rendered, "*bold*") {
    io.println("markup: render lost bold");
    return 6;
  }
  if !string.str_contains(rendered, "[link](url)") {
    io.println("markup: render lost link");
    return 7;
  }
  if markup_strip("*x* y") != "x y" {
    io.println("markup: strip wrong");
    return 8;
  }
  if markup_bold("hi") != "*hi*" {
    io.println("markup: bold marker wrong");
    return 9;
  }
  if markup_link("go", "https://x") != "[go](https://x)" {
    io.println("markup: link marker wrong");
    return 10;
  }
  if markup_escape("a*b") != "a\\*b" {
    io.println("markup: escape wrong");
    return 11;
  }
  var bad = markup_parse("*unclosed");
  if !bad.is_err {
    io.println("markup: unclosed accepted");
    return 12;
  }
  var empty = markup_parse("");
  if empty.is_err {
    io.println("markup: empty rejected");
    return 13;
  }

  io.println("OK");
  return 0;
}
