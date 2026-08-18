module smoke_stress_serialize_json_nested
use xiom.serialize.json;

fn main() -> Int {
    var arr = json.json_array_new();
    arr = json.json_array_push(arr, json.json_number(1.0));
    arr = json.json_array_push(arr, json.json_number(2.0));
    arr = json.json_array_push(arr, json.json_number(3.0));

    var inner = json.json_object_new();
    inner = json.json_set(inner, "x", json.json_number(10.0));
    inner = json.json_set(inner, "y", json.json_number(20.0));

    var outer = json.json_object_new();
    outer = json.json_set(outer, "name", json.json_string("test"));
    outer = json.json_set(outer, "points", arr);
    outer = json.json_set(outer, "coord", inner);

    var json_str = json.json_stringify(outer);
    if json_str.len() > 0 {
      var result = json.json_parse(json_str);
      if result.is_ok {
        return 0;
      }
    }
    return 1;
}
