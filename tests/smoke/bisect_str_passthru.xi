// user-land Str.to_str passthrough
fn Str.to_str() -> Str {
  self
}
fn main() -> Int {
  if "".to_str() != "" { return 1; }
  return 0;
}
