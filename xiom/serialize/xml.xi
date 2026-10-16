// XIOM - Serialize: XML
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.serialize.xml

// Depends on: xiom.string, xiom.collections, xiom.convert

// ============================================================================
// Streaming XML tokenizer (tokenizer only -- no tree builder).
//
// Emits a lexical token stream for the shapes the packages wishlist asks for
// (2026-10-02: tags, quote-aware attributes, comments/PIs, entity/char-ref
// decode): prolog, processing instructions, DOCTYPE (raw, internal subset
// skipped), start/end tags with attributes, text, comments, CDATA, and EOF.
//
// Safety stance (malformed input never crashes):
//   - the scanner is iterative (no recursion), so nesting depth cannot
//     overflow the process stack;
//   - every unterminated construct (tag, quoted attribute, comment, CDATA,
//     PI, DOCTYPE) returns a typed Err with the byte offset;
//   - bare '&' and invalid entity/char references are rejected with Err
//     (strict XML 1.0 lexical rules; numeric refs are validated as XML
//     characters and encoded to UTF-8);
//   - after the first Err the tokenizer latches: every further xml_next call
//     returns Err again, never a partial token.
//
// Scope: tokenizer only. Tag-name matching, attribute-name uniqueness,
// DOCTYPE grammar, and namespace rules are NOT checked here.
//
// Byte-access note: like xiom.serialize.json, the scanner works through one
// cached (base, n) view bound once per call (string.char_at/byte_at strnlen
// the whole string per accessor call). ASCII structure bytes are compared
// exactly; non-ASCII name bytes and text pass through as UTF-8.
// ============================================================================

use xiom.string;
use xiom.collections;
use xiom.convert;

// ============================================================================
// Types
// ============================================================================

/// One attribute of a start tag. `value` is the entity-decoded text between
/// the quotes (the quotes themselves are not part of it).
pub type XmlAttr = {
  name: Str;
  value: Str;
}

/// A start tag: its name, attributes in document order, and whether the tag
/// was explicitly closed with `/>`.
pub type XmlTag = {
  name: Str;
  attrs: Vec[XmlAttr];
  self_closing: Bool;
}

/// One lexical XML token.
///
/// Payloads:
///   - Prolog / ProcessingInstruction / Doctype: the raw text between the
///     delimiters (no entity decoding; DOCTYPE includes its internal subset);
///   - StartTag: the tag with its attributes (attribute values decoded);
///   - EndTag: the tag name;
///   - Text / Comment / CData: the content (Text is entity-decoded, Comment
///     and CData are raw);
///   - Eof: end of input.
pub type XmlToken = enum {
  Prolog(content: Str),
  ProcessingInstruction(content: Str),
  Doctype(content: Str),
  StartTag(tag: XmlTag),
  EndTag(name: Str),
  Text(value: Str),
  Comment(value: Str),
  CData(value: Str),
  Eof,
}

/// Streaming tokenizer state. Create it with xml_tokenizer_new, then pull
/// tokens with xml_next until XmlToken.Eof (or Err).
///
/// Fields: `src` is the whole document, `pos` the next unread byte offset,
/// `failed`/`err` latch the first error so a broken stream can never yield a
/// token after its Err.
pub type XmlTokenizer = {
  src: Str;
  pos: Int;
  failed: Bool;
  err: Str;
}

// ============================================================================
// Byte helpers (base pointer is always bounds-checked against n by callers)
// ============================================================================

fn _xml_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bounds-check against n (T007)
{
  unsafe { return *(base + i); }
}

fn _xml_is_ws(b: UInt8) -> Bool {
  return b == 32 || b == 9 || b == 10 || b == 13;
}

fn _xml_is_alpha(b: UInt8) -> Bool {
  return (b >= 65 && b <= 90) || (b >= 97 && b <= 122);
}

fn _xml_is_digit_b(b: UInt8) -> Bool {
  return b >= 48 && b <= 57;
}

fn _xml_is_name_start(b: UInt8) -> Bool {
  if _xml_is_alpha(b) { return true; }
  if b == 95 || b == 58 { return true; }  // _ :
  return b >= 0x80;  // UTF-8 name bytes pass through unvalidated
}

fn _xml_is_name_char(b: UInt8) -> Bool {
  if _xml_is_name_start(b) { return true; }
  if _xml_is_digit_b(b) { return true; }
  if b == 45 || b == 46 { return true; }  // - .
  return false;
}

fn _xml_push_range(buf: &mut Vec[UInt8], base: *UInt8, start: Int, end: Int) {
  var i = start;
  while i < end {
    buf.push(_xml_byte(base, i));
    i = i + 1;
  }
}

fn _xml_buf_str(buf: Vec[UInt8]) -> Str {
  if buf.len() == 0 {
    return "";
  }
  return Str::from_utf8(buf);
}

fn _xml_range_str(base: *UInt8, start: Int, end: Int) -> Str {
  if end <= start {
    return "";
  }
  var buf = Vec[UInt8].new();
  _xml_push_range(&mut buf, base, start, end);
  return _xml_buf_str(buf);
}

// Errors carry the byte offset of the offending construct (relay ask:
// byte-offset errors for flat scanners).
fn _xml_err_at(msg: Str, off: Int) -> Str {
  return msg + " at byte " + convert.int_to_string(off);
}

// Byte-exact literal match at `pos` (bounds-checked against n).
fn _xml_match_lit(base: *UInt8, n: Int, pos: Int, lit: Str) -> Bool
  requires: true  // base/n pairing is the caller's contract (T007)
{
  let ln = lit.len();
  if pos + ln > n {
    return false;
  }
  let lb = lit.c_str();
  var k = 0;
  while k < ln {
    if _xml_byte(base, pos + k) != _xml_byte(lb, k) {
      return false;
    }
    k = k + 1;
  }
  return true;
}

fn _xml_hex_val(b: UInt8) -> Int {
  if b >= 48 && b <= 57 { return (b as Int) - 48; }
  if b >= 97 && b <= 102 { return (b as Int) - 87; }
  if b >= 65 && b <= 70 { return (b as Int) - 55; }
  return -1;
}

// Encode one code point as UTF-8 into `buf`. False when `cp` is not a valid
// XML 1.0 character (surrogates, controls other than tab/LF/CR, > U+10FFFF).
fn _xml_encode_cp(cp: Int, buf: &mut Vec[UInt8]) -> Bool {
  if cp < 0 || cp > 0x10FFFF { return false; }
  if cp >= 0xD800 && cp <= 0xDFFF { return false; }
  if cp < 0x20 && cp != 9 && cp != 10 && cp != 13 { return false; }
  if cp < 0x80 {
    buf.push(cp as UInt8);
    return true;
  }
  if cp < 0x800 {
    buf.push((0xC0 | (cp >> 6)) as UInt8);
    buf.push((0x80 | (cp & 0x3F)) as UInt8);
    return true;
  }
  if cp < 0x10000 {
    buf.push((0xE0 | (cp >> 12)) as UInt8);
    buf.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    buf.push((0x80 | (cp & 0x3F)) as UInt8);
    return true;
  }
  buf.push((0xF0 | (cp >> 18)) as UInt8);
  buf.push((0x80 | ((cp >> 12) & 0x3F)) as UInt8);
  buf.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
  buf.push((0x80 | (cp & 0x3F)) as UInt8);
  return true;
}

// Decode the entity/char references in base[start..end) into `out`. Plain
// bytes pass through. Returns Err on a bare '&', an unknown named entity, an
// empty/oversized/unterminated char ref, or an invalid XML character.
fn _xml_decode_range(out: &mut Vec[UInt8], base: *UInt8, start: Int, end: Int) -> Result[Bool, Str] {
  var i = start;
  while i < end {
    let b = _xml_byte(base, i);
    if b != 38 {  // '&'
      out.push(b);
      i = i + 1;
      continue;
    }
    if i + 1 >= end {
      return Err(_xml_err_at("xml: bare '&'", i));
    }
    let c = _xml_byte(base, i + 1);
    if c == 35 {  // '#'
      var j = i + 2;
      var cp = 0;
      var digits = 0;
      if j < end && (_xml_byte(base, j) == 120 || _xml_byte(base, j) == 88) {  // x X
        j = j + 1;
        while j < end && _xml_hex_val(_xml_byte(base, j)) >= 0 {
          cp = cp * 16 + _xml_hex_val(_xml_byte(base, j));
          if cp > 0x10FFFF {
            return Err(_xml_err_at("xml: char ref out of range", i));
          }
          j = j + 1;
          digits = digits + 1;
        }
      } else {
        while j < end && _xml_is_digit_b(_xml_byte(base, j)) {
          cp = cp * 10 + ((_xml_byte(base, j) as Int) - 48);
          if cp > 0x10FFFF {
            return Err(_xml_err_at("xml: char ref out of range", i));
          }
          j = j + 1;
          digits = digits + 1;
        }
      }
      if digits == 0 {
        return Err(_xml_err_at("xml: empty char ref", i));
      }
      if j >= end || _xml_byte(base, j) != 59 {  // ';'
        return Err(_xml_err_at("xml: unterminated char ref", i));
      }
      if !_xml_encode_cp(cp, out) {
        return Err(_xml_err_at("xml: invalid char ref", i));
      }
      i = j + 1;
    } else {
      var matched = false;
      var adv = 0;
      if _xml_match_lit(base, end, i + 1, "amp;") {
        out.push(38);
        matched = true;
        adv = 4;
      } elif _xml_match_lit(base, end, i + 1, "lt;") {
        out.push(60);
        matched = true;
        adv = 3;
      } elif _xml_match_lit(base, end, i + 1, "gt;") {
        out.push(62);
        matched = true;
        adv = 3;
      } elif _xml_match_lit(base, end, i + 1, "quot;") {
        out.push(34);
        matched = true;
        adv = 5;
      } elif _xml_match_lit(base, end, i + 1, "apos;") {
        out.push(39);
        matched = true;
        adv = 5;
      }
      if !matched {
        return Err(_xml_err_at("xml: unknown entity", i));
      }
      i = i + 1 + adv;
    }
  }
  return Ok(true);
}

// ============================================================================
// Scanner state machine (iterative)
// ============================================================================

fn _xml_fail(t: &mut XmlTokenizer, msg: Str) -> Result[XmlToken, Str] {
  t.failed = true;
  t.err = msg;
  return Err(msg);
}

fn _xml_scan_name(base: *UInt8, n: Int, i: &mut Int) -> Result[Str, Str] {
  if *i >= n {
    return Err(_xml_err_at("xml: expected tag name", *i));
  }
  if !_xml_is_name_start(_xml_byte(base, *i)) {
    return Err(_xml_err_at("xml: invalid tag name", *i));
  }
  let start = *i;
  while *i < n && _xml_is_name_char(_xml_byte(base, *i)) {
    *i = *i + 1;
  }
  return Ok(_xml_range_str(base, start, *i));
}

fn _xml_scan_text(t: &mut XmlTokenizer, base: *UInt8, n: Int, pos: Int) -> Result[XmlToken, Str] {
  var end = pos;
  while end < n && _xml_byte(base, end) != 60 {  // '<'
    end = end + 1;
  }
  var buf = Vec[UInt8].new();
  match _xml_decode_range(&mut buf, base, pos, end) {
    Ok(_) => {},
    Err(e) => { return _xml_fail(t, e); },
  }
  t.pos = end;
  return Ok(XmlToken.Text(_xml_buf_str(buf)));
}

fn _xml_scan_pi(t: &mut XmlTokenizer, base: *UInt8, n: Int, pos: Int) -> Result[XmlToken, Str] {
  var i = pos + 2;
  var name = "";
  match _xml_scan_name(base, n, &i) {
    Ok(v) => { name = v; },
    Err(e) => { return _xml_fail(t, e); },
  }
  let is_prolog = name == "xml";
  var j = i;
  var found = false;
  while j + 1 < n {
    if _xml_byte(base, j) == 63 && _xml_byte(base, j + 1) == 62 {  // ? >
      found = true;
      break;
    }
    j = j + 1;
  }
  if !found {
    return _xml_fail(t, _xml_err_at("xml: unterminated processing instruction", pos));
  }
  let content = _xml_range_str(base, pos + 2, j);
  t.pos = j + 2;
  if is_prolog {
    return Ok(XmlToken.Prolog(content));
  }
  return Ok(XmlToken.ProcessingInstruction(content));
}

fn _xml_scan_comment(t: &mut XmlTokenizer, base: *UInt8, n: Int, pos: Int) -> Result[XmlToken, Str] {
  var j = pos + 4;  // after "<!--"
  var end_at = -1;
  while j + 2 < n {
    if _xml_byte(base, j) == 45 {  // '-'
      if _xml_byte(base, j + 1) == 45 {
        if _xml_byte(base, j + 2) == 62 {  // '>'
          end_at = j;
          break;
        }
        return _xml_fail(t, _xml_err_at("xml: '--' inside comment", j));
      }
    }
    j = j + 1;
  }
  if end_at < 0 {
    return _xml_fail(t, _xml_err_at("xml: unterminated comment", pos));
  }
  let content = _xml_range_str(base, pos + 4, end_at);
  t.pos = end_at + 3;
  return Ok(XmlToken.Comment(content));
}

fn _xml_scan_cdata(t: &mut XmlTokenizer, base: *UInt8, n: Int, pos: Int) -> Result[XmlToken, Str] {
  var j = pos + 9;  // after "<![CDATA["
  var end_at = -1;
  while j + 2 < n {
    if _xml_byte(base, j) == 93 && _xml_byte(base, j + 1) == 93 && _xml_byte(base, j + 2) == 62 {  // ] ] >
      end_at = j;
      break;
    }
    j = j + 1;
  }
  if end_at < 0 {
    return _xml_fail(t, _xml_err_at("xml: unterminated CDATA section", pos));
  }
  let content = _xml_range_str(base, pos + 9, end_at);
  t.pos = end_at + 3;
  return Ok(XmlToken.CData(content));
}

fn _xml_scan_doctype(t: &mut XmlTokenizer, base: *UInt8, n: Int, pos: Int) -> Result[XmlToken, Str] {
  var j = pos + 9;  // after "<!DOCTYPE"
  var depth = 0;
  var quote: UInt8 = 0;
  var end_at = -1;
  while j < n {
    let b = _xml_byte(base, j);
    if quote != 0 {
      if b == quote { quote = 0; }
    } elif b == 34 || b == 39 {
      quote = b;
    } elif b == 91 {  // '['
      depth = depth + 1;
    } elif b == 93 {  // ']'
      if depth > 0 { depth = depth - 1; }
    } elif b == 62 && depth == 0 {  // '>'
      end_at = j;
      break;
    }
    j = j + 1;
  }
  if end_at < 0 {
    return _xml_fail(t, _xml_err_at("xml: unterminated DOCTYPE", pos));
  }
  let content = _xml_range_str(base, pos + 9, end_at);
  t.pos = end_at + 1;
  return Ok(XmlToken.Doctype(content));
}

fn _xml_scan_start_tag(t: &mut XmlTokenizer, base: *UInt8, n: Int, pos: Int) -> Result[XmlToken, Str] {
  var i = pos + 1;
  var name = "";
  match _xml_scan_name(base, n, &i) {
    Ok(v) => { name = v; },
    Err(e) => { return _xml_fail(t, e); },
  }
  var attrs = Vec[XmlAttr].new();
  loop {
    var had_ws = false;
    while i < n && _xml_is_ws(_xml_byte(base, i)) {
      i = i + 1;
      had_ws = true;
    }
    if i >= n {
      return _xml_fail(t, _xml_err_at("xml: unterminated start tag", pos));
    }
    let b = _xml_byte(base, i);
    if b == 62 {  // '>'
      i = i + 1;
      t.pos = i;
      return Ok(XmlToken.StartTag(XmlTag{ name: name; attrs: attrs; self_closing: false; }));
    }
    if b == 47 {  // '/'
      if i + 1 < n && _xml_byte(base, i + 1) == 62 {
        i = i + 2;
        t.pos = i;
        return Ok(XmlToken.StartTag(XmlTag{ name: name; attrs: attrs; self_closing: true; }));
      }
      return _xml_fail(t, _xml_err_at("xml: expected '>' after '/'", i));
    }
    if !had_ws {
      return _xml_fail(t, _xml_err_at("xml: whitespace required before attribute", i));
    }
    var aname = "";
    match _xml_scan_name(base, n, &i) {
      Ok(v) => { aname = v; },
      Err(e) => { return _xml_fail(t, e); },
    }
    while i < n && _xml_is_ws(_xml_byte(base, i)) { i = i + 1; }
    if i >= n || _xml_byte(base, i) != 61 {  // '='
      return _xml_fail(t, _xml_err_at("xml: expected '=' after attribute name", i));
    }
    i = i + 1;
    while i < n && _xml_is_ws(_xml_byte(base, i)) { i = i + 1; }
    if i >= n {
      return _xml_fail(t, _xml_err_at("xml: missing attribute value", i));
    }
    let q = _xml_byte(base, i);
    if q != 34 && q != 39 {
      return _xml_fail(t, _xml_err_at("xml: attribute value must be quoted", i));
    }
    i = i + 1;
    let vstart = i;
    var vend = -1;
    while i < n {
      let vb = _xml_byte(base, i);
      if vb == q {
        vend = i;
        break;
      }
      if vb == 60 {  // '<'
        return _xml_fail(t, _xml_err_at("xml: '<' in attribute value", i));
      }
      i = i + 1;
    }
    if vend < 0 {
      return _xml_fail(t, _xml_err_at("xml: unterminated attribute value", vstart));
    }
    var vbuf = Vec[UInt8].new();
    match _xml_decode_range(&mut vbuf, base, vstart, vend) {
      Ok(_) => {},
      Err(e) => { return _xml_fail(t, e); },
    }
    attrs.push(XmlAttr{ name: aname; value: _xml_buf_str(vbuf); });
    i = i + 1;
  }
}

fn _xml_scan_end_tag(t: &mut XmlTokenizer, base: *UInt8, n: Int, pos: Int) -> Result[XmlToken, Str] {
  var i = pos + 2;
  var name = "";
  match _xml_scan_name(base, n, &i) {
    Ok(v) => { name = v; },
    Err(e) => { return _xml_fail(t, e); },
  }
  while i < n && _xml_is_ws(_xml_byte(base, i)) { i = i + 1; }
  if i >= n || _xml_byte(base, i) != 62 {  // '>'
    return _xml_fail(t, _xml_err_at("xml: malformed end tag", pos));
  }
  t.pos = i + 1;
  return Ok(XmlToken.EndTag(name));
}

// ============================================================================
// Public API
// ============================================================================

/// Create a streaming tokenizer over `s`.
/// Complexity: O(1); no bytes are scanned until the first xml_next call.
pub fn xml_tokenizer_new(s: Str) -> XmlTokenizer
  ensures: result.pos == 0
{
  return XmlTokenizer{ src: s; pos: 0; failed: false; err: ""; };
}

/// Pull the next token. Returns XmlToken.Eof at the end of input and a typed
/// Err (with a byte offset) on malformed input; after an Err every further
/// call returns the same Err (the tokenizer latches).
/// Complexity: O(k), k = bytes consumed by this token.
pub fn xml_next(t: &mut XmlTokenizer) -> Result[XmlToken, Str]
  ensures: (result.is_err == true) => (t.failed == true)
{
  if t.failed {
    return Err(t.err);
  }
  let base = t.src.c_str();
  let n = t.src.len();
  let pos = t.pos;
  if pos >= n {
    return Ok(XmlToken.Eof);
  }
  let b = _xml_byte(base, pos);
  if b != 60 {  // not '<' -> text run
    return _xml_scan_text(t, base, n, pos);
  }
  if pos + 1 >= n {
    return _xml_fail(t, _xml_err_at("xml: unexpected end after '<'", pos));
  }
  let c1 = _xml_byte(base, pos + 1);
  if c1 == 63 {  // '?'
    return _xml_scan_pi(t, base, n, pos);
  }
  if c1 == 33 {  // '!'
    if _xml_match_lit(base, n, pos + 2, "--") {
      return _xml_scan_comment(t, base, n, pos);
    }
    if _xml_match_lit(base, n, pos + 2, "[CDATA[") {
      return _xml_scan_cdata(t, base, n, pos);
    }
    if _xml_match_lit(base, n, pos + 2, "DOCTYPE") {
      let after = pos + 9;
      if after < n && !_xml_is_ws(_xml_byte(base, after)) {
        return _xml_fail(t, _xml_err_at("xml: malformed DOCTYPE", pos));
      }
      return _xml_scan_doctype(t, base, n, pos);
    }
    return _xml_fail(t, _xml_err_at("xml: unsupported markup declaration", pos));
  }
  if c1 == 47 {  // '/'
    return _xml_scan_end_tag(t, base, n, pos);
  }
  return _xml_scan_start_tag(t, base, n, pos);
}

/// Tokenize the whole document into a Vec (without the trailing Eof token).
/// Returns Err on the first malformed construct.
/// Complexity: O(n), n = input length.
pub fn xml_tokenize(s: Str) -> Result[Vec[XmlToken], Str]
  ensures: (s.len() == 0) => (result.is_ok == true)
{
  var t = xml_tokenizer_new(s);
  var out = Vec[XmlToken].new();
  loop {
    match xml_next(&mut t) {
      Ok(tok) => {
        match tok {
          XmlToken.Eof => { return Ok(out); },
          _ => { out.push(tok); },
        }
      }
      Err(e) => { return Err(e); },
    }
  }
}

/// The token kind name: "prolog", "processing_instruction", "doctype",
/// "start_tag", "end_tag", "text", "comment", "cdata", or "eof".
/// Complexity: O(1).
pub fn xml_token_kind(t: XmlToken) -> Str
  ensures: result.len() >= 3
{
  match t {
    XmlToken.Prolog(_) => "prolog",
    XmlToken.ProcessingInstruction(_) => "processing_instruction",
    XmlToken.Doctype(_) => "doctype",
    XmlToken.StartTag(_) => "start_tag",
    XmlToken.EndTag(_) => "end_tag",
    XmlToken.Text(_) => "text",
    XmlToken.Comment(_) => "comment",
    XmlToken.CData(_) => "cdata",
    XmlToken.Eof => "eof",
  }
}

/// The first attribute named `name` on `tag` (names are case-sensitive).
/// Complexity: O(a), a = attribute count.
pub fn xml_attr_get(tag: &XmlTag, name: Str) -> Option[Str]
  ensures: (name.len() == 0) => (result.is_none == true)
{
  var i = 0;
  while i < tag.attrs.len() {
    if tag.attrs[i].name == name {
      return Some(tag.attrs[i].value);
    }
    i = i + 1;
  }
  return None;
}

/// Decode the predefined XML entities (&amp; &lt; &gt; &quot; &apos;) and
/// numeric character references (&#123; / &#x1F;) in `s`. Raw text outside
/// references passes through. Returns Err on a bare '&', an unknown or
/// malformed reference, or an invalid XML character.
/// Complexity: O(n), n = string length.
pub fn xml_decode_entities(s: Str) -> Result[Str, Str]
  ensures: (s.len() == 0) => (result.is_ok == true)
{
  let base = s.c_str();
  let n = s.len();
  var buf = Vec[UInt8].new();
  match _xml_decode_range(&mut buf, base, 0, n) {
    Ok(_) => { return Ok(_xml_buf_str(buf)); },
    Err(e) => { return Err(e); },
  }
}
