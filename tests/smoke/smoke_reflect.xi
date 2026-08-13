// XIOM stdlib smoke — xiom.reflect.typeinfo + fields (LIMITED placeholders)
// Returns 0 on success, nonzero (and a tag) on failure.

module smoke_reflect
use xiom.reflect.typeinfo;
use xiom.reflect.fields;
use xiom.io;

fn fail(tag: Str) -> Int {
  io.println("smoke_reflect FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  // typeinfo: limited placeholders
  if typeinfo.type_name[Int]() != "unknown" { return fail("t-name"); }
  if typeinfo.type_id[Int]() != 0 { return fail("t-id"); }
  if typeinfo.type_size[Int]() != 0 { return fail("t-size"); }
  if typeinfo.type_align[Int]() != 0 { return fail("t-align"); }
  if typeinfo.type_is_primitive[Int]() { return fail("t-primitive"); }
  if typeinfo.type_is_struct[Int]() { return fail("t-struct"); }
  if typeinfo.type_is_enum[Int]() { return fail("t-enum"); }
  if typeinfo.type_is_generic[Int]() { return fail("t-generic"); }
  if typeinfo.type_of[Int](5) != "unknown" { return fail("t-of"); }
  if typeinfo.type_variant_count[Int]() != 0 { return fail("t-variants"); }
  if !typeinfo.type_is_sized[Int]() { return fail("t-sized"); }
  if !typeinfo.type_is_sized[Float64]() { return fail("t-sized-extra"); }

  // fields: limited placeholders
  if fields.field_count[Int]() != 0 { return fail("f-count"); }
  let fn1 = fields.field_name[Int](0);
  if fn1.is_some { return fail("f-name"); }
  let ft1 = fields.field_type[Int](0);
  if ft1.is_some { return fail("f-type"); }
  let fo1 = fields.field_offset[Int](0);
  if fo1.is_some { return fail("f-offset"); }
  let x: Int = 42;
  let fv = fields.field_value[Int](&x, 0);
  if fv.is_some { return fail("f-value"); }
  let names = fields.field_names[Int]();
  if names.len() != 0 { return fail("f-names"); }
  let types = fields.field_types[Int]();
  if types.len() != 0 { return fail("f-types"); }
  let offsets = fields.field_offsets[Int]();
  if offsets.len() != 0 { return fail("f-offsets"); }
  if fields.variant_name[Int](7) != "unknown" { return fail("f-variant-name"); }
  if fields.variant_index[Int](7) != 0 { return fail("f-variant-index"); }

  io.println("smoke_reflect OK");
  return 0;
}
