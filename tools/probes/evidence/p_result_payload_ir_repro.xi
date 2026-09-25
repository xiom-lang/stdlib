// p_result_payload_ir_repro.xi -- EVIDENCE (compiler finding), 2026-09-25.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// GREEN as long as `Regex.captures`' catalog clause stays payload-free.
// The compiler finding it documents is CLAUSE-POISONING of user codegen:
//
//   1. With `xiom.regex.regex.Regex.captures` carrying
//        ensures: result is Some => result.value.groups.len() == 1
//      this program fails to COMPILE on v0.61.3:
//        error: clang failed with exit code 1
//        stderr: xiominput.ll:4495:40: error: '%tmp117' defined with type
//                '%struct.Vec = type { ptr, i64, i64, i64 }' but ...
//      (verified 2026-09-25 by re-adding the one-line clause; compiled
//      rc 1, then rc 0 after replacing it with a payload-free guard).
//   2. With the payload-free clause (`self.pattern.len() == 0 => result is
//      Some`) the same program compiles and runs (this file, exit 0).
//
// So a single clause that reads a nested-Vec payload field in a CATALOG
// module invalidates every user-side call to that function. Related family
// members observed the same session: `regex_unescape`'s Ok-Str `.len()`
// clause fires a FALSE "contract violated" from user modules, and
// `regex_parse`'s Ok-Str field compare exits 0xC0000005, while Int-field
// consumers of the same Ok payload pass. Written up in
// tools/known_failures/README.md; stdlib mitigation = payload-free clauses.

module p_result_payload_ir_repro

use xiom.regex.regex;

fn main() -> Int {
  let cr = regex.Regex.new("a+");
  match cr {
    Ok(r) => {
      let caps = r.captures("aaa");
      if !caps.is_some { return 1; }
      return 0;
    };
    Err(e) => { return 2; };
  }
}
