// XIOM - Encoding: Endian Codecs
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.encoding.le

// Depends on: none

// ============================================================================
// Unsigned little-/big-endian readers and writers with Result-shaped bounds
// and range errors (2026-10-02 intake row 32; requesters flash, apple, gpio,
// interrupt, tls (BE u16/u24/u32), ssh2, tor, mongo, memcached, ethereum,
// perf, etcd, parquet, inference, video, audio-meta). Contrast with
// xiom.serialize.endian, whose readers return 0 on out-of-bounds input:
// these variants refuse instead, so truncated buffers cannot silently turn
// into zeros. Widths: 16/24/32/64 (u24 is the 24-bit mid-size the binary
// packages kept hand-rolling). u64 accepts and returns the non-negative Int
// domain 0..=INT64_MAX; the 8-byte pattern round-trips exactly for it.
// ============================================================================

// Shared width range check. `bits` is 16, 24, 32, or 64.
fn _le_range_err(bits: Int) -> Str {
  if bits == 16 {
    return "u16 value out of range";
  };
  if bits == 24 {
    return "u24 value out of range";
  };
  if bits == 32 {
    return "u32 value out of range";
  };
  "u64 value out of range";
}

// Shared width bounds check message.
fn _le_bounds_err(bits: Int) -> Str {
  if bits == 16 {
    return "u16 read out of bounds";
  };
  if bits == 24 {
    return "u24 read out of bounds";
  };
  if bits == 32 {
    return "u32 read out of bounds";
  };
  "u64 read out of bounds";
}

// -- Little-endian writers ---------------------------------------------------

/// Append `v` as a little-endian UInt16; Err when v < 0 or v > 0xFFFF.
pub fn write_u16_le(out: &mut Vec[UInt8], v: Int) -> Result[Unit, Str]
  ensures: true
{
  if v < 0 || v > 0xFFFF {
    return Err(_le_range_err(16));
  };
  out.push((v & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
  Ok(())
}

/// Append `v` as a little-endian 24-bit value; Err when v < 0 or v > 0xFFFFFF.
pub fn write_u24_le(out: &mut Vec[UInt8], v: Int) -> Result[Unit, Str]
  ensures: true
{
  if v < 0 || v > 0xFFFFFF {
    return Err(_le_range_err(24));
  };
  out.push((v & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push(((v >> 16) & 0xFF) as UInt8);
  Ok(())
}

/// Append `v` as a little-endian UInt32; Err when v < 0 or v > 0xFFFFFFFF.
pub fn write_u32_le(out: &mut Vec[UInt8], v: Int) -> Result[Unit, Str]
  ensures: true
{
  if v < 0 || v > 0xFFFFFFFF {
    return Err(_le_range_err(32));
  };
  var i = 0;
  var n = v;
  while i < 4 {
    out.push((n & 0xFF) as UInt8);
    n = n >> 8;
    i = i + 1;
  };
  Ok(())
}

/// Append `v` as a little-endian UInt64 (accepted domain 0..=INT64_MAX);
/// Err when v < 0.
pub fn write_u64_le(out: &mut Vec<UInt8>, v: Int) -> Result[Unit, Str]
  ensures: (v < 0) => (result.is_err)
{
  if v < 0 {
    return Err(_le_range_err(64));
  };
  var i = 0;
  var n = v;
  while i < 8 {
    out.push((n & 0xFF) as UInt8);
    n = n >> 8;
    i = i + 1;
  };
  Ok(())
}

// -- Big-endian writers ------------------------------------------------------

/// Append `v` as a big-endian UInt16; Err when v < 0 or v > 0xFFFF.
pub fn write_u16_be(out: &mut Vec[UInt8], v: Int) -> Result[Unit, Str]
  ensures: true
{
  if v < 0 || v > 0xFFFF {
    return Err(_le_range_err(16));
  };
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push((v & 0xFF) as UInt8);
  Ok(())
}

/// Append `v` as a big-endian 24-bit value; Err when v < 0 or v > 0xFFFFFF.
pub fn write_u24_be(out: &mut Vec[UInt8], v: Int) -> Result[Unit, Str]
  ensures: true
{
  if v < 0 || v > 0xFFFFFF {
    return Err(_le_range_err(24));
  };
  out.push(((v >> 16) & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push((v & 0xFF) as UInt8);
  Ok(())
}

/// Append `v` as a big-endian UInt32; Err when v < 0 or v > 0xFFFFFFFF.
pub fn write_u32_be(out: &mut Vec<UInt8>, v: Int) -> Result[Unit, Str]
  ensures: (v < 0 || v > 0xFFFFFFFF) => (result.is_err)
{
  if v < 0 || v > 0xFFFFFFFF {
    return Err(_le_range_err(32));
  };
  var i = 24;
  while i >= 0 {
    out.push(((v >> i) & 0xFF) as UInt8);
    i = i - 8;
  };
  Ok(())
}

/// Append `v` as a big-endian UInt64 (accepted domain 0..=INT64_MAX);
/// Err when v < 0.
pub fn write_u64_be(out: &mut Vec[UInt8], v: Int) -> Result[Unit, Str]
  ensures: true
{
  if v < 0 {
    return Err(_le_range_err(64));
  };
  var i = 56;
  while i >= 0 {
    out.push(((v >> i) & 0xFF) as UInt8);
    i = i - 8;
  };
  Ok(())
}

// -- Little-endian readers ---------------------------------------------------

/// Read a little-endian UInt16 at `pos`; Err when pos < 0 or fewer than two
/// bytes remain.
pub fn read_u16_le(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
  ensures: true
{
  if pos < 0 || pos + 2 > data.len() {
    return Err(_le_bounds_err(16));
  };
  let b0 = (data[pos] as Int) & 0xFF;
  let b1 = (data[pos + 1] as Int) & 0xFF;
  Ok(b0 | (b1 << 8))
}

/// Read a little-endian 24-bit value at `pos`; Err when pos < 0 or fewer than
/// three bytes remain.
pub fn read_u24_le(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
  ensures: true
{
  if pos < 0 || pos + 3 > data.len() {
    return Err(_le_bounds_err(24));
  };
  let b0 = (data[pos] as Int) & 0xFF;
  let b1 = (data[pos + 1] as Int) & 0xFF;
  let b2 = (data[pos + 2] as Int) & 0xFF;
  Ok(b0 | (b1 << 8) | (b2 << 16))
}

/// Read a little-endian UInt32 at `pos`; Err when pos < 0 or fewer than four
/// bytes remain.
pub fn read_u32_le(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
  ensures: (pos < 0) => (result.is_err)
{
  if pos < 0 || pos + 4 > data.len() {
    return Err(_le_bounds_err(32));
  };
  var result = 0;
  var k = 0;
  while k < 4 {
    let b = (data[pos + k] as Int) & 0xFF;
    result = result | (b << (k * 8));
    k = k + 1;
  };
  Ok(result)
}

/// Read a little-endian UInt64 at `pos`; Err when pos < 0 or fewer than eight
/// bytes remain. The return carries the raw 64-bit pattern (two's complement
/// when the top bit is set), which write_u64_le reproduces for the accepted
/// domain.
pub fn read_u64_le(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
  ensures: (pos < 0) => (result.is_err)
{
  if pos < 0 || pos + 8 > data.len() {
    return Err(_le_bounds_err(64));
  };
  var result = 0;
  var k = 0;
  while k < 8 {
    let b = (data[pos + k] as Int) & 0xFF;
    result = result | (b << (k * 8));
    k = k + 1;
  };
  Ok(result)
}

// -- Big-endian readers ------------------------------------------------------

/// Read a big-endian UInt16 at `pos`; Err when pos < 0 or fewer than two
/// bytes remain.
pub fn read_u16_be(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
  ensures: true
{
  if pos < 0 || pos + 2 > data.len() {
    return Err(_le_bounds_err(16));
  };
  let b0 = (data[pos] as Int) & 0xFF;
  let b1 = (data[pos + 1] as Int) & 0xFF;
  Ok((b0 << 8) | b1)
}

/// Read a big-endian 24-bit value at `pos`; Err when pos < 0 or fewer than
/// three bytes remain.
pub fn read_u24_be(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
  ensures: true
{
  if pos < 0 || pos + 3 > data.len() {
    return Err(_le_bounds_err(24));
  };
  let b0 = (data[pos] as Int) & 0xFF;
  let b1 = (data[pos + 1] as Int) & 0xFF;
  let b2 = (data[pos + 2] as Int) & 0xFF;
  Ok((b0 << 16) | (b1 << 8) | b2)
}

/// Read a big-endian UInt32 at `pos`; Err when pos < 0 or fewer than four
/// bytes remain.
pub fn read_u32_be(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
  ensures: (pos < 0) => (result.is_err)
{
  if pos < 0 || pos + 4 > data.len() {
    return Err(_le_bounds_err(32));
  };
  var result = 0;
  var k = 0;
  while k < 4 {
    let b = (data[pos + k] as Int) & 0xFF;
    result = (result << 8) | b;
    k = k + 1;
  };
  Ok(result)
}

/// Read a big-endian UInt64 at `pos`; Err when pos < 0 or fewer than eight
/// bytes remain. The return carries the raw 64-bit pattern (two's complement
/// when the top bit is set).
pub fn read_u64_be(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
  ensures: true
{
  if pos < 0 || pos + 8 > data.len() {
    return Err(_le_bounds_err(64));
  };
  var result = 0;
  var k = 0;
  while k < 8 {
    let b = (data[pos + k] as Int) & 0xFF;
    result = (result << 8) | b;
    k = k + 1;
  };
  Ok(result)
}
