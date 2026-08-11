// XIOM - Serialize: JSON
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.serialize.json

// Depends on: xiom.serialize

// ============================================================================
// JSON parsing, stringification, and tree navigation.
// NOTE: current implementation lives in serialize.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type JsonValue - an enum of JSON null, bool, number, string, array, or object.
// fn json_parse(s: Str) -> Result[JsonValue, Str] - parse s into a JsonValue tree. TODO(compiler): implement.
// fn json_stringify(v: JsonValue) -> Str - serialize v as compact JSON. TODO(compiler): implement.
// fn json_pretty(v: JsonValue) -> Str - serialize v as indented JSON. TODO(compiler): implement.
// fn json_get(v, key: Str) -> Option[JsonValue] - the value under key, if v is an object. TODO(compiler): implement.
// fn json_get_path(v, path: &Vec[Str]) -> Option[JsonValue] - the value at a key path. TODO(compiler): implement.
// fn json_set(v, key, value) -> JsonValue - a copy of v with key set to value. TODO(compiler): implement.
// fn json_array_push(v, item) -> JsonValue - a copy of the array v with item appended. TODO(compiler): implement.
// fn json_object_new() -> JsonValue - a new empty JSON object. TODO(compiler): implement.
// fn json_array_new() -> JsonValue - a new empty JSON array. TODO(compiler): implement.
// fn json_number(f: Float64) -> JsonValue - wrap a float as a JSON number. TODO(compiler): implement.
// fn json_string(s: Str) -> JsonValue - wrap a string as a JSON string. TODO(compiler): implement.
// fn json_bool(b: Bool) -> JsonValue - wrap a bool as a JSON bool. TODO(compiler): implement.
// fn json_null() -> JsonValue - the JSON null value. TODO(compiler): implement.
// fn json_type(v) -> Str - the type name of v: object, array, string, number, bool, or null. TODO(compiler): implement.
// fn json_escape(s: Str) -> Str - escape s for embedding inside a JSON string. TODO(compiler): implement.
