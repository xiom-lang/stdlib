module p_gp_c
use xiom.io;
use xiom.serialize.json;
type Holder[V] = { values: Vec[V]; }
fn make_holder[V]() -> Holder[V] { return Holder[V]{ values: Vec[V].new() }; }
fn main() -> Int {
  var h2 = make_holder[JsonValue]();
  h2.values.push(json.json_number(9.0));
  io.println("C=[" + json.json_stringify(h2.values[0]) + "]");
  return 0;
}
