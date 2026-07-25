module smoke_serialize
use xiom.serialize;
use xiom.collections;
use xiom.convert;
fn main() -> Int {
  // json_bool / json_null (simple string-returning functions)
  if xiom.serialize.json_bool(true) != "true" { return 1; }
  if xiom.serialize.json_bool(false) != "false" { return 2; }
  if xiom.serialize.json_null() != "null" { return 3; }

  // json_string
  if xiom.serialize.json_string("hello") != "\"hello\"" { return 4; }

  // JsonValue.to_str() for basic types
  var num = JsonValue.Number(42.0);
  if num.to_str() != "42" { return 5; }

  var nil = JsonValue.Null;
  if nil.to_str() != "null" { return 6; }

  // json_parse is NOT tested here (known codegen issue with Result propagation)

  return 0;
}
