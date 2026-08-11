// XIOM - Conversion: Escape
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.escape

// ============================================================================
// Escaping and quoting families for markup, delimited text, and shells.
// Covers HTML/XML entities, CSV/TSV fields, regex and glob literals, and
// POSIX/Windows shell quoting. URL component encoding lives in encoding.xi.
// ============================================================================

// fn html_escape(s: Str) -> Str - Escape text for HTML body content (&<> plus entities). TODO(compiler): implement.
// fn html_unescape(s: Str) -> Str - Decode HTML entities back to characters. TODO(compiler): implement.
// fn html_escape_attr(s: Str) -> Str - Escape text for use inside HTML attribute quotes. TODO(compiler): implement.
// fn xml_escape(s: Str) -> Str - Escape the five predefined XML entities. TODO(compiler): implement.
// fn xml_unescape(s: Str) -> Str - Decode predefined XML entities back to characters. TODO(compiler): implement.
// fn csv_escape_field(s: Str) -> Str - Escape and quote a field for RFC 4180 CSV output. TODO(compiler): implement.
// fn csv_unescape_field(s: Str) -> Str - Parse and unquote a single CSV field. TODO(compiler): implement.
// fn tsv_escape_field(s: Str) -> Str - Escape tab and newline characters in a TSV field. TODO(compiler): implement.
// fn tsv_unescape_field(s: Str) -> Str - Restore tab and newline escapes in a TSV field. TODO(compiler): implement.
// fn regex_escape(s: Str) -> Str - Escape all regex metacharacters in a literal string. TODO(compiler): implement.
// fn glob_escape(s: Str) -> Str - Escape glob wildcard metacharacters in a literal string. TODO(compiler): implement.
// fn glob_unescape(s: Str) -> Str - Restore escaped glob metacharacters in a literal string. TODO(compiler): implement.
// fn shell_escape(s: Str) -> Str - Escape a string for safe use in a POSIX shell command. TODO(compiler): implement.
// fn shell_quote(s: Str) -> Str - Quote a string with single quotes for a POSIX shell. TODO(compiler): implement.
// fn cmd_escape(s: Str) -> Str - Escape a string for safe use in a Windows cmd command line. TODO(compiler): implement.
// fn cmd_quote(s: Str) -> Str - Quote a string for a Windows cmd command line. TODO(compiler): implement.
