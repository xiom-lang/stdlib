// XIOM stdlib stress -- Captures.get surface.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// get(0) is the whole match; get(1) is None because the engine does not
// extract groups yet (regex.xi documents the no-group limitation).
module smoke_stress_regex_captures_get
use xiom.regex;

fn main() -> Int {
  var rn = regex.Regex.new("[a-z]+");
  match rn {
    Err(_) => { return 3; },
    Ok(re) => {
      match re.captures("hello42") {
        None => { return 1; },
        Some(caps) => {
          match caps.get(0) {
            None => { return 2; },
            Some(m) => {
              if m.text != "hello" { return 4; }
            },
          };
          // No group 1 exists in the current engine.
          match caps.get(1) {
            Some(_) => { return 5; },
            None => { return 0; },
          }
        },
      }
    },
  }
}
