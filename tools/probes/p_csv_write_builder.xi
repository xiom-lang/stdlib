// p_csv_write_builder.xi -- byte-exact CSV writer after the wave-209 byte
// builder rewrite: quoting, doubled quotes, embedded newlines, empty cells.
// Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_csv_write_builder

use xiom.serialize.csv;
use xiom.io;

fn main() -> Int {
  var r1: Vec[Str] = Vec[Str].new();
  r1.push("a");
  r1.push("b,c");
  r1.push("d\"e");
  r1.push("f\ng");
  r1.push("");

  let row_want = "a,\"b,c\",\"d\"\"e\",\"f\ng\",";
  if csv.csv_write_row(&r1) != row_want {
    io.println("row got=[" + csv.csv_write_row(&r1) + "]");
    return 1;
  }

  var r2: Vec[Str] = Vec[Str].new();
  r2.push("plain");
  r2.push("x");
  var rows: Vec[Vec[Str]] = Vec[Vec[Str]].new();
  rows.push(r1);
  rows.push(r2);
  if csv.csv_write(&rows) != row_want + "\r\n" + "plain,x\r\n" {
    return 2;
  }

  var empty: Vec[Str] = Vec[Str].new();
  if csv.csv_write_row(&empty) != "" { return 3; }
  var norows: Vec[Vec[Str]] = Vec[Vec[Str]].new();
  if csv.csv_write(&norows) != "" { return 4; }
  return 0;
}
