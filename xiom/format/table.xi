// XIOM - Format: Tables
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.table

// Depends on: xiom.string

use xiom.string;

// ============================================================================
// Plain-text, aligned, markdown, CSV and HTML table rendering with sorting
// and cell access.
//
// Table stores headers plus row-major string cells (a flat Vec[Str], so no
// nested-Vec layout). table_add_row truncates extra cells and pads missing
// ones with "". Column widths are the maximum display width (byte length) of
// the header and data cells. Alignments: 0 = left, 1 = right, 2 = center.
// ============================================================================

/// A table of headers and row-major string cells with computed column widths.
pub type Table = {
  headers: Vec[Str];
  cells: Vec[Str];
  row_count: Int;
  col_count: Int;
}

/// Create an empty table with the given headers.
pub fn table_new(headers: &Vec[Str]) -> Table {
  var h = Vec[Str].new();
  var i = 0;
  while i < headers.len() {
    h.push(headers[i]);
    i = i + 1;
  }
  var cells = Vec[Str].new();
  return Table{ headers: h; cells: cells; row_count: 0; col_count: headers.len(); };
}

/// Append a row; extra cells are truncated, missing cells pad empty.
pub fn table_add_row(t: &mut Table, cells: &Vec[Str]) {
  var i = 0;
  while i < t.col_count {
    var val = "";
    if i < cells.len() {
      val = cells[i];
    };
    t.cells.push(val);
    i = i + 1;
  }
  t.row_count = t.row_count + 1;
}

/// Cell value at (row, col); empty string when out of range.
fn _cell_at(t: &Table, row: Int, col: Int) -> Str {
  if row < 0 || col < 0 {
    return "";
  };
  if row >= t.row_count {
    return "";
  };
  if col >= t.col_count {
    return "";
  };
  return t.cells[row * t.col_count + col];
}

/// The display width of each column (max of header and cells, byte length).
pub fn table_widths(t: &Table) -> Vec[Int] {
  var widths = Vec[Int].new();
  var c = 0;
  while c < t.col_count {
    var w = string.str_len(t.headers[c]);
    var r = 0;
    while r < t.row_count {
      var v = string.str_len(_cell_at(t, r, c));
      if v > w {
        w = v;
      };
      r = r + 1;
    }
    widths.push(w);
    c = c + 1;
  }
  return widths;
}

/// The number of data rows.
pub fn table_rows(t: &Table) -> Int {
  return t.row_count;
}

/// The number of columns.
pub fn table_columns(t: &Table) -> Int {
  return t.col_count;
}

/// Pad `s` per alignment (0 left, 1 right, 2 center) to `width`.
fn _pad(s: Str, width: Int, align: Int) -> Str {
  if align == 1 {
    return string.str_pad_left(s, width, ' ');
  };
  if align == 2 {
    return string.str_center(s, width);
  };
  return string.str_pad_right(s, width, ' ');
}

/// Render the table as plain aligned text with left-aligned columns:
/// "| a | b |" rows separated by "|---|" under the header.
pub fn table_render(t: &Table) -> Str {
  var align = Vec[Int].new();
  var a = 0;
  while a < t.col_count {
    align.push(0);
    a = a + 1;
  }
  return _render_rows(t, &align);
}

/// Render with per-column alignment (0 left, 1 right, 2 center).
pub fn table_render_aligned(t: &Table, align: &Vec[Int]) -> Str {
  return _render_rows(t, align);
}

fn _render_rows(t: &Table, align: &Vec[Int]) -> Str {
  var widths = table_widths(t);
  var result = "";
  var c = 0;
  while c < t.col_count {
    if c > 0 {
      result = result + "|";
    };
    result = result + " " + _pad(t.headers[c], widths[c], _align_at(align, c)) + " ";
    c = c + 1;
  }
  var sep = "";
  var c3 = 0;
  while c3 < t.col_count {
    if c3 > 0 {
      sep = sep + "|";
    };
    sep = sep + " " + string.str_repeat("-", widths[c3]) + " ";
    c3 = c3 + 1;
  }
  result = result + "\n" + sep;
  var r = 0;
  while r < t.row_count {
    var line = "";
    var c2 = 0;
    while c2 < t.col_count {
      if c2 > 0 {
        line = line + "|";
      };
      line = line + " " + _pad(_cell_at(t, r, c2), widths[c2], _align_at(align, c2)) + " ";
      c2 = c2 + 1;
    }
    result = result + "\n" + line;
    r = r + 1;
  }
  return result;
}

fn _align_at(align: &Vec[Int], c: Int) -> Int {
  if c >= align.len() {
    return 0;
  };
  return align[c];
}

/// Render the table as a GitHub-flavored markdown table.
pub fn table_render_markdown(t: &Table) -> Str {
  var widths = table_widths(t);
  var result = "";
  var c = 0;
  while c < t.col_count {
    if c > 0 {
      result = result + "|";
    };
    result = result + " " + string.str_pad_right(t.headers[c], widths[c], ' ') + " ";
    c = c + 1;
  }
  result = result + "\n";
  var c2 = 0;
  while c2 < t.col_count {
    if c2 > 0 {
      result = result + "|";
    };
    result = result + " " + string.str_repeat("-", widths[c2]) + " ";
    c2 = c2 + 1;
  }
  var r = 0;
  while r < t.row_count {
    var line = "";
    var c3 = 0;
    while c3 < t.col_count {
      if c3 > 0 {
        line = line + "|";
      };
      line = line + " " + string.str_pad_right(_cell_at(t, r, c3), widths[c3], ' ') + " ";
      c3 = c3 + 1;
    }
    result = result + "\n" + line;
    r = r + 1;
  }
  return result;
}

/// Quote a CSV field when it contains a comma, quote, or newline.
fn _csv_field(s: Str) -> Str {
  var needs = false;
  var i = 0;
  while i < s.len() {
    var b = string.byte_at(s, i);
    if b == 44 || b == 34 || b == 10 {
      needs = true;
    };
    i = i + 1;
  }
  if !needs {
    return s;
  };
  var quoted = "\"" + string.replace(s, "\"", "\"\"") + "\"";
  return quoted;
}

/// Render the table as comma-separated values (RFC 4180 style quoting).
pub fn table_render_csv(t: &Table) -> Str {
  var result = "";
  var c = 0;
  while c < t.col_count {
    if c > 0 {
      result = result + ",";
    };
    result = result + _csv_field(t.headers[c]);
    c = c + 1;
  }
  var r = 0;
  while r < t.row_count {
    var line = "";
    var c2 = 0;
    while c2 < t.col_count {
      if c2 > 0 {
        line = line + ",";
      };
      line = line + _csv_field(_cell_at(t, r, c2));
      c2 = c2 + 1;
    }
    result = result + "\n" + line;
    r = r + 1;
  }
  return result;
}

/// Render the table as an HTML table.
pub fn table_render_html(t: &Table) -> Str {
  var result = "<table>\n<thead><tr>";
  var c = 0;
  while c < t.col_count {
    result = result + "<th>" + t.headers[c] + "</th>";
    c = c + 1;
  }
  result = result + "</tr></thead>\n<tbody>";
  var r = 0;
  while r < t.row_count {
    result = result + "\n<tr>";
    var c2 = 0;
    while c2 < t.col_count {
      result = result + "<td>" + _cell_at(t, r, c2) + "</td>";
      c2 = c2 + 1;
    }
    result = result + "</tr>";
    r = r + 1;
  }
  result = result + "\n</tbody>\n</table>";
  return result;
}

/// Sort rows in place by a column (stable selection sort by byte order).
pub fn table_sort_by(t: &mut Table, col: Int) {
  var i = 0;
  while i < t.row_count {
    var best = i;
    var j = i + 1;
    while j < t.row_count {
      var a = _cell_at(t, j, col);
      var b = _cell_at(t, best, col);
      if a < b {
        best = j;
      };
      j = j + 1;
    }
    if best != i {
      var k = 0;
      while k < t.col_count {
        var tmp = t.cells[i * t.col_count + k];
        t.cells[i * t.col_count + k] = t.cells[best * t.col_count + k];
        t.cells[best * t.col_count + k] = tmp;
        k = k + 1;
      }
    };
    i = i + 1;
  }
}

/// Replace a single cell value. Out-of-range cells are ignored.
pub fn table_set_cell(t: &mut Table, row: Int, col: Int, value: Str) {
  if row < 0 || col < 0 {
    return;
  };
  if row >= t.row_count {
    return;
  };
  if col >= t.col_count {
    return;
  };
  t.cells[row * t.col_count + col] = value;
}
