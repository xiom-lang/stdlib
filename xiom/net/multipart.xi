// XIOM - Network: Multipart Form Data
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.multipart

// Depends on: xiom.string

// ============================================================================
// multipart/form-data construction and parsing per RFC 7578.
// Builds and splits multi-part bodies using a caller-provided boundary.
// Pure byte/string operations; UTF-8 encoding delegates to xiom.encoding.
// ============================================================================

use xiom.string;
use xiom.encoding;
use xiom.io;

// struct Part { name: Str; filename: Str; content_type: Str; data: Vec[UInt8] }
/// struct Part { name: Str; filename: Str; content_type: Str; data: Vec[UInt8] }
pub type Part = {
  name: Str;
  filename: Str;
  content_type: Str;
  data: Vec[UInt8];
}

// index_of returns the byte index of needle in hay, or -1.
fn index_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return 0; }
  if nlen > hlen { return -1; }
  var i = 0;
  while i <= hlen - nlen {
    if string.str_slice(hay, i, i + nlen) == needle {
      return i;
    }
    i = i + 1;
  }
  -1
}

// split splits s on every occurrence of delim.
fn split(s: Str, delim: Str) -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  let dlen = delim.len();
  if dlen == 0 {
    var i = 0;
    while i < s.len() {
      result.push(string.str_slice(s, i, i + 1));
      i = i + 1;
    }
    return result;
  }
  var start = 0;
  var pos = 0;
  let slen = s.len();
  while pos < slen {
    if pos + dlen <= slen && string.str_slice(s, pos, pos + dlen) == delim {
      result.push(string.str_slice(s, start, pos));
      pos = pos + dlen;
      start = pos;
    } else {
      pos = pos + 1;
    }
  }
  result.push(string.str_slice(s, start, slen));
  result
}

// is_ws_byte returns true for space, tab, newline and carriage return.
fn is_ws_byte(b: UInt8) -> Bool {
  b == 32 || b == 9 || b == 10 || b == 13
}

// trim_ws trims leading and trailing whitespace.
fn trim_ws(s: Str) -> Str {
  let len = s.len();
  var start = 0;
  var end = len;
  while start < end && is_ws_byte(s.byte_at(start)) {
    start = start + 1;
  }
  while end > start && is_ws_byte(s.byte_at(end - 1)) {
    end = end - 1;
  }
  string.str_slice(s, start, end)
}

// lower returns the lowercase form of s.
fn lower(s: Str) -> Str {
  string.str_lower(s)
}

// fresh re-slices a string read from a vector element.
fn fresh(s: Str) -> Str {
  string.str_slice(s, 0, s.len())
}

// push_str appends the UTF-8 bytes of a string to a byte vector.
fn push_str(dst: &mut Vec[UInt8], s: Str) {
  let raw = encoding.utf8_encode(s);
  var i = 0;
  while i < raw.len() {
    dst.push(raw[i]);
    i = i + 1;
  }
}

// boundary_delim returns the "--boundary" delimiter.
fn boundary_delim(boundary: Str) -> Str {
  var result = "--";
  result = result + boundary;
  result
}

// boundary_final returns the closing "--boundary--" delimiter.
fn boundary_final(boundary: Str) -> Str {
  var result = "--";
  result = result + boundary;
  result = result + "--";
  result
}

/// Build a plain text field part.
/// Parameters: name -- the field name; value -- the field value.
/// Returns: a Part with no filename or content type.
/// Complexity: O(n). Pure.
pub fn multipart_part(name: Str, value: Str) -> Part {
  let data = encoding.utf8_encode(value);
  Part{ name: name; filename: ""; content_type: ""; data: data; }
}

/// Build a file field part.
/// Parameters: name -- the field name; filename -- the client file name;
///          content_type -- the file's MIME type; data -- the file bytes.
/// Returns: a Part carrying the file metadata and bytes.
/// Complexity: O(n). Pure.
pub fn multipart_part_file(name: Str, filename: Str, content_type: Str, data: &Vec[UInt8]) -> Part {
  var bytes = Vec[UInt8].new();
  var i = 0;
  while i < data.len() {
    bytes.push(data[i]);
    i = i + 1;
  }
  Part{ name: name; filename: filename; content_type: content_type; data: bytes; }
}

/// Serialize parts into a multipart body.
/// Parameters: parts -- the parts to serialize; boundary -- the boundary string.
/// Returns: the multipart/form-data body bytes.
/// Complexity: O(n). Pure.
pub fn multipart_build(parts: &Vec[Part], boundary: Str) -> Vec[UInt8] {
  var body = Vec[UInt8].new();
  var i = 0;
  while i < parts.len() {
    let p = parts[i];
    push_str(&mut body, boundary_delim(boundary));
    push_str(&mut body, "\r\n");
    let pname = fresh(p.name);
    var header = "Content-Disposition: form-data; name=\"";
    header = header + pname;
    header = header + "\"";
    if p.filename.len() > 0 {
      let pfname = fresh(p.filename);
      header = header + "; filename=\"";
      header = header + pfname;
      header = header + "\"";
    }
    push_str(&mut body, header);
    push_str(&mut body, "\r\n");
    if p.content_type.len() > 0 {
      let pct = fresh(p.content_type);
      var ct = "Content-Type: ";
      ct = ct + pct;
      push_str(&mut body, ct);
      push_str(&mut body, "\r\n");
    }
    push_str(&mut body, "\r\n");
    var j = 0;
    while j < p.data.len() {
      body.push(p.data[j]);
      j = j + 1;
    }
    push_str(&mut body, "\r\n");
    i = i + 1;
  }
  push_str(&mut body, boundary_final(boundary));
  push_str(&mut body, "\r\n");
  body
}

// bytes_find returns the first index >= from where needle appears in data,
// or -1.
fn bytes_find(data: &Vec[UInt8], from: Int, needle: &Vec[UInt8]) -> Int {
  let dlen = data.len();
  let nlen = needle.len();
  if nlen == 0 {
    return from;
  }
  if nlen > dlen {
    return -1;
  }
  var i = from;
  while i + nlen <= dlen {
    var j = 0;
    var ok = true;
    while j < nlen {
      if data[i + j] != needle[j] {
        ok = false;
        break;
      }
      j = j + 1;
    }
    if ok {
      return i;
    }
    i = i + 1;
  }
  -1
}

// bytes_region copies data[from, to) into a fresh vector.
fn bytes_region(data: &Vec[UInt8], from: Int, to: Int) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i = from;
  while i < to && i < data.len() {
    out.push(data[i]);
    i = i + 1;
  }
  out
}

// crlf_bytes_t returns a fresh "\r\n" byte vector.
fn crlf_bytes_t() -> Vec[UInt8] {
  var b = Vec[UInt8].new();
  b.push(13 as UInt8);
  b.push(10 as UInt8);
  b
}

// parse_part_headers extracts name, filename and content type from the header
// block of a part.
fn parse_part_headers(header_block: Str) -> (Str, Str, Str) {
  var name = "";
  var filename = "";
  var content_type = "";
  let lines = split(header_block, "\r\n");
  var i = 0;
  while i < lines.len() {
    let line = fresh(trim_ws(lines[i]));
    let colon = index_of(line, ":");
    if colon > 0 {
      let hname = lower(fresh(trim_ws(string.str_slice(line, 0, colon))));
      let hval = fresh(trim_ws(string.str_slice(line, colon + 1, line.len())));
      if hname == "content-disposition" {
        let parts = split(hval, ";");
        var j = 1;
        while j < parts.len() {
          let attr = fresh(trim_ws(parts[j]));
          let eq = index_of(attr, "=");
          if eq > 0 {
            let aname = lower(fresh(trim_ws(string.str_slice(attr, 0, eq))));
            var aval = fresh(trim_ws(string.str_slice(attr, eq + 1, attr.len())));
            let alen = aval.len();
            if alen >= 2 && aval.byte_at(0) == 34 && aval.byte_at(alen - 1) == 34 {
              aval = string.str_slice(aval, 1, alen - 1);
            }
            if aname == "name" {
              name = aval;
            } elif aname == "filename" {
              filename = aval;
            }
          }
          j = j + 1;
        }
      } elif hname == "content-type" {
        content_type = hval;
      }
    }
    i = i + 1;
  }
  (name, filename, content_type)
}

/// Split a multipart body into parts.
/// Parameters: body -- the multipart body bytes; boundary -- the boundary
///          string.
/// Returns: Ok(parts) on success, Err when the body has no boundary markers
///          or is malformed.
/// Complexity: O(n). Pure.
pub fn multipart_parse(body: &Vec[UInt8], boundary: Str) -> Result[Vec[Part], Str] {
  let delim_raw = encoding.utf8_encode(boundary_delim(boundary));
  var delim = Vec[UInt8].new();
  var di = 0;
  while di < delim_raw.len() {
    delim.push(delim_raw[di]);
    di = di + 1;
  }
  var result: Vec[Part] = Vec[Part].new();
  let dlen = body.len();
  if dlen == 0 {
    return Err("empty multipart body");
  }
  var first = bytes_find(body, 0, &delim);
  if first < 0 {
    return Err("multipart boundary not found");
  }
  var pos = first + delim.len();
  var done = false;
  while !done {
    // pos points just past the delimiter; expect "--" (final) or CRLF.
    if pos + 1 < dlen && body[pos] == 45 && body[pos + 1] == 45 {
      done = true;
      break;
    }
    var body_start: Int = -1;
    if pos + 1 < dlen && body[pos] == 13 && body[pos + 1] == 10 {
      body_start = pos + 2;
    } elif pos < dlen && body[pos] == 10 {
      body_start = pos + 1;
    } else {
      return Err("malformed multipart boundary");
    }
    // Find the blank line ("\r\n\r\n") that ends the part headers.
    let crlf_vec = crlf_bytes_t();
    var data_start: Int = -1;
    var scan = body_start;
    while scan + 3 < dlen {
      let f = bytes_find(body, scan, &crlf_vec);
      if f < 0 {
        break;
      }
      if f + 3 < dlen && body[f + 2] == 13 && body[f + 3] == 10 {
        data_start = f + 4;
        break;
      }
      scan = f + 2;
    }
    if data_start < 0 {
      return Err("multipart part has no header terminator");
    }
    let next_delim = bytes_find(body, data_start, &delim);
    if next_delim < 0 {
      return Err("multipart part is unterminated");
    }
    var data_end = next_delim;
    if data_end >= 2 && body[data_end - 2] == 13 && body[data_end - 1] == 10 {
      data_end = data_end - 2;
    }
    let header_bytes = bytes_region(body, body_start, data_start - 4);
    let hs = Str::from_utf8(header_bytes);
    let hdr = parse_part_headers(hs);
    let data = bytes_region(body, data_start, data_end);
    let name = hdr.0;
    let filename = hdr.1;
    let content_type = hdr.2;
    result.push(Part{ name: name; filename: filename; content_type: content_type; data: data; });
    pos = next_delim + delim.len();
    if pos >= dlen {
      done = true;
      break;
    }
  }
  Ok(result)
}

// crlf_bytes_t returns a fresh "\r\n" byte vector.
fn crlf_bytes_t() -> Vec[UInt8] {
  var b = Vec[UInt8].new();
  b.push(13 as UInt8);
  b.push(10 as UInt8);
  b
}

/// Generate a random boundary string.
/// Returns: a boundary of the form "----xiomboundary<unix timestamp>".
/// Complexity: O(1). Pure (timestamp-based uniqueness).
pub fn multipart_boundary_new() -> Str {
  let ts = io.time_now();
  var result = "----xiomboundary";
  result = result + ts.to_str();
  result
}

/// Build the Content-Type header value for a boundary.
/// Parameters: boundary -- the boundary string.
/// Returns: "multipart/form-data; boundary=<boundary>".
/// Complexity: O(1). Pure.
pub fn multipart_content_type(boundary: Str) -> Str {
  var result = "multipart/form-data; boundary=";
  result = result + boundary;
  result
}

