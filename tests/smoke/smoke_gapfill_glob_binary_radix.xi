module smoke_gapfill_glob_binary_radix
use xiom.misc.glob;
use xiom.search.binary;
use xiom.sort.radix;

// NOTE: bigfloat_to_float128 (num/bigfloat.xi) is implemented but cannot be
// exercised here: calling it crashes any consumer (TODO(compiler): BUG 37),
// and combining the bigfloat import chain with these modules trips the
// BUG 20 SIMD-flag family (0xC000001D on non-AVX-512 CPUs). bigfloat parse/
// format is covered by smoke_bigfloat. Re-enable when those land.

fn main() -> Int {
  // ---- glob_compile / glob_compile_match ----
  var h = glob.glob_compile("*.xi");
  match h {
    Err(_) => { return 1; },
    Ok(handle) => {
      if not glob.glob_compile_match(handle, "main.xi") { return 2; }
      if glob.glob_compile_match(handle, "main.xi.txt") { return 3; }
    }
  }
  var hq = glob.glob_compile("a?c");
  match hq {
    Err(_) => { return 4; },
    Ok(handle) => {
      if not glob.glob_compile_match(handle, "abc") { return 5; }
      if glob.glob_compile_match(handle, "ac") { return 6; }
    }
  }
  match glob.glob_compile("") {
    Err(_) => {},
    Ok(_) => { return 7; }
  }
  if glob.glob_compile_match(0, "x") { return 8; }

  // ---- binary_search_float ----
  var fv = Vec[Float64].new();
  fv.push(0.5); fv.push(1.5); fv.push(2.5); fv.push(3.5); fv.push(4.5);
  match binary.binary_search_float(&fv, 2.5) {
    Some(i) => { if i != 2 { return 9; } }
    None => { return 10; }
  }
  match binary.binary_search_float(&fv, 9.9) {
    Some(_) => { return 11; }
    None => {}
  }
  var fe = Vec[Float64].new();
  match binary.binary_search_float(&fe, 1.0) {
    Some(_) => { return 12; }
    None => {}
  }

  // ---- bucket_sort ----
  var bv = Vec[Int].new();
  bv.push(42); bv.push(7); bv.push(99); bv.push(-3); bv.push(0); bv.push(77); bv.push(13);
  radix.bucket_sort(&bv, 4);
  var expect = Vec[Int].new();
  expect.push(-3); expect.push(0); expect.push(7); expect.push(13); expect.push(42); expect.push(77); expect.push(99);
  var i = 0;
  while i < bv.len() {
    if bv[i] != expect[i] { return 13; }
    i = i + 1;
  }
  // reverse input, 2 buckets
  var rev = Vec[Int].new();
  rev.push(5); rev.push(4); rev.push(3); rev.push(2); rev.push(1);
  radix.bucket_sort(&rev, 2);
  i = 0;
  while i < 5 {
    if rev[i] != i + 1 { return 14; }
    i = i + 1;
  }
  // single element / single bucket
  var one = Vec[Int].new();
  one.push(7);
  radix.bucket_sort(&one, 1);
  if one.len() != 1 || one[0] != 7 { return 15; }

  return 0;
}
