// XIOM - Network: HTTP Headers
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.header

// Depends on: xiom.net, xiom.string

// ============================================================================
// Helpers for working with HTTP header lists stored as (name, value) pairs.
// NOTE: current implementation lives in net.xi http_header_* - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// Tuple (Str, Str) holds a single header as (name, value).

// fn header_get(headers: &Vec[(Str, Str)], name: Str) -> Option[Str] - fetch the first value for name. TODO(compiler): implement.
// fn header_set(headers: &mut Vec[(Str, Str)], name: Str, value: Str) - set name, replacing any existing value. TODO(compiler): implement.
// fn header_remove(headers: &mut Vec[(Str, Str)], name: Str) -> Bool - remove all entries for name; true if any was removed. TODO(compiler): implement.
// fn header_contains(headers: &Vec[(Str, Str)], name: Str) -> Bool - test if name is present. TODO(compiler): implement.
// fn header_parse_line(line: Str) -> Option[(Str, Str)] - parse one "Name: value" line into a (name, value) pair. TODO(compiler): implement.
// fn header_serialize(headers: &Vec[(Str, Str)]) -> Str - serialize headers into "Name: value" lines. TODO(compiler): implement.
