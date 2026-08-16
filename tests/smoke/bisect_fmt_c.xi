// bisect to_str: Str.to_str only
fn main() -> Int {
  if "".to_str() != "" { return 1; }
  return 0;
}
