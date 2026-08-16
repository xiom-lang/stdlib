// minimal: Result[Unit, FmtError] struct literal
type FmtError = { message: Str; }
fn f() -> Result[Unit, FmtError] {
  Result[Unit, FmtError] { is_ok: true; value: (); error: FmtError { message: ""; }; }
}
fn main() -> Int {
  match f() {
    Ok(_) => { return 0; }
    Err(_) => { return 1; }
}
