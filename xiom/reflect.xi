// XIOM — Runtime Reflection
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.reflect

pub type TypeId = { id: Int; } derive[Eq, Clone, Hash]

var next_type_id: Int = 0;

pub fn TypeId.of[T]() -> TypeId {
  return TypeId{ id: 0; };
}

pub interface Any {
  fn type_id(self) -> TypeId;
}

pub fn type_name[T]() -> Str {
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

pub fn type_info_by_name(name: Str) -> Option<TypeInfo> {
  return None;
}

pub fn all_types() -> Vec<TypeInfo> {
  return Vec<TypeInfo>.new();
}
