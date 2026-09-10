// kat_serialize_json_minimal.xi -- JSON parser known-answer tests
// Accept/reject subset of JSONTestSuite plus RFC 8259 section semantics.
// Number-formatting assertions are deliberately excluded (float repr is a
// separate battle); this file pins structural parse behavior only.
// UN-GATED 2026-09-10 (compiler rounds 26-29: json heap layer Parts 1+2).
// Ran as a flip-green regression lock through the round-15..29 fix series.
module kat_serialize_json_minimal
use xiom.serialize.json;
use xiom.io;

fn expect_ok(src: Str, code: Int) -> Int {
  match json.json_parse(src) {
    Ok(_) => { return 0; },
    Err(e) => { io.println("json rejected valid '" + src + "': " + e); return code; },
  }
}

fn expect_err(src: Str, code: Int) -> Int {
  match json.json_parse(src) {
    Ok(_) => { io.println("json accepted invalid '" + src + "'"); return code; },
    Err(_) => { return 0; },
  }
}

fn main() -> Int {
  // ---- y_ cases: MUST parse ----
  var r = expect_ok("{}", 1);
  if r != 0 { return r; }
  r = expect_ok("[]", 2);
  if r != 0 { return r; }
  r = expect_ok("{\"a\":[1,2.5,true,null,\"x\"]}", 3);
  if r != 0 { return r; }
  r = expect_ok("[[[[[[[[[]]]]]]]]]", 4);
  if r != 0 { return r; }
  r = expect_ok("\"\\u0041\\n\\t\\\\\"", 5);
  if r != 0 { return r; }

  // ---- n_ cases: MUST be rejected ----
  r = expect_err("{", 6);
  if r != 0 { return r; }
  r = expect_err("{\"a\":}", 7);
  if r != 0 { return r; }
  r = expect_err("[1,]", 8);
  if r != 0 { return r; }
  r = expect_err("{'a':1}", 9);
  if r != 0 { return r; }
  r = expect_err("{\"a\":tru}", 10);
  if r != 0 { return r; }
  r = expect_err("[1 2]", 11);
  if r != 0 { return r; }
  r = expect_err("{\"a\" 1}", 12);
  if r != 0 { return r; }

  // ---- structural spot checks via json_get / json_type ----
  var doc = json.json_parse("{\"name\":\"xiom\",\"n\":42,\"flags\":[true,false,null],\"nested\":{\"deep\":\"v\"}}");
  match doc {
    Ok(v) => {
      var t = json.json_type(v);
      if t != "object" && t != "Object" {
        io.println("root type unexpected: " + t);
        return 13;
      }
      match json.json_get(v, "name") {
        Some(s) => {
          var st = json.json_type(s);
          if st != "string" && st != "Str" && st != "String" {
            io.println("name type unexpected: " + st);
            return 14;
          }
        },
        None => { io.println("get(name) missing"); return 15; },
      }
      match json.json_get(v, "missing-key") {
        Some(_) => { io.println("get(missing) returned Some"); return 16; },
        None => {},
      }
      match json.json_get(v, "nested") {
        Some(inner) => {
          match json.json_get(inner, "deep") {
            Some(_) => {},
            None => { io.println("get(nested.deep) missing"); return 17; },
          }
        },
        None => { io.println("get(nested) missing"); return 18; },
      }
    },
    Err(e) => { io.println("composite doc failed to parse: " + e); return 19; },
  }

  io.println("kat_serialize_json_minimal OK");
  return 0;
}
