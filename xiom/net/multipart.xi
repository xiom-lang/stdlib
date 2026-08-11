// XIOM - Network: Multipart Form Data
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.multipart

// Depends on: xiom.string

// ============================================================================
// multipart/form-data construction and parsing per RFC 7578.
// Builds and splits multi-part bodies using a caller-provided boundary.
// ============================================================================

// struct Part { name: Str; filename: Str; content_type: Str; data: Vec[UInt8] }

// fn multipart_parse(body: &Vec[UInt8], boundary: Str) -> Result[Vec[Part], Str] - split a multipart body into parts. TODO(compiler): implement.
// fn multipart_part(name: Str, value: Str) -> Part - build a plain text field part. TODO(compiler): implement.
// fn multipart_part_file(name: Str, filename: Str, content_type: Str, data: &Vec[UInt8]) -> Part - build a file field part. TODO(compiler): implement.
// fn multipart_build(parts: &Vec[Part], boundary: Str) -> Vec[UInt8] - serialize parts into a multipart body. TODO(compiler): implement.
// fn multipart_boundary_new() -> Str - generate a random boundary string. TODO(compiler): implement.
// fn multipart_content_type(boundary: Str) -> Str - build the Content-Type header value for a boundary. TODO(compiler): implement.
