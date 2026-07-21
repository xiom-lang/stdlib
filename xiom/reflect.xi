// XIOM — Runtime Reflection
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.reflect

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

// Number of user types registered in this compilation unit. REAL.
pub fn type_count() -> Int {
  unsafe {
    return xiom_type_count();
  }
}

// Name of the type with the given stable id, or "unknown" if out of range. REAL.
pub fn type_name_by_id(id: Int) -> Str {
  unsafe {
    return xiom_type_name(id);
  }
}

// Stable id of the type with the given name, or -1 if not found. REAL.
pub fn type_id_by_name(name: Str) -> Int {
  unsafe {
    return xiom_type_id_by_name(name);
  }
}

// Number of fields of the type with the given id (0 for enums/unknown). REAL.
pub fn type_field_count(id: Int) -> Int {
  unsafe {
    return xiom_type_field_count(id);
  }
}

pub type TypeId = { id: Int; } derive[Eq, Clone, Hash]

var next_type_id: Int = 0;

pub fn TypeId.of[T]() -> TypeId {
  return TypeId{ id: 0; };
}

pub interface Any {
  fn type_id(self) -> TypeId;
}

pub fn type_name[T]() -> Str
  ensures: result.len() > 0 {
  return "unknown";
}

pub fn type_size[T]() -> Int {
  return size_of[T]();
}

pub fn type_align[T]() -> Int {
  return align_of[T]();
}

// Downcasting
pub fn downcast_ref[T: Any](value: &dyn Any) -> Option<&T> {
  return None;
}

pub fn downcast_mut[T: Any](value: &mut dyn Any) -> Option<&mut T> {
  return None;
}

pub type TypeInfo = {
  name: Str;
  size: Int;
  align: Int;
  kind: Int; // 0=primitive, 1=struct, 2=enum, 3=interface
  fields: Vec<FieldInfo>;
  variants: Vec<Str>;
  derives: Vec<Str>;
} derive[Clone]

pub type FieldInfo = {
  name: Str;
  type_name: Str;
  offset: Int;
} derive[Clone]

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

// Look up a type by name and return REAL data from the compiler RTTI table:
// the canonical `name` and the true field count (materialised as that many
// placeholder FieldInfo entries so `result.fields.len()` is exact).
// LIMITED: size/align are reported as 0, kind defaults to 1 (struct), and
// per-field names/types are "unknown" — that metadata is not embedded yet.
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

// Enumerate every registered user type with REAL names and field counts.
// LIMITED: size/align/kind and per-field metadata are placeholders (see above).
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
