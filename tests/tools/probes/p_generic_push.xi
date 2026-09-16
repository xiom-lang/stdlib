module p_generic_push
use xiom.io;
use xiom.serialize.json;

fn push_v[V](v: &mut Vec[V], x: V) {
  v.push(x);
}

type Holder[V] = { values: Vec[V]; }

fn add_h[V](h: &mut Holder[V], x: V) {
  h.values.push(x);
}

fn make_holder[V]() -> Holder[V] {
  return Holder[V]{ values: Vec[V].new() };
}

fn main() -> Int {
  // A: concrete Vec creation, generic-param push
  var vs = Vec[JsonValue].new();
  push_v(&vs, json.json_number(42.0));
  io.println("A=[" + json.json_stringify(vs[0]) + "]");

  // B: generic holder creation + generic field push
  var h = make_holder[JsonValue]();
  add_h(&h, json.json_string("tree"));
  io.println("B=[" + json.json_stringify(h.values[0]) + "]");

  // C: generic holder creation + concrete push from main
  var h2 = make_holder[JsonValue]();
  h2.values.push(json.json_number(9.0));
  io.println("C=[" + json.json_stringify(h2.values[0]) + "]");
  return 0;
}
