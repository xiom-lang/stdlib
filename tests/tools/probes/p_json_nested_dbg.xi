module p_json_nested_dbg
use xiom.serialize.json;
use xiom.io;
fn main() -> Int {
  var arr = json.json_array_new();
  arr = json.json_array_push(arr, json.json_number(1.0));
  arr = json.json_array_push(arr, json.json_number(2.0));
  var inner = json.json_object_new();
  inner = json.json_set(inner, "x", json.json_number(10.0));
  var outer = json.json_object_new();
  outer = json.json_set(outer, "name", json.json_string("test"));
  outer = json.json_set(outer, "points", arr);
  outer = json.json_set(outer, "coord", inner);
  var s = json.json_stringify(outer);
  io.println("str=[" + s + "]");
  var r = json.json_parse(s);
  if r.is_ok { io.println("parse-OK"); return 0; }
  io.println("parse-FAILED");
  return 1;
}
