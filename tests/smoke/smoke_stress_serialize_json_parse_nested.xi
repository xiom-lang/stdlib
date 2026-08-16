module smoke_stress_serialize_json_parse_nested
use xiom.serialize;

fn main() -> Int {
    var nested_json = "{\"user\":{\"name\":\"Alice\",\"scores\":[95,87,92]},\"active\":true}";

    var result = serialize.parse_json(&nested_json);
    match result {
      Ok(value) => {
        var name = value.get("user");
        match name {
          Some(user_obj) => {
            var active = value.get("active");
            match active {
              Some(_) => { return 0; }
              None => { return 3; }
            }
          }
          None => { return 2; }
        }
      }
      Err(_) => { return 1; }
    }
}
