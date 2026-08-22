// XIOM - Format: Textual
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.textual

// Depends on: xiom.string

use xiom.string;
use xiom.convert;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

// ============================================================================
// Text layout helpers: boxes, borders, separators, headers, footers, titles,
// sections, lists, definition lists, tables of contents, and text wrapping.
// Pure string builders with zero external dependencies.
//
// Box styles: 0 = plain ASCII (+/-/|), 1 = rounded corners, 2 = double lines.
// All widths are byte counts; multi-byte box characters repeat via str_repeat.
// ============================================================================

const BOX_PLAIN: Int = 0;
const BOX_ROUNDED: Int = 1;
const BOX_DOUBLE: Int = 2;

/// Repeat a character `width` times as a string (UTF-8 aware).
fn _char_repeat(ch: Char, width: Int) -> Str {
  var bytes = Vec[UInt8].new();
  xiom.char.encode_utf8(ch, &bytes);
  var blen = bytes.len();
  if blen == 0 {
    return "";
  };
  unsafe {
    var buf = malloc(blen + 1);
    var i = 0;
    while i < blen {
      buf[i] = bytes[i];
      i = i + 1;
    }
    buf[blen] = 0;
    var single = Str.from_cstring(buf);
    return string.str_repeat(single, width);
  }
}

/// Border characters for a box style.
type BoxChars = {
  tl: Str;
  tr: Str;
  h: Str;
  v: Str;
  bl: Str;
  br: Str;
}

/// Border characters for a box style. Returns (top-left, top-right,
/// horizontal, vertical, bottom-left, bottom-right).
fn _box_chars(style: Int) -> BoxChars {
  if style == BOX_ROUNDED {
    return BoxChars{ tl: "\u{256d}"; tr: "\u{256e}"; h: "\u{2500}"; v: "\u{2502}"; bl: "\u{2570}"; br: "\u{256f}"; };
  };
  if style == BOX_DOUBLE {
    return BoxChars{ tl: "\u{2554}"; tr: "\u{2557}"; h: "\u{2550}"; v: "\u{2551}"; bl: "\u{255a}"; br: "\u{255d}"; };
  };
  return BoxChars{ tl: "+"; tr: "+"; h: "-"; v: "|"; bl: "+"; br: "+"; };
}

/// Wrap `lines` in a box of the given width using `style` border characters.
fn _box(lines: &Vec[Str], width: Int, style: Int) -> Str {
  var chars = _box_chars(style);
  var tl = chars.tl;
  var tr = chars.tr;
  var h = chars.h;
  var v = chars.v;
  var bl = chars.bl;
  var br = chars.br;
  var w = width;
  if w < 2 {
    w = 2;
  };
  var inner = w - 2;
  var result = tl + string.str_repeat(h, inner) + tr;
  var i = 0;
  while i < lines.len() {
    var content = lines[i];
    if content.len() > inner {
      content = string.str_slice(content, 0, inner);
    };
    result = result + "\n" + v + string.str_pad_right(content, inner, ' ') + v;
    i = i + 1;
  }
  result = result + "\n" + bl + string.str_repeat(h, inner) + br;
  return result;
}

/// Wrap lines in a plain ASCII box of the given width.
pub fn box_around(lines: &Vec[Str], width: Int) -> Str {
  return _box(lines, width, BOX_PLAIN);
}

/// Wrap lines in a rounded-corner box of the given width.
pub fn box_rounded(lines: &Vec[Str], width: Int) -> Str {
  return _box(lines, width, BOX_ROUNDED);
}

/// Wrap lines in a double-line box of the given width.
pub fn box_double(lines: &Vec[Str], width: Int) -> Str {
  return _box(lines, width, BOX_DOUBLE);
}

/// Render a top border line; `style` selects the character set (0 plain,
/// 1 rounded, 2 double).
pub fn border_top(width: Int, style: Int) -> Str {
  var chars = _box_chars(style);
  var tl = chars.tl;
  var tr = chars.tr;
  var h = chars.h;
  var w = width;
  if w < 2 {
    w = 2;
  };
  return tl + string.str_repeat(h, w - 2) + tr;
}

/// Render a bottom border line; `style` selects the character set.
pub fn border_bottom(width: Int, style: Int) -> Str {
  var chars = _box_chars(style);
  var bl = chars.bl;
  var br = chars.br;
  var h = chars.h;
  var w = width;
  if w < 2 {
    w = 2;
  };
  return bl + string.str_repeat(h, w - 2) + br;
}

/// Repeat `ch` `width` times as a horizontal separator.
pub fn separator_line(ch: Char, width: Int) -> Str {
  return _char_repeat(ch, width);
}

/// Render a double-line horizontal separator.
pub fn separator_double(width: Int) -> Str {
  return string.str_repeat("\u{2550}", width);
}

/// Render a dashed horizontal separator.
pub fn separator_dashed(width: Int) -> Str {
  return string.str_repeat("-", width);
}

/// Render a multi-line block header with the title centered inside a box.
pub fn header_block(title: Str, width: Int) -> Str {
  var lines = Vec[Str].new();
  lines.push(title);
  return _box(&lines, width, BOX_PLAIN);
}

/// Render a one-line bar header: a horizontal rule above the centered title.
pub fn header_bar(title: Str, width: Int) -> Str {
  return string.str_repeat("-", width) + "\n" + string.str_center(title, width);
}

/// Render a multi-line footer block with the text centered inside a box.
pub fn footer_block(text: Str, width: Int) -> Str {
  var lines = Vec[Str].new();
  lines.push(text);
  return _box(&lines, width, BOX_PLAIN);
}

/// Center the title within `width` columns.
pub fn title_center(title: Str, width: Int) -> Str {
  return string.str_center(title, width);
}

/// Render the title with an overline and underline.
pub fn title_overline(title: Str, width: Int) -> Str {
  return string.str_repeat("-", width) + "\n" + string.str_center(title, width) + "\n" + string.str_repeat("-", width);
}

/// Render the title with an underline.
pub fn title_underline(title: Str, width: Int) -> Str {
  return string.str_center(title, width) + "\n" + string.str_repeat("-", width);
}

/// Render a section header with rule lines above and below.
pub fn section_header(title: Str, width: Int) -> Str {
  return string.str_repeat("-", width) + "\n" + string.str_center(title, width) + "\n" + string.str_repeat("-", width);
}

/// Render a numbered section heading such as "3. title".
pub fn section_number(n: Int, title: Str) -> Str {
  return convert.int_to_string(n) + ". " + title;
}

/// Render each item prefixed by the bullet marker.
pub fn bullet_list(items: &Vec[Str], bullet: Str) -> Str {
  var result = "";
  var i = 0;
  while i < items.len() {
    if i > 0 {
      result = result + "\n";
    };
    result = result + bullet + " " + items[i];
    i = i + 1;
  }
  return result;
}

/// Render each item prefixed by its 1-based number.
pub fn numbered_list(items: &Vec[Str]) -> Str {
  var result = "";
  var i = 0;
  while i < items.len() {
    if i > 0 {
      result = result + "\n";
    };
    result = result + convert.int_to_string(i + 1) + ". " + items[i];
    i = i + 1;
  }
  return result;
}

/// Render term/definition pairs, one per line.
pub fn definition_list(terms: &Vec[Str], definitions: &Vec[Str]) -> Str {
  var result = "";
  var n = terms.len();
  if definitions.len() < n {
    n = definitions.len();
  };
  var i = 0;
  while i < n {
    if i > 0 {
      result = result + "\n";
    };
    result = result + terms[i] + ": " + definitions[i];
    i = i + 1;
  }
  return result;
}

/// Fetch one heading element through a helper boundary (direct Vec[Str]
/// element reads in the caller body miscompile for mixed-ref signatures).
fn _toc_heading(headings: &Vec[Str], i: Int) -> Str {
  return headings[i];
}

/// Render a table of contents with dot leaders and page numbers.
/// Each line: heading, dots to fill to `width`, then the page number.
pub fn toc(headings: &Vec[Str], pages: &Vec[Int]) -> Str {
  var result = "";
  var n = headings.len();
  if pages.len() < n {
    n = pages.len();
  };
  var width = 60;
  var i = 0;
  while i < n {
    var heading = _toc_heading(headings, i);
    var hl = heading.len();
    if i > 0 {
      result = result + "\n";
    };
    result = result + heading;
    var page = convert.int_to_string(pages[i]);
    var pl = page.len();
    var fill = width - hl - pl - 1;
    if fill < 1 {
      fill = 1;
    };
    var dots = "";
    var k = 0;
    while k < fill {
      dots = dots + ".";
      k = k + 1;
    }
    result = result + " " + dots + " " + page;
    i = i + 1;
  }
  return result;
}

/// Return the indentation prefix for a TOC entry at the given level
/// (two spaces per level).
pub fn toc_indent(level: Int) -> Str {
  var l = level;
  if l < 0 {
    l = 0;
  };
  return string.str_repeat("  ", l);
}

/// Wrap `s` to `width` columns and center each line.
pub fn text_wrap_center(s: Str, width: Int) -> Str {
  var lines = _wrap_words(s, width);
  var result = "";
  var i = 0;
  while i < lines.len() {
    if i > 0 {
      result = result + "\n";
    };
    result = result + string.str_center(lines[i], width);
    i = i + 1;
  }
  return result;
}

/// Wrap `s` to `width` columns with justified alignment.
pub fn text_justify(s: Str, width: Int) -> Str {
  var lines = _wrap_words(s, width);
  var result = "";
  var i = 0;
  while i < lines.len() {
    if i > 0 {
      result = result + "\n";
    };
    result = result + _justify_line(lines[i], width);
    i = i + 1;
  }
  return result;
}

/// Greedy word-wrap of `s` into lines of at most `width` bytes.
fn _wrap_words(s: Str, width: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  var line = "";
  var pos = 0;
  var span = _next_word(s, pos);
  while span.ok {
    var word = string.str_slice(s, span.start, span.end);
    if line.len() == 0 {
      line = word;
    } elif line.len() + 1 + word.len() <= width {
      line = line + " " + word;
    } else {
      result.push(line);
      line = word;
    };
    pos = span.end;
    span = _next_word(s, pos);
  }
  if line.len() > 0 || result.len() == 0 {
    result.push(line);
  };
  return result;
}

/// Justify a single line to `width` by distributing spaces between words.
fn _justify_line(s: Str, width: Int) -> Str {
  var span = _next_word(s, 0);
  var count = 0;
  var total = 0;
  while span.ok {
    count = count + 1;
    total = total + (span.end - span.start);
    span = _next_word(s, span.end);
  }
  if count <= 1 {
    return s;
  };
  var gaps = count - 1;
  if total + gaps >= width {
    return s;
  };
  var extra = width - total;
  var result = "";
  var pos = 0;
  var wi = 0;
  span = _next_word(s, pos);
  while span.ok {
    if wi > 0 {
      var spaces = extra / gaps;
      if wi - 1 < extra % gaps {
        spaces = spaces + 1;
      };
      var sp = "";
      var k = 0;
      while k < spaces {
        sp = sp + " ";
        k = k + 1;
      }
      result = result + sp;
    };
    result = result + string.str_slice(s, span.start, span.end);
    pos = span.end;
    wi = wi + 1;
    span = _next_word(s, pos);
  }
  return result;
}

/// Locate the next whitespace-delimited word at or after `from`.
fn _next_word(s: Str, from: Int) -> WordSpan {
  var len = s.len();
  var start = from;
  while start < len {
    var b = string.byte_at(s, start);
    if b == 32 || b == 9 || b == 10 || b == 13 {
      start = start + 1;
    } else {
      break;
    }
  }
  if start >= len {
    return WordSpan{ start: from; end: from; ok: false; };
  };
  var end = start;
  while end < len {
    var b2 = string.byte_at(s, end);
    if b2 == 32 || b2 == 9 || b2 == 10 || b2 == 13 {
      break;
    };
    end = end + 1;
  }
  return WordSpan{ start: start; end: end; ok: true; };
}

/// A word found by scanning: byte offsets into the source string.
type WordSpan = {
  start: Int;
  end: Int;
  ok: Bool;
}

/// Lay out items in the given number of equal columns (row-major), each line
/// joined with two spaces between padded columns.
pub fn text_columns(items: &Vec[Str], cols: Int) -> Str {
  var result = "";
  var n = items.len();
  if n == 0 {
    return result;
  };
  var c = cols;
  if c < 1 {
    c = 1;
  };
  var col_width = 0;
  var i = 0;
  while i < n {
    let item = items[i];
    var il = item.len();
    if il > col_width {
      col_width = il;
    };
    i = i + 1;
  }
  var rows = (n + c - 1) / c;
  var r = 0;
  while r < rows {
    var line = "";
    var c2 = 0;
    while c2 < c {
      var idx = r * c + c2;
      if idx < n {
        if c2 > 0 {
          line = line + "  ";
        };
        line = line + string.str_pad_right(items[idx], col_width, ' ');
      };
      c2 = c2 + 1;
    }
    if r > 0 {
      result = result + "\n";
    };
    result = result + line;
    r = r + 1;
  }
  return result;
}
