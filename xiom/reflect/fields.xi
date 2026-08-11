// XIOM - Reflect: Fields
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.reflect.fields

// Depends on: xiom.reflect

// ============================================================================
// Struct field and enum variant introspection: names, types, offsets and
// values. NOTE: current implementation lives in reflect.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn field_count[T]() -> Int - the number of fields in struct T. TODO(compiler): implement.
// fn field_name[T](i: Int) -> Option[Str] - the name of field i. TODO(compiler): implement.
// fn field_type[T](i: Int) -> Option[Str] - the type name of field i. TODO(compiler): implement.
// fn field_offset[T](i: Int) -> Option[Int] - the byte offset of field i. TODO(compiler): implement.
// fn field_value[T](obj: &T, i: Int) -> Option[Int] - read field i of obj as an integer. TODO(compiler): implement.
// fn field_names[T]() -> Vec[Str] - all field names in declaration order. TODO(compiler): implement.
// fn field_types[T]() -> Vec[Str] - all field type names in declaration order. TODO(compiler): implement.
// fn field_offsets[T]() -> Vec[Int] - all field byte offsets in declaration order. TODO(compiler): implement.
// fn variant_name[T](v: T) -> Str - the name of enum variant v. TODO(compiler): implement.
// fn variant_index[T](v: T) -> Int - the index of enum variant v. TODO(compiler): implement.
