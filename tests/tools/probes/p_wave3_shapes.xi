module p_wave3_shapes
use xiom.io;

// Conditional boolean ensures (empty-prefix => true / no-match => false).
fn w1(s: Str, prefix: Str) -> Bool
  ensures: prefix.len() == 0 => result
{
  return s.len() >= prefix.len();
}

fn w2(s: Str, keys: &Vec[Str]) -> Bool
  ensures: keys.len() == 0 => result == false
{
  var i = 0;
  while i < keys.len() {
    if s == keys[i] { return true; }
    i = i + 1;
  }
  return false;
}

// Option[Str] payload length bound.
fn w3(s: Str, prefix: Str) -> Option[Str]
  ensures: result is Some => result.value.len() <= s.len()
{
  if s.len() < prefix.len() { return None; }
  return Some(s);
}

// Exact slice length under valid bounds.
fn w4(s: Str, start: Int, end: Int) -> Str
  ensures: end >= start && start >= 0 && end <= s.len() => result.len() == end - start
  ensures: result.len() <= s.len()
{
  var a = start;
  var b = end;
  if a < 0 { a = 0; }
  if b > s.len() { b = s.len(); }
  if a >= b { return ""; }
  var out = "";
  var i = a;
  while i < b { out = out + "#"; i = i + 1; }
  return out;
}

// concat length arithmetic.
fn w5(a: Str, b: Str) -> Str
  ensures: result.len() == a.len() + b.len()
{
  return a + b;
}

fn main() -> Int {
  if !w1("abc", "") { return 1; }
  if !w1("abc", "ab") { return 2; }
  var empty = Vec[Str].new();
  if w2("abc", &empty) { return 3; }
  var keys = Vec[Str].new(); keys.push("x");
  if w2("abc", &keys) { return 4; }
  var o = w3("abc", "ab");
  match o { Some(v) => { if v.len() != 3 { return 5; } }, None => { return 6; } }
  let sl = w4("abcdef", 2, 5);
  if sl.len() != 3 { return 7; }
  let cc = w5("ab", "cde");
  if cc.len() != 5 { return 8; }
  io.println("WAVE3 SHAPES OK");
  return 0;
}
