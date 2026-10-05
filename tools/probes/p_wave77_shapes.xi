// p_wave77_shapes.xi -- wave 77 shape validation: stats (dist, histogram,
// moments, test)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-77 clause guards on xiom.stats.dist (15),
// xiom.stats.histogram (9; histogram_add is void and stays clause-free),
// xiom.stats.moments (13) and xiom.stats.test (11); returns 0 when every
// case holds. No network. Guard paths: empty/short vectors, NaN and
// infinite parameters, out-of-domain quantiles, mismatched lengths,
// degenerate histograms (empty counts, bins <= 0, max <= min) and the
// moment formulas. `Vec.new()` temporaries passed as `&Vec` are bound to
// named locals first (probe landmine).

module p_wave77_shapes

use xiom.stats.dist;
use xiom.stats.histogram;
use xiom.stats.moments;
use xiom.stats.test;

fn _isnan(x: Float64) -> Bool {
  return x != x;
}

fn _near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn main() -> Int {
  var nan = 0.0 / 0.0;
  var inf = 1.0 / 0.0;

  // ---- dist: uniform ----------------------------------------------------
  if !_near(dist.uniform_pdf(1.5, 0.0, 3.0), 1.0 / 3.0, 1e-12) { return 1; }
  if dist.uniform_pdf(5.0, 0.0, 3.0) != 0.0 { return 2; }
  if !_isnan(dist.uniform_pdf(1.0, 2.0, 1.0)) { return 3; }
  if !_isnan(dist.uniform_pdf(1.0, 2.0, 2.0)) { return 4; }
  if dist.uniform_cdf(-1.0, 0.0, 3.0) != 0.0 { return 5; }
  if dist.uniform_cdf(4.0, 0.0, 3.0) != 1.0 { return 6; }
  if !_near(dist.uniform_cdf(1.5, 0.0, 3.0), 0.5, 1e-12) { return 7; }
  if !_isnan(dist.uniform_cdf(1.0, 2.0, 1.0)) { return 8; }
  if !_isnan(dist.uniform_cdf(nan, 0.0, 3.0)) { return 9; }

  // ---- dist: normal -----------------------------------------------------
  if !_near(dist.normal_pdf(0.0, 0.0, 1.0), 0.3989422804014327, 1e-12) { return 10; }
  if !_isnan(dist.normal_pdf(0.0, 0.0, 0.0)) { return 11; }
  if !_isnan(dist.normal_pdf(0.0, 0.0, -2.0)) { return 12; }
  if !_isnan(dist.normal_pdf(nan, 0.0, 1.0)) { return 13; }
  if dist.normal_cdf(0.0, 0.0, 1.0) != 0.5 { return 14; }
  if dist.normal_cdf(0.0 - inf, 0.0, 1.0) != 0.0 { return 15; }
  if dist.normal_cdf(inf, 0.0, 1.0) != 1.0 { return 16; }
  if !_isnan(dist.normal_cdf(0.0, 0.0, 0.0)) { return 17; }
  if !_near(dist.normal_ppf(0.5, 0.0, 1.0), 0.0, 1e-6) { return 18; }
  if !_isnan(dist.normal_ppf(0.0, 0.0, 1.0)) { return 19; }
  if !_isnan(dist.normal_ppf(1.0, 0.0, 1.0)) { return 20; }
  if !_isnan(dist.normal_ppf(-0.5, 0.0, 1.0)) { return 21; }
  if !_isnan(dist.normal_ppf(1.5, 0.0, 1.0)) { return 22; }

  // ---- dist: exponential ------------------------------------------------
  if !_near(dist.exponential_pdf(1.0, 1.0), 0.36787944117144233, 1e-12) { return 23; }
  if dist.exponential_pdf(0.0, 1.0) != 1.0 { return 24; }
  if dist.exponential_pdf(inf, 1.0) != 0.0 { return 25; }
  if !_isnan(dist.exponential_pdf(-1.0, 1.0)) { return 26; }
  if !_isnan(dist.exponential_pdf(1.0, 0.0)) { return 27; }
  if dist.exponential_cdf(0.0, 1.0) != 0.0 { return 28; }
  if !_near(dist.exponential_cdf(1.0, 1.0), 0.6321205588285577, 1e-12) { return 29; }
  if dist.exponential_cdf(inf, 1.0) != 1.0 { return 30; }
  if !_isnan(dist.exponential_cdf(-1.0, 1.0)) { return 31; }
  if !_isnan(dist.exponential_cdf(1.0, 0.0)) { return 32; }

  // ---- dist: discrete ---------------------------------------------------
  if dist.poisson_pmf(0.0, 0.0) != 1.0 { return 33; }
  if dist.poisson_pmf(3.0, 0.0) != 0.0 { return 34; }
  if !_isnan(dist.poisson_pmf(-1.0, 0.0)) { return 35; }
  if !_near(dist.poisson_pmf(2.0, 1.0), 0.18393972058572117, 1e-12) { return 36; }
  if !_near(dist.binomial_pmf(2.0, 5.0, 0.5), 0.3125, 1e-12) { return 37; }
  if !_isnan(dist.binomial_pmf(6.0, 5.0, 0.5)) { return 38; }
  if !_isnan(dist.binomial_pmf(1.0, 5.0, 1.5)) { return 39; }
  if !_near(dist.geometric_pmf(1.0, 0.5), 0.5, 1e-12) { return 40; }
  if !_near(dist.geometric_pmf(3.0, 0.25), 0.140625, 1e-12) { return 41; }
  if !_isnan(dist.geometric_pmf(0.0, 0.5)) { return 42; }
  if !_isnan(dist.geometric_pmf(2.0, 0.0)) { return 43; }
  if !_isnan(dist.geometric_pmf(2.0, 1.5)) { return 44; }

  // ---- dist: continuous -------------------------------------------------
  if dist.chi_squared_pdf(0.0, 2.0) != 0.5 { return 45; }
  if dist.chi_squared_pdf(0.0, 1.0) != inf { return 46; }
  if dist.chi_squared_pdf(0.0, 3.0) != 0.0 { return 47; }
  if !_isnan(dist.chi_squared_pdf(-1.0, 2.0)) { return 48; }
  if !_isnan(dist.chi_squared_pdf(1.0, 0.0)) { return 49; }
  if !_near(dist.student_t_pdf(0.0, 1.0), 0.3183098861837907, 1e-12) { return 50; }
  if !_isnan(dist.student_t_pdf(0.0, 0.0)) { return 51; }
  if !_isnan(dist.student_t_pdf(0.0, -1.0)) { return 52; }
  if !_near(dist.beta_pdf(0.5, 2.0, 3.0), 1.5, 1e-12) { return 53; }
  if dist.beta_pdf(0.0, 2.0, 3.0) != 0.0 { return 54; }
  if dist.beta_pdf(1.0, 2.0, 3.0) != 0.0 { return 55; }
  if !_isnan(dist.beta_pdf(0.5, 0.0, 3.0)) { return 56; }
  if !_isnan(dist.beta_pdf(0.5, 2.0, 0.0)) { return 57; }

  // ---- dist: samplers ---------------------------------------------------
  if _isnan(dist.sample_normal(0.0, 1.0)) { return 58; }
  if !_isnan(dist.sample_normal(0.0, 0.0)) { return 59; }
  if !_isnan(dist.sample_normal(0.0, -1.0)) { return 60; }
  var su = dist.sample_uniform(0.0, 1.0);
  if su < 0.0 || su > 1.0 { return 61; }
  var su2 = dist.sample_uniform(-1.0, 1.0);
  if su2 < -1.0 || su2 > 1.0 { return 62; }
  if !_isnan(dist.sample_uniform(2.0, 1.0)) { return 63; }

  // ---- histogram: construction/shape ------------------------------------
  let h4 = histogram.histogram_new(4, 0.0, 4.0);
  if h4.bins != 4 { return 64; }
  if h4.min != 0.0 || h4.max != 4.0 { return 65; }
  if histogram.histogram_counts(h4).len() != 4 { return 66; }
  let h0 = histogram.histogram_new(0, 0.0, 4.0);
  if histogram.histogram_counts(h0).len() != 0 { return 67; }
  let hbad = histogram.histogram_new(4, 4.0, 0.0);
  if histogram.histogram_counts(hbad).len() != 0 { return 68; }
  let hneg = histogram.histogram_new(0 - 2, 0.0, 4.0);
  if histogram.histogram_counts(hneg).len() != 0 { return 69; }

  // ---- histogram: edges/normalize/mode ----------------------------------
  let e4 = histogram.histogram_edges(h4);
  if e4.len() != 5 { return 70; }
  if e4[0] != 0.0 || e4[4] != 4.0 { return 71; }
  if histogram.histogram_edges(h0).len() != 0 { return 72; }
  if histogram.histogram_edges(hbad).len() != 0 { return 73; }
  if histogram.histogram_normalize(h4).len() != 0 { return 74; }
  if histogram.histogram_normalize(h0).len() != 0 { return 75; }
  if histogram.histogram_mode(h4) != 0 { return 76; }
  if histogram.histogram_mode(h0) != -1 { return 77; }

  // ---- histogram: statistics (empty counts / zero total) ----------------
  if !_isnan(histogram.histogram_mean(h0)) { return 78; }
  if !_isnan(histogram.histogram_mean(h4)) { return 79; }
  if !_isnan(histogram.histogram_variance(h0)) { return 80; }
  if !_isnan(histogram.histogram_variance(h4)) { return 81; }
  if !_isnan(histogram.histogram_quantile(h0, 0.5)) { return 82; }
  if !_isnan(histogram.histogram_quantile(h4, 0.5)) { return 83; }
  if !_isnan(histogram.histogram_quantile(h4, -0.1)) { return 84; }
  if !_isnan(histogram.histogram_quantile(h4, 1.1)) { return 85; }

  // ---- histogram: merge -------------------------------------------------
  let h4m = histogram.histogram_merge(h4, h4);
  if h4m.bins != 4 || h4m.min != 0.0 || h4m.max != 4.0 { return 86; }
  if histogram.histogram_counts(h4m).len() != 4 { return 87; }
  let h2 = histogram.histogram_new(2, 0.0, 2.0);
  let h3 = histogram.histogram_new(3, 0.0, 3.0);
  let mm = histogram.histogram_merge(h2, h3);
  if mm.bins != 2 || mm.min != 0.0 || mm.max != 2.0 { return 88; }
  if histogram.histogram_counts(mm).len() != 2 { return 89; }
  // histogram_add takes the histogram by value (mutation discarded).
  histogram.histogram_add(h4, 1.0);

  // ---- moments: inputs --------------------------------------------------
  var d4 = Vec[Float64].new();
  d4.push(1.0);
  d4.push(2.0);
  d4.push(3.0);
  d4.push(4.0);
  var drev = Vec[Float64].new();
  drev.push(4.0);
  drev.push(3.0);
  drev.push(2.0);
  drev.push(1.0);
  var d1 = Vec[Float64].new();
  d1.push(7.0);
  var de = Vec[Float64].new();
  var dnan = Vec[Float64].new();
  dnan.push(nan);
  dnan.push(1.0);
  var d01 = Vec[Float64].new();
  d01.push(0.0);
  d01.push(1.0);
  var dneg = Vec[Float64].new();
  dneg.push(1.0);
  dneg.push(-1.0);
  var d3 = Vec[Float64].new();
  d3.push(3.0);
  d3.push(1.0);
  d3.push(2.0);

  // ---- moments: central tendency ----------------------------------------
  if moments.mean(&de) != 0.0 { return 90; }
  if !_near(moments.mean(&d4), 2.5, 1e-12) { return 91; }
  if !_near(moments.median(&d4), 2.5, 1e-12) { return 92; }
  if !_near(moments.median(&d3), 2.0, 1e-12) { return 93; }
  if !_isnan(moments.median(&de)) { return 94; }
  if !_near(moments.quantile(&d4, 0.25), 1.75, 1e-12) { return 95; }
  if moments.quantile(&d4, 0.0) != 1.0 { return 96; }
  if moments.quantile(&d4, 1.0) != 4.0 { return 97; }
  if !_isnan(moments.quantile(&de, 0.5)) { return 98; }
  if !_isnan(moments.quantile(&d4, -0.5)) { return 99; }
  if !_isnan(moments.quantile(&d4, 1.5)) { return 100; }
  if !_near(moments.geometric_mean(&d4), 2.213363839400643, 1e-9) { return 101; }
  if !_isnan(moments.geometric_mean(&de)) { return 102; }
  if !_isnan(moments.geometric_mean(&d01)) { return 103; }
  if !_isnan(moments.geometric_mean(&dnan)) { return 104; }
  if !_near(moments.harmonic_mean(&d4), 1.92, 1e-9) { return 105; }
  if !_isnan(moments.harmonic_mean(&de)) { return 106; }
  if !_isnan(moments.harmonic_mean(&d01)) { return 107; }
  if !_near(moments.weighted_mean(&d4, &d4), 3.0, 1e-12) { return 108; }
  if !_isnan(moments.weighted_mean(&d4, &d1)) { return 109; }
  if !_isnan(moments.weighted_mean(&de, &de)) { return 110; }

  // ---- moments: dispersion ----------------------------------------------
  if moments.variance(&de) != 0.0 { return 111; }
  if moments.variance(&d1) != 0.0 { return 112; }
  if !_near(moments.variance(&d4), 5.0 / 3.0, 1e-12) { return 113; }
  if !_isnan(moments.variance(&dnan)) { return 114; }
  if moments.stddev(&d1) != 0.0 { return 115; }
  if !_near(moments.stddev(&d4), 1.2909944487358056, 1e-12) { return 116; }
  if !_isnan(moments.stddev(&dnan)) { return 117; }
  if !_near(moments.covariance(&d4, &d4), 5.0 / 3.0, 1e-12) { return 118; }
  if !_isnan(moments.covariance(&d4, &d1)) { return 119; }
  if moments.covariance(&de, &de) != 0.0 { return 120; }
  if !_isnan(moments.covariance(&dnan, &dnan)) { return 121; }

  // ---- moments: shape/moments -------------------------------------------
  if moments.skewness(&d4) != 0.0 { return 122; }
  if !_isnan(moments.skewness(&d1)) { return 123; }
  if !_near(moments.kurtosis(&d4), -1.36, 1e-12) { return 124; }
  if !_isnan(moments.kurtosis(&d1)) { return 125; }
  if !_near(moments.central_moment(&d4, 2), 1.25, 1e-12) { return 126; }
  if moments.central_moment(&d4, 3) != 0.0 { return 127; }
  if !_near(moments.central_moment(&d4, 4), 2.5625, 1e-12) { return 128; }
  if !_isnan(moments.central_moment(&de, 2)) { return 129; }
  if !_isnan(moments.central_moment(&d4, 1)) { return 130; }
  if !_near(moments.raw_moment(&d4, 1), 2.5, 1e-12) { return 131; }
  if !_near(moments.raw_moment(&d4, 2), 7.5, 1e-12) { return 132; }
  if !_isnan(moments.raw_moment(&de, 1)) { return 133; }
  if !_isnan(moments.raw_moment(&d4, 0)) { return 134; }
  if !_isnan(moments.raw_moment(&dnan, 2)) { return 135; }

  // ---- test: t/chi2/f ---------------------------------------------------
  if test.t_test_one_sample(&d4, 2.5) != 0.0 { return 136; }
  if !_isnan(test.t_test_one_sample(&d1, 0.0)) { return 137; }
  if !_isnan(test.t_test_one_sample(&de, 0.0)) { return 138; }
  if test.t_test_two_sample(&d4, &d4) != 0.0 { return 139; }
  if !_isnan(test.t_test_two_sample(&d1, &d4)) { return 140; }
  if test.t_test_paired(&d4, &drev) != 0.0 { return 141; }
  if !_isnan(test.t_test_paired(&d4, &d1)) { return 142; }
  if !_isnan(test.t_test_paired(&d1, &d1)) { return 143; }
  var obs = Vec[Int].new();
  obs.push(10);
  obs.push(20);
  var expd = Vec[Float64].new();
  expd.push(15.0);
  expd.push(15.0);
  var exp1 = Vec[Float64].new();
  exp1.push(15.0);
  var expz = Vec[Float64].new();
  expz.push(0.0);
  expz.push(15.0);
  if !_near(test.chi_squared_test(&obs, &expd), 10.0 / 3.0, 1e-9) { return 144; }
  if !_isnan(test.chi_squared_test(&obs, &exp1)) { return 145; }
  if !_isnan(test.chi_squared_test(&obs, &expz)) { return 146; }
  if !_near(test.f_test(&d4, &d4), 1.0, 1e-12) { return 147; }
  if !_isnan(test.f_test(&d1, &d4)) { return 148; }

  // ---- test: anova (compiler-stub mirror) -------------------------------
  var groups = Vec[Vec[Float64]].new();
  if !_isnan(test.anova_one_way(&groups)) { return 149; }

  // ---- test: p-values/z/errors ------------------------------------------
  if !_near(test.p_value_from_t(2.0, 10.0), 0.073389, 1e-4) { return 150; }
  if !_isnan(test.p_value_from_t(2.0, 0.0)) { return 151; }
  if !_isnan(test.p_value_from_t(nan, 5.0)) { return 152; }
  if test.p_value_from_chi2(0.0, 1.0) != 1.0 { return 153; }
  if !_near(test.p_value_from_chi2(3.84, 1.0), 0.05, 0.01) { return 154; }
  if !_isnan(test.p_value_from_chi2(1.0, 0.0)) { return 155; }
  if !_isnan(test.p_value_from_chi2(-1.0, 1.0)) { return 156; }
  if test.z_score(3.0, 2.5, 0.5) != 1.0 { return 157; }
  if !_isnan(test.z_score(1.0, 1.0, 0.0)) { return 158; }
  if !_near(test.standard_error(&d4), 0.6454972243679028, 1e-12) { return 159; }
  if !_isnan(test.standard_error(&d1)) { return 160; }
  let ci = test.confidence_interval(&d4, 0.95);
  if _isnan(ci.0) || _isnan(ci.1) { return 161; }
  if ci.0 >= 2.5 || ci.1 <= 2.5 { return 162; }
  if ci.1 < ci.0 { return 163; }
  let c1 = test.confidence_interval(&d1, 0.95);
  if !_isnan(c1.0) || !_isnan(c1.1) { return 164; }
  let c0 = test.confidence_interval(&d4, 0.0);
  if !_isnan(c0.0) || !_isnan(c0.1) { return 165; }
  let c0b = test.confidence_interval(&d4, 1.0);
  if !_isnan(c0b.0) || !_isnan(c0b.1) { return 166; }
  let c0c = test.confidence_interval(&d4, 1.5);
  if !_isnan(c0c.0) || !_isnan(c0c.1) { return 167; }

  return 0;
}
