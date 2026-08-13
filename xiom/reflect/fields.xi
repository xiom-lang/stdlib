// XIOM - Reflect: Fields
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.reflect.fields

// Depends on: xiom.reflect

// ============================================================================
// Struct field and enum variant introspection: names, types, offsets and
// values.
//
// NOTE (limited): the compiler does not emit per-field metadata or field
// intrinsics in this build, so every query returns the documented
// placeholder: counts 0, field queries None/empty, variant queries
// "unknown"/0. This mirrors xiom.reflect's documented LIMITED behaviour.
// ============================================================================

/// The number of fields in struct T. LIMITED: always 0.
/// Complexity: O(1).
pub fn field_count[T]() -> Int {
  0
}

/// The name of field `i` of T. LIMITED: always None.
/// Complexity: O(1).
pub fn field_name[T](i: Int) -> Option[Str] {
  None
}

/// The type name of field `i` of T. LIMITED: always None.
/// Complexity: O(1).
pub fn field_type[T](i: Int) -> Option[Str] {
  None
}

/// The byte offset of field `i` of T. LIMITED: always None.
/// Complexity: O(1).
pub fn field_offset[T](i: Int) -> Option[Int] {
  None
}

/// Read field `i` of `obj` as an integer. LIMITED: always None.
/// Complexity: O(1).
pub fn field_value[T](obj: &T, i: Int) -> Option[Int] {
  None
}

/// All field names in declaration order. LIMITED: always empty.
/// Complexity: O(1).
pub fn field_names[T]() -> Vec[Str] {
  Vec[Str].new()
}

/// All field type names in declaration order. LIMITED: always empty.
/// Complexity: O(1).
pub fn field_types[T]() -> Vec[Str] {
  Vec[Str].new()
}

/// All field byte offsets in declaration order. LIMITED: always empty.
/// Complexity: O(1).
pub fn field_offsets[T]() -> Vec[Int] {
  Vec[Int].new()
}

/// The name of enum variant `v`. LIMITED: the compiler does not expose
/// variant metadata — returns "unknown".
/// Complexity: O(1).
pub fn variant_name[T](v: T) -> Str {
  "unknown"
}

/// The index of enum variant `v`. LIMITED: returns 0.
/// Complexity: O(1).
pub fn variant_index[T](v: T) -> Int {
  0
}
