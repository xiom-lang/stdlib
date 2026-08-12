// Smoke: all xiom.stats sublibs (moments, statistics, regress, dist,
// probability, test, histogram). Returns 0 on success.
use xiom.stats;
use xiom.io;
use xiom.core.to_int;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn main() -> Int {
  var data = Vec[Float64].new();
  data.push(1.0);
  data.push(2.0);
  data.push(3.0);
  data.push(4.0);

  // ---- moments ----
  if !near(stats.moments.mean(&data), 2.5, 1e-12) { io.println("mean"); return 1; }
  if !near(stats.moments.variance(&data), 5.0 / 3.0, 1e-9) { io.println("variance"); return 2; }
  if !near(stats.moments.stddev(&data), 1.2909944487, 1e-6) { io.println("stddev"); return 3; }
  if !near(stats.moments.median(&data), 2.5, 1e-12) { io.println("median"); return 4; }
  if !near(stats.moments.quantile(&data, 0.25), 1.75, 1e-12) { io.println("quantile"); return 5; }
  if !near(stats.moments.covariance(&data, &data), 5.0 / 3.0, 1e-9) { io.println("cov"); return 6; }
  if !near(stats.moments.weighted_mean(&data, &data), 3.0, 1e-9) { io.println("wmean"); return 7; }

  // ---- statistics ----
  if !near(stats.statistics.mean(&data), 2.5, 1e-12) { io.println("mean2"); return 8; }
  if !near(stats.statistics.median(&data), 2.5, 1e-12) { io.println("median2"); return 9; }
  if !near(stats.statistics.variance(&data), 5.0 / 3.0, 1e-9) { io.println("var2"); return 10; }
  if !near(stats.statistics.variance_pop(&data), 1.25, 1e-9) { io.println("varpop"); return 11; }
  if !near(stats.statistics.stddev(&data), 1.2909944487, 1e-6) { io.println("std2"); return 12; }
  if stats.statistics.range(&data) != 3.0 { io.println("range"); return 13; }
  if !near(stats.statistics.percentile(&data, 50.0), 2.5, 1e-12) { io.println("percentile"); return 14; }
  if !near(stats.statistics.correlation(&data, &data), 1.0, 1e-9) { io.println("corr"); return 15; }
  if !near(stats.statistics.rms(&data), 2.7386127875, 1e-6) { io.println("rms"); return 16; }
  if !near(stats.statistics.mad(&data), 1.0, 1e-9) { io.println("mad"); return 17; }
  var m1 = stats.statistics.mode(&data);
  var m1v = -1.0;
  match m1 {
    Some(v) => { m1v = v; },
    None => { m1v = -2.0; },
  }
  if !near(m1v, 1.0, 1e-12) { io.println("mode"); return 18; }
  if !near(stats.statistics.spearman_correlation(&data, &data), 1.0, 1e-9) { io.println("spearman"); return 19; }
  if !near(stats.statistics.kendall_correlation(&data, &data), 1.0, 1e-9) { io.println("kendall"); return 20; }
  if !near(stats.statistics.z_score(3.0, 2.5, 0.5), 1.0, 1e-9) { io.println("zscore"); return 21; }
  var qts = stats.statistics.quartiles(&data);
  if qts.len() != 3 { io.println("quartiles"); return 22; }
  if !near(qts[1], 2.5, 1e-12) { io.println("quartiles-q2"); return 23; }
  var trimmed = stats.statistics.trimmed_mean(&data, 0.1);
  if trimmed != trimmed { io.println("trimmed"); return 24; }
  if !near(stats.statistics.geometric_mean(&data), 2.2133638394, 1e-6) { io.println("gmean"); return 25; }

  // ---- regress ----
  var xs = Vec[Float64].new();
  xs.push(0.0);
  xs.push(1.0);
  xs.push(2.0);
  var ys = Vec[Float64].new();
  ys.push(1.0);
  ys.push(3.0);
  ys.push(5.0);
  if !near(stats.regress.slope(&xs, &ys), 2.0, 1e-9) { io.println("slope"); return 26; }
  if !near(stats.regress.intercept(&xs, &ys), 1.0, 1e-9) { io.println("intercept"); return 27; }
  if !near(stats.regress.r_squared(&xs, &ys), 1.0, 1e-9) { io.println("r2"); return 28; }
  if !near(stats.regress.pearson_correlation(&xs, &ys), 1.0, 1e-9) { io.println("pearson"); return 29; }
  var lr = stats.regress.linear_regression(&xs, &ys);
  if !near(lr.slope, 2.0, 1e-9) { io.println("lr"); return 30; }
  if !near(lr.intercept, 1.0, 1e-9) { io.println("lr2"); return 31; }
  var pr = stats.regress.polynomial_regression(&xs, &ys, 1);
  if pr.len() != 2 { io.println("poly"); return 32; }
  if !near(pr[0], 1.0, 1e-9) || !near(pr[1], 2.0, 1e-9) { io.println("poly2"); return 33; }
  if !near(stats.regress.predict_line(2.0, 1.0, 3.0), 7.0, 1e-12) { io.println("predict"); return 34; }
  var res = stats.regress.residuals(&xs, &ys, 2.0, 1.0);
  if res.len() != 3 { io.println("residuals"); return 35; }
  var ef = stats.regress.exponential_fit(&xs, &ys);
  if ef.0 != ef.0 { io.println("expfit"); return 36; }

  // ---- dist ----
  if !near(stats.dist.normal_pdf(0.0, 0.0, 1.0), 0.3989422804, 1e-6) { io.println("npdf"); return 37; }
  if !near(stats.dist.normal_cdf(0.0, 0.0, 1.0), 0.5, 1e-9) { io.println("ncdf"); return 38; }
  if !near(stats.dist.normal_ppf(0.5, 0.0, 1.0), 0.0, 1e-6) { io.println("ppf"); return 39; }
  if !near(stats.dist.uniform_pdf(1.5, 0.0, 3.0), 1.0 / 3.0, 1e-9) { io.println("updf"); return 40; }
  if !near(stats.dist.exponential_cdf(1.0, 1.0), 0.6321205588, 1e-6) { io.println("expcdf"); return 41; }
  if !near(stats.dist.poisson_pmf(2.0, 1.0), 0.1839397206, 1e-6) { io.println("poisson"); return 42; }
  var sn = stats.dist.sample_uniform(0.0, 1.0);
  if sn < 0.0 || sn > 1.0 { io.println("sample-u"); return 43; }

  // ---- probability ----
  if !near(stats.probability.normal_cdf(0.0, 0.0, 1.0), 0.5, 1e-9) { io.println("pncdf"); return 44; }
  if !near(stats.probability.gamma_cdf(2.0, 2.0, 1.0), 0.59399415, 1e-4) { io.println("gammacdf"); return 45; }
  if !near(stats.probability.beta_cdf(0.5, 2.0, 3.0), 0.6875, 1e-9) { io.println("betacdf"); return 46; }
  if !near(stats.probability.t_cdf(0.0, 5.0), 0.5, 1e-9) { io.println("tcdf"); return 47; }
  if !near(stats.probability.chi2_cdf(1.0, 1.0), 0.6826894921, 1e-4) { io.println("chi2cdf"); return 48; }
  var pmf = stats.probability.binomial_pmf(2, 5, 0.5);
  if !near(pmf, 0.3125, 1e-9) { io.println("binpmf"); return 49; }
  var bcdf = stats.probability.binomial_cdf(2, 5, 0.5);
  if !near(bcdf, 0.5, 1e-9) { io.println("bincdf"); return 50; }
  if !near(stats.probability.poisson_pmf(1, 1.0), 0.3678794412, 1e-6) { io.println("ppmf"); return 51; }
  if !near(stats.probability.geometric_pmf(3, 0.25), 0.140625, 1e-9) { io.println("geopmf"); return 52; }
  if !near(stats.probability.weibull_cdf(1.0, 2.0, 1.0), 0.6321205588, 1e-6) { io.println("weibull"); return 53; }
  if !near(stats.probability.lognormal_cdf(1.0, 0.0, 1.0), 0.5, 1e-9) { io.println("lognormal"); return 54; }
  if !near(stats.probability.pareto_cdf(2.0, 1.0, 1.0), 0.5, 1e-9) { io.println("pareto"); return 55; }
  if !near(stats.probability.f_cdf(1.0, 2.0, 3.0), 0.535242, 1e-4) { io.println("fcdf"); return 56; }

  // ---- test ----
  if !near(stats.test.t_test_one_sample(&data, 2.5), 0.0, 1e-9) { io.println("t1"); return 57; }
  var t2 = stats.test.t_test_two_sample(&data, &data);
  if !near(t2, 0.0, 1e-9) { io.println("t2"); return 58; }
  var pa = Vec[Float64].new();
  pa.push(2.0);
  pa.push(1.0);
  pa.push(4.0);
  pa.push(3.0);
  var tp = stats.test.t_test_paired(&data, &pa);
  if !near(tp, 0.0, 1e-9) { io.println("tp"); return 59; }
  var obs = Vec[Int].new();
  obs.push(10);
  obs.push(20);
  var exp = Vec[Float64].new();
  exp.push(15.0);
  exp.push(15.0);
  if !near(stats.test.chi_squared_test(&obs, &exp), 10.0 / 3.0, 1e-9) { io.println("chi2test"); return 60; }
  var ft = stats.test.f_test(&data, &data);
  if !near(ft, 1.0, 1e-9) { io.println("ftest"); return 61; }
  if !near(stats.test.p_value_from_t(2.0, 10.0), 0.073389, 1e-4) { io.println("pvt"); return 62; }
  if !near(stats.test.p_value_from_chi2(3.84, 1.0), 0.05, 0.01) { io.println("pvchi2"); return 63; }
  if !near(stats.test.z_score(3.0, 2.5, 0.5), 1.0, 1e-9) { io.println("z"); return 64; }
  if !near(stats.test.standard_error(&data), 0.6454972244, 1e-6) { io.println("se"); return 65; }
  var ci = stats.test.confidence_interval(&data, 0.95);
  if ci.0 > 1.0 || ci.1 < 4.0 { io.println("ci"); return 66; }

  // ---- histogram ----
  var h = stats.histogram.histogram_new(4, 0.0, 4.0);
  var edges = stats.histogram.histogram_edges(h);
  if edges.len() != 5 { io.println("hedges"); return 67; }
  if edges[0] != 0.0 || edges[4] != 4.0 { io.println("hedges2"); return 68; }
  var cnts = stats.histogram.histogram_counts(h);
  if cnts.len() != 4 { io.println("hcounts"); return 69; }
  if stats.histogram.histogram_mode(h) != 0 { io.println("hmode"); return 70; }
  var merged = stats.histogram.histogram_merge(h, h);
  var mc = stats.histogram.histogram_counts(merged);
  if mc.len() != 4 { io.println("hmerge"); return 71; }
  var norm = stats.histogram.histogram_normalize(h);
  if norm.len() != 0 { io.println("hnorm"); return 72; }
  // histogram_add takes the histogram by value (XIOM move semantics); the
  // mutation is discarded by the frozen void signature.
  stats.histogram.histogram_add(h, 1.0);

  io.println("smoke_stats: OK");
  return 0;
}
