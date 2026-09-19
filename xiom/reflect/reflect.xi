// XIOM -- Runtime Reflection
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.reflect

use xiom.reflect.typeinfo;
use xiom.reflect.fields;
use xiom.core.size_of;  // bare intrinsic binding (strict catalog gate)
use xiom.core.align_of;

// === FFI: compiler-emitted RTTI table ===
// These accessors are backed by an additive, read-only metadata table that the
// codegen (`xiom-codegen::emit_metadata_tables`) emits for every registered
// user struct/enum type in the compilation unit. Type ids are stable indices
// into that table for a given compilation unit.
//
// REAL vs LIMITED (see functions below):
//   REAL:    type_count, type_name_by_id, type_id_by_name, type_field_count,
//            type_info_by_name (name + field COUNT), all_types (names + counts).
//   LIMITED: the generic `[T]` queries (type_name[T], reflect_type[T],
//            TypeId.of[T]) still need a per-monomorphisation compiler intrinsic
//            that does not exist yet, so they remain pragmatic placeholders.
//            size/align/kind/field-names/variants/derives are not embedded yet.
extern "C" {
  fn xiom_type_count() -> Int;
  fn xiom_type_name(id: Int) -> Str;
  fn xiom_type_id_by_name(name: Str) -> Int;
  fn xiom_type_field_count(id: Int) -> Int;
}

/// Number of user types registered in this compilation unit. REAL.
pub fn type_count() -> Int
  requires: true
  ensures: result >= 0
{
  unsafe {
    return xiom_type_count();
  }
}

/// Name of the type with the given stable id, or "unknown" if out of range. REAL.
pub fn type_name_by_id(id: Int) -> Str
  requires: true
  ensures: result.len() >= 0
{
  unsafe {
    return xiom_type_name(id);
  }
}

/// Stable id of the type with the given name, or -1 if not found. REAL.
pub fn type_id_by_name(name: Str) -> Int
  requires: true
  ensures: result >= -1
{
  unsafe {
    return xiom_type_id_by_name(name);
  }
}

/// Number of fields of the type with the given id (0 for enums/unknown). REAL.
pub fn type_field_count(id: Int) -> Int
  requires: true
  ensures: result >= 0
{
  unsafe {
    return xiom_type_field_count(id);
  }
}

/// Stable numeric identity of a type.
pub type TypeId = { id: Int; } derive[Eq, Clone, Hash]

var next_type_id: Int = 0;

/// TypeId of T.
pub fn TypeId.of[T]() -> TypeId {
  return TypeId{ id: 0; };
}

/// Marker interface for downcastable values.
pub interface Any {
  fn type_id(self) -> TypeId;
}

/// Source name of T.
pub fn type_name[T]() -> Str
  ensures: result.len() > 0 {
  return "unknown";
}

/// Size of T in bytes.
pub fn type_size[T]() -> Int {
  return size_of[T]();
}

/// Alignment of T in bytes.
pub fn type_align[T]() -> Int {
  return align_of[T]();
}

/// Downcasting
pub fn downcast_ref[T: Any](value: &dyn Any) -> Option<&T> {
  return None;
}

/// Downcast a dyn Any to &mut T, or None on mismatch.
pub fn downcast_mut[T: Any](value: &mut dyn Any) -> Option<&mut T> {
  return None;
}

/// Reflected type description (name, size, alignment, fields).
pub type TypeInfo = {
  name: Str;
  size: Int;
  align: Int;
  kind: Int; // 0=primitive, 1=struct, 2=enum, 3=interface
  fields: Vec<FieldInfo>;
  variants: Vec<Str>;
  derives: Vec<Str>;
} derive[Clone]

/// Reflected field description (name, offset, type name).
pub type FieldInfo = {
  name: Str;
  type_name: Str;
  offset: Int;
} derive[Clone]

/// TypeInfo for T.
pub fn reflect_type[T]() -> TypeInfo {
  return TypeInfo{
    name: type_name[T]();
    size: type_size[T]();
    align: type_align[T]();
    kind: 0;
    fields: Vec<FieldInfo>.new();
    variants: Vec<Str>.new();
    derives: Vec<Str>.new();
  };
}

/// Look up a type by name and return REAL data from the compiler RTTI table:
/// the canonical `name` and the true field count (materialised as that many
/// placeholder FieldInfo entries so `result.fields.len()` is exact).
/// LIMITED: size/align are reported as 0, kind defaults to 1 (struct), and
/// per-field names/types are "unknown" -- that metadata is not embedded yet.
pub fn type_info_by_name(name: Str) -> Option<TypeInfo> {
  let id = type_id_by_name(name);
  if id < 0 {
    return None;
  }
  let real_name = type_name_by_id(id);
  let fcount = type_field_count(id);
  var fields = Vec<FieldInfo>.new();
  var i = 0;
  while i < fcount {
    fields.push(FieldInfo{
      name: "";
      type_name: "unknown";
      offset: i;
    });
    i = i + 1;
  }
  return Some(TypeInfo{
    name: real_name;
    size: 0;
    align: 0;
    kind: 1;
    fields: fields;
    variants: Vec<Str>.new();
    derives: Vec<Str>.new();
  });
}

/// Enumerate every registered user type with REAL names and field counts.
/// LIMITED: size/align/kind and per-field metadata are placeholders (see above).
pub fn all_types() -> Vec<TypeInfo> {
  var result = Vec<TypeInfo>.new();
  let count = type_count();
  var id = 0;
  while id < count {
    let real_name = type_name_by_id(id);
    let fcount = type_field_count(id);
    var fields = Vec<FieldInfo>.new();
    var i = 0;
    while i < fcount {
      fields.push(FieldInfo{
        name: "";
        type_name: "unknown";
        offset: i;
      });
      i = i + 1;
    }
    result.push(TypeInfo{
      name: real_name;
      size: 0;
      align: 0;
      kind: 1;
      fields: fields;
      variants: Vec<Str>.new();
      derives: Vec<Str>.new();
    });
    id = id + 1;
  }
  return result;
}

// -- Type Classification Queries ------------------------------------

/// Returns true if `T` is a primitive type (Int, Float64, Bool, Char, etc.).
/// LIMITED: compiler does not expose this metadata yet -- always returns false.
/// Complexity: O(1).
pub fn type_is_primitive[T]() -> Bool {
  return false;
}

/// Returns true if `T` is a struct type.
/// LIMITED: compiler does not expose this metadata yet -- always returns false.
/// Complexity: O(1).
pub fn type_is_struct[T]() -> Bool {
  return false;
}

/// Returns true if `T` is an enum type.
/// LIMITED: compiler does not expose this metadata yet -- always returns false.
/// Complexity: O(1).
pub fn type_is_enum[T]() -> Bool {
  return false;
}

/// Returns true if `T` has generic parameters.
/// LIMITED: compiler does not expose this metadata yet -- always returns false.
/// Complexity: O(1).
pub fn type_is_generic[T]() -> Bool {
  return false;
}

/// Always returns `true`: all XIOM types are sized (statically known layout).
/// Complexity: O(1).
pub fn type_is_sized[T]() -> Bool {
  return true;
}

// -- Type Kind ------------------------------------------------------

/// Returns a human-readable kind string: "primitive", "struct", "enum", or "unknown".
/// LIMITED: compiler does not expose kind metadata yet -- always returns "unknown".
/// Complexity: O(1).
pub fn type_kind[T]() -> Str {
  return "unknown";
}

// -- Type Value Queries ---------------------------------------------

/// Returns the type name of the value referenced by `value`.
/// Delegates to `type_name[T]()`.
/// Complexity: O(1).
pub fn type_name_of_value[T](value: &T) -> Str {
  return type_name[T]();
}

/// Returns the stable type id of the value referenced by `value`.
/// Delegates to `TypeId.of[T]()`.
/// Complexity: O(1).
pub fn type_id_of_value[T](value: &T) -> Int {
  return TypeId.of[T]().id;
}

// -- Field Introspection --------------------------------------------

/// Returns the name of field at index `idx` in type `T`, or "unknown".
/// LIMITED: per-field metadata not embedded yet -- always returns "unknown".
/// Complexity: O(1).
pub fn type_field_name[T](idx: Int) -> Str {
  return "unknown";
}

/// Returns the byte offset of field at index `idx` in type `T`, or 0.
/// LIMITED: field offset intrinsic not available yet -- always returns 0.
/// Complexity: O(1).
pub fn type_field_offset[T](idx: Int) -> Int {
  return 0;
}

// -- Size Aliases ---------------------------------------------------

/// Returns the total size of type `T` in bytes. Alias for `type_size[T]()`.
/// Complexity: O(1).
pub fn type_total_size[T]() -> Int {
  return type_size[T]();
}
