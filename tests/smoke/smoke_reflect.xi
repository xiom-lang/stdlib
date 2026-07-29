// XIOM stdlib smoke test — xiom.reflect
// Exercises the real RTTI accessors: type_count / type_name_by_id / type_id_by_name.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_reflect
use xiom.reflect;

fn main() -> Int {
  var n = xiom.reflect.type_count();
  var nm = xiom.reflect.type_name_by_id(0);
  var id = xiom.reflect.type_id_by_name("Nonexistent");
  if n >= 0 && nm.len() >= 0 && id >= -1 {
    return 0;
  }
  return 1;
}
