// p_ensures_isok_guard.xi -- known failure: clause payload-length claims
// guarded with `(result.is_ok == true) =>` violate at runtime while the
// canonical `result is Ok =>` guard works
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Found while landing the wave-80 convert base-codec clauses: mirroring the
// canonical `result is Ok => result.len() == ...` claims as
// `(result.is_ok == true) => (result.len() == ...)` made
// base16.hex_decode("abcd") abort at runtime with `contract violated:
// ensures at 33:12` even though the Ok payload length was correct. The
// canonical `is Ok =>` form was then verified green on the same call. The
// compiler/checker should either reject the implication form at compile
// time (like other unsupported clause payload reads) or evaluate it as the
// `is Ok =>` form does.
//
// Expected when fixed: rc 0. On the pin: the runtime aborts in
// guarded_len -> nonzero rc ("contract violated").

module p_ensures_isok_guard

fn canonical_len(s: Str) -> Result[Str, Str]
  ensures: result is Ok => result.len() == s.len()
{
  return Ok(s);
}

fn guarded_len(s: Str) -> Result[Str, Str]
  ensures: (result.is_ok == true) => (result.len() == s.len())
{
  return Ok(s);
}

fn main() -> Int {
  let a = canonical_len("ab");
  if !a.is_ok { return 2; }
  let b = guarded_len("ab");
  if !b.is_ok { return 3; }
  return 0;
}
