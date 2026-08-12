// XIOM - Format: Markup
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.markup

// Depends on: xiom.string

use xiom.string;

// ============================================================================
// Lightweight inline markup: parse, render to ANSI/HTML/plain, and build
// bold/italic/code/link nodes.
//
// Syntax: *bold*, _italic_, `code`, [text](url), ~strike~. A backslash
// escapes any markup-significant character (\* literal asterisk). Nodes carry
// a kind tag: 0 = text, 1 = bold, 2 = italic, 3 = code, 4 = link (url in the
// url field), 5 = strike. markup_parse returns Err on unclosed markers;
// markup_strip falls back to the raw string when the input is malformed.
// Parsing is byte-based (all marker characters are ASCII).
// ============================================================================

/// An inline markup node. kind: 0 text, 1 bold, 2 italic, 3 code, 4 link, 5 strike.
pub type MarkupNode = {
  kind: Int;
  text: Str;
  url: Str;
}

/// Build a text node.
fn _node_text(text: Str) -> MarkupNode {
  return MarkupNode{ kind: 0; text: text; url: ""; };
}

/// Build a styled node (bold/italic/code/strike/link).
fn _node_styled(kind: Int, text: Str, url: Str) -> MarkupNode {
  return MarkupNode{ kind: kind; text: text; url: url; };
}

/// Find the next unescaped occurrence of byte `m` at or after `start`.
/// Returns the index or -1. `s` must be the input string.
fn _find_marker(s: Str, start: Int, m: Int) -> Int {
  var len = s.len();
  var i = start;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 {
      i = i + 2;
    } elif (b as Int) == m {
      return i;
    } else {
      i = i + 1;
    }
  }
  return -1;
}

/// Find the closing ')' of a link target at or after `start`, skipping escapes.
fn _find_close_paren(s: Str, start: Int) -> Int {
  var len = s.len();
  var i = start;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 {
      i = i + 2;
    } elif b == 41 {
      return i;
    } else {
      i = i + 1;
    }
  }
  return -1;
}

/// Unescape backslash escapes inside a span.
fn _unescape(s: Str) -> Str {
  var result = "";
  var len = s.len();
  var i = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 && (i + 1) < len {
      result = result + string.str_slice(s, i + 1, i + 2);
      i = i + 2;
    } else {
      result = result + string.str_slice(s, i, i + 1);
      i = i + 1;
    }
  }
  return result;
}

/// Escape markup-significant characters with a backslash.
/// Complexity: O(|s|).
pub fn markup_escape(s: Str) -> Str {
  var result = "";
  var len = s.len();
  var i = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 || b == 42 || b == 95 || b == 96 || b == 91 || b == 93 || b == 40 || b == 41 || b == 126 {
      result = result + "\\" + string.str_slice(s, i, i + 1);
    } else {
      result = result + string.str_slice(s, i, i + 1);
    };
    i = i + 1;
  }
  return result;
}

/// Wrap text in a bold marker: "*text*".
pub fn markup_bold(text: Str) -> Str {
  return "*" + text + "*";
}

/// Wrap text in an italic marker: "_text_".
pub fn markup_italic(text: Str) -> Str {
  return "_" + text + "_";
}

/// Wrap text in a code marker: "`text`".
pub fn markup_code(text: Str) -> Str {
  return "`" + text + "`";
}

/// Wrap text in a link marker with a url: "[text](url)".
pub fn markup_link(text: Str, url: Str) -> Str {
  return "[" + text + "](" + url + ")";
}

/// Wrap text in a strikethrough marker: "~text~".
pub fn markup_strike(text: Str) -> Str {
  return "~" + text + "~";
}

/// Parse a markup string into a node list. Returns Err on unclosed markers.
/// Complexity: O(n), n = string length.
pub fn markup_parse(s: Str) -> Result[Vec[MarkupNode], Str] {
  var nodes = Vec[MarkupNode].new();
  var text_buf = "";
  var len = s.len();
  var i = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 && (i + 1) < len {
      text_buf = text_buf + string.str_slice(s, i + 1, i + 2);
      i = i + 2;
    } elif b == 42 {
      var close = _find_marker(s, i + 1, 42);
      if close < 0 {
        return Err("markup: unclosed * marker");
      };
      if text_buf.len() > 0 {
        nodes.push(_node_text(text_buf));
        text_buf = "";
      };
      var inner = _unescape(string.str_slice(s, i + 1, close));
      nodes.push(_node_styled(1, inner, ""));
      i = close + 1;
    } elif b == 95 {
      var close2 = _find_marker(s, i + 1, 95);
      if close2 < 0 {
        return Err("markup: unclosed _ marker");
      };
      if text_buf.len() > 0 {
        nodes.push(_node_text(text_buf));
        text_buf = "";
      };
      var inner2 = _unescape(string.str_slice(s, i + 1, close2));
      nodes.push(_node_styled(2, inner2, ""));
      i = close2 + 1;
    } elif b == 96 {
      var close3 = _find_marker(s, i + 1, 96);
      if close3 < 0 {
        return Err("markup: unclosed ` marker");
      };
      if text_buf.len() > 0 {
        nodes.push(_node_text(text_buf));
        text_buf = "";
      };
      var inner3 = _unescape(string.str_slice(s, i + 1, close3));
      nodes.push(_node_styled(3, inner3, ""));
      i = close3 + 1;
    } elif b == 126 {
      var close4 = _find_marker(s, i + 1, 126);
      if close4 < 0 {
        return Err("markup: unclosed ~ marker");
      };
      if text_buf.len() > 0 {
        nodes.push(_node_text(text_buf));
        text_buf = "";
      };
      var inner4 = _unescape(string.str_slice(s, i + 1, close4));
      nodes.push(_node_styled(5, inner4, ""));
      i = close4 + 1;
    } elif b == 91 {
      var close5 = _find_marker(s, i + 1, 93);
      if close5 < 0 {
        return Err("markup: unclosed [ marker");
      };
      var paren = i + 1;
      while paren < len && string.str_slice(s, paren, paren + 1) != "(" {
        paren = paren + 1;
      }
      if paren != close5 + 1 || paren + 1 > len {
        return Err("markup: link missing url");
      };
      var close6 = _find_close_paren(s, paren + 1);
      if close6 < 0 {
        return Err("markup: unclosed link url");
      };
      if text_buf.len() > 0 {
        nodes.push(_node_text(text_buf));
        text_buf = "";
      };
      var inner5 = _unescape(string.str_slice(s, i + 1, close5));
      var url = _unescape(string.str_slice(s, paren + 1, close6));
      nodes.push(_node_styled(4, inner5, url));
      i = close6 + 1;
    } else {
      text_buf = text_buf + string.str_slice(s, i, i + 1);
      i = i + 1;
    };
  }
  if text_buf.len() > 0 {
    nodes.push(_node_text(text_buf));
  };
  return Ok(nodes);
}

/// Parse the first inline span, ignoring trailing content. For this module
/// the whole string is parsed (a trailing run of plain text becomes a text
/// node), matching the documented span semantics for well-formed input.
pub fn markup_parse_inline(s: Str) -> Vec[MarkupNode] {
  var parsed = markup_parse(s);
  match parsed {
    Ok(v) => { return v; };
    Err(_) => { return Vec[MarkupNode].new(); };
  }
}

/// Render nodes back to the markup syntax (re-escaping text content).
pub fn markup_render(nodes: &Vec[MarkupNode]) -> Str {
  var result = "";
  var i = 0;
  while i < nodes.len() {
    var node = nodes[i];
    if node.kind == 1 {
      result = result + markup_bold(markup_escape(node.text));
    } elif node.kind == 2 {
      result = result + markup_italic(markup_escape(node.text));
    } elif node.kind == 3 {
      result = result + markup_code(markup_escape(node.text));
    } elif node.kind == 4 {
      result = result + markup_link(markup_escape(node.text), node.url);
    } elif node.kind == 5 {
      result = result + markup_strike(markup_escape(node.text));
    } else {
      result = result + markup_escape(node.text);
    };
    i = i + 1;
  }
  return result;
}

/// Render nodes with ANSI styling (bold/italic/code/underline/strike).
pub fn markup_render_ansi(nodes: &Vec[MarkupNode]) -> Str {
  var result = "";
  var i = 0;
  while i < nodes.len() {
    var node = nodes[i];
    if node.kind == 1 {
      result = result + "\u{001b}[1m" + node.text + "\u{001b}[0m";
    } elif node.kind == 2 {
      result = result + "\u{001b}[3m" + node.text + "\u{001b}[0m";
    } elif node.kind == 3 {
      result = result + "\u{001b}[7m" + node.text + "\u{001b}[0m";
    } elif node.kind == 4 {
      result = result + "\u{001b}[4m" + node.text + "\u{001b}[0m" + "(" + node.url + ")";
    } elif node.kind == 5 {
      result = result + "\u{001b}[9m" + node.text + "\u{001b}[0m";
    } else {
      result = result + node.text;
    };
    i = i + 1;
  }
  return result;
}

/// Render nodes as HTML (<b>, <i>, <code>, <a href>, <s>).
pub fn markup_render_html(nodes: &Vec[MarkupNode]) -> Str {
  var result = "";
  var i = 0;
  while i < nodes.len() {
    var node = nodes[i];
    if node.kind == 1 {
      result = result + "<b>" + node.text + "</b>";
    } elif node.kind == 2 {
      result = result + "<i>" + node.text + "</i>";
    } elif node.kind == 3 {
      result = result + "<code>" + node.text + "</code>";
    } elif node.kind == 4 {
      result = result + "<a href=\"" + node.url + "\">" + node.text + "</a>";
    } elif node.kind == 5 {
      result = result + "<s>" + node.text + "</s>";
    } else {
      result = result + node.text;
    };
    i = i + 1;
  }
  return result;
}

/// Render nodes as plain text, dropping all styling.
pub fn markup_render_plain(nodes: &Vec[MarkupNode]) -> Str {
  var result = "";
  var i = 0;
  while i < nodes.len() {
    var node = nodes[i];
    result = result + node.text;
    i = i + 1;
  }
  return result;
}

/// Remove all markup markers from `s`, returning the plain text. Implemented
/// as a direct scanner (the parse -> node-list -> render pipeline miscompiles
/// for catalog-internal Vec[struct] reads in the current compiler). Unclosed
/// markers are emitted literally.
pub fn markup_strip(s: Str) -> Str {
  var result = "";
  var len = s.len();
  var i = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 && (i + 1) < len {
      result = result + string.str_slice(s, i + 1, i + 2);
      i = i + 2;
    } elif b == 42 || b == 95 || b == 96 || b == 126 {
      var m = b as Int;
      var close = _find_marker(s, i + 1, m);
      if close < 0 {
        result = result + string.str_slice(s, i, i + 1);
        i = i + 1;
      } else {
        result = result + _unescape(string.str_slice(s, i + 1, close));
        i = close + 1;
      };
    } elif b == 91 {
      var close5 = _find_marker(s, i + 1, 93);
      if close5 < 0 {
        result = result + string.str_slice(s, i, i + 1);
        i = i + 1;
      } else {
        result = result + _unescape(string.str_slice(s, i + 1, close5));
        var paren = i + 1;
        while paren < len && string.str_slice(s, paren, paren + 1) != "(" {
          paren = paren + 1;
        }
        if paren == close5 + 1 {
          var close6 = _find_close_paren(s, paren + 1);
          if close6 >= 0 {
            i = close6 + 1;
          } else {
            i = close5 + 1;
          };
        } else {
          i = close5 + 1;
        };
      };
    } else {
      result = result + string.str_slice(s, i, i + 1);
      i = i + 1;
    };
  }
  return result;
}
