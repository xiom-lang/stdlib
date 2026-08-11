// XIOM - Format: Text Layout
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.text

// Depends on: xiom.string

// ============================================================================
// Text alignment, wrapping, flowing, indentation, columns, ellipsis and
// decoration helpers. NOTE: current implementation lives in fmt.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn text_center(s: Str, width: Int) -> Str - center s in a field of width. TODO(compiler): implement.
// fn text_left(s, width) -> Str - left-align s in a field of width. TODO(compiler): implement.
// fn text_right(s, width) -> Str - right-align s in a field of width. TODO(compiler): implement.
// fn text_justify(s, width) -> Str - justify s to fill the width with spaces between words. TODO(compiler): implement.
// fn text_wrap(s, width) -> Vec[Str] - wrap s into lines no longer than width at word boundaries. TODO(compiler): implement.
// fn text_indent(s, n) -> Str - prefix every line of s with n spaces. TODO(compiler): implement.
// fn text_hanging_indent(s, n) -> Str - indent every line except the first by n spaces. TODO(compiler): implement.
// fn text_columns(items: &Vec[Str], cols: Int) -> Vec[Str] - lay items out in cols columns, row-major. TODO(compiler): implement.
// fn text_ellipsis(s, max_len) -> Str - truncate s to max_len with a trailing ellipsis. TODO(compiler): implement.
// fn text_overline(s) -> Str - apply an overline decoration. TODO(compiler): implement.
// fn text_underline(s) -> Str - apply an underline decoration. TODO(compiler): implement.
// fn text_strikethrough(s) -> Str - apply a strikethrough decoration. TODO(compiler): implement.
// fn text_quote(s) -> Str - wrap s in quotation marks. TODO(compiler): implement.
// fn text_blockquote(lines: &Vec[Str]) -> Str - join lines into a blockquote. TODO(compiler): implement.
// fn text_paragraph(s, width) -> Str - wrap s into a single justified paragraph. TODO(compiler): implement.
// fn text_flow(words: &Vec[Str], width) -> Vec[Str] - pack words greedily into lines of at most width. TODO(compiler): implement.
// fn text_reflow(s, width) -> Str - reflow s to width, joining short lines and breaking long ones. TODO(compiler): implement.
// fn text_measure(s) -> Int - the display width of s. TODO(compiler): implement.
