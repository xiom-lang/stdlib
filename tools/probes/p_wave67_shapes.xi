// p_wave67_shapes.xi -- wave 67 shape validation: format (dump/number/relative/table)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-67 clauses on xiom.format.{dump (4), number (6),
// relative (11), table (12)} = 33 fns. No network or socket I/O;
// 59 checks; returns 0 when every case holds.

module p_wave67_shapes

use xiom.format.dump;
use xiom.format.number;
use xiom.format.relative;
use xiom.format.table;
use xiom.string;

fn _bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(string.byte_at(s, i));
    i = i + 1;
  };
  v
}

fn main() -> Int {
  var empty = Vec[UInt8].new();
  var ab = _bytes("AB");

  // ---- dump
  if dump.hexdump_line(&ab, 0, 0, 0).len() != 14 { return 1; }
  if dump.hexdump(&empty).len() != 0 { return 2; }
  if dump.hexdump(&ab).len() == 0 { return 3; }
  if dump.octal_dump(&empty).len() != 0 { return 4; }
  if dump.octal_dump(&ab).len() == 0 { return 5; }
  if dump.binary_dump(&empty).len() != 0 { return 6; }
  if dump.binary_dump(&ab).len() == 0 { return 7; }

  // ---- number
  if !(number.fmt_int_with_separators(0, ",") == "0") { return 8; }
  if !(number.fmt_int_with_separators(987654, ",") == "987,654") { return 9; }
  if !(number.fmt_float_fixed(0.0, 0) == "0") { return 10; }
  if !(number.fmt_float_fixed(0.0, 2) == "0.00") { return 11; }
  if !(number.fmt_float_fixed(3.14159, 2) == "3.14") { return 12; }
  if !(number.fmt_percent(0.0, 0) == "0%") { return 13; }
  if !(number.fmt_percent(0.125, 1) == "12.5%") { return 14; }
  if !(number.fmt_bytes(0) == "0 B") { return 15; }
  if !(number.fmt_bytes(1024) == "1.0 KiB") { return 16; }
  if !(number.fmt_bytes(0 - 512) == "512 B") { return 17; }
  if !(number.fmt_duration_ms(0) == "0ms") { return 18; }
  if !(number.fmt_duration_ms(65000) == "1m 5s") { return 19; }
  if !(number.fmt_duration_ms(90061000) == "1d 1h 1m 1s") { return 20; }
  if !(number.fmt_duration_ms(0 - 1000) == "-1s") { return 21; }
  if !(number.fmt_ordinal(1) == "1st") { return 22; }
  if !(number.fmt_ordinal(2) == "2nd") { return 23; }
  if !(number.fmt_ordinal(3) == "3rd") { return 24; }
  if !(number.fmt_ordinal(4) == "4th") { return 25; }
  if !(number.fmt_ordinal(11) == "11th") { return 26; }
  if !(number.fmt_ordinal(21) == "21st") { return 27; }
  if !(number.fmt_ordinal(111) == "111th") { return 28; }

  // ---- relative
  if !(relative.format_relative_future(0) == "in a moment") { return 29; }
  if !(relative.format_relative_future(29) == "in a moment") { return 30; }
  if !(relative.format_relative_future(30) == "in 30 seconds") { return 31; }
  if !(relative.format_relative_past(0) == "just now") { return 32; }
  if !(relative.format_relative_time(0) == "just now") { return 33; }
  if !(relative.format_relative_time(0 - 5) == "just now") { return 34; }
  if !(relative.format_relative_time_short(0) == "now") { return 35; }
  if !(relative.format_elapsed(5, 5) == "0 seconds") { return 36; }
  if !(relative.format_elapsed_ms(0) == "0ms") { return 37; }
  if !(relative.format_elapsed_ms(500) == "500ms") { return 38; }
  if !(relative.format_ago(100, 100) == "just now") { return 39; }
  if !(relative.format_until(100, 100) == "in a moment") { return 40; }
  if !(relative.format_age(0) == "0 seconds") { return 41; }
  if relative.relative_parts(0).len() != 1 { return 42; }
  if relative.relative_parts(3661).len() != 3 { return 43; }
  if !(relative.format_seconds(0) == "0s") { return 44; }
  if !(relative.format_seconds(3661) == "1h 1m 1s") { return 45; }

  // ---- table
  var headers = Vec[Str].new();
  headers.push("a");
  headers.push("bb");
  var t = table.table_new(&headers);
  if t.row_count != 0 || t.col_count != 2 { return 46; }
  if t.headers.len() != 2 || t.cells.len() != 0 { return 47; }
  var row = Vec[Str].new();
  row.push("x");
  table.table_add_row(&t, &row);
  if t.row_count != 1 { return 48; }
  if t.cells.len() != 2 { return 49; }
  if table.table_widths(&t).len() != 2 { return 50; }
  if table.table_rows(&t) != 1 { return 51; }
  if table.table_columns(&t) != 2 { return 52; }
  table.table_sort_by(&t, 0);
  if t.row_count != 1 || t.col_count != 2 { return 53; }
  table.table_set_cell(&t, 0, 0, "y");
  if t.cells.len() != 2 { return 54; }
  if !(table.table_render_html(&t).len() > 0) { return 55; }

  // Empty tables exercise the exact empty-shape clauses.
  var eh = Vec[Str].new();
  var ea = Vec[Int].new();
  let t0 = table.table_new(&eh);
  if !(table.table_render(&t0) == "\n") { return 56; }
  if !(table.table_render_aligned(&t0, &ea) == "\n") { return 57; }
  if !(table.table_render_markdown(&t0) == "\n") { return 58; }
  if table.table_render_csv(&t0).len() != 0 { return 59; }

  return 0;
}
