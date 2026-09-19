// XIOM -- Random Number Generation
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.rand

use xiom.string;
use xiom.crypto;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn clock() -> Int;
  fn time(ptr: *Int) -> Int;
}

/// === RNG trait ===
pub interface Rng {
  fn next_int(self) -> Int;
  fn next_float(self) -> Float64;
  fn next_bytes(self, buf: &mut Vec[UInt8]);
}

// === Global RNG state ===
var _global_state: Int = 12345;

// === LCG step ===
fn _lcg_step(state: Int) -> Int {
  var s = (state * 48271) % 2147483647;
  if s <= 0 {
    s = s + 2147483647;
  };
  return s;
}

/// === Standard RNG ===
pub type StdRng = { state: Int; } derive[Clone]

pub fn StdRng.new() -> StdRng
  requires: true  // extern clock call below (T002 confinement)
{
  let t = clock();
  var seed = t;
  if seed == 0 {
    seed = 12345;
  } elif seed < 0 {
    seed = -seed;
  };
  return StdRng{ state: seed; };
}

pub fn StdRng.from_seed(seed: Int) -> StdRng {
  if seed == 0 {
    return StdRng{ state: 1; };
  };
  return StdRng{ state: seed; };
}

fn StdRng.next_int(self) -> Int {
  state = _lcg_step(state);
  return state;
}

fn StdRng.next_float(self) -> Float64 {
  state = _lcg_step(state);
  return (state as Float64) / 2147483647.0;
}

fn StdRng.next_bytes(self, buf: &mut Vec[UInt8]) {
  var i: Int = 0;
  while i < 16 {
    state = _lcg_step(state);
    buf.push((state & 0xFF) as UInt8);
    i = i + 1;
  };
}

/// === Basic random values ===
pub fn random() -> Float64
  ensures: result >= 0.0
  ensures: result < 1.0
{ // [0, 1)
  _global_state = _lcg_step(_global_state);
  return (_global_state as Float64) / 2147483647.0;
}

pub fn random_int(min: Int, max: Int) -> Int
  requires: min <= max
  ensures:  result >= min && result <= max
{ // [min, max]
  let r = random();
  let range = max - min + 1;
  if range <= 0 {
    return min;
  };
  let val = xiom.math.floor(r * (range as Float64)) as Int;
  if val >= range {
    return max;
  };
  return min + val;
}

pub fn random_float(min: Float64, max: Float64) -> Float64 { // [min, max)
  return min + random() * (max - min);
}

pub fn random_bool() -> Bool {
  return random() >= 0.5;
}

pub fn random_bytes(count: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i: Int = 0;
  while i < count {
    _global_state = _lcg_step(_global_state);
    result.push((_global_state & 0xFF) as UInt8);
    i = i + 1;
  };
  return result;
}

/// === Distributions ===
pub fn sample_uniform(min: Float64, max: Float64) -> Float64 {
  return min + random() * (max - min);
}

pub fn sample_normal(mean: Float64, stddev: Float64) -> Float64 {
  let u1 = random();
  let u2 = random();
  var safe_u1 = u1;
  if safe_u1 <= 0.0 {
    safe_u1 = 0.0000000001;
  };
  let r = xiom.math.sqrt(-2.0 * xiom.math.ln(safe_u1));
  let theta = 2.0 * xiom.math.PI * u2;
  let z0 = r * xiom.math.cos(theta);
  return mean + z0 * stddev;
}

pub fn sample_exponential(lambda: Float64) -> Float64 {
  var u = random();
  if u <= 0.0 {
    u = 0.0000000001;
  };
  return -xiom.math.ln(u) / lambda;
}

pub fn sample_bernoulli(p: Float64) -> Bool {
  return random() < p;
}

pub fn sample_binomial(n: Int, p: Float64) -> Int {
  var count: Int = 0;
  var i: Int = 0;
  while i < n {
    if random() < p {
      count = count + 1;
    };
    i = i + 1;
  };
  return count;
}

pub fn sample_poisson(lambda: Float64) -> Int {
  let L = xiom.math.exp(-lambda);
  var k: Int = 0;
  var p: Float64 = 1.0;
  while p > L {
    k = k + 1;
    p = p * random();
  };
  return k - 1;
}

pub fn sample_gamma(shape: Float64, scale: Float64) -> Float64 {
  if shape <= 0.0 {
    return 0.0;
  };
  if shape < 1.0 {
    let g = sample_gamma(shape + 1.0, 1.0);
    var u = random();
    if u <= 0.0 {
      u = 0.0000000001;
    };
    return g * xiom.math.pow(u, 1.0 / shape) * scale;
  };
  let d = shape - 1.0 / 3.0;
  let c = 1.0 / xiom.math.sqrt(9.0 * d);
  loop {
    var x: Float64 = 0.0;
    var v: Float64 = 0.0;
    loop {
      x = sample_normal(0.0, 1.0);
      v = 1.0 + c * x;
      if v > 0.0 {
        break;
      };
    };
    v = v * v * v;
    let u = random();
    if u < 1.0 - 0.0331 * (x * x) * (x * x) {
      return d * v * scale;
    };
    if xiom.math.ln(u) < 0.5 * x * x + d * (1.0 - v + xiom.math.ln(v)) {
      return d * v * scale;
    };
  };
}

pub fn sample_beta(alpha: Float64, beta: Float64) -> Float64 {
  if alpha <= 0.0 || beta <= 0.0 {
    return 0.0;
  };
  let x = sample_gamma(alpha, 1.0);
  let y = sample_gamma(beta, 1.0);
  return x / (x + y);
}

/// === Shuffle & Pick ===
pub fn shuffle[T](items: &mut Vec[T])
  ensures: items.len() == items.len()@pre
{
  var i = items.len() - 1;
  while i > 0 {
    let j = ((random() * ((i + 1) as Float64)) as Int);
    if j <= i {
      let temp = items[i];
      items[i] = items[j];
      items[j] = temp;
    };
    i = i - 1;
  };
}

pub fn pick[T](items: &Vec[T]) -> Option<&T> {
  let len = items.len();
  if len == 0 {
    return None;
  };
  let idx = ((random() * (len as Float64)) as Int);
  if idx >= len {
    return Some(&items[0]);
  };
  return Some(&items[idx]);
}

pub fn pick_n[T](items: &Vec[T], n: Int) -> Vec<&T> {
  let len = items.len();
  var count = n;
  if count > len {
    count = len;
  };
  var result = Vec[&T].new();
  if count == 0 {
    return result;
  };
  var indices = Vec[Int].new();
  var m: Int = 0;
  while m < len {
    indices.push(m);
    m = m + 1;
  };
  var i = len - 1;
  while i > 0 {
    let k = ((random() * ((i + 1) as Float64)) as Int);
    if k <= i {
      let temp = indices[i];
      indices[i] = indices[k];
      indices[k] = temp;
    };
    i = i - 1;
  };
  var j: Int = 0;
  while j < count {
    result.push(&items[indices[j]]);
    j = j + 1;
  };
  return result;
}

pub fn weighted_pick[T](items: &Vec[T], weights: &Vec[Float64]) -> Option<&T> {
  let len = items.len();
  if len == 0 || weights.len() != len {
    return None;
  };
  var total: Float64 = 0.0;
  var k: Int = 0;
  while k < len {
    if weights[k] < 0.0 {
      return None;
    };
    total = total + weights[k];
    k = k + 1;
  };
  if total <= 0.0 {
    return None;
  };
  let threshold = random() * total;
  var cumulative: Float64 = 0.0;
  var i: Int = 0;
  while i < len {
    cumulative = cumulative + weights[i];
    if cumulative >= threshold {
      return Some(&items[i]);
    };
    i = i + 1;
  };
  return Some(&items[len - 1]);
}

// === UUID ===

fn _format_uuid(bytes: &Vec[UInt8]) -> Str {
  let hex = "0123456789abcdef";
  unsafe {
    var buf = malloc(37);
    var pos: Int = 0;
    var i: Int = 0;
    while i < 16 {
      if i == 4 || i == 6 || i == 8 || i == 10 {
        buf[pos] = 45;
        pos = pos + 1;
      };
      let b = bytes[i];
      buf[pos] = hex.char_at((b >> 4) as Int) as UInt8;
      pos = pos + 1;
      buf[pos] = hex.char_at((b & 0x0F) as Int) as UInt8;
      pos = pos + 1;
      i = i + 1;
    };
    buf[36] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn uuid_v4() -> Str
  ensures: result.len() == 36
{
  var bytes = Vec[UInt8].new();
  var i: Int = 0;
  while i < 16 {
    _global_state = _lcg_step(_global_state);
    bytes.push((_global_state & 0xFF) as UInt8);
    i = i + 1;
  };
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  return _format_uuid(&bytes);
}

pub fn uuid_v7() -> Str
  ensures: result.len() == 36
{
  let t = time(0);
  var bytes = Vec[UInt8].new();
  var i: Int = 0;
  while i < 16 {
    _global_state = _lcg_step(_global_state);
    bytes.push((_global_state & 0xFF) as UInt8);
    i = i + 1;
  };
  var ts = t;
  var j: Int = 5;
  while j >= 0 {
    bytes[j] = (ts & 0xFF) as UInt8;
    ts = ts >> 8;
    j = j - 1;
  };
  bytes[6] = (bytes[6] & 0x0F) | 0x70;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  return _format_uuid(&bytes);
}

/// === Seeding ===
pub fn seed_from_entropy()
  requires: true  // extern clock call below (T002 confinement)
{
  let t = clock();
  var seed = t;
  if seed == 0 {
    seed = 12345;
  } elif seed < 0 {
    seed = -seed;
  };
  _global_state = seed;
}

pub fn seed_from_time()
  requires: true  // extern time call below (T002 confinement)
{
  let t = time(0);
  var seed = t;
  if seed <= 0 {
    seed = 1;
  };
  _global_state = seed;
}

pub fn seed_from_value(seed: Int) {
  if seed == 0 {
    _global_state = 1;
  } else {
    _global_state = seed;
  };
}

// -- Xorshift64 --------------------------------------------------------------

/// Xorshift64 PRNG (Marsaglia, 2003).
/// State: 64-bit unsigned. Period: 2^64 - 1.
/// Triple-xorshift: x ^= x << a; x ^= x >> b; x ^= x << c.
/// Complexity: O(1) per call.
pub type Xorshift64 = { state: Int; } derive[Clone]

/// Creates a new Xorshift64 generator with the given seed.
/// Seed must be non-zero. Zero seed is replaced with 1.
pub fn Xorshift64.new(seed: Int) -> Xorshift64 {
  var s = seed;
  if s == 0 {
    s = 1;
  };
  return Xorshift64{ state: s; };
}

/// Returns the next pseudo-random integer from this Xorshift64 generator.
/// Uses triple-xorshift: x ^= x << 13; x ^= x >> 7; x ^= x << 17.
pub fn Xorshift64.next_int(self) -> Int {
  state = state ^ (state << 13);
  state = state ^ (state >> 7);
  state = state ^ (state << 17);
  return state;
}

// -- Random choice -----------------------------------------------------------

/// Returns a random element from a vector.
/// Returns None if the vector is empty.
/// Wraps the existing pick function.
/// Complexity: O(1).
pub fn random_choice[T](items: &Vec[T]) -> Option[&T] {
  return pick(items);
}

// -- Random shuffle ----------------------------------------------------------

/// Shuffles a vector in place using Fisher-Yates.
/// Wraps the existing shuffle function.
/// Complexity: O(n), n = items length.
pub fn random_shuffle[T](items: &mut Vec[T]) {
  shuffle(items);
}

// -- Random fraction ---------------------------------------------------------

/// Alias for random(). Returns a Float64 in [0, 1).
pub fn random_fraction() -> Float64 {
  return random();
}

// -- Gaussian Box-Muller -----------------------------------------------------

/// Generates a normally distributed random number using the Box-Muller transform.
/// Mean and stddev parameters control the distribution center and spread.
/// Complexity: O(1).
pub fn gaussian_box_muller(mean: Float64, stddev: Float64) -> Float64 {
  let u1 = random();
  let u2 = random();
  var safe_u1 = u1;
  if safe_u1 <= 0.0 {
    safe_u1 = 0.0000000001;
  };
  let r = xiom.math.sqrt(-2.0 * xiom.math.ln(safe_u1));
  let theta = 2.0 * xiom.math.PI * u2;
  let z0 = r * xiom.math.cos(theta);
  return mean + z0 * stddev;
}

// -- Cryptographic random bytes ----------------------------------------------

/// Fills a buffer with cryptographically secure random bytes.
/// Delegates to xiom.crypto.secure_random_bytes.
/// Complexity: O(n), n = count.
pub fn random_bytes_crypto(count: Int) -> Vec[UInt8] {
  return crypto.secure_random_bytes(count);
}
