// bisect to_str: Int.to_str only
fn main() -> Int {
  if 0.to_str() != "0" { return 2; }
  return 0;
}
