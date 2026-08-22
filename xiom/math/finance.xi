// XIOM - Math: Finance
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.finance

// Depends on: xiom.math

// ============================================================================
// Time value of money, bonds, options, and portfolio risk analytics.
//
// Sign conventions follow Excel/Numpy: outflows are negative, inflows
// positive; pv/fv/pmt return the payment/principal that satisfies the annuity
// identity. Rates are per-period (annual unless freq says otherwise) and
// returns are decimals (0.05 = 5%). Convergence methods carry explicit
// iteration caps; domain errors return IEEE NaN (0.0/0.0). Complexity is
// documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;

const _SQRT_2PI: Float64 = 2.5066282746310002;

// Standard normal CDF N(x) = 0.5 (1 + erf(x / sqrt(2))). Complexity: O(1).
fn _ncdf(x: Float64) -> Float64 {
  var a = x / 1.4142135623730951;
  var e = math.special.erf(a);
  return 0.5 * (1.0 + e);
}

// Standard normal density phi(x) = exp(-x^2/2)/sqrt(2 pi). Complexity: O(1).
fn _nphi(x: Float64) -> Float64 {
  var e = math.exp(-0.5 * x * x);
  return e / _SQRT_2PI;
}

// Present value of an annuity and lump sum: PV = -(FV + pmt*((1+r)^n-1)/r)
// / (1+r)^n. r == 0 uses PV = -(FV + pmt*n). Complexity: O(1).
pub fn pv(rate: Float64, nper: Float64, pmt: Float64, fv: Float64) -> Float64 {
  if rate == 0.0 {
    return -(fv + pmt * nper);
  }
  var f = math.pow(1.0 + rate, nper);
  var a = (fv + pmt * (f - 1.0) / rate) / f;
  return -a;
}

// Future value of an annuity and lump sum: FV = PV (1+r)^n + pmt*((1+r)^n-1)
// / r. r == 0 uses FV = PV + pmt*n. Complexity: O(1).
pub fn fv(rate: Float64, nper: Float64, pmt: Float64, pv: Float64) -> Float64 {
  if rate == 0.0 {
    return pv + pmt * nper;
  }
  var f = math.pow(1.0 + rate, nper);
  return pv * f + pmt * (f - 1.0) / rate;
}

// Net present value of a cashflow series discounted from t = 0 (the first
// element is the undiscounted cashflow at time zero). Complexity: O(n).
pub fn npv(rate: Float64, cashflows: &Vec[Float64]) -> Float64 {
  var sum = 0.0;
  var i = 0;
  while i < cashflows.len() {
    var d = math.pow(1.0 + rate, i as Float64);
    sum = sum + cashflows[i] / d;
    i = i + 1;
  }
  return sum;
}

// Internal rate of return: the rate r with npv(r, cashflows) == 0, found by
// bisection over [-0.99, 10] (200 iterations). NaN when no sign change exists.
// Complexity: O(iters * n).
pub fn irr(cashflows: &Vec[Float64]) -> Float64 {
  var lo = -0.99;
  var hi = 10.0;
  var f_lo = npv(lo, cashflows);
  var f_hi = npv(hi, cashflows);
  if f_lo * f_hi > 0.0 { return 0.0 / 0.0; }
  var it = 0;
  while it < 200 {
    var mid = 0.5 * (lo + hi);
    var f_mid = npv(mid, cashflows);
    if math.abs_float(f_mid) < 1.0e-12 { return mid; }
    if f_lo * f_mid < 0.0 {
      hi = mid;
      f_hi = f_mid;
    } else {
      lo = mid;
      f_lo = f_mid;
    }
    it = it + 1;
  }
  return 0.5 * (lo + hi);
}

// Modified internal rate of return: MIRR = ((FV_positive / PV_negative)^(1/n)
// - 1) where positive cashflows compound at reinvest_rate and negative ones
// discount at finance_rate. NaN when no negative cashflow exists.
// Complexity: O(n).
pub fn mirr(cashflows: &Vec[Float64], finance_rate: Float64, reinvest_rate: Float64) -> Float64 {
  var n = cashflows.len();
  if n == 0 { return 0.0 / 0.0; }
  var pv_neg = 0.0;
  var fv_pos = 0.0;
  var i = 0;
  while i < n {
    var t = (n - 1 - i) as Float64;
    if cashflows[i] < 0.0 {
      pv_neg = pv_neg + cashflows[i] / math.pow(1.0 + finance_rate, t);
    } else {
      fv_pos = fv_pos + cashflows[i] * math.pow(1.0 + reinvest_rate, t);
    }
    i = i + 1;
  }
  if pv_neg == 0.0 { return 0.0 / 0.0; }
  var v = fv_pos / (-pv_neg);
  if v <= 0.0 { return 0.0 / 0.0; }
  var e = math.pow(v, 1.0 / ((n - 1) as Float64));
  return e - 1.0;
}

// Periodic payment of an annuity: pmt = (fv - pv (1+r)^n) r / ((1+r)^n - 1);
// r == 0 uses (fv - pv)/n. Complexity: O(1).
pub fn pmt(rate: Float64, nper: Float64, pv: Float64, fv: Float64) -> Float64 {
  if nper == 0.0 { return 0.0 / 0.0; }
  if rate == 0.0 {
    return (fv - pv) / nper;
  }
  var f = math.pow(1.0 + rate, nper);
  var denom = f - 1.0;
  if denom == 0.0 { return 0.0 / 0.0; }
  return (fv - pv * f) * rate / denom;
}

// Interest portion of the payment in period per (1-based) for a loan of pv
// amortized at rate over nper periods (fv = 0). Complexity: O(per).
pub fn ipmt(rate: Float64, per: Int, nper: Float64, pv: Float64) -> Float64 {
  if per < 1 { return 0.0 / 0.0; }
  var p = pmt(rate, nper, pv, 0.0);
  if rate == 0.0 { return 0.0; }
  var f = math.pow(1.0 + rate, (per - 1) as Float64);
  var bal = pv * f + p * (f - 1.0) / rate;
  return bal * rate;
}

// Principal portion of the payment in period per. Complexity: O(per).
pub fn ppmt(rate: Float64, per: Int, nper: Float64, pv: Float64) -> Float64 {
  var p = pmt(rate, nper, pv, 0.0);
  var ip = ipmt(rate, per, nper, pv);
  return p - ip;
}

// Number of periods to reach fv from pv paying pmt per period:
// n = ln((pmt - fv r) / (pmt + pv r)) / ln(1 + r). Complexity: O(1).
pub fn nper(rate: Float64, pmt: Float64, pv: Float64, fv: Float64) -> Float64 {
  if rate == 0.0 {
    var d = pmt;
    if d == 0.0 { return 0.0 / 0.0; }
    return -(pv + fv) / d;
  }
  var num = pmt - fv * rate;
  var den = pmt + pv * rate;
  if num <= 0.0 || den <= 0.0 { return 0.0 / 0.0; }
  var l1 = math.ln(num);
  var l2 = math.ln(den);
  return (l1 - l2) / math.ln(1.0 + rate);
}

// Interest rate implied by an annuity: bisection on the fv identity over
// [-0.999, 10] (200 iterations). NaN when no root exists. Complexity: O(200).
pub fn rate(nper: Float64, pmt: Float64, pv: Float64, fv: Float64) -> Float64 {
  var lo = -0.999;
  var hi = 10.0;
  var f_lo = fv(lo, nper, pmt, pv);
  var f_hi = fv(hi, nper, pmt, pv);
  var target = fv;
  if (f_lo - target) * (f_hi - target) > 0.0 { return 0.0 / 0.0; }
  var it = 0;
  while it < 200 {
    var mid = 0.5 * (lo + hi);
    var f_mid = fv(mid, nper, pmt, pv);
    if math.abs_float(f_mid - target) < 1.0e-12 { return mid; }
    if (f_lo - target) * (f_mid - target) < 0.0 {
      hi = mid;
      f_hi = f_mid;
    } else {
      lo = mid;
      f_lo = f_mid;
    }
    it = it + 1;
  }
  return 0.5 * (lo + hi);
}

// Present value of a level annuity paying pmt for nper periods at rate.
// Complexity: O(1).
pub fn annuity(rate: Float64, nper: Float64, pmt: Float64) -> Float64 {
  if rate == 0.0 {
    return pmt * nper;
  }
  var f = math.pow(1.0 + rate, -nper);
  return pmt * (1.0 - f) / rate;
}

// Present value of a level perpetuity pmt / rate. NaN for rate <= 0.
// Complexity: O(1).
pub fn perpetuity(pmt: Float64, rate: Float64) -> Float64 {
  if rate <= 0.0 { return 0.0 / 0.0; }
  return pmt / rate;
}

// Price of a coupon bond with face, annual coupon rate, yield to maturity,
// n years and freq coupons per year. Complexity: O(n * freq).
pub fn bond_price(face: Float64, coupon: Float64, ytm: Float64, n: Int, freq: Int) -> Float64 {
  if face <= 0.0 || freq <= 0 { return 0.0 / 0.0; }
  var periods = n * freq;
  var c = coupon * face / (freq as Float64);
  var y = ytm / (freq as Float64);
  var price = 0.0;
  var k = 1;
  while k <= periods {
    price = price + c / math.pow(1.0 + y, k as Float64);
    k = k + 1;
  }
  price = price + face / math.pow(1.0 + y, periods as Float64);
  return price;
}

// Yield to maturity of a coupon bond, found by bisection on the price
// equation over [-0.999, 10] (200 iterations). NaN when no root exists.
// Complexity: O(200 * n * freq).
pub fn bond_yield(face: Float64, coupon: Float64, price: Float64, n: Int, freq: Int) -> Float64 {
  var lo = -0.999;
  var hi = 10.0;
  var f_lo = bond_price(face, coupon, lo, n, freq);
  var f_hi = bond_price(face, coupon, hi, n, freq);
  if (f_lo - price) * (f_hi - price) > 0.0 { return 0.0 / 0.0; }
  var it = 0;
  while it < 200 {
    var mid = 0.5 * (lo + hi);
    var f_mid = bond_price(face, coupon, mid, n, freq);
    if math.abs_float(f_mid - price) < 1.0e-10 { return mid; }
    if (f_lo - price) * (f_mid - price) < 0.0 {
      hi = mid;
      f_hi = f_mid;
    } else {
      lo = mid;
      f_lo = f_mid;
    }
    it = it + 1;
  }
  return 0.5 * (lo + hi);
}

// Macaulay duration of a coupon bond (years). Complexity: O(n * freq).
pub fn duration(face: Float64, coupon: Float64, ytm: Float64, n: Int, freq: Int) -> Float64 {
  if face <= 0.0 || freq <= 0 { return 0.0 / 0.0; }
  var periods = n * freq;
  var c = coupon * face / (freq as Float64);
  var y = ytm / (freq as Float64);
  var price = 0.0;
  var num = 0.0;
  var k = 1;
  while k <= periods {
    var pv = c / math.pow(1.0 + y, k as Float64);
    price = price + pv;
    num = num + (k as Float64) * pv;
    k = k + 1;
  }
  var pvface = face / math.pow(1.0 + y, periods as Float64);
  price = price + pvface;
  num = num + (periods as Float64) * pvface;
  if price == 0.0 { return 0.0 / 0.0; }
  return num / price / (freq as Float64);
}

// Convexity of a coupon bond (years squared). Complexity: O(n * freq).
pub fn convexity(face: Float64, coupon: Float64, ytm: Float64, n: Int, freq: Int) -> Float64 {
  if face <= 0.0 || freq <= 0 { return 0.0 / 0.0; }
  var periods = n * freq;
  var c = coupon * face / (freq as Float64);
  var y = ytm / (freq as Float64);
  var price = 0.0;
  var num = 0.0;
  var k = 1;
  while k <= periods {
    var pv = c / math.pow(1.0 + y, k as Float64);
    price = price + pv;
    num = num + (k as Float64) * (k as Float64 + 1.0) * pv;
    k = k + 1;
  }
  var pvface = face / math.pow(1.0 + y, periods as Float64);
  price = price + pvface;
  num = num + (periods as Float64) * (periods as Float64 + 1.0) * pvface;
  if price == 0.0 { return 0.0 / 0.0; }
  return num / (price * math.pow(1.0 + y, 2.0)) / (freq as Float64 * freq as Float64);
}

// Black-Scholes price of a European call. Complexity: O(1).
pub fn option_call(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 {
  if s <= 0.0 || k <= 0.0 || t < 0.0 || sigma <= 0.0 { return 0.0 / 0.0; }
  if t == 0.0 {
    var payoff = s - k;
    if payoff < 0.0 { payoff = 0.0; }
    return payoff;
  }
  var st = sigma * math.sqrt(t);
  var d1 = (math.ln(s / k) + (r + 0.5 * sigma * sigma) * t) / st;
  var d2 = d1 - st;
  var n1 = _ncdf(d1);
  var n2 = _ncdf(d2);
  var df = math.exp(-r * t);
  return s * n1 - k * df * n2;
}

// Black-Scholes price of a European put. Complexity: O(1).
pub fn option_put(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 {
  if s <= 0.0 || k <= 0.0 || t < 0.0 || sigma <= 0.0 { return 0.0 / 0.0; }
  if t == 0.0 {
    var payoff = k - s;
    if payoff < 0.0 { payoff = 0.0; }
    return payoff;
  }
  var st = sigma * math.sqrt(t);
  var d1 = (math.ln(s / k) + (r + 0.5 * sigma * sigma) * t) / st;
  var d2 = d1 - st;
  var df = math.exp(-r * t);
  var nmd1 = _ncdf(-d1);
  var nmd2 = _ncdf(-d2);
  return k * df * nmd2 - s * nmd1;
}

// Delta of a European call: N(d1). Complexity: O(1).
pub fn option_call_delta(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 {
  if s <= 0.0 || k <= 0.0 || t < 0.0 || sigma <= 0.0 { return 0.0 / 0.0; }
  if t == 0.0 {
    if s > k { return 1.0; }
    return 0.0;
  }
  var st = sigma * math.sqrt(t);
  var d1 = (math.ln(s / k) + (r + 0.5 * sigma * sigma) * t) / st;
  return _ncdf(d1);
}

// Delta of a European put: N(d1) - 1. Complexity: O(1).
pub fn option_put_delta(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 {
  var d = option_call_delta(s, k, t, r, sigma);
  return d - 1.0;
}

// Gamma of a European option: phi(d1) / (S sigma sqrt(T)). Complexity: O(1).
pub fn option_gamma(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 {
  if s <= 0.0 || k <= 0.0 || t <= 0.0 || sigma <= 0.0 { return 0.0 / 0.0; }
  var st = sigma * math.sqrt(t);
  var d1 = (math.ln(s / k) + (r + 0.5 * sigma * sigma) * t) / st;
  var denom = s * st;
  if denom == 0.0 { return 0.0 / 0.0; }
  return _nphi(d1) / denom;
}

// Theta of a European call (per year): -(S phi(d1) sigma)/(2 sqrt(T))
// - r K e^{-rT} N(d2). Complexity: O(1).
pub fn option_theta(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 {
  if s <= 0.0 || k <= 0.0 || t <= 0.0 || sigma <= 0.0 { return 0.0 / 0.0; }
  var st = sigma * math.sqrt(t);
  var d1 = (math.ln(s / k) + (r + 0.5 * sigma * sigma) * t) / st;
  var d2 = d1 - st;
  var df = math.exp(-r * t);
  var t1 = -(s * _nphi(d1) * sigma) / (2.0 * math.sqrt(t));
  var t2 = -r * k * df * _ncdf(d2);
  return t1 + t2;
}

// Vega of a European option: S phi(d1) sqrt(T) / 100 (per 1% volatility).
// Complexity: O(1).
pub fn option_vega(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 {
  if s <= 0.0 || k <= 0.0 || t < 0.0 || sigma <= 0.0 { return 0.0 / 0.0; }
  if t == 0.0 { return 0.0; }
  var st = sigma * math.sqrt(t);
  var d1 = (math.ln(s / k) + (r + 0.5 * sigma * sigma) * t) / st;
  return s * _nphi(d1) * math.sqrt(t) / 100.0;
}

// Rho of a European call: K T e^{-rT} N(d2) / 100. Complexity: O(1).
pub fn option_rho(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 {
  if s <= 0.0 || k <= 0.0 || t < 0.0 || sigma <= 0.0 { return 0.0 / 0.0; }
  if t == 0.0 { return 0.0; }
  var st = sigma * math.sqrt(t);
  var d2 = (math.ln(s / k) + (r + 0.5 * sigma * sigma) * t) / st - st;
  var df = math.exp(-r * t);
  return k * t * df * _ncdf(d2) / 100.0;
}

// Black-Scholes implied volatility for a European call price, by Newton
// iteration (100 iterations from sigma = 0.2). NaN when no solution is found
// (e.g. an arbitrage-violating price). Complexity: O(100).
pub fn implied_volatility(market: Float64, s: Float64, k: Float64, t: Float64, r: Float64) -> Float64 {
  if s <= 0.0 || k <= 0.0 || t <= 0.0 { return 0.0 / 0.0; }
  var low = s - k * math.exp(-r * t);
  if low < 0.0 { low = 0.0; }
  if market < low { return 0.0 / 0.0; }
  var sigma = 0.2;
  var i = 0;
  while i < 100 {
    var price = option_call(s, k, t, r, sigma);
    var diff = price - market;
    if math.abs_float(diff) < 1.0e-10 { return sigma; }
    var vega = option_vega(s, k, t, r, sigma) * 100.0;
    if vega == 0.0 { return sigma; }
    sigma = sigma - diff / vega;
    if sigma <= 0.0 { sigma = 0.01; }
    if sigma > 5.0 { return 0.0 / 0.0; }
    i = i + 1;
  }
  return sigma;
}

// Compound annual growth rate (end/begin)^(1/years) - 1. NaN for years <= 0
// or non-positive begin. Complexity: O(1).
pub fn cagr(begin_value: Float64, end_value: Float64, years: Float64) -> Float64 {
  if begin_value <= 0.0 || years <= 0.0 { return 0.0 / 0.0; }
  var e = math.pow(end_value / begin_value, 1.0 / years);
  return e - 1.0;
}

// Sharpe ratio (mean(returns) - rf) / sample_stddev(returns). NaN for fewer
// than 2 returns. Complexity: O(n).
pub fn sharpe_ratio(returns: &Vec[Float64], rf: Float64) -> Float64 {
  var n = returns.len();
  if n < 2 { return 0.0 / 0.0; }
  var mean = 0.0;
  var i = 0;
  while i < n {
    mean = mean + returns[i];
    i = i + 1;
  }
  mean = mean / (n as Float64);
  var v = 0.0;
  var j = 0;
  while j < n {
    var d = returns[j] - mean;
    v = v + d * d;
    j = j + 1;
  }
  var std = math.sqrt(v / ((n - 1) as Float64));
  if std == 0.0 { return 0.0 / 0.0; }
  return (mean - rf) / std;
}

// Sortino ratio (mean(returns) - rf) / downside_deviation(returns, rf), where
// the downside deviation is the sqrt of the mean of squared returns below rf.
// NaN for fewer than 2 returns. Complexity: O(n).
pub fn sortino_ratio(returns: &Vec[Float64], rf: Float64) -> Float64 {
  var n = returns.len();
  if n < 2 { return 0.0 / 0.0; }
  var mean = 0.0;
  var i = 0;
  while i < n {
    mean = mean + returns[i];
    i = i + 1;
  }
  mean = mean / (n as Float64);
  var dv = 0.0;
  var count = 0;
  var j = 0;
  while j < n {
    var dd = returns[j] - rf;
    if dd < 0.0 {
      dv = dv + dd * dd;
      count = count + 1;
    }
    j = j + 1;
  }
  if count == 0 { return 0.0 / 0.0; }
  var downside = math.sqrt(dv / (count as Float64));
  if downside == 0.0 { return 0.0 / 0.0; }
  return (mean - rf) / downside;
}

// Calmar ratio annualized mean return / |max drawdown|. NaN for a zero
// drawdown or fewer than 2 returns. Complexity: O(n).
pub fn calmar_ratio(returns: &Vec[Float64], max_drawdown: Float64) -> Float64 {
  var n = returns.len();
  if n < 2 || max_drawdown == 0.0 { return 0.0 / 0.0; }
  var mean = 0.0;
  var i = 0;
  while i < n {
    mean = mean + returns[i];
    i = i + 1;
  }
  mean = mean / (n as Float64);
  var md = max_drawdown;
  if md < 0.0 { md = -md; }
  return mean / md;
}

// Insertion sort of a Float64 vector in ascending order.
fn _sort_asc(v: &mut Vec[Float64]) {
  var n = v.len();
  var i = 1;
  while i < n {
    var j = i;
    while j > 0 {
      if v[j] < v[j - 1] {
        var t = v[j];
        v[j] = v[j - 1];
        v[j - 1] = t;
        j = j - 1;
      } else {
        j = 0;
      }
    }
    i = i + 1;
  }
}

// Value at risk at confidence alpha: method 0 = historical quantile,
// method 1 = parametric (normal) quantile. Returns a positive loss.
// Complexity: O(n log n) historical / O(n) parametric.
pub fn var(returns: &Vec[Float64], alpha: Float64, method: Int) -> Float64 {
  var n = returns.len();
  if n == 0 { return 0.0 / 0.0; }
  if alpha <= 0.0 || alpha >= 1.0 { return 0.0 / 0.0; }
  if method == 1 {
    var mean = 0.0;
    var i = 0;
    while i < n {
      mean = mean + returns[i];
      i = i + 1;
    }
    mean = mean / (n as Float64);
    var v = 0.0;
    var j = 0;
    while j < n {
      var d = returns[j] - mean;
      v = v + d * d;
      j = j + 1;
    }
    var std = math.sqrt(v / ((n - 1) as Float64));
    var z = math.special.erfinv(2.0 * (1.0 - alpha) - 1.0);
    return -(mean + z * std);
  }
  var sorted = Vec[Float64].new();
  var k = 0;
  while k < n {
    sorted.push(returns[k]);
    k = k + 1;
  }
  _sort_asc(&mut sorted);
  var idx = to_int((1.0 - alpha) * (n as Float64));
  if idx < 0 { idx = 0; }
  if idx >= n { idx = n - 1; }
  return -(sorted[idx]);
}

// Conditional value at risk: mean of the returns below the alpha-VaR level.
// NaN for fewer than 1 tail observation. Complexity: O(n log n).
pub fn cvar(returns: &Vec[Float64], alpha: Float64) -> Float64 {
  var n = returns.len();
  if n == 0 { return 0.0 / 0.0; }
  if alpha <= 0.0 || alpha >= 1.0 { return 0.0 / 0.0; }
  var sorted = Vec[Float64].new();
  var i = 0;
  while i < n {
    sorted.push(returns[i]);
    i = i + 1;
  }
  _sort_asc(&mut sorted);
  var cutoff = sorted[to_int((1.0 - alpha) * (n as Float64))];
  var sum = 0.0;
  var count = 0;
  var j = 0;
  while j < n {
    if sorted[j] <= cutoff {
      sum = sum + sorted[j];
      count = count + 1;
    }
    j = j + 1;
  }
  if count == 0 { return 0.0 / 0.0; }
  return -sum / (count as Float64);
}

// Drawdown series of the returns (cumulative product minus 1, then
// peak-to-trough). Complexity: O(n).
pub fn drawdown(returns: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var equity = 1.0;
  var peak = 1.0;
  var i = 0;
  while i < returns.len() {
    equity = equity * (1.0 + returns[i]);
    if equity > peak {
      peak = equity;
    }
    var dd = equity / peak - 1.0;
    out.push(dd);
    i = i + 1;
  }
  return out;
}

// Systematic risk of an asset versus the market: covariance / market variance.
// NaN for fewer than 2 observations or zero market variance. Complexity: O(n).
pub fn beta(asset_returns: &Vec[Float64], market_returns: &Vec[Float64]) -> Float64 {
  var n = asset_returns.len();
  if n < 2 || market_returns.len() != n { return 0.0 / 0.0; }
  var ma = 0.0;
  var mm = 0.0;
  var i = 0;
  while i < n {
    ma = ma + asset_returns[i];
    mm = mm + market_returns[i];
    i = i + 1;
  }
  ma = ma / (n as Float64);
  mm = mm / (n as Float64);
  var cov = 0.0;
  var varm = 0.0;
  var j = 0;
  while j < n {
    cov = cov + (asset_returns[j] - ma) * (market_returns[j] - mm);
    varm = varm + (market_returns[j] - mm) * (market_returns[j] - mm);
    j = j + 1;
  }
  if varm == 0.0 { return 0.0 / 0.0; }
  return cov / varm;
}

// Jensen's alpha: mean(asset) - (rf + beta * (mean(market) - rf)).
// Complexity: O(n).
pub fn alpha(asset_returns: &Vec[Float64], market_returns: &Vec[Float64], rf: Float64) -> Float64 {
  var n = asset_returns.len();
  if n == 0 || market_returns.len() != n { return 0.0 / 0.0; }
  var ma = 0.0;
  var mm = 0.0;
  var i = 0;
  while i < n {
    ma = ma + asset_returns[i];
    mm = mm + market_returns[i];
    i = i + 1;
  }
  ma = ma / (n as Float64);
  mm = mm / (n as Float64);
  var b = beta(asset_returns, market_returns);
  return ma - (rf + b * (mm - rf));
}

// Treynor ratio (mean(returns) - rf) / beta. NaN for beta <= 0.
// Complexity: O(n).
pub fn treynor_ratio(returns: &Vec[Float64], beta: Float64, rf: Float64) -> Float64 {
  var n = returns.len();
  if n == 0 || beta <= 0.0 { return 0.0 / 0.0; }
  var mean = 0.0;
  var i = 0;
  while i < n {
    mean = mean + returns[i];
    i = i + 1;
  }
  mean = mean / (n as Float64);
  return (mean - rf) / beta;
}
