// XIOM - Conversion: Network
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.network

// Depends on: none

// ============================================================================
// Host-to-network and network-to-host byte order conversions. All functions
// are pure byte swaps implemented with explicit byte shifts and small masks
// (no reliance on the C runtime); the 16/32-bit swaps are self-inverse, so
// hton and ntoh share one implementation each.
// ============================================================================

/// Convert a 16-bit host-order value to network order (big-endian).
/// Parameters: n -- a 16-bit value (0..65535).
/// Returns: the byte-swapped value.
/// Complexity: O(1).
pub fn host_to_network16(n: Int) -> Int {
  var lo = n & 0xFF;
  var hi = (n >> 8) & 0xFF;
  return (lo << 8) | hi;
}

/// Convert a 32-bit host-order value to network order (big-endian).
/// Parameters: n -- a 32-bit value.
/// Returns: the byte-swapped value.
/// Complexity: O(1).
pub fn host_to_network32(n: Int) -> Int {
  return _bswap32(n);
}

/// Convert a 16-bit network-order value to host order (little-endian).
/// Parameters: n -- a 16-bit network-order value.
/// Returns: the byte-swapped value.
/// Complexity: O(1).
pub fn network_to_host16(n: Int) -> Int {
  var lo = n & 0xFF;
  var hi = (n >> 8) & 0xFF;
  return (lo << 8) | hi;
}

/// Convert a 32-bit network-order value to host order (little-endian).
/// Parameters: n -- a 32-bit network-order value.
/// Returns: the byte-swapped value.
/// Complexity: O(1).
pub fn network_to_host32(n: Int) -> Int {
  return _bswap32(n);
}

/// Convert a 64-bit host-order value to network order (big-endian).
/// Parameters: n -- a 64-bit value.
/// Returns: the byte-swapped value.
/// Complexity: O(1).
pub fn htonll(n: Int) -> Int {
  return _bswap64(n);
}

/// Convert a 64-bit network-order value to host order (little-endian).
/// Parameters: n -- a 64-bit network-order value.
/// Returns: the byte-swapped value.
/// Complexity: O(1).
pub fn ntohll(n: Int) -> Int {
  return _bswap64(n);
}

// 32-bit byte swap: [b3 b2 b1 b0] -> [b0 b1 b2 b3].
fn _bswap32(n: Int) -> Int {
  var b0 = n & 0xFF;
  var b1 = (n >> 8) & 0xFF;
  var b2 = (n >> 16) & 0xFF;
  var b3 = (n >> 24) & 0xFF;
  var r = b0 << 24;
  r = r | (b1 << 16);
  r = r | (b2 << 8);
  r = r | b3;
  return r;
}

// 64-bit byte swap via eight shift-and-mask rounds.
fn _bswap64(n: Int) -> Int {
  var r: Int = 0;
  var x = n;
  var i: Int = 0;
  while i < 8 {
    var b = x & 0xFF;
    r = (r << 8) | b;
    x = x >> 8;
    i = i + 1;
  }
  return r;
}
