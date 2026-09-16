// XIOM - Format: Text Layout
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.format.text

// Depends on: xiom.string

use xiom.string;

// ============================================================================
// Text alignment, wrapping, flowing, indentation, columns, ellipsis and
// decoration helpers. Widths are byte lengths (ASCII-aware); text_measure
// estimates display width, counting 3-byte (CJK) characters as 2 columns.
//
// Word/line processing scans the source string directly (no Vec[Str] element
// dereferences): the current compiler returns garbage pointers for Vec[Str]
// element values, so every intermediate is a plain Str or an Int span.
// ============================================================================

/// A word found by scanning: byte offsets into the source string.
type WordSpan = {
  start: Int;
  end: Int;
  ok: Bool;
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

/// A string of `n` spaces.
fn _spaces(n: Int) -> Str {
  var result = "";
  var i = 0;
  while i < n {
    result = result + " ";
    i = i + 1;
  }
  return result;
}

/// Center `s` in a field of `width` bytes.
pub fn text_center(s: Str, width: Int) -> Str {
  return string.str_center(s, width);
}

/// Left-align `s` in a field of `width` bytes.
pub fn text_left(s: Str, width: Int) -> Str {
  return string.str_pad_right(s, width, ' ');
}

/// Right-align `s` in a field of `width` bytes.
pub fn text_right(s: Str, width: Int) -> Str {
  return string.str_pad_left(s, width, ' ');
}

/// Justify `s` to fill `width` by distributing extra spaces between words.
/// Single-word or already-too-long text is returned unchanged.
/// Complexity: O(|s|).
pub fn text_justify(s: Str, width: Int) -> Str {
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
      result = result + _spaces(spaces);
    };
    result = result + string.str_slice(s, span.start, span.end);
    pos = span.end;
    wi = wi + 1;
    span = _next_word(s, pos);
  }
  return result;
}

/// Wrap `s` into lines no longer than `width` at word boundaries.
/// Complexity: O(|s|).
pub fn text_wrap(s: Str, width: Int) -> Vec[Str] {
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

/// Pack words greedily into lines of at most `width` bytes. The input Vec is
/// read directly; callers should prefer text_wrap (string-based) where the
/// input is already a string.
pub fn text_flow(words: &Vec[Str], width: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  var w = 0;
  var line = "";
  while w < words.len() {
    var word = words[w];
    if line.len() == 0 {
      line = word;
    } elif line.len() + 1 + word.len() <= width {
      line = line + " " + word;
    } else {
      result.push(line);
      line = word;
    };
    w = w + 1;
  }
  if line.len() > 0 || result.len() == 0 {
    result.push(line);
  };
  return result;
}

/// Prefix every line of `s` with `n` spaces.
pub fn text_indent(s: Str, n: Int) -> Str {
  if n <= 0 {
    return s;
  };
  var prefix = _spaces(n);
  var result = "";
  var len = s.len();
  var start = 0;
  var i = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 10 {
      result = result + prefix + string.str_slice(s, start, i) + "\n";
      start = i + 1;
    };
    i = i + 1;
  }
  result = result + prefix + string.str_slice(s, start, len);
  return result;
}

/// Indent every line except the first by `n` spaces.
pub fn text_hanging_indent(s: Str, n: Int) -> Str {
  if n <= 0 {
    return s;
  };
  var prefix = _spaces(n);
  var result = "";
  var len = s.len();
  var start = 0;
  var i = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 10 {
      result = result + string.str_slice(s, start, i) + "\n" + prefix;
      start = i + 1;
    };
    i = i + 1;
  }
  result = result + string.str_slice(s, start, len);
  return result;
}

/// Lay `items` out in `cols` columns, row-major, padded to the widest item.
pub fn text_columns(items: &Vec[Str], cols: Int) -> Vec[Str] {
  var result = Vec[Str].new();
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
    var il = items[i].len();
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
          line = line + " ";
        };
        line = line + string.str_pad_right(items[idx], col_width, ' ');
      };
      c2 = c2 + 1;
    }
    result.push(line);
    r = r + 1;
  }
  return result;
}

/// Truncate `s` to `max_len` bytes with a trailing "..." (at least 3 bytes).
pub fn text_ellipsis(s: Str, max_len: Int) -> Str {
  if max_len < 3 {
    return string.str_slice(s, 0, max_len);
  };
  if s.len() <= max_len {
    return s;
  };
  return string.str_slice(s, 0, max_len - 3) + "...";
}

/// Apply an overline decoration: a dash line above the text.
pub fn text_overline(s: Str) -> Str {
  return string.str_repeat("-", s.len()) + "\n" + s;
}

/// Apply an underline decoration: a dash line below the text.
pub fn text_underline(s: Str) -> Str {
  return s + "\n" + string.str_repeat("-", s.len());
}

/// Apply a strikethrough decoration: each character followed by the combining
/// long stroke overlay (U+0336).
pub fn text_strikethrough(s: Str) -> Str {
  var result = "";
  var len = s.len();
  var i = 0;
  while i < len {
    result = result + string.str_slice(s, i, i + 1) + "\u{0336}";
    i = i + 1;
  }
  return result;
}

/// Wrap `s` in quotation marks.
pub fn text_quote(s: Str) -> Str {
  return "\"" + s + "\"";
}

/// Join lines into a blockquote, prefixing each with "> ".
pub fn text_blockquote(lines: &Vec[Str]) -> Str {
  var result = "";
  var i = 0;
  while i < lines.len() {
    if i > 0 {
      result = result + "\n";
    };
    result = result + "> " + lines[i];
    i = i + 1;
  }
  return result;
}

/// Wrap `s` into a single justified paragraph of `width` columns.
pub fn text_paragraph(s: Str, width: Int) -> Str {
  var result = "";
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
      if result.len() > 0 {
        result = result + "\n";
      };
      result = result + text_justify(line, width);
      line = word;
    };
    pos = span.end;
    span = _next_word(s, pos);
  }
  if line.len() > 0 || result.len() == 0 {
    if result.len() > 0 {
      result = result + "\n";
    };
    result = result + text_justify(line, width);
  };
  return result;
}

/// Reflow `s` to `width`: words are repacked into lines of at most `width`.
pub fn text_reflow(s: Str, width: Int) -> Str {
  var result = "";
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
      if result.len() > 0 {
        result = result + "\n";
      };
      result = result + line;
      line = word;
    };
    pos = span.end;
    span = _next_word(s, pos);
  }
  if line.len() > 0 || result.len() == 0 {
    if result.len() > 0 {
      result = result + "\n";
    };
    result = result + line;
  };
  return result;
}

/// The display width of `s`: ASCII bytes count 1, 3-byte (CJK) characters
/// count 2. Complexity: O(|s|).
pub fn text_measure(s: Str) -> Int {
  var total = 0;
  var len = s.len();
  var i = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if (b & 0xE0) == 0xC0 {
      total = total + 1;
      i = i + 2;
    } elif (b & 0xF0) == 0xE0 {
      total = total + 2;
      i = i + 3;
    } elif (b & 0xF8) == 0xF0 {
      total = total + 2;
      i = i + 4;
    } else {
      total = total + 1;
      i = i + 1;
    };
  }
  return total;
}
