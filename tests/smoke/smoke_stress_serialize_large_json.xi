module smoke_stress_serialize_large_json
use xiom.serialize.json;

fn main() -> Int {
    var arr = json.json_array_new();
    arr = json.json_array_push(arr, json.json_number(1.0));
    arr = json.json_array_push(arr, json.json_number(2.0));
    arr = json.json_array_push(arr, json.json_number(3.0));
    arr = json.json_array_push(arr, json.json_number(4.0));
    arr = json.json_array_push(arr, json.json_number(5.0));
    arr = json.json_array_push(arr, json.json_number(6.0));
    arr = json.json_array_push(arr, json.json_number(7.0));
    arr = json.json_array_push(arr, json.json_number(8.0));
    arr = json.json_array_push(arr, json.json_number(9.0));
    arr = json.json_array_push(arr, json.json_number(10.0));
    arr = json.json_array_push(arr, json.json_number(11.0));
    arr = json.json_array_push(arr, json.json_number(12.0));
    arr = json.json_array_push(arr, json.json_number(13.0));
    arr = json.json_array_push(arr, json.json_number(14.0));
    arr = json.json_array_push(arr, json.json_number(15.0));
    arr = json.json_array_push(arr, json.json_number(16.0));
    arr = json.json_array_push(arr, json.json_number(17.0));
    arr = json.json_array_push(arr, json.json_number(18.0));
    arr = json.json_array_push(arr, json.json_number(19.0));
    arr = json.json_array_push(arr, json.json_number(20.0));
    arr = json.json_array_push(arr, json.json_number(21.0));
    arr = json.json_array_push(arr, json.json_number(22.0));
    arr = json.json_array_push(arr, json.json_number(23.0));
    arr = json.json_array_push(arr, json.json_number(24.0));
    arr = json.json_array_push(arr, json.json_number(25.0));

    var json_str = json.json_stringify(arr);
    if json_str.len() == 0 { return 1; }

    var parsed = json.json_parse(json_str);
    match parsed {
      Ok(v) => {
        // arrays navigate by numeric string index via json_get_path
        var path = Vec[Str].new();
        path.push("0");
        match json.json_get_path(v, &path) {
          Some(_) => { return 0; }
          None => { return 2; }
        }
      }
      Err(_) => { return 1; }
    }
}
