module smoke_serialize
use xiom.serialize;
use xiom.collections;
use xiom.convert;
fn main() -> Int {
  // json_bool / json_null (simple string-returning)
  if xiom.serialize.json_bool(true) != "true" { return 1; }
  if xiom.serialize.json_bool(false) != "false" { return 2; }
  if xiom.serialize.json_null() != "null" { return 3; }
  // json_string
  if xiom.serialize.json_string("hello") != "\"hello\"" { return 4; }
  if xiom.serialize.json_string("a\"b") != "\"a\\\"b\"" { return 5; }
  // JsonValue.to_str()
  var num = JsonValue.Number(42.0);
  if num.to_str() != "42" { return 6; }
  var nil = JsonValue.Null;
  if nil.to_str() != "null" { return 7; }
  // is_valid_json calls json_parse — skip (codegen bug in parse_number)
  // format detection
  var data: Vec[UInt8] = Vec[UInt8].new();
  data.push('{' as UInt8);
  var fmt = xiom.serialize.detect_format(&data);
  if fmt.len() <= 0 { return 8; }
  return 0;
}
