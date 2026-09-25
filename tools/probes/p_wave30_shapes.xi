// p_wave30_shapes.xi -- contract shape validation for wave 30 (math signal + exponential).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 30 applies to xiom.math.signal and xiom.math.exponential:
// 1. exact output-length identities on the transform/filter/window functions
//    (dft/fft/fft_real 2n; idft/ifft/ifft_real n/2; dct/dst/windows/spectrum/
//    psd/cepstrum n; convolve/correlate n + m - 1)
// 2. upper bounds on wavelet coefficient vectors (haar/dwt/daubechies <= n,
//    idwt <= coeffs.len()) plus empty-input guards
// 3. filter guards: x.len() == 0 or order <= 0 yields an empty result
// 4. matrix-row guards: empty input / degenerate sizes yield zero rows
//    (spectrogram, mel_filterbank; mfcc <= 24 coefficients)
// 5. Float64 sign/range guarantees on the exponential family, NaN-tolerant
//    where NaN is representable (exp/exp2/exp10/exp_pure >= 0,
//    expm1 >= -1, ln/log2/log10/ln_pure/... for x > 1 yield >= 0,
//    log1p/ln_1_plus for x > 0 yield >= 0, pow/pow_float/pow_pure with
//    base > 0 yield >= 0 (or NaN), pow_int(_, 0) == 1.0 exactly)
// 6. filter_bandstop order <= 0 returns empty: the old body indexed the
//    empty band-pass buffer (OOB read); fixed in this wave, RED before.
// main() drives the real functions with safe inputs; every call evaluates the
// new runtime clauses. Returns 0 when every shape holds.

module p_wave30_shapes

use xiom.math;

fn main() -> Int {
  var sig = Vec[Float64].new();
  sig.push(1.0);
  sig.push(2.0);
  sig.push(3.0);
  sig.push(4.0);
  var empty = Vec[Float64].new();
  var kern = Vec[Float64].new();
  kern.push(1.0);
  kern.push(1.0);

  // ---- transforms: exact lengths ----
  var d = math.signal.dft(&sig);
  if d.len() != 8 { return 1; }
  var d0 = math.signal.dft(&empty);
  if d0.len() != 0 { return 2; }
  var id = math.signal.idft(&d);
  if id.len() != 4 { return 3; }
  var f = math.signal.fft(&sig);
  if f.len() != 8 { return 4; }
  var f0 = math.signal.fft(&empty);
  if f0.len() != 0 { return 5; }
  var back = math.signal.ifft(&f);
  if back.len() != 4 { return 6; }
  var fr = math.signal.fft_real(&sig);
  if fr.len() != 8 { return 7; }
  var ir = math.signal.ifft_real(&f);
  if ir.len() != 4 { return 8; }
  var dc = math.signal.dct(&sig);
  if dc.len() != 4 { return 9; }
  var dc3 = math.signal.idct(&dc);
  if dc3.len() != 4 { return 10; }
  var dt2 = math.signal.dct_type2(&sig);
  if dt2.len() != 4 { return 11; }
  var dt3 = math.signal.dct_type3(&dc);
  if dt3.len() != 4 { return 12; }
  var ds = math.signal.dst(&sig);
  if ds.len() != 4 { return 13; }
  var ids = math.signal.idst(&ds);
  if ids.len() != 4 { return 14; }

  // ---- wavelets: upper bounds + guards ----
  var wh = math.signal.wavelet_haar(&sig, 1);
  if wh.len() > 4 { return 15; }
  var wh0 = math.signal.wavelet_haar(&sig, 0);
  if wh0.len() != 0 { return 16; }
  var wd = math.signal.wavelet_dwt(&sig, 1);
  if wd.len() > 4 { return 17; }
  var wi = math.signal.wavelet_idwt(&wh, 1);
  if wi.len() > wh.len() { return 18; }
  var wi0 = math.signal.wavelet_idwt(&wh, 0);
  if wi0.len() != 0 { return 19; }
  var wdb = math.signal.wavelet_daubechies(&sig, 4, 1);
  if wdb.len() > 4 { return 20; }
  var wdh = math.signal.wavelet_daubechies(&sig, 2, 1);
  if wdh.len() > 4 { return 21; }

  // ---- filters: exact lengths + order/x guards ----
  var lp = math.signal.filter_lowpass(&sig, 1.0, 1);
  if lp.len() != 4 { return 22; }
  var lp0 = math.signal.filter_lowpass(&sig, 1.0, 0);
  if lp0.len() != 0 { return 23; }
  var hp = math.signal.filter_highpass(&sig, 1.0, 1);
  if hp.len() != 4 { return 24; }
  var bp = math.signal.filter_bandpass(&sig, 0.2, 0.8, 1);
  if bp.len() != 4 { return 25; }
  var bs = math.signal.filter_bandstop(&sig, 0.2, 0.8, 1);
  if bs.len() != 4 { return 26; }
  var bs0 = math.signal.filter_bandstop(&sig, 0.2, 0.8, 0);
  if bs0.len() != 0 { return 27; }
  var bw = math.signal.filter_butterworth(&sig, 1.0, 1);
  if bw.len() != 4 { return 28; }
  var ch = math.signal.filter_chebyshev(&sig, 1.0, 0.1, 1);
  if ch.len() != 4 { return 29; }
  var be = math.signal.filter_bessel(&sig, 1.0, 1);
  if be.len() != 4 { return 30; }
  var fir = math.signal.filter_fir(&sig, &kern);
  if fir.len() != 4 { return 31; }
  var fir0 = math.signal.filter_fir(&sig, &empty);
  if fir0.len() != 0 { return 32; }
  var bcoef = Vec[Float64].new();
  bcoef.push(1.0);
  var acoef = Vec[Float64].new();
  acoef.push(1.0);
  var iir = math.signal.filter_iir(&sig, &bcoef, &acoef);
  if iir.len() != 4 { return 33; }
  var azero = Vec[Float64].new();
  azero.push(0.0);
  var iir0 = math.signal.filter_iir(&sig, &bcoef, &azero);
  if iir0.len() != 0 { return 34; }
  var cv = math.signal.convolve(&sig, &kern);
  if cv.len() != 5 { return 35; }
  var cr = math.signal.correlate(&sig, &kern);
  if cr.len() != 5 { return 36; }
  var ac = math.signal.autocorrelate(&sig);
  if ac.len() != 4 { return 37; }

  // ---- windows ----
  var w1 = math.signal.window_hanning(5);
  if w1.len() != 5 { return 38; }
  var w2 = math.signal.window_hamming(0);
  if w2.len() != 0 { return 39; }
  var w3 = math.signal.window_blackman(5);
  if w3.len() != 5 { return 40; }
  var w4 = math.signal.window_kaiser(5, 2.0);
  if w4.len() != 5 { return 41; }
  var w5 = math.signal.window_bartlett(5);
  if w5.len() != 5 { return 42; }
  var w6 = math.signal.window_gaussian(5, 1.0);
  if w6.len() != 5 { return 43; }

  // ---- spectral ----
  var sp = math.signal.spectrum(&sig);
  if sp.len() != 4 { return 44; }
  var ps = math.signal.psd(&sig);
  if ps.len() != 4 { return 45; }
  var sg0 = math.signal.spectrogram(&empty, 2, 1);
  if sg0.len() != 0 { return 46; }
  var sg = math.signal.spectrogram(&sig, 2, 1);
  if sg.len() > 4 { return 47; }
  var ce = math.signal.cepstrum(&sig);
  if ce.len() != 4 { return 48; }
  var mf0 = math.signal.mel_filterbank(0, 8, 8000.0);
  if mf0.len() != 0 { return 49; }
  var mf = math.signal.mel_filterbank(3, 8, 8000.0);
  if mf.len() != 3 { return 50; }
  var mc = math.signal.mfcc(&sig, 4, 8000.0);
  if mc.len() > 24 { return 51; }
  var mc0 = math.signal.mfcc(&sig, 0, 8000.0);
  if mc0.len() != 0 { return 52; }

  // ---- exponential: sign/range guarantees ----
  var ex = math.exponential.exp(1.0);
  if ex < 0.0 { return 53; }
  var exo = math.exponential.exp(1000.0);
  if exo < 0.0 { return 54; }
  var e2 = math.exponential.exp2(3.0);
  if e2 < 0.0 { return 55; }
  var e10 = math.exponential.exp10(2.0);
  if e10 < 0.0 { return 56; }
  var em1 = math.exponential.expm1(1e-10);
  if em1 < -1.0 { return 57; }
  var em1b = math.exponential.expm1(-1000.0);
  if em1b < -1.0 { return 58; }
  var l2 = math.exponential.ln(2.0);
  if l2 < 0.0 { return 59; }
  var lhalf = math.exponential.ln(0.5);
  if lhalf >= 0.0 { return 60; }
  var lz = math.exponential.ln(0.0);
  if !math.is_nan(lz) { return 61; }
  var lo2 = math.exponential.log2(8.0);
  if lo2 < 0.0 { return 62; }
  var lo10 = math.exponential.log10(100.0);
  if lo10 < 0.0 { return 63; }
  var l1p = math.exponential.log1p(1.0);
  if l1p < 0.0 { return 64; }
  var l1pn = math.exponential.log1p(-2.0);
  if !math.is_nan(l1pn) { return 65; }
  var l1pb = math.exponential.ln_1_plus(2.0);
  if l1pb < 0.0 { return 66; }
  var pw = math.exponential.pow(2.0, 10.0);
  if pw < 0.0 { return 67; }
  var pi0 = math.exponential.pow_int(5.0, 0);
  if pi0 != 1.0 { return 68; }
  var pf = math.exponential.pow_float(3.0, 2.0);
  if pf < 0.0 { return 69; }
  var sq = math.exponential.sqrt_power(16.0, 0.5);
  if sq < 0.0 { return 70; }
  var ep = math.exponential.exp_pure(1.0);
  if ep < 0.0 { return 71; }
  var epn = math.exponential.exp_pure(-1.0);
  if epn < 0.0 { return 72; }
  var lp2 = math.exponential.ln_pure(2.0);
  if lp2 < 0.0 { return 73; }
  var l2p = math.exponential.log2_pure(8.0);
  if l2p < 0.0 { return 74; }
  var l10p = math.exponential.log10_pure(100.0);
  if l10p < 0.0 { return 75; }
  var pp = math.exponential.pow_pure(2.0, 10.0);
  if pp < 0.0 { return 76; }
  var ppn = math.exponential.pow_pure(-2.0, 0.5);
  if !math.is_nan(ppn) { return 77; }
  return 0;
}
