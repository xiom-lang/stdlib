// XIOM — Hashing
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash

pub interface Hasher {
  fn write(self, bytes: &Vec[UInt8]);
  fn write_int(self, n: Int);
  fn write_str(self, s: Str);
  fn finish(self) -> Int;
}

pub fn hash_value[T: Hash](value: &T) -> Int;
pub fn hash_combine(seed: Int, hash: Int) -> Int;

// Default hasher (SipHash-like)
pub type DefaultHasher = { state: Int; } derive[Clone]
pub fn DefaultHasher.new() -> DefaultHasher;
