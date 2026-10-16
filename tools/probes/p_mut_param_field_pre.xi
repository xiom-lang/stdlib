// p_mut_param_field_pre.xi -- &mut param scalar-field @pre aliases post-state
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 (`bump` increments p.a from 1 to 2 and the clause's
// `x.a@pre` snapshot is the entry value 1).
// Observed on compiler v0.64.1: `contract violated: ensures at 22:12` and
// rc 1 -- `x.a@pre` evaluates to the POST-mutation value (2), so the
// arithmetic pre-state clause fails. Found while landing the wave-94 sync
// clauses:
// `sem_try_acquire`/`sem_release`/`cdl_count_down` (&mut param field reads)
// hit the same aliasing; those clauses were rewritten to post-state forms.
// Self-field @pre on method receivers works on the pin (wave-93 Range.next),
// so this is the &mut-parameter half of the R49 entry-snapshot residual
// (known_failures history: p_pre_capture_callee / p_pre_call_capture).
// The sync surface keeps @pre-free clauses until this resolves.

module p_mut_param_field_pre

type Pair = { a: Int; b: Int; }

fn bump(x: &mut Pair) -> Int
  ensures: (x.a@pre < 100) => (x.a == x.a@pre + 1)
{
  x.a = x.a + 1;
  return x.a;
}

fn main() -> Int {
  var p = Pair{ a: 1; b: 0; };
  let v = bump(&p);
  if v != 2 { return 1; }
  if p.a != 2 { return 2; }
  return 0;
}
