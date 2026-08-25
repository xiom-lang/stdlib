// smoke_os_args.xi -- xiom.os.args
// Pure helpers are tested against synthetic vectors (no argv control under
// the driver); the raw binding is sanity-checked for at least one entry.
module smoke_os_args
use xiom.os.args;
use xiom.io;

fn main() -> Int {
  // ---- raw binding sanity: the host always provides >= 1 entry ----
  var raw = args_raw();
  if raw.len() < 1 { io.println("raw:empty"); return 1; }

  // ---- synthetic vector: flag / inline option / spaced option / positionals
  var args = Vec[Str].new();
  args.push("prog");
  args.push("--verbose");
  args.push("--out=result.txt");
  args.push("--level");
  args.push("3");
  args.push("input.txt");

  if !flag_lookup(&args, "--verbose") { io.println("flag:verbose"); return 2; }
  if flag_lookup(&args, "--quiet") { io.println("flag:false-hit"); return 3; }

  // inline form
  var out = option_value(&args, "--out");
  match out {
    Some(v) => { if v != "result.txt" { io.println("opt:inline"); return 4; } }
    None => { io.println("opt:inline-miss"); return 5; }
  }
  // spaced form
  var lvl = option_value(&args, "--level");
  match lvl {
    Some(v) => { if v != "3" { io.println("opt:spaced"); return 6; } }
    None => { io.println("opt:spaced-miss"); return 7; }
  }
  // absent key
  match option_value(&args, "--missing") {
    Some(_) => { io.println("opt:false-hit"); return 8; }
    None => {}
  }
  // last-one-wins
  var dup = Vec[Str].new();
  dup.push("--k=1");
  dup.push("--k=2");
  match option_value(&dup, "--k") {
    Some(v) => { if v != "2" { io.println("opt:last-wins"); return 9; } }
    None => { io.println("opt:last-wins-miss"); return 10; }
  }

  // ---- positionals: skips flags and spaced-option values ----
  var pos = positionals(&args);
  if pos.len() != 2 { io.println("pos:len"); return 11; }
  if pos[0] != "prog" { io.println("pos:prog"); return 12; }
  if pos[1] != "input.txt" { io.println("pos:input"); return 13; }

  io.println("OK");
  return 0;
}
