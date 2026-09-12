// XIOM stdlib smoke test - xiom.serialize.csv (RFC 4180)
// Checks: basic/CRLF records, quoted fields (commas, doubled quotes,
// embedded newlines), empty fields, trailing terminator behavior, custom
// delimiters, error on unterminated quotes, writer quoting, and round-trips.
// Returns 0 on success, unique error code on failure.

module smoke_serialize_csv
use xiom.serialize.csv;
use xiom.io;

fn flat(rows: &Vec[Vec[Str]]) -> Str {
  var out = "";
  var i = 0;
  while i < rows.len() {
    if i > 0 { out = out + ";"; }
    var j = 0;
    while j < rows[i].len() {
      if j > 0 { out = out + "|"; }
      out = out + rows[i][j];
      j = j + 1;
    }
    i = i + 1;
  }
  return out;
}

fn check_rows(tag: Str, got: Result[Vec[Vec[Str]], Str], want: Str, code: Int) -> Int {
  match got {
    Ok(rows) => {
      let f = flat(&rows);
      if f != want {
        io.println(tag + ": got [" + f + "] want [" + want + "]");
        return code;
      }
    },
    Err(e) => {
      io.println(tag + ": Err " + e);
      return code;
    },
  }
  return 0;
}

fn main() -> Int {
  var r = check_rows("basic", csv.csv_parse("a,b,c\n1,2,3\n"), "a|b|c;1|2|3", 1);
  if r != 0 { return r; }
  r = check_rows("crlf", csv.csv_parse("a,b\r\n1,2\r\n"), "a|b;1|2", 2);
  if r != 0 { return r; }
  r = check_rows("quoted-comma", csv.csv_parse("\"a,b\",c"), "a,b|c", 3);
  if r != 0 { return r; }
  r = check_rows("doubled-quote", csv.csv_parse("\"he said \"\"hi\"\"\""), "he said \"hi\"", 4);
  if r != 0 { return r; }
  r = check_rows("embedded-lf", csv.csv_parse("\"l1\nl2\",z"), "l1\nl2|z", 5);
  if r != 0 { return r; }
  r = check_rows("empty-field", csv.csv_parse("a,,c"), "a||c", 6);
  if r != 0 { return r; }
  r = check_rows("trailing-nl", csv.csv_parse("a\n"), "a", 7);
  if r != 0 { return r; }
  r = check_rows("semicolon", csv.csv_parse_with("a;b", 59u8), "a|b", 8);
  if r != 0 { return r; }

  var one = csv.csv_parse("\"\"");
  match one {
    Ok(rows) => { if rows.len() != 1 { io.println("quoted-empty rows=" + rows.len()); return 9; } },
    Err(e) => { io.println("quoted-empty Err " + e); return 10; },
  }

  var bad = csv.csv_parse("\"unterminated");
  match bad {
    Ok(_) => { io.println("unterminated parsed"); return 11; },
    Err(_) => { },
  }

  var f1 = Vec[Str].new();
  f1.push("a"); f1.push("b,c"); f1.push("d\"e");
  let w = csv.csv_write_row(&f1);
  if w != "a,\"b,c\",\"d\"\"e\"" { io.println("write_row [" + w + "]"); return 12; }

  var rows2 = Vec[Vec[Str]].new();
  var row2 = Vec[Str].new(); row2.push("x"); row2.push("y\nz");
  rows2.push(row2);
  let block = csv.csv_write(&rows2);
  r = check_rows("roundtrip", csv.csv_parse(block), "x|y\nz", 13);
  if r != 0 { return r; }

  io.println("OK");
  return 0;
}

