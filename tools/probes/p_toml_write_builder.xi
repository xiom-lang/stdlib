// p_toml_write_builder.xi -- byte-exact TOML writer after the wave-209
// byte-builder rewrite: sections, escapes, quoted keys, floats, arrays.
// Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_toml_write_builder

use xiom.serialize.toml;
use xiom.string;
use xiom.io;

fn main() -> Int {
  let manifest_text = "# xiom manifest\n[package]\nname = \"xiom\"\nversion = \"0.58.0\"\ncount = 1_024\nratio = 1.5\nenabled = true\npath = 'C:\\tools\\x'\n[build]\ntargets = [\"core\", \"jit\"]\nlevels = [1, 2, 3]\n";
  match toml_parse(manifest_text) {
    Ok(t) => {
      let out = toml_write(&t);
      if !string.str_contains(out, "[package]\nname = \"xiom\"\n") { return 1; }
      if !string.str_contains(out, "path = \"C:\\\\tools\\\\x\"") { return 2; }
      if !string.str_contains(out, "[build]\ntargets = [\"core\", \"jit\"]\n") { return 3; }
    },
    Err(e) => { io.println("manifest err " + e); return 4; },
  }

  match toml_parse("[tool.chain]\nbin = \"x\"\n") {
    Ok(t) => {
      if toml_write(&t) != "[tool.chain]\nbin = \"x\"\n" { return 5; }
    },
    Err(e) => { return 6; },
  }

  match toml_parse("\"quoted key\" = \"line\\nbreak\\tand \\\"quote\\\"\"\n") {
    Ok(t) => {
      if toml_write(&t) != "\"quoted key\" = \"line\\nbreak\\tand \\\"quote\\\"\"\n" { return 7; }
    },
    Err(e) => { return 8; },
  }

  match toml_parse("a = 1.5\nb = 2.0\nc = [1.5, 2.5]\n") {
    Ok(t) => {
      if toml_write(&t) != "a = 1.5\nb = 2.0\nc = [1.5, 2.5]\n" { return 9; }
    },
    Err(e) => { return 10; },
  }

  return 0;
}
