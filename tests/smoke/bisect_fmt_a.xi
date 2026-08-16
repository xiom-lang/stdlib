// bisect fmt_edge a: to_str only
fn main() -> Int {
  if "".to_str() != "" { return 1; }
  if 0.to_str() != "0" { return 2; }
  if (-0).to_str() != "0" { return 3; }
  return 0;
}
