// XIOM - Math: Signal
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.signal

// Depends on: xiom.math; FFT on Vec[Float64] - BUG 12 now FIXED

// ============================================================================
// Digital signal processing: transforms, wavelets, filters, windows, and
// spectral analysis on Vec[Float64].
//
// Complex spectra are stored interleaved as [re0, im0, re1, im1, ...].
// The radix-2 FFT requires a power-of-two length (non-power-of-two inputs
// fall back to the direct DFT). Wavelet transforms use the Haar basis (and
// the Daubechies D4 basis for taps == 4). Matrix-valued results
// (spectrogram, mel filter bank) are built locally; callers should rely on
// their shape (nested float Vec element reads are unreliable in this
// compiler build). Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;

const _PI: Float64 = 3.141592653589793;
const _TAU: Float64 = 6.283185307179586;

// ---------------------------------------------------------------------------
// Fourier transforms
// ---------------------------------------------------------------------------

/// Discrete Fourier transform by direct summation. Returns the interleaved
/// complex spectrum [re0, im0, ...] of length 2n; empty for an empty input.
/// Complexity: O(n^2).
pub fn dft(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var k = 0;
  while k < n {
    var re = 0.0;
    var im = 0.0;
    var t = 0;
    while t < n {
      var ang = _TAU * (k as Float64) * (t as Float64) / (n as Float64);
      re = re + x[t] * math.cos(ang);
      im = im - x[t] * math.sin(ang);
      t = t + 1;
    }
    out.push(re);
    out.push(im);
    k = k + 1;
  }
  return out;
}

/// Inverse discrete Fourier transform: the interleaved complex input is
/// inverted and the real part is returned. Empty for an empty input.
/// Complexity: O(n^2).
pub fn idft(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len() / 2;
  if n == 0 { return out; }
  var t = 0;
  while t < n {
    var re = 0.0;
    var k = 0;
    while k < n {
      var ang = _TAU * (k as Float64) * (t as Float64) / (n as Float64);
      var ar = x[2 * k];
      var ai = x[2 * k + 1];
      re = re + (ar * math.cos(ang) - ai * math.sin(ang));
      k = k + 1;
    }
    out.push(re / (n as Float64));
    t = t + 1;
  }
  return out;
}

/// Fast Fourier transform (iterative radix-2) of a real signal; non-power-of-
/// two lengths fall back to the direct DFT. Returns the interleaved spectrum.
/// Complexity: O(n log n).
pub fn fft(x: &Vec[Float64]) -> Vec[Float64] {
  var n = x.len();
  if n == 0 { return Vec[Float64].new(); }
  var np2 = true;
  var m = n;
  while m > 1 {
    if m % 2 == 1 { np2 = false; }
    m = m / 2;
  }
  if !np2 { return dft(x); }
  var re = Vec[Float64].new();
  var im = Vec[Float64].new();
  var i = 0;
  while i < n {
    re.push(x[i]);
    im.push(0.0);
    i = i + 1;
  }
  var j = 0;
  var k = 0;
  while k < n - 1 {
    if k < j {
      var tr = re[j];
      var ti = im[j];
      re[j] = re[k];
      im[j] = im[k];
      re[k] = tr;
      im[k] = ti;
    }
    var bit = n / 2;
    while bit >= 1 && j >= bit {
      j = j - bit;
      bit = bit / 2;
    }
    j = j + bit;
    k = k + 1;
  }
  var len = 2;
  while len <= n {
    var ang = -_TAU / (len as Float64);
    var w_re = math.cos(ang);
    var w_im = math.sin(ang);
    var s = 0;
    while s < n {
      var u_re = 1.0;
      var u_im = 0.0;
      var half = len / 2;
      var p = 0;
      while p < half {
        var a_re = re[s + p];
        var a_im = im[s + p];
        var b_re = re[s + p + half];
        var b_im = im[s + p + half];
        var m_re = b_re * u_re - b_im * u_im;
        var m_im = b_re * u_im + b_im * u_re;
        re[s + p] = a_re + m_re;
        im[s + p] = a_im + m_im;
        re[s + p + half] = a_re - m_re;
        im[s + p + half] = a_im - m_im;
        var nu_re = u_re * w_re - u_im * w_im;
        var nu_im = u_re * w_im + u_im * w_re;
        u_re = nu_re;
        u_im = nu_im;
        p = p + 1;
      }
      s = s + len;
    }
    len = len * 2;
  }
  var out = Vec[Float64].new();
  var q = 0;
  while q < n {
    out.push(re[q]);
    out.push(im[q]);
    q = q + 1;
  }
  return out;
}

/// Inverse fast Fourier transform: inverts the interleaved complex spectrum
/// by the direct inverse DFT (O(n^2)); the real signal is returned.
/// Complexity: O(n^2).
pub fn ifft(x: &Vec[Float64]) -> Vec[Float64] {
  return idft(x);
}

/// FFT specialized for real-valued input (same routine as fft).
/// Complexity: O(n log n).
pub fn fft_real(x: &Vec[Float64]) -> Vec[Float64] {
  return fft(x);
}

/// Inverse FFT returning the real signal. Complexity: O(n log n).
pub fn ifft_real(x: &Vec[Float64]) -> Vec[Float64] {
  return ifft(x);
}

// ---------------------------------------------------------------------------
// Cosine and sine transforms
// ---------------------------------------------------------------------------

/// Orthonormal discrete cosine transform (type II). Complexity: O(n^2).
pub fn dct(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var k = 0;
  while k < n {
    var sum = 0.0;
    var t = 0;
    while t < n {
      var ang = _PI * (k as Float64) * (2.0 * (t as Float64) + 1.0) / (2.0 * (n as Float64));
      sum = sum + x[t] * math.cos(ang);
      t = t + 1;
    }
    var scale = math.sqrt(2.0 / (n as Float64));
    if k == 0 {
      scale = math.sqrt(1.0 / (n as Float64));
    }
    out.push(scale * sum);
    k = k + 1;
  }
  return out;
}

/// Inverse discrete cosine transform (type III, unnormalized-compatible with
/// dct). Complexity: O(n^2).
pub fn idct(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var t = 0;
  while t < n {
    var sum = 0.0;
    var k = 0;
    while k < n {
      var ang = _PI * (k as Float64) * (2.0 * (t as Float64) + 1.0) / (2.0 * (n as Float64));
      var c = x[k];
      if k == 0 {
        c = c * math.sqrt(1.0 / (n as Float64));
      } else {
        c = c * math.sqrt(2.0 / (n as Float64));
      }
      sum = sum + c * math.cos(ang);
      k = k + 1;
    }
    out.push(sum);
    t = t + 1;
  }
  return out;
}

/// Discrete cosine transform type II (alias of dct). Complexity: O(n^2).
pub fn dct_type2(x: &Vec[Float64]) -> Vec[Float64] {
  return dct(x);
}

/// Discrete cosine transform type III (alias of idct). Complexity: O(n^2).
pub fn dct_type3(x: &Vec[Float64]) -> Vec[Float64] {
  return idct(x);
}

/// Discrete sine transform (DST-I). Complexity: O(n^2).
pub fn dst(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var k = 0;
  while k < n {
    var sum = 0.0;
    var t = 0;
    while t < n {
      var ang = _PI * (k as Float64 + 1.0) * (t as Float64 + 1.0) / (n as Float64 + 1.0);
      sum = sum + x[t] * math.sin(ang);
      t = t + 1;
    }
    out.push(sum);
    k = k + 1;
  }
  return out;
}

/// Inverse discrete sine transform (IDST-I). Complexity: O(n^2).
pub fn idst(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var scale = 2.0 / (n as Float64 + 1.0);
  var t = 0;
  while t < n {
    var sum = 0.0;
    var k = 0;
    while k < n {
      var ang = _PI * (k as Float64 + 1.0) * (t as Float64 + 1.0) / (n as Float64 + 1.0);
      sum = sum + x[k] * math.sin(ang);
      k = k + 1;
    }
    out.push(scale * sum);
    t = t + 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Wavelets
// ---------------------------------------------------------------------------

/// Haar discrete wavelet transform to the given level: the approximation
/// coefficients followed by the detail coefficients of each level. Returns
/// the empty vector for level <= 0 or an empty signal. Complexity: O(n).
pub fn wavelet_haar(x: &Vec[Float64], level: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 || level <= 0 { return out; }
  var a = Vec[Float64].new();
  var i = 0;
  while i < n {
    a.push(x[i]);
    i = i + 1;
  }
  var l = 0;
  while l < level {
    var len = a.len();
    if len < 2 { l = level; }
    else {
      var next = Vec[Float64].new();
      var details = Vec[Float64].new();
      var j = 0;
      while j + 1 < len {
        next.push(0.5 * (a[j] + a[j + 1]));
        details.push(0.5 * (a[j] - a[j + 1]));
        j = j + 2;
      }
      var k = 0;
      while k < details.len() {
        out.push(details[k]);
        k = k + 1;
      }
      a = next;
    }
    l = l + 1;
  }
  var m = 0;
  while m < a.len() {
    out.push(a[m]);
    m = m + 1;
  }
  return out;
}

/// Level multi-resolution discrete wavelet transform (Haar basis). Alias of
/// wavelet_haar. Complexity: O(n).
pub fn wavelet_dwt(x: &Vec[Float64], level: Int) -> Vec[Float64] {
  return wavelet_haar(x, level);
}

/// Inverse Haar wavelet transform: the input holds the detail coefficients of
/// each level (level 1 first) followed by the final approximation block, as
/// produced by wavelet_haar. Complexity: O(n).
pub fn wavelet_idwt(coeffs: &Vec[Float64], level: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var total = coeffs.len();
  if level <= 0 || total == 0 { return out; }
  var approx_len = total;
  var l = 0;
  while l < level {
    approx_len = approx_len / 2;
    l = l + 1;
  }
  if approx_len <= 0 { return out; }
  var approx = Vec[Float64].new();
  var start = total - approx_len;
  var i = start;
  while i < total {
    approx.push(coeffs[i]);
    i = i + 1;
  }
  var cur_level = level;
  while cur_level > 0 {
    var dstart = 0;
    var pow2 = 1;
    var j = 1;
    while j < cur_level {
      pow2 = pow2 * 2;
      dstart = dstart + total / pow2;
      j = j + 1;
    }
    var next = Vec[Float64].new();
    var k = 0;
    while k < approx.len() {
      var d = 0.0;
      if dstart + k < total {
        d = coeffs[dstart + k];
      }
      next.push(approx[k] + d);
      next.push(approx[k] - d);
      k = k + 1;
    }
    approx = next;
    cur_level = cur_level - 1;
  }
  var m = 0;
  while m < approx.len() {
    out.push(approx[m]);
    m = m + 1;
  }
  return out;
}

/// Daubechies wavelet transform with the D4 filter for taps == 4; other tap
/// counts fall back to the Haar basis. Complexity: O(n).
pub fn wavelet_daubechies(x: &Vec[Float64], taps: Int, level: Int) -> Vec[Float64] {
  if taps == 4 {
    var out = Vec[Float64].new();
    var n = x.len();
    if n == 0 || level <= 0 { return out; }
    var a = Vec[Float64].new();
    var i = 0;
    while i < n {
      a.push(x[i]);
      i = i + 1;
    }
    var l = 0;
    while l < level {
      var len = a.len();
      if len < 4 { l = level; }
      else {
        var s0 = 0.4829629131445341;
        var s1 = 0.8365163037378079;
        var s2 = 0.2241438680420134;
        var s3 = -0.1294095225512604;
        var next = Vec[Float64].new();
        var details = Vec[Float64].new();
        var j = 0;
        while j + 3 < len {
          var c0 = a[j] * s0 + a[j + 1] * s1 + a[j + 2] * s2 + a[j + 3] * s3;
          var d0 = a[j] * s3 - a[j + 1] * s2 + a[j + 2] * s1 - a[j + 3] * s0;
          next.push(c0);
          details.push(d0);
          j = j + 2;
        }
        var k = 0;
        while k < details.len() {
          out.push(details[k]);
          k = k + 1;
        }
        a = next;
      }
      l = l + 1;
    }
    var m = 0;
    while m < a.len() {
      out.push(a[m]);
      m = m + 1;
    }
    return out;
  }
  return wavelet_haar(x, level);
}

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/// One-pass first-order alpha filter: y[n] = y[n-1] + a (x[n] - y[n-1]) with
/// a = cutoff / (1 + cutoff). filter_lowpass applies it `order` times.
/// Complexity: O(n * order).
pub fn filter_lowpass(x: &Vec[Float64], cutoff: Float64, order: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 || order <= 0 { return out; }
  var alpha = cutoff / (1.0 + cutoff);
  var cur = Vec[Float64].new();
  var i = 0;
  while i < n {
    cur.push(x[i]);
    i = i + 1;
  }
  var pass = 0;
  while pass < order {
    var y = Vec[Float64].new();
    var prev = 0.0;
    var k = 0;
    while k < n {
      prev = prev + alpha * (cur[k] - prev);
      y.push(prev);
      k = k + 1;
    }
    cur = y;
    pass = pass + 1;
  }
  var j = 0;
  while j < n {
    out.push(cur[j]);
    j = j + 1;
  }
  return out;
}

/// First-order high-pass filter: y[n] = alpha (y[n-1] + x[n] - x[n-1]), applied
/// `order` times. Complexity: O(n * order).
pub fn filter_highpass(x: &Vec[Float64], cutoff: Float64, order: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 || order <= 0 { return out; }
  var alpha = cutoff / (1.0 + cutoff);
  var cur = Vec[Float64].new();
  var i = 0;
  while i < n {
    cur.push(x[i]);
    i = i + 1;
  }
  var pass = 0;
  while pass < order {
    var y = Vec[Float64].new();
    var prev = 0.0;
    var xprev = 0.0;
    var k = 0;
    while k < n {
      var v = prev + cur[k] - xprev;
      prev = alpha * v;
      xprev = cur[k];
      y.push(prev);
      k = k + 1;
    }
    cur = y;
    pass = pass + 1;
  }
  var j = 0;
  while j < n {
    out.push(cur[j]);
    j = j + 1;
  }
  return out;
}

/// Band-pass filter: a low-pass at hi cascaded with a high-pass at lo.
/// Complexity: O(n * order).
pub fn filter_bandpass(x: &Vec[Float64], lo: Float64, hi: Float64, order: Int) -> Vec[Float64] {
  var lp = filter_lowpass(x, hi, order);
  return filter_highpass(&lp, lo, order);
}

/// Band-stop filter: the input minus the band-passed signal.
/// Complexity: O(n * order).
pub fn filter_bandstop(x: &Vec[Float64], lo: Float64, hi: Float64, order: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var bp = filter_bandpass(x, lo, hi, order);
  var i = 0;
  while i < n {
    out.push(x[i] - bp[i]);
    i = i + 1;
  }
  return out;
}

/// Butterworth low-pass filter (maximally flat): implemented as the cascaded
/// first-order alpha low-pass of filter_lowpass. Complexity: O(n * order).
pub fn filter_butterworth(x: &Vec[Float64], cutoff: Float64, order: Int) -> Vec[Float64] {
  return filter_lowpass(x, cutoff, order);
}

/// Chebyshev low-pass filter with passband ripple: implemented as the
/// cascaded alpha low-pass (the ripple parameter shapes the alpha gain).
/// Complexity: O(n * order).
pub fn filter_chebyshev(x: &Vec[Float64], cutoff: Float64, ripple: Float64, order: Int) -> Vec[Float64] {
  var c = cutoff;
  if ripple > 0.0 {
    c = cutoff / (1.0 + ripple);
  }
  return filter_lowpass(x, c, order);
}

/// Bessel low-pass filter (maximally flat group delay): implemented as the
/// cascaded alpha low-pass. Complexity: O(n * order).
pub fn filter_bessel(x: &Vec[Float64], cutoff: Float64, order: Int) -> Vec[Float64] {
  return filter_lowpass(x, cutoff, order);
}

/// Finite impulse response filter: y[n] = sum_k coeffs[k] x[n-k].
/// Complexity: O(n * taps).
pub fn filter_fir(x: &Vec[Float64], coeffs: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var m = coeffs.len();
  if m == 0 { return out; }
  var i = 0;
  while i < n {
    var s = 0.0;
    var k = 0;
    while k < m {
      if i >= k {
        s = s + coeffs[k] * x[i - k];
      }
      k = k + 1;
    }
    out.push(s);
    i = i + 1;
  }
  return out;
}

/// Infinite impulse response filter with numerator b and denominator a:
/// y[n] = (sum_k b_k x[n-k] - sum_{k>=1} a_k y[n-k]) / a_0.
/// Complexity: O(n * taps).
pub fn filter_iir(x: &Vec[Float64], b: &Vec[Float64], a: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  if a.len() == 0 { return out; }
  var a0 = a[0];
  if a0 == 0.0 { return out; }
  var nb = b.len();
  var na = a.len();
  var i = 0;
  while i < n {
    var s = 0.0;
    var k = 0;
    while k < nb {
      if i >= k {
        s = s + b[k] * x[i - k];
      }
      k = k + 1;
    }
    var j = 1;
    while j < na {
      if i >= j {
        s = s - a[j] * out[i - j];
      }
      j = j + 1;
    }
    out.push(s / a0);
    i = i + 1;
  }
  return out;
}

/// Linear convolution of x with kernel (length n + m - 1). Complexity: O(n*m).
pub fn convolve(x: &Vec[Float64], kernel: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  var m = kernel.len();
  if n == 0 || m == 0 { return out; }
  var total = n + m - 1;
  var i = 0;
  while i < total {
    var s = 0.0;
    var k = 0;
    while k < m {
      var xi = i - k;
      if xi >= 0 && xi < n {
        s = s + kernel[k] * x[xi];
      }
      k = k + 1;
    }
    out.push(s);
    i = i + 1;
  }
  return out;
}

/// Cross-correlation of x with kernel at lags - (m-1) .. (n-1).
/// Complexity: O(n*m).
pub fn correlate(x: &Vec[Float64], kernel: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  var m = kernel.len();
  if n == 0 || m == 0 { return out; }
  var total = n + m - 1;
  var lag = 0;
  while lag < total {
    var shift = lag - (m - 1);
    var s = 0.0;
    var i = 0;
    while i < n {
      var ki = i - shift;
      if ki >= 0 && ki < m {
        s = s + x[i] * kernel[ki];
      }
      i = i + 1;
    }
    out.push(s);
    lag = lag + 1;
  }
  return out;
}

/// Autocorrelation of x at lags 0 .. n-1. Complexity: O(n^2).
pub fn autocorrelate(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var lag = 0;
  while lag < n {
    var s = 0.0;
    var i = 0;
    while i < n - lag {
      s = s + x[i] * x[i + lag];
      i = i + 1;
    }
    out.push(s);
    lag = lag + 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Windows
// ---------------------------------------------------------------------------

/// Length-n Hanning window: 0.5 (1 - cos(2 pi i / (n-1))). Empty for n <= 0.
/// Complexity: O(n).
pub fn window_hanning(n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var i = 0;
  while i < n {
    var v = 0.5 * (1.0 - math.cos(_TAU * (i as Float64) / ((n - 1) as Float64)));
    out.push(v);
    i = i + 1;
  }
  return out;
}

/// Length-n Hamming window: 0.54 - 0.46 cos(2 pi i / (n-1)). Complexity: O(n).
pub fn window_hamming(n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var i = 0;
  while i < n {
    var v = 0.54 - 0.46 * math.cos(_TAU * (i as Float64) / ((n - 1) as Float64));
    out.push(v);
    i = i + 1;
  }
  return out;
}

/// Length-n Blackman window. Complexity: O(n).
pub fn window_blackman(n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var i = 0;
  while i < n {
    var t = _TAU * (i as Float64) / ((n - 1) as Float64);
    var v = 0.42 - 0.5 * math.cos(t) + 0.08 * math.cos(2.0 * t);
    out.push(v);
    i = i + 1;
  }
  return out;
}

/// Length-n Kaiser window with shape beta (zeroth-order modified Bessel
/// approximation). Complexity: O(n).
pub fn window_kaiser(n: Int, beta: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var denom = _i0(beta);
  var i = 0;
  while i < n {
    var x = 2.0 * (i as Float64) / ((n - 1) as Float64) - 1.0;
    var arg = beta * math.sqrt(1.0 - x * x);
    var w = _i0(arg) / denom;
    out.push(w);
    i = i + 1;
  }
  return out;
}

// Modified Bessel I0 by series. Complexity: O(terms).
fn _i0(x: Float64) -> Float64 {
  var sum = 1.0;
  var term = 1.0;
  var k = 1;
  while k <= 20 {
    term = term * (x / 2.0) * (x / 2.0) / ((k as Float64) * (k as Float64));
    sum = sum + term;
    k = k + 1;
  }
  return sum;
}

/// Length-n Bartlett triangular window. Complexity: O(n).
pub fn window_bartlett(n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var i = 0;
  while i < n {
    var v = 2.0 * (i as Float64) / ((n - 1) as Float64) - 1.0;
    if v < 0.0 { v = -v; }
    out.push(1.0 - v);
    i = i + 1;
  }
  return out;
}

/// Length-n Gaussian window with deviation sigma. Complexity: O(n).
pub fn window_gaussian(n: Int, sigma: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var i = 0;
  while i < n {
    var x = 2.0 * (i as Float64) / ((n - 1) as Float64) - 1.0;
    var v = math.exp(-0.5 * (x / sigma) * (x / sigma));
    out.push(v);
    i = i + 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Spectral analysis
// ---------------------------------------------------------------------------

/// Magnitude spectrum |FFT(x)|. Complexity: O(n log n).
pub fn spectrum(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var f = fft(x);
  var k = 0;
  while k < n {
    var re = f[2 * k];
    var im = f[2 * k + 1];
    out.push(math.sqrt(re * re + im * im));
    k = k + 1;
  }
  return out;
}

/// Power spectral density |FFT(x)|^2 / N. Complexity: O(n log n).
pub fn psd(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var f = fft(x);
  var k = 0;
  while k < n {
    var re = f[2 * k];
    var im = f[2 * k + 1];
    out.push((re * re + im * im) / (n as Float64));
    k = k + 1;
  }
  return out;
}

/// Time-frequency spectrogram matrix: windowed magnitude spectra, one row per
/// frame (frames start every `hop` samples, width `win_size`). Complexity:
/// O(frames * win_size^2).
pub fn spectrogram(x: &Vec[Float64], win_size: Int, hop: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var n = x.len();
  if n == 0 || win_size <= 0 || hop <= 0 { return out; }
  var win = window_hann_internal(win_size);
  var start = 0;
  while start + win_size <= n {
    var frame = Vec[Float64].new();
    var i = 0;
    while i < win_size {
      frame.push(x[start + i] * win[i]);
      i = i + 1;
    }
    var mag = spectrum(&frame);
    var row = Vec[Float64].new();
    var j = 0;
    while j < win_size / 2 + 1 {
      row.push(mag[j]);
      j = j + 1;
    }
    out.push(row);
    start = start + hop;
  }
  return out;
}

// Internal Hanning window builder (spectrogram needs a window at runtime).
fn window_hann_internal(n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 1 {
    out.push(1.0);
    return out;
  }
  var i = 0;
  while i < n {
    var v = 0.5 * (1.0 - math.cos(_TAU * (i as Float64) / ((n - 1) as Float64)));
    out.push(v);
    i = i + 1;
  }
  return out;
}

/// Cepstrum: |IDFT(ln(|DFT(x)| + eps))|. Complexity: O(n log n).
pub fn cepstrum(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var f = fft(x);
  var logmag = Vec[Float64].new();
  var k = 0;
  while k < n {
    var re = f[2 * k];
    var im = f[2 * k + 1];
    var m = math.sqrt(re * re + im * im) + 1.0e-10;
    logmag.push(math.ln(m));
    k = k + 1;
  }
  var ifft_v = ifft(&logmag);
  var i = 0;
  while i < n {
    var v = ifft_v[i];
    if v < 0.0 { v = -v; }
    out.push(v);
    i = i + 1;
  }
  return out;
}

/// Mel-scale triangular filter bank: n_filters rows of fft_size/2 + 1 weights.
/// Complexity: O(n_filters * fft_size).
pub fn mel_filterbank(n_filters: Int, fft_size: Int, sample_rate: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if n_filters <= 0 || fft_size <= 0 || sample_rate <= 0 { return out; }
  var nfft = fft_size / 2 + 1;
  var fmax = sample_rate / 2.0;
  var mel_max = 2595.0 * math.log10(1.0 + fmax / 700.0);
  var mel_min = 2595.0 * math.log10(1.0 + 0.0 / 700.0);
  var mel_points = Vec[Float64].new();
  var i = 0;
  while i < n_filters + 2 {
    var f = mel_min + (mel_max - mel_min) * (i as Float64) / ((n_filters + 1) as Float64);
    var hz = 700.0 * (math.pow(10.0, f / 2595.0) - 1.0);
    var bin = hz * (fft_size as Float64) / sample_rate;
    mel_points.push(bin);
    i = i + 1;
  }
  var f2 = 0;
  while f2 < n_filters {
    var row = Vec[Float64].new();
    var b = 0;
    while b < nfft {
      var lo = mel_points[f2];
      var mid = mel_points[f2 + 1];
      var hi = mel_points[f2 + 2];
      var w = 0.0;
      if (b as Float64) >= lo && (b as Float64) <= mid && mid > lo {
        w = ((b as Float64) - lo) / (mid - lo);
      }
      if (b as Float64) > mid && (b as Float64) <= hi && hi > mid {
        w = (hi - (b as Float64)) / (hi - mid);
      }
      row.push(w);
      b = b + 1;
    }
    out.push(row);
    f2 = f2 + 1;
  }
  return out;
}

/// Mel-frequency cepstral coefficients: the log-mel spectrum of x followed by
/// the DCT, keeping the first n_coeffs coefficients. Empty for degenerate
/// input. Complexity: O(n log n + filters * fft_size + filters^2).
pub fn mfcc(x: &Vec[Float64], n_coeffs: Int, sample_rate: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 || n_coeffs <= 0 || sample_rate <= 0 { return out; }
  var nfft = 1;
  while nfft < n {
    nfft = nfft * 2;
  }
  var fft_size = nfft;
  var n_filters = 24;
  if n_coeffs > n_filters { n_coeffs = n_filters; }
  var padded = Vec[Float64].new();
  var i = 0;
  while i < fft_size {
    if i < n {
      padded.push(x[i]);
    } else {
      padded.push(0.0);
    }
    i = i + 1;
  }
  var f = fft(&padded);
  var mag = Vec[Float64].new();
  var k = 0;
  while k < fft_size / 2 + 1 {
    var re = f[2 * k];
    var im = f[2 * k + 1];
    mag.push(math.sqrt(re * re + im * im));
    k = k + 1;
  }
  var fb = mel_filterbank(n_filters, fft_size, sample_rate);
  var energies = Vec[Float64].new();
  var fi = 0;
  while fi < n_filters {
    var row = fb[fi];
    var s = 0.0;
    var b = 0;
    while b < row.len() {
      s = s + mag[b] * row[b];
      b = b + 1;
    }
    var e = s + 1.0e-10;
    energies.push(math.ln(e));
    fi = fi + 1;
  }
  var c = 0;
  while c < n_coeffs {
    var sum = 0.0;
    var m2 = 0;
    while m2 < n_filters {
      var ang = _PI * (c as Float64) * ((m2 as Float64) + 0.5) / (n_filters as Float64);
      sum = sum + energies[m2] * math.cos(ang);
      m2 = m2 + 1;
    }
    var scale = math.sqrt(2.0 / (n_filters as Float64));
    if c == 0 {
      scale = math.sqrt(1.0 / (n_filters as Float64));
    }
    out.push(scale * sum);
    c = c + 1;
  }
  return out;
}
