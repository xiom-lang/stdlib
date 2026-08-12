module smoke_string_format_printf
use xiom.string.format;
use xiom.io;

fn main() -> Int {
  // ---- format ----
  // NOTE (compiler bug): this module is tested in isolation because calling
  // any other xiom.string.* module's functions breaks resolution of the
  // `xiom.string.format` path on the current compiler build. Also, the
  // generic Display dispatch miscompiles: Str.to_str() and Float64.to_str()
  // crash, and Bool.to_str() through a generic renders "1", so only Int
  // arguments are exercised.
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
  var f5 = xiom.string.format.str_format2("{}|{}", 4, 9);
  match f5 {
    Ok(v) => { if v != "4|9" { io.println("fmt-5"); return 9; } };
    Err(e) => { io.println(e); return 10; };
  }
  var f6 = xiom.string.format.str_format3("{};{};{}", 7, 8, 9);
  match f6 {
    Ok(v) => { if v != "7;8;9" { io.println("fmt-6"); return 11; } };
    Err(e) => { io.println(e); return 12; };
  }

  io.println("smoke_string_format_printf: OK");
  return 0;
}
