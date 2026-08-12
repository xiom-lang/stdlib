// XIOM stdlib smoke test - xiom.format.table
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_format_table
use xiom.format.table;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var headers = Vec[Str].new();
  headers.push("Name");
  headers.push("Qty");
  var t = table_new(&headers);
  if table_columns(&t) != 2 {
    io.println("table: columns wrong");
    return 1;
  }
  var r1 = Vec[Str].new();
  r1.push("apple");
  r1.push("3");
  table_add_row(&mut t, &r1);
  var r2 = Vec[Str].new();
  r2.push("pear");
  r2.push("17");
  table_add_row(&mut t, &r2);
  if table_rows(&t) != 2 {
    io.println("table: rows wrong");
    return 2;
  }
  var rendered = table_render(&t);
  if !string.str_contains(rendered, "Name") {
    io.println("table: render missing header");
    return 3;
  }
  if !string.str_contains(rendered, "apple") {
    io.println("table: render missing cell");
    return 4;
  }
  var align = Vec[Int].new();
  align.push(2);
  align.push(1);
  var aligned = table_render_aligned(&t, &align);
  if !string.str_contains(aligned, "apple") {
    io.println("table: aligned render missing cell");
    return 5;
  }
  var md = table_render_markdown(&t);
  if !string.str_contains(md, "---") {
    io.println("table: markdown missing separator");
    return 6;
  }
  var csv = table_render_csv(&t);
  if !string.str_contains(csv, "Name,Qty") {
    io.println("table: csv header wrong");
    return 7;
  }
  var html = table_render_html(&t);
  if !string.str_contains(html, "<table>") {
    io.println("table: html missing table tag");
    return 8;
  }
  if !string.str_contains(html, "<th>Name</th>") {
    io.println("table: html th wrong");
    return 9;
  }
  var widths = table_widths(&t);
  if widths.len() != 2 {
    io.println("table: widths wrong");
    return 10;
  }
  table_set_cell(&mut t, 0, 1, "9");
  var widths2 = table_widths(&t);
  if widths2.len() != 2 {
    io.println("table: widths after set wrong");
    return 11;
  }
  var t2 = table_new(&headers);
  var s1 = Vec[Str].new();
  s1.push("b");
  s1.push("2");
  table_add_row(&mut t2, &s1);
  var s2 = Vec[Str].new();
  s2.push("a");
  s2.push("1");
  table_add_row(&mut t2, &s2);
  table_sort_by(&mut t2, 0);
  var sorted = table_render(&t2);
  if !string.str_contains(sorted, "a") {
    io.println("table: sort failed");
    return 12;
  }

  io.println("OK");
  return 0;
}
