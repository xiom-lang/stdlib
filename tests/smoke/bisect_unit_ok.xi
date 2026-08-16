// minimal: Ok(()) on Result[Unit, Str]
fn f() -> Result[Unit, Str] {
  return Ok(());
}
fn main() -> Int {
  match f() {
    Ok(_) => { return 0; }
    Err(_) => { return 1; }
}
