// p_json_parse_depth_cap.xi -- unbounded json_parse recursion (stack death)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 -- `json_parse` returns Err for input nested beyond the
// parser's internal depth cap, so untrusted deep payloads cannot kill the
// process.
// Observed on compiler v0.64.2 / stdlib main (official archive pin,
// Windows x64, 2026-10-10): a run of '[' deeper than ~300 overflows the
// process stack before any error path -- the run dies with exit
// -1073741795 (0xC000001D, stack-overflow guard trap), no Err, no
// message. Depth 100/150/200 return the graceful
// "expected ']' or ','" Err; depth 300+ dies. Found by the XVECTOR lane
// (`probe_http_fuzz` t-unbalanced; workaround json_depth_ok(body, 64));
// relayed 2026-10-10 and verified natively. Requested shape: an internal
// cap around 128 (serde_json's default, well under the observed ~300
// floor) returning Err("json_parse: nesting too deep"), or any documented
// cap that cannot overflow the stack on Windows/macOS/Linux.

module p_json_parse_depth_cap

use xiom.serialize.json as json;
use xiom.string as string;

fn main() -> Int {
  // 10000 unbalanced '[' -- deep enough to die pre-fix, cheap to build.
  let deep = string.str_repeat("[", 10000);
  let r = json.json_parse(deep);
  if r.is_err { return 0; }
  return 1;
}
