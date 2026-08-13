// XIOM - Reflect: Type Info
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.reflect.typeinfo

// Depends on: xiom.reflect

// ============================================================================
// Compile-time type queries: name, id, size, alignment, kind and variant
// counts.
//
// NOTE (limited): the per-monomorphisation generic `[T]` intrinsics are not
// emitted by this build, so every generic query returns the documented
// placeholder: name/id "unknown"/0, size/align 0, primitives/structs/enums/
// generics all false, variants 0, and sized always true. This mirrors
// xiom.reflect's documented LIMITED behaviour.
// ============================================================================

/// The name of type T. LIMITED: the compiler does not expose generic type
/// names yet — returns "unknown".
/// Complexity: O(1).
pub fn type_name[T]() -> Str {
  "unknown"
}

/// A stable numeric id for type T. LIMITED: returns 0.
/// Complexity: O(1).
pub fn type_id[T]() -> Int {
  0
}

/// The size of type T in bytes. LIMITED: the layout intrinsics are not
/// emitted yet — returns 0.
/// Complexity: O(1).
pub fn type_size[T]() -> Int {
  0
}

/// The alignment of type T in bytes. LIMITED: returns 0.
/// Complexity: O(1).
pub fn type_align[T]() -> Int {
  0
}

/// Whether T is a primitive type. LIMITED: always false.
/// Complexity: O(1).
pub fn type_is_primitive[T]() -> Bool {
  false
}

/// Whether T is a struct type. LIMITED: always false.
/// Complexity: O(1).
pub fn type_is_struct[T]() -> Bool {
  false
}

/// Whether T is an enum type. LIMITED: always false.
/// Complexity: O(1).
pub fn type_is_enum[T]() -> Bool {
  false
}

/// Whether T is a generic type. LIMITED: always false.
/// Complexity: O(1).
pub fn type_is_generic[T]() -> Bool {
  false
}

/// The type name of a value. Delegates to `type_name[T]()`.
/// Complexity: O(1).
pub fn type_of[T](value: T) -> Str {
  type_name[T]()
}

/// The number of enum variants of T, or 0 when T is not an enum. LIMITED:
/// always 0.
/// Complexity: O(1).
pub fn type_variant_count[T]() -> Int {
  0
}

/// Whether T has a known size. All XIOM types are statically sized, so this
/// is always true.
/// Complexity: O(1).
pub fn type_is_sized[T]() -> Bool {
  true
}
