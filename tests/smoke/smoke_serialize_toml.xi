// XIOM stdlib smoke test - xiom.serialize.toml (v1 subset)
// Checks: comments, [table]/[a.b] headers, bare/quoted keys, basic +
// literal strings with escapes, integers with '_' separators, floats,
// booleans, string/int arrays, section-qualified lookups, typed getters,
// and the error paths (unterminated string/array, duplicate key,
// malformed header, missing value, mixed array).
// Returns 0 on success, unique error code on failure.

module smoke_serialize_toml
use xiom.serialize.toml;
use xiom.io;

fn main() -> Int {
  let text = "# xiom manifest\n[package]\nname = \"xiom\"\nversion = \"0.58.0\"\ncount = 1_024\nratio = 1.5\nenabled = true\npath = 'C:\\tools\\x'\n[build]\ntargets = [\"core\", \"jit\"]\nlevels = [1, 2, 3]\n";

  match toml_parse(text) {
    Ok(t) => {
      if !toml_has(&t, "package.name") { io.println("has name"); return 2; }
      if toml_has(&t, "package.missing") { io.println("has missing"); return 3; }
      if toml_keys(&t).len() != 8 { io.println("keys=" + toml_keys(&t).len()); return 4; }

      match toml_get_str(&t, "package.name") {
        Some(s) => { if s != "xiom" { io.println("name=" + s); return 5; } },
        None => { io.println("name None"); return 6; },
      }
      match toml_get_str(&t, "package.version") {
        Some(s) => { if s != "0.58.0" { return 7; } },
        None => { return 8; },
      }
      match toml_get_int(&t, "package.count") {
        Some(n) => { if n != 1024 { io.println("count=" + n); return 9; } },
        None => { return 10; },
      }
      match toml_get_float(&t, "package.ratio") {
        Some(f) => { if f != 1.5 { io.println("ratio"); return 11; } },
        None => { return 12; },
      }
      match toml_get_bool(&t, "package.enabled") {
        Some(b) => { if !b { io.println("enabled"); return 13; } },
        None => { return 14; },
      }
      match toml_get_str(&t, "package.path") {
        Some(s) => { if s != "C:\\tools\\x" { io.println("path=" + s); return 15; } },
        None => { return 16; },
      }
      match toml_get_str_array(&t, "build.targets") {
        Some(a) => {
          if a.len() != 2 { io.println("targets len=" + a.len()); return 17; }
          if a[0] != "core" || a[1] != "jit" { io.println("targets vals"); return 18; }
        },
        None => { return 19; },
      }
      match toml_get_int_array(&t, "build.levels") {
        Some(a) => {
          if a.len() != 3 { return 20; }
          if a[0] != 1 || a[2] != 3 { return 21; }
        },
        None => { return 22; },
      }
      if toml_get_int(&t, "package.name").is_some { return 23; }
    },
    Err(e) => { io.println("parse err: " + e); return 1; },
  }

  // Dotted table header.
  match toml_parse("[tool.chain]\nbin = \"x\"\n") {
    Ok(t2) => {
      match toml_get_str(&t2, "tool.chain.bin") {
        Some(s) => { if s != "x" { return 24; } },
        None => { return 25; },
      }
    },
    Err(_) => { return 26; },
  }

  // Escapes in basic strings.
  match toml_parse("k = \"a\\nb\\tc\\\"d\"\n") {
    Ok(t3) => {
      match toml_get_str(&t3, "k") {
        Some(s) => { if s != "a\nb\tc\"d" { io.println("esc=[" + s + "]"); return 27; } },
        None => { return 28; },
      }
    },
    Err(_) => { return 29; },
  }

  // Error cases.
  match toml_parse("x = \"abc\n") { Ok(_) => { return 30; }, Err(_) => { } }
  match toml_parse("[a]\nk = 1\nk = 2\n") { Ok(_) => { return 31; }, Err(_) => { } }
  match toml_parse("[bad\n") { Ok(_) => { return 32; }, Err(_) => { } }
  match toml_parse("x =\n") { Ok(_) => { return 33; }, Err(_) => { } }
  match toml_parse("a = [1, \"s\"]\n") { Ok(_) => { return 34; }, Err(_) => { } }
  match toml_parse("a = [1, 2\n") { Ok(_) => { return 35; }, Err(_) => { } }

  io.println("OK");
  return 0;
}
