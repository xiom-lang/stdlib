// XIOM -- Serialize: CSV (RFC 4180)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.serialize.csv

use xiom.string;
use xiom.convert;

// ============================================================================
// RFC 4180 CSV reader/writer.
//
// Reader (csv_parse / csv_parse_with):
//   - fields are separated by the delimiter (default comma 0x2C);
//   - records end at LF, CR, or CRLF; a trailing record terminator at EOF
//     does not produce an extra empty record;
//   - a field wrapped in double quotes may contain delimiters, doubled
//     quotes ("" = literal "), and CR/LF; UTF-8 passes through byte-exact;
//   - an unterminated quoted field returns Err (byte offset in message).
// Writer:
//   - csv_write_row joins fields with the delimiter, quoting any field that
//     contains the delimiter, a quote, CR, or LF (embedded quotes double);
//   - csv_write emits CRLF record terminators per RFC 4180.
//
// Limits: Str inputs cannot contain NUL bytes (language string model);
// all other bytes are preserved. Complexity: reader O(n), writer O(n).
// ============================================================================

const _CSV_COMMA: UInt8 = 44u8;
const _CSV_QUOTE: UInt8 = 34u8;
const _CSV_CR: UInt8 = 13u8;
const _CSV_LF: UInt8 = 10u8;

fn _is_record_end(b: UInt8) -> Bool {
  return b == _CSV_CR || b == _CSV_LF;
}

/// Parse RFC 4180 CSV with the default comma delimiter.
pub fn csv_parse(text: Str) -> Result[Vec[Vec[Str]], Str] {
  return csv_parse_with(text, _CSV_COMMA);
}

/// Parse RFC 4180 CSV with an explicit delimiter byte.
pub fn csv_parse_with(text: Str, delimiter: UInt8) -> Result[Vec[Vec[Str]], Str]
  requires: delimiter != _CSV_QUOTE
  requires: delimiter != _CSV_CR && delimiter != _CSV_LF
{
  var rows = Vec[Vec[Str]].new();
  let len = text.len();
  if len == 0 {
    return Ok(rows);
  }
  var record = Vec[Str].new();
  var field = Vec[UInt8].new();
  var in_quotes = false;
  var record_open = false;
  var i = 0;
  while i < len {
    let b = string.byte_at(text, i);
    if in_quotes {
      if b == _CSV_QUOTE {
        if i + 1 < len && string.byte_at(text, i + 1) == _CSV_QUOTE {
          field.push(_CSV_QUOTE);
          i = i + 2;
          continue;
        }
        in_quotes = false;
        i = i + 1;
        continue;
      }
      field.push(b);
      i = i + 1;
      continue;
    }
    if b == _CSV_QUOTE {
      in_quotes = true;
      record_open = true;
      i = i + 1;
      continue;
    }
    if b == delimiter {
      record.push(Str::from_utf8(field));
      field = Vec[UInt8].new();
      record_open = true;
      i = i + 1;
      continue;
    }
    if _is_record_end(b) {
      record.push(Str::from_utf8(field));
      field = Vec[UInt8].new();
      rows.push(record);
      record = Vec[Str].new();
      record_open = false;
      if b == _CSV_CR && i + 1 < len && string.byte_at(text, i + 1) == _CSV_LF {
        i = i + 2;
      } else {
        i = i + 1;
      }
      continue;
    }
    field.push(b);
    record_open = true;
    i = i + 1;
  }
  if in_quotes {
    return Err("csv: unterminated quoted field at byte " + convert.int_to_string(i));
  }
  if record_open || field.len() > 0 || record.len() > 0 {
    record.push(Str::from_utf8(field));
    rows.push(record);
  }
  return Ok(rows);
}

fn _needs_quote(s: Str, delimiter: UInt8) -> Bool {
  var i = 0;
  while i < s.len() {
    let b = string.byte_at(s, i);
    if b == delimiter || b == _CSV_QUOTE || b == _CSV_CR || b == _CSV_LF {
      return true;
    }
    i = i + 1;
  }
  return false;
}

fn _quote_field(s: Str, delimiter: UInt8) -> Str {
  if !_needs_quote(s, delimiter) {
    return s;
  }
  var out = "\"";
  var i = 0;
  while i < s.len() {
    let b = string.byte_at(s, i);
    if b == _CSV_QUOTE {
      out = out + "\"\"";
    } else {
      out = out + string.str_slice(s, i, i + 1);
    }
    i = i + 1;
  }
  return out + "\"";
}

/// Serialize one record (no trailing terminator), quoting as needed.
pub fn csv_write_row(fields: &Vec[Str]) -> Str {
  var out = "";
  var i = 0;
  while i < fields.len() {
    if i > 0 { out = out + ","; }
    out = out + _quote_field(fields[i], _CSV_COMMA);
    i = i + 1;
  }
  return out;
}

/// Serialize records with CRLF terminators per RFC 4180.
pub fn csv_write(rows: &Vec[Vec[Str]]) -> Str {
  var out = "";
  var i = 0;
  while i < rows.len() {
    out = out + csv_write_row(&rows[i]);
    out = out + "\r\n";
    i = i + 1;
  }
  return out;
}
