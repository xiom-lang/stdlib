module p_contract_shapes
use xiom.io;

type Minfo = {
  used: Int;
  values: Vec[Int];
}

// Shape 1: Option[Str] payload len in ensures (method on payload).
fn s1(s: Str) -> Option[Str]
  ensures: result is Some => result.value.len() > 0
{
  if s.len() == 0 { return None; }
  return Some(s);
}

// Shape 2: Option[Int] payload scalar in ensures.
fn s2(o: Option[Int]) -> Option[Int]
  ensures: result is Some => result.value >= 0
{
  match o {
    Some(v) => { if v < 0 { return None; } return Some(v); },
    None => { return None; },
  }
}

// Shape 3: Result[Int, Str] payload scalar in ensures.
fn s3(n: Int) -> Result[Int, Str]
  ensures: result is Ok => result.value >= 0
{
  if n < 0 { return Err("neg"); }
  return Ok(n);
}

// Shape 4: param struct field equals in ensures (mutating fn).
fn s4(m: &mut Minfo)
  ensures: m.used == 0
{
  m.used = 0;
}

// Shape 5: result struct field in ensures (ctor).
fn s5() -> Minfo
  ensures: result.used == 0
{
  return Minfo{ used: 0; values: Vec[Int].new() };
}

// Shape 6: free-fn call with arg inside ensures.
fn size(m: &Minfo) -> Int {
  return m.used;
}
fn s6(m: &Minfo) -> Vec[Int]
  ensures: result.len() == size(m)
{
  var out = Vec[Int].new();
  var i = 0;
  while i < m.used {
    out.push(1);
    i = i + 1;
  }
  return out;
}

// Shape 7: conditional ensures (n <= 0 => ...).
fn s7(n: Int) -> Str
  ensures: n <= 0 => result.len() == 0
{
  if n <= 0 { return ""; }
  return "x";
}

// Shape 8: result.len() >= param.len().
fn s8(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  if s.len() >= 5 { return s; }
  return s + s;
}

// Shape 9: self field vs result len (method).
type Wrap = { data: Vec[Int]; }
fn Wrap.into_inner(self) -> Vec[Int]
  ensures: result.len() == self.data.len()
{
  return self.data;
}

// Shape 10: requires with conjunction on params.
fn s10(start: Int, end: Int) -> Int
  requires: start >= 0 && end >= start
{
  return end - start;
}

fn main() -> Int {
  var r1 = s1("abc");
  match r1 { Some(v) => { if v != "abc" { return 1; } }, None => { return 2; } }
  var r2 = s2(Some(7));
  match r2 { Some(v) => { if v != 7 { return 3; } }, None => { return 4; } }
  var r3 = s3(5);
  match r3 { Ok(v) => { if v != 5 { return 5; } }, Err(_) => { return 6; } }
  var m = Minfo{ used: 3; values: Vec[Int].new() };
  s4(&m);
  var m2 = s5();
  if m2.used != 0 { return 7; }
  var ks = s6(&m);
  if ks.len() != 0 { return 8; }
  var r7 = s7(0);
  if r7.len() != 0 { return 9; }
  var r8 = s8("ab");
  if r8.len() < 2 { return 10; }
  var w = Wrap{ data: Vec[Int].new() };
  w.data.push(1);
  var r9 = w.into_inner();
  if r9.len() != 1 { return 11; }
  var r10 = s10(2, 5);
  if r10 != 3 { return 12; }
  io.println("ALL SHAPES OK");
  return 0;
}
