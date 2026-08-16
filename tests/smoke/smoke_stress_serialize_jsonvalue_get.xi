module smoke_stress_serialize_jsonvalue_get
use xiom.serialize;

fn main() -> Int {
    var json_str = "{\"id\":42,\"label\":\"hello\",\"flag\":false}";

    var result = serialize.parse_json(&json_str);
    match result {
      Ok(value) => {
        var id = value.get("id");
        match id {
          Some(v) => {
            var label = value.get("label");
            match label {
              Some(v2) => {
                var flag = value.get("flag");
                match flag {
                  Some(v3) => { return 0; }
                  None => { return 5; }
                }
              }
              None => { return 3; }
            }
          }
          None => { return 2; }
        }
      }
      Err(_) => { return 1; }
    }
}
