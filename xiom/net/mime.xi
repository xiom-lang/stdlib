// XIOM - Network: MIME and HTTP Header Utils
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.mime

// Depends on: xiom.string

// ============================================================================
// MIME type parsing, extension mapping, and content negotiation plus related
// HTTP header utilities: charset, etag, accept, and link. All functions are
// pure string/byte operations; ETags delegate to xiom.crypto (SHA-256) and
// xiom.encoding (hex) with different names -- safe.
// ============================================================================

use xiom.string;
use xiom.crypto;
use xiom.encoding;

// struct MimeType { type: Str; subtype: Str; params: Vec[(Str, Str)] }
//   NOTE: the frozen spec documents `params: Map[Str, Str]`. The compiler
//   cannot construct/return a struct containing a Map field (hangs/0xC0000005,
//   see probe in agent_net2); `type` must also not be the first field (reserved
//   keyword breaks cross-module resolution). Params are therefore stored as
//   ordered (name, value) pairs.
pub type MimeType = {
  subtype: Str;
  params: Vec[(Str, Str)];
  type: Str;
}

// struct Link { href: Str; rel: Str; title: Str; type: Str }
pub type Link = {
  href: Str;
  rel: Str;
  title: Str;
  type: Str;
}

// (Str, Int) - accept entry: mime pattern plus q value (scaled by 1000).

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

// idx_of returns the byte index of needle in hay, or -1.
fn idx_of(hay: Str, needle: Str) -> Int {
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

// last_idx_of returns the byte index of the last occurrence of needle, or -1.
fn last_idx_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return hlen; }
  if nlen > hlen { return -1; }
  var i = hlen - nlen;
  while i >= 0 {
    if string.str_slice(hay, i, i + nlen) == needle {
      return i;
    }
    i = i - 1;
  }
  -1
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

// fresh re-slices a string so a value read from a vector element is safe to
// concatenate (compiler BUG 26 family).
fn fresh(s: Str) -> Str {
  string.str_slice(s, 0, s.len())
}

// lower returns the lowercase form of s.
fn lower(s: Str) -> Str {
  string.str_lower(s)
}

// ext_of returns the lowercase file extension of a path ("" when absent).
fn ext_of(path: Str) -> Str {
  var i = path.len() - 1;
  while i >= 0 {
    let b = path.byte_at(i);
    if b == 47 || b == 92 {
      break;
    }
    if b == 46 {
      if i == 0 || i == path.len() - 1 {
        return "";
      }
      return lower(string.str_slice(path, i + 1, path.len()));
    }
    i = i - 1;
  }
  ""
}

// parse_q parses a "q=0.9" token into a scaled Int (q * 1000), or -1.
fn parse_q(token: Str) -> Int {
  let eq = idx_of(token, "=");
  if eq < 0 {
    return -1;
  }
  let name = lower(trim_ws(string.str_slice(token, 0, eq)));
  if name != "q" {
    return -1;
  }
  let value = trim_ws(string.str_slice(token, eq + 1, token.len()));
  let len = value.len();
  if len == 0 {
    return -1;
  }
  var int_part = 0;
  var i = 0;
  while i < len {
    let b = value.byte_at(i);
    if b == 46 {
      break;
    }
    if b < 48 || b > 57 {
      return -1;
    }
    int_part = int_part * 10 + (b as Int - 48);
    i = i + 1;
  }
  if int_part > 1 {
    return -1;
  }
  var frac = 0;
  var frac_digits = 0;
  if i < len && value.byte_at(i) == 46 {
    i = i + 1;
    while i < len && frac_digits < 3 {
      let b = value.byte_at(i);
      if b < 48 || b > 57 {
        return -1;
      }
      frac = frac * 10 + (b as Int - 48);
      frac_digits = frac_digits + 1;
      i = i + 1;
    }
  }
  while frac_digits < 3 {
    frac = frac * 10;
    frac_digits = frac_digits + 1;
  }
  int_part * 1000 + frac
}

/// Parse a MIME type string into its parts.
/// Parameters: s -- the MIME type (e.g. "text/html; charset=utf-8").
/// Returns: Ok(MimeType) with a lowercased type/subtype and parsed
///          parameters (in declaration order); Err for a missing slash or an
///          empty type.
/// Complexity: O(n). Pure.
pub fn mime_parse(s: Str) -> Result[MimeType, Str] {
  var params: Vec[(Str, Str)] = Vec[(Str, Str)].new();
  let semi = idx_of(s, ";");
  var base = s;
  if semi >= 0 {
    base = string.str_slice(s, 0, semi);
  }
  let slash = idx_of(base, "/");
  if slash <= 0 {
    return Err("invalid MIME type: missing slash");
  }
  let typ = lower(trim_ws(string.str_slice(base, 0, slash)));
  let sub = lower(trim_ws(string.str_slice(base, slash + 1, base.len())));
  if typ.len() == 0 || sub.len() == 0 {
    return Err("invalid MIME type: empty type or subtype");
  }
  if semi >= 0 {
    let rest = string.str_slice(s, semi + 1, s.len());
    let parts = split(rest, ";");
    var i = 0;
    while i < parts.len() {
      let seg = fresh(trim_ws(parts[i]));
      let eq = idx_of(seg, "=");
      if eq > 0 {
        let k = lower(trim_ws(string.str_slice(seg, 0, eq)));
        let v = fresh(trim_ws(string.str_slice(seg, eq + 1, seg.len())));
        if k.len() > 0 {
          params.push((k, v));
        }
      }
      i = i + 1;
    }
  }
  Ok(MimeType{ subtype: sub; params: params; type: typ; })
}

/// Guess the MIME type from a file extension.
/// Parameters: path -- the file path.
/// Returns: the MIME type (lowercase) or "application/octet-stream".
/// Complexity: O(1). Pure.
pub fn mime_type_of(path: Str) -> Str {
  let e = ext_of(path);
  if e == "html" || e == "htm" { return "text/html"; }
  if e == "txt" { return "text/plain"; }
  if e == "css" { return "text/css"; }
  if e == "csv" { return "text/csv"; }
  if e == "md" { return "text/markdown"; }
  if e == "json" { return "application/json"; }
  if e == "js" || e == "mjs" { return "application/javascript"; }
  if e == "xml" { return "application/xml"; }
  if e == "pdf" { return "application/pdf"; }
  if e == "zip" { return "application/zip"; }
  if e == "gz" { return "application/gzip"; }
  if e == "tar" { return "application/x-tar"; }
  if e == "wasm" { return "application/wasm"; }
  if e == "png" { return "image/png"; }
  if e == "jpg" || e == "jpeg" { return "image/jpeg"; }
  if e == "gif" { return "image/gif"; }
  if e == "bmp" { return "image/bmp"; }
  if e == "webp" { return "image/webp"; }
  if e == "svg" { return "image/svg+xml"; }
  if e == "ico" { return "image/x-icon"; }
  if e == "avif" { return "image/avif"; }
  if e == "mp3" { return "audio/mpeg"; }
  if e == "wav" { return "audio/wav"; }
  if e == "ogg" { return "audio/ogg"; }
  if e == "flac" { return "audio/flac"; }
  if e == "mp4" { return "video/mp4"; }
  if e == "webm" { return "video/webm"; }
  if e == "mov" { return "video/quicktime"; }
  if e == "avi" { return "video/x-msvideo"; }
  if e == "ttf" { return "font/ttf"; }
  if e == "woff" { return "font/woff"; }
  if e == "woff2" { return "font/woff2"; }
  "application/octet-stream"
}

/// Guess a file extension for a MIME type.
/// Parameters: mime -- the MIME type (lowercase).
/// Returns: the extension without the leading dot, or "" when unknown.
/// Complexity: O(1). Pure.
pub fn mime_extension_of(mime: Str) -> Str {
  let m = lower(trim_ws(mime));
  if m == "text/html" { return "html"; }
  if m == "text/plain" { return "txt"; }
  if m == "text/css" { return "css"; }
  if m == "text/csv" { return "csv"; }
  if m == "application/json" { return "json"; }
  if m == "application/javascript" { return "js"; }
  if m == "application/xml" { return "xml"; }
  if m == "application/pdf" { return "pdf"; }
  if m == "application/zip" { return "zip"; }
  if m == "application/gzip" { return "gz"; }
  if m == "image/png" { return "png"; }
  if m == "image/jpeg" { return "jpg"; }
  if m == "image/gif" { return "gif"; }
  if m == "image/bmp" { return "bmp"; }
  if m == "image/webp" { return "webp"; }
  if m == "image/svg+xml" { return "svg"; }
  if m == "audio/mpeg" { return "mp3"; }
  if m == "audio/wav" { return "wav"; }
  if m == "video/mp4" { return "mp4"; }
  if m == "video/webm" { return "webm"; }
  ""
}

/// Wildcard pattern match against a MIME type.
/// Parameters: pattern -- e.g. "text/*", "application/json" or "*/*"; mime --
///          the actual MIME type.
/// Returns: true when the pattern matches.
/// Complexity: O(n). Pure.
pub fn mime_matches(pattern: Str, mime: Str) -> Bool {
  let p = lower(pattern);
  let m = lower(mime);
  if p == "*/*" || p == "*" {
    return true;
  }
  if p == m {
    return true;
  }
  let star = idx_of(p, "*");
  if star >= 0 {
    let prefix = string.str_slice(p, 0, star);
    if string.str_slice(m, 0, prefix.len()) == prefix {
      return true;
    }
  }
  false
}

// type_part returns the top-level type of a MIME string.
fn type_part(mime: Str) -> Str {
  let m = lower(trim_ws(mime));
  let slash = idx_of(m, "/");
  if slash > 0 {
    return string.str_slice(m, 0, slash);
  }
  m
}

/// Test if a MIME type is text-based.
/// Parameters: mime -- the MIME type.
/// Returns: true for text/*, application/json, application/xml and related.
/// Complexity: O(1). Pure.
pub fn mime_is_text(mime: Str) -> Bool {
  let m = lower(trim_ws(mime));
  if m == "application/json" || m == "application/xml" || m == "application/javascript" {
    return true;
  }
  if m == "application/x-www-form-urlencoded" || m == "application/xhtml+xml" {
    return true;
  }
  type_part(m) == "text"
}

/// Test if a MIME type is an image.
/// Parameters: mime -- the MIME type.
/// Returns: true for image/* and image/x-* types.
/// Complexity: O(1). Pure.
pub fn mime_is_image(mime: Str) -> Bool {
  let m = lower(trim_ws(mime));
  string.str_starts_with(m, "image/")
}

/// Test if a MIME type is audio.
/// Parameters: mime -- the MIME type.
/// Returns: true for audio/* types.
/// Complexity: O(1). Pure.
pub fn mime_is_audio(mime: Str) -> Bool {
  let m = lower(trim_ws(mime));
  string.str_starts_with(m, "audio/")
}

/// Test if a MIME type is video.
/// Parameters: mime -- the MIME type.
/// Returns: true for video/* types.
/// Complexity: O(1). Pure.
pub fn mime_is_video(mime: Str) -> Bool {
  let m = lower(trim_ws(mime));
  string.str_starts_with(m, "video/")
}

/// Test if a MIME type is an application type.
/// Parameters: mime -- the MIME type.
/// Returns: true for application/* types.
/// Complexity: O(1). Pure.
pub fn mime_is_application(mime: Str) -> Bool {
  let m = lower(trim_ws(mime));
  string.str_starts_with(m, "application/")
}

// has_utf8_bom_b returns whether data starts with the UTF-8 BOM.
fn has_utf8_bom_b(data: &Vec[UInt8]) -> Bool {
  data.len() >= 3 && data[0] == 239 as UInt8 && data[1] == 187 as UInt8 && data[2] == 191 as UInt8
}

/// Guess the character encoding of a byte buffer.
/// Parameters: data -- the bytes to inspect.
/// Returns: "utf-8", "utf-16le", "utf-16be", "utf-32le", "utf-32be", "ascii"
///          or "binary".
/// Complexity: O(n). Pure.
pub fn charset_detect(data: &Vec[UInt8]) -> Str {
  let len = data.len();
  if len >= 4 && data[0] == 255 as UInt8 && data[1] == 254 as UInt8 && data[2] == 0 as UInt8 && data[3] == 0 as UInt8 {
    return "utf-32le";
  }
  if len >= 4 && data[0] == 0 as UInt8 && data[1] == 0 as UInt8 && data[2] == 254 as UInt8 && data[3] == 255 as UInt8 {
    return "utf-32be";
  }
  if len >= 2 && data[0] == 255 as UInt8 && data[1] == 254 as UInt8 {
    return "utf-16le";
  }
  if len >= 2 && data[0] == 254 as UInt8 && data[1] == 255 as UInt8 {
    return "utf-16be";
  }
  if has_utf8_bom_b(data) {
    return "utf-8";
  }
  var i = 0;
  var ascii = true;
  var binary = false;
  while i < len {
    let b = data[i] as Int;
    if b > 127 {
      ascii = false;
    }
    if b == 0 {
      binary = true;
    }
    i = i + 1;
  }
  if binary {
    return "binary";
  }
  if ascii {
    return "ascii";
  }
  "utf-8"
}

/// Re-encode a string into a target charset.
/// Parameters: s -- the input string (already UTF-8); charset -- the requested
///          target charset.
/// Returns: Ok(s) for UTF-8/ASCII targets (XIOM strings are always UTF-8),
///          Err for unsupported targets.
/// Complexity: O(1). Pure.
pub fn charset_normalize(s: Str, charset: Str) -> Result[Str, Str] {
  let c = lower(charset);
  if c == "utf-8" || c == "utf8" || c == "us-ascii" || c == "ascii" || c == "iso-8859-1" {
    return Ok(s);
  }
  Err("cannot transcode to charset: " + charset)
}

/// Compute a quoted etag for a byte buffer (SHA-256 hex).
/// Parameters: content -- the bytes to hash.
/// Returns: the quoted etag, e.g. "\"a1b2c3...\"".
/// Complexity: O(n). Pure.
pub fn etag_new(content: &Vec[UInt8]) -> Str {
  let hash = crypto.sha256(content);
  var fresh_hash = Vec[UInt8].new();
  var i = 0;
  while i < hash.len() {
    fresh_hash.push(hash[i]);
    i = i + 1;
  }
  let hex = encoding.hex_encode(&fresh_hash);
  "\"" + hex + "\""
}

/// Test an etag against an If-None-Match header.
/// Parameters: etag -- the entity tag (quoted); if_none_match -- the header
///          value (a comma-separated list, optionally W/ prefixed).
/// Returns: true when any list entry matches (including "*").
/// Complexity: O(n). Pure.
pub fn etag_matches(etag: Str, if_none_match: Str) -> Bool {
  let e = trim_ws(etag);
  if if_none_match == "*" {
    return true;
  }
  let items = split(if_none_match, ",");
  var i = 0;
  while i < items.len() {
    var item = fresh(trim_ws(items[i]));
    if string.str_starts_with(item, "W/") {
      item = string.str_slice(item, 2, item.len());
    }
    if item == e {
      return true;
    }
    i = i + 1;
  }
  false
}

/// Parse an Accept header into mime pattern and q pairs.
/// Parameters: header -- the Accept header value.
/// Returns: the (pattern, q*1000) entries; malformed entries are skipped.
/// Complexity: O(n). Pure.
pub fn accept_parse(header: Str) -> Vec[(Str, Int)] {
  var result: Vec[(Str, Int)] = Vec[(Str, Int)].new();
  let items = split(header, ",");
  var i = 0;
  while i < items.len() {
    let entry = fresh(trim_ws(items[i]));
    if entry.len() == 0 {
      i = i + 1;
      continue;
    }
    let parts = split(entry, ";");
    let mime = fresh(trim_ws(parts[0]));
    var q = 1000;
    var j = 1;
    while j < parts.len() {
      let tok = fresh(trim_ws(parts[j]));
      let qv = parse_q(tok);
      if qv >= 0 {
        q = qv;
      }
      j = j + 1;
    }
    if mime.len() > 0 {
      result.push((mime, q));
    }
    i = i + 1;
  }
  result
}

/// Look up the q value of a MIME type in an Accept header.
/// Parameters: header -- the Accept header value; mime -- the actual MIME type.
/// Returns: the highest matching q (scaled by 1000), or 0 when absent.
/// Complexity: O(n). Pure.
pub fn accept_q_value(header: Str, mime: Str) -> Int {
  let entries = accept_parse(header);
  var best = 0;
  var i = 0;
  while i < entries.len() {
    let e = entries[i];
    if mime_matches(e.0, mime) {
      if e.1 > best {
        best = e.1;
      }
    }
    i = i + 1;
  }
  best
}

/// Pick the best available MIME type for an Accept header.
/// Parameters: header -- the Accept header value; available -- the candidate
///          MIME types.
/// Returns: Some(best) when a match with q > 0 exists, None otherwise.
/// Complexity: O(n-m). Pure.
pub fn accept_negotiate(header: Str, available: &Vec[Str]) -> Option[Str] {
  var best_q = 0;
  var best = "";
  var i = 0;
  while i < available.len() {
    let cand = available[i];
    let q = accept_q_value(header, cand);
    if q > best_q {
      best_q = q;
      best = cand;
    }
    i = i + 1;
  }
  if best_q > 0 && best.len() > 0 {
    return Some(best);
  }
  None
}

/// Parse a Link header into typed links.
/// Parameters: header -- the Link header value (e.g.
///          "<https://a.com>; rel=\"next\"; title=\"Next\"").
/// Returns: the parsed links; malformed entries are skipped.
/// Complexity: O(n). Pure.
pub fn link_parse(header: Str) -> Vec[Link] {
  var result: Vec[Link] = Vec[Link].new();
  let items = split(header, ",");
  var i = 0;
  while i < items.len() {
    let entry = fresh(trim_ws(items[i]));
    if entry.len() == 0 || entry.byte_at(0) != 60 {
      i = i + 1;
      continue;
    }
    let close = idx_of(entry, ">");
    if close < 0 {
      i = i + 1;
      continue;
    }
    let href = fresh(trim_ws(string.str_slice(entry, 1, close)));
    var rel = "";
    var title = "";
    var typ = "";
    let rest = string.str_slice(entry, close + 1, entry.len());
    let attrs = split(rest, ";");
    var j = 0;
    while j < attrs.len() {
      let attr = fresh(trim_ws(attrs[j]));
      let eq = idx_of(attr, "=");
      if eq > 0 {
        let name = lower(fresh(trim_ws(string.str_slice(attr, 0, eq))));
        var value = fresh(trim_ws(string.str_slice(attr, eq + 1, attr.len())));
        let vlen = value.len();
        if vlen >= 2 && value.byte_at(0) == 34 && value.byte_at(vlen - 1) == 34 {
          value = string.str_slice(value, 1, vlen - 1);
        }
        if name == "rel" {
          rel = value;
        } elif name == "title" {
          title = value;
        } elif name == "type" {
          typ = value;
        }
      }
      j = j + 1;
    }
    result.push(Link{ href: href; rel: rel; title: title; type: typ; });
    i = i + 1;
  }
  result
}

/// Find the href of a link with the given rel.
/// Parameters: links -- the parsed links; rel -- the relation type.
/// Returns: Some(href) for the first matching link, None otherwise.
/// Complexity: O(n). Pure.
pub fn link_find(links: &Vec[Link], rel: Str) -> Option[Str] {
  var i = 0;
  while i < links.len() {
    let l = links[i];
    if l.rel == rel {
      return Some(l.href);
    }
    i = i + 1;
  }
  None
}
