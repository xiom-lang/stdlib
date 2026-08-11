// XIOM - Format: Markup
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.markup

// Depends on: xiom.string

// ============================================================================
// Lightweight inline markup: parse, render to ANSI/HTML/plain, and build
// bold/italic/code/link nodes. NOTE: current implementation lives in fmt.xi -
// move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// type MarkupNode - an inline markup node: text, bold, italic, code or link (with url).
// fn markup_parse(s: Str) -> Result[Vec[MarkupNode], Str] - parse a markup string into a node list. TODO(compiler): implement.
// fn markup_render(nodes: &Vec[MarkupNode]) -> Str - render nodes back to the markup syntax. TODO(compiler): implement.
// fn markup_render_ansi(nodes) -> Str - render nodes with ANSI styling. TODO(compiler): implement.
// fn markup_render_html(nodes) -> Str - render nodes as HTML. TODO(compiler): implement.
// fn markup_render_plain(nodes) -> Str - render nodes as plain text, dropping styling. TODO(compiler): implement.
// fn markup_bold(text: Str) -> Str - wrap text in a bold marker. TODO(compiler): implement.
// fn markup_italic(text) -> Str - wrap text in an italic marker. TODO(compiler): implement.
// fn markup_code(text) -> Str - wrap text in a code marker. TODO(compiler): implement.
// fn markup_link(text, url) -> Str - wrap text in a link marker with a url. TODO(compiler): implement.
// fn markup_strike(text) -> Str - wrap text in a strikethrough marker. TODO(compiler): implement.
// fn markup_parse_inline(s) -> Vec[MarkupNode] - parse the first inline span, ignoring trailing content. TODO(compiler): implement.
// fn markup_strip(s) -> Str - remove all markup markers from s. TODO(compiler): implement.
// fn markup_escape(s) -> Str - escape markup-significant characters. TODO(compiler): implement.
