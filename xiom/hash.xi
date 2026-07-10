// XIOM — Hashing
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash

// === Hash interface (hasher-based) ===
pub interface Hash {
  fn hash(self, hasher: Hasher);
}

// === Hasher interface ===
pub interface Hasher {
  fn write(self, bytes: &Vec[UInt8]);
  fn write_int(self, n: Int);
  fn write_str(self, s: Str);
  fn finish(self) -> Int;
}

// === BuildHasher interface ===
pub interface BuildHasher {
  fn build_hasher(self) -> Hasher;
}

// === DefaultHasher — DJB2-based concrete hasher ===
pub type DefaultHasher = { state: Int; } derive[Clone]

pub fn DefaultHasher.new() -> DefaultHasher {
  return DefaultHasher { state: 5381; };
}

pub fn DefaultHasher.write(self, bytes: &Vec[UInt8]) {
  var i: Int = 0;
  while i < bytes.len() {
    self.state = ((self.state * 33) + bytes[i]);
    i = i + 1;
  }
}

pub fn DefaultHasher.write_int(self, n: Int) {
  var val: Int = n;
  var i: Int = 0;
  while i < 8 {
    self.state = ((self.state * 33) + (val & 0xFF));
    val = val >> 8;
    i = i + 1;
  }
}

pub fn DefaultHasher.write_str(self, s: Str) {
  var i: Int = 0;
  let len: Int = str_len(s);
  while i < len {
    let ch: Option[Char] = char_at(s, i);
    if ch.is_some {
      let code: Int = to_int_from_char(ch.value);
      self.state = ((self.state * 33) + code);
    };
    i = i + 1;
  }
}

pub fn DefaultHasher.finish(self) -> Int {
  return self.state;
}

// === Hash implementations for standard types ===
// Full DJB2 hash computation. Each type hashes its bytes directly.
pub fn Int.hash(self) -> UInt64 {
  var h: Int = 5381;
  var val: Int = self;
  var i: Int = 0;
  while i < 8 {
    let byte = val & 0xFF;
    h = ((h * 33) + byte);
    val = val >> 8;
    i = i + 1;
  }
  h
}

pub fn Bool.hash(self) -> UInt64 {
  var h: Int = 5381;
  if self {
    h = ((h * 33) + 1);
  } else {
    h = ((h * 33) + 0);
  }
  h
}

// === Free functions ===
pub fn hash_value[T: Hash](value: &T) -> Int {
  value.hash()
}

pub fn hash_combine(seed: Int, hash: Int) -> Int {
  return seed ^ (hash + 0x9e3779b9 + (seed << 6) + (seed >> 2));
}

pub fn hash[T: Hash](value: T) -> UInt64 {
  value.hash()
}

pub fn sip_hash(data: &Vec[UInt8]) -> UInt64 {
  var hasher: DefaultHasher = DefaultHasher.new();
  hasher.write(data);
  return hasher.finish();
}
