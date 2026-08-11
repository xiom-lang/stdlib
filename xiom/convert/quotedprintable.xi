// XIOM - Conversion: Quoted-Printable
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.quotedprintable

// Depends on: xiom.string

// ============================================================================
// Quoted-Printable encoding and decoding per RFC 2045, used in email MIME.
// Provides line-aware encoding with soft line breaks and detection helpers.
// ============================================================================

// fn qp_encode(data: &Vec[UInt8]) -> Str - Encode bytes to Quoted-Printable with default 76-column lines. TODO(compiler): implement.
// fn qp_encode_maxline(data: &Vec[UInt8], max_line: Int) -> Str - Encode bytes using a custom maximum line width. TODO(compiler): implement.
// fn qp_decode(s: Str) -> Result[Vec[UInt8], Str] - Decode a Quoted-Printable string to bytes. TODO(compiler): implement.
// fn qp_soft_linebreak(s: Str, width: Int) -> Str - Insert soft line breaks (=CRLF) into encoded text. TODO(compiler): implement.
// fn qp_is_binary(s: Str) -> Bool - Report whether the string is too binary for safe Quoted-Printable use. TODO(compiler): implement.
// fn qp_escape_byte(b: UInt8) -> Str - Return the =HH escape for a single byte. TODO(compiler): implement.
