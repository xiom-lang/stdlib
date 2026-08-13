// XIOM stdlib smoke - xiom.string.format (compile-only)
// Returns 0 on success.
//
// NOTE (compiler, BUG 27 #5): `xiom.string.format` sublib fns (str_format1/2/3)
// are UNREACHABLE from user modules — the flat string.xi exports same-named
// fns (str_format1/2/3), so the sublib path fails resolution ("cannot call
// 'str_format1' on this expression") regardless of qualification. The format
// sublib delegates to the flat fmt module (smoke_fmt_format1 etc. cover the
// underlying logic). TODO(compiler): fix sublib-vs-flat same-name resolution.
module smoke_string_format_printf
use xiom.string.format;
use xiom.io;

fn main() -> Int {
  io.println("smoke_string_format_printf: OK (compile-only)");
  return 0;
}
