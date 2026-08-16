module smoke_stress_serialize_jsonvalue_index
use xiom.serialize;

fn main() -> Int {
    var json_str = "[10, 20, 30, 40, 50]";

    var result = serialize.parse_json(&json_str);
    match result {
      Ok(value) => {
        var e0 = value.index(0);
        var e2 = value.index(2);
        var e4 = value.index(4);
        match e0 {
          Some(v0) => {
            match e2 {
              Some(v2) => {
                match e4 {
                  Some(v4) => { return 0; }
                  None => { return 5; }
                }
              }
              None => { return 4; }
            }
          }
          None => { return 3; }
        }
      }
      Err(_) => { return 1; }
    }
}
