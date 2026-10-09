// p_wave100_shapes.xi -- wave 100 shape validation: finance + information_theory
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-100 clause guards:
//   (a) xiom.math.finance: the r==0 closed forms (pv/fv/pmt/nper), the
//       NaN guards (mirr/pmt nper 0/ipmt/ppmt per<1/nper pmt 0/perpetuity/
//       cagr/sharpe/sortino/calmar/bond_price/var/cvar/beta/alpha/
//       treynor), the empty-series identities (npv, drawdown) and the
//       exact perpetuity/cagr pins;
//   (b) xiom.math.information_theory: the empty entropy/perplexity/
//       compression-bound identities, the length-mismatch NaN guards
//       (kl/js/cross entropy), self_information +inf for p<=0, the empty
//       Huffman identity and arithmetic_coding's empty-sequence midpoint.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave100_shapes

use xiom.math.finance as fin;
use xiom.math.information_theory as info;

fn main() -> Int {
  // ---- finance: r == 0 closed forms
  let pv0 = fin.pv(0.0, 10.0, 5.0, 100.0);
  if pv0 != -150.0 { return 1; }
  let fv0 = fin.fv(0.0, 10.0, 5.0, 100.0);
  if fv0 != 150.0 { return 2; }
  let pmt0 = fin.pmt(0.0, 10.0, 100.0, 0.0);
  if pmt0 != -10.0 { return 3; }
  let nper0 = fin.nper(0.0, 10.0, 100.0, 0.0);
  if nper0 != -10.0 { return 4; }

  // ---- finance: empty-series identities
  var ef = Vec[Float64].new();
  let npv0 = fin.npv(0.1, &ef);
  if npv0 != 0.0 { return 5; }
  let dd0 = fin.drawdown(&ef);
  if dd0.len() != 0 { return 6; }

  // ---- finance: NaN guards
  let mi0 = fin.mirr(&ef, 0.1, 0.1);
  if mi0 == mi0 { return 7; }
  let pm1 = fin.pmt(0.0, 0.0, 10.0, 0.0);
  if pm1 == pm1 { return 8; }
  let ip0 = fin.ipmt(0.1, 0, 10.0, 100.0);
  if ip0 == ip0 { return 9; }
  let ip1 = fin.ipmt(0.0, 1, 10.0, 100.0);
  if ip1 != 0.0 { return 10; }
  let pp0 = fin.ppmt(0.1, 0, 10.0, 100.0);
  if pp0 == pp0 { return 11; }
  let np1 = fin.nper(0.0, 0.0, 10.0, 5.0);
  if np1 == np1 { return 12; }
  let pe0 = fin.perpetuity(10.0, 0.0);
  if pe0 == pe0 { return 13; }
  let pe1 = fin.perpetuity(10.0, 2.0);
  if pe1 != 5.0 { return 14; }
  let cg0 = fin.cagr(0.0, 1.0, 1.0);
  if cg0 == cg0 { return 15; }
  let cg1 = fin.cagr(100.0, 121.0, 2.0);
  if cg1 < 0.099 || cg1 > 0.101 { return 16; }

  // ---- finance: series-stat NaN guards
  let sh0 = fin.sharpe_ratio(&ef, 0.0);
  if sh0 == sh0 { return 17; }
  var one = Vec[Float64].new();
  one.push(1.0);
  let sh1 = fin.sharpe_ratio(&one, 0.0);
  if sh1 == sh1 { return 18; }
  let so0 = fin.sortino_ratio(&ef, 0.0);
  if so0 == so0 { return 19; }
  let ca0 = fin.calmar_ratio(&ef, 1.0);
  if ca0 == ca0 { return 20; }
  var two = Vec[Float64].new();
  two.push(1.0); two.push(2.0);
  let ca1 = fin.calmar_ratio(&two, 0.0);
  if ca1 == ca1 { return 21; }
  let bp0 = fin.bond_price(0.0, 0.05, 0.05, 5, 2);
  if bp0 == bp0 { return 22; }
  let va0 = fin.value_at_risk(&ef, 0.95, 0);
  if va0 == va0 { return 23; }
  let va1 = fin.value_at_risk(&two, 0.0, 0);
  if va1 == va1 { return 24; }
  let cv0 = fin.cvar(&ef, 0.95);
  if cv0 == cv0 { return 25; }
  let cv1 = fin.cvar(&two, 1.0);
  if cv1 == cv1 { return 26; }
  let be0 = fin.beta(&ef, &ef);
  if be0 == be0 { return 27; }
  let be1 = fin.beta(&one, &one);
  if be1 == be1 { return 28; }
  let al0 = fin.alpha(&ef, &ef, 0.0);
  if al0 == al0 { return 29; }
  let tr0 = fin.treynor_ratio(&ef, 1.0, 0.0);
  if tr0 == tr0 { return 30; }
  let tr1 = fin.treynor_ratio(&one, 0.0, 0.0);
  if tr1 == tr1 { return 31; }

  // ---- information_theory: empty identities
  let en0 = info.entropy(&ef);
  if en0 != 0.0 { return 32; }
  let pp1 = info.perplexity(&ef);
  if pp1 != 1.0 { return 33; }
  let dc0 = info.data_compression_bound(&ef);
  if dc0 != 0.0 { return 34; }
  let hf0 = info.huffman_coding(&ef);
  if hf0.len() != 0 { return 35; }
  var ei = Vec[Int].new();
  let ac0 = info.arithmetic_coding(&ef, &ei);
  if ac0 != 0.5 { return 36; }

  // ---- information_theory: mismatch NaN guards
  var pq = Vec[Float64].new();
  pq.push(0.5);
  let kl0 = info.kl_divergence(&pq, &two);
  if kl0 == kl0 { return 37; }
  let js0 = info.js_divergence(&pq, &two);
  if js0 == js0 { return 38; }
  let ce0 = info.cross_entropy(&pq, &two);
  if ce0 == ce0 { return 39; }

  // ---- information_theory: self_information +inf
  let si0 = info.self_information(0.0);
  if si0 <= 1.0 { return 40; }
  let si1 = info.self_information(-1.0);
  if si1 <= 1.0 { return 41; }

  return 0;
}
