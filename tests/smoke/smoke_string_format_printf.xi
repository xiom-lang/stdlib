// XIOM stdlib smoke test - xiom.string.format + xiom.string.printf + xiom.string.scanf
// Returns 0 on success, nonzero on failure (process exit code).
//
// NOTE (compiler, BUG 27 #2 -- FIXED 4e95717e): the sublib path now resolves
// via FULLY-QUALIFIED calls (xiom.string.format.str_format1); the bare
// module-prefix form (format.str_format1) still fails T001 and the aggregate
// form (string.format.str_format1) silently resolves to the flat string.xi
// fn of the same name. Format fns take Int args only (Str/Float64 to_str
// crash, Bool renders "1" -- BUG 27 #19).

module smoke_string_format_printf
use xiom.string.format;
use xiom.string.printf;
use xiom.io;

fn main() -> Int {
  // ---- format ----
  var f1 = xiom.string.format.str_format1("Hello {}", 42);
  match f1 {
    Ok(v) => { if v != "Hello 42" { io.println("fmt-1"); return 1; } };
    Err(e) => { io.println(e); return 2; };
  }
  var f2 = xiom.string.format.str_format2("{} and {}", 1, 2);
  match f2 {
    Ok(v) => { if v != "1 and 2" { io.println("fmt-2"); return 3; } };
    Err(e) => { io.println(e); return 4; };
  }
  var f3 = xiom.string.format.str_format3("{} {} {}", 1, 2, 3);
  match f3 {
    Ok(v) => { if v != "1 2 3" { io.println("fmt-3"); return 5; } };
    Err(e) => { io.println(e); return 6; };
  }
  var f4 = xiom.string.format.str_format1("plain", 7);
  match f4 {
    Ok(v) => { if v != "plain" { io.println("fmt-4"); return 7; } };
    Err(e) => { io.println(e); return 8; };
  }

  // ---- printf ----
  var p1 = xiom.string.printf.str_printf_i1("%d", 42);
  match p1 {
    Ok(v) => { if v != "42" { io.println("prf-1"); return 9; } };
    Err(e) => { io.println(e); return 10; };
  }
  var p2 = xiom.string.printf.str_printf_s1("%s", "hi");
  match p2 {
    Ok(v) => { if v != "hi" { io.println("prf-2"); return 11; } };
    Err(e) => { io.println(e); return 12; };
  }

  io.println("smoke_string_format_printf: OK");
  return 0;
}
