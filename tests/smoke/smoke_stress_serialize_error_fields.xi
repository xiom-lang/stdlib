module smoke_stress_serialize_error_fields
  use xiom.serialize;

  fn main() -> Int {
    var bad_json = "{invalid";

    var result = serialize.parse_json(&bad_json);
    match result {
      Ok(_) => { return 1; }
      Err(err) => {
        if err.message.len() > 0 {
          if err.line >= 0 {
            if err.column >= 0 {
              return 0;
            }
          }
        }
        return 2;
      }
    }
  }
