// XIOM - Network: NTP / SNTP
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.ntp

// Depends on: xiom.net

// ============================================================================
// NTP/SNTP client over UDP datagrams per RFC 5905 / RFC 4330.
// Packet encode/decode, offset and roundtrip math, and validate are pure.
// The network functions (ntp_request, ntp_sync_time, sntp_request) require a
// UDP socket layer that is not available in the pure stdlib — they are
// documented stubs returning Err.
// ============================================================================

use xiom.string;
use xiom.io;

// struct NtpPacket { li: Int; vn: Int; mode: Int; stratum: Int; poll: Int;
//   precision: Int; root_delay: Float64; root_dispersion: Float64; ref_id: Int;
//   ref_timestamp: Int; origin_timestamp: Int; recv_timestamp: Int;
//   transmit_timestamp: Int }
//   Timestamps are 64-bit NTP era timestamps (seconds since 1900-01-01).
pub type NtpPacket = {
  li: Int;
  vn: Int;
  mode: Int;
  stratum: Int;
  poll: Int;
  precision: Int;
  root_delay: Float64;
  root_dispersion: Float64;
  ref_id: Int;
  ref_timestamp: Int;
  origin_timestamp: Int;
  recv_timestamp: Int;
  transmit_timestamp: Int;
}

// NTP_UNIX_OFFSET is the seconds between the NTP epoch (1900) and the Unix
// epoch (1970).
const NTP_UNIX_OFFSET: Int = 2208988800;

// NTP_PACKET_SIZE is the fixed NTP packet length in bytes.
const NTP_PACKET_SIZE: Int = 48;

// push_u32_be appends a 32-bit big-endian value to a byte vector.
fn push_u32_be(dst: &mut Vec[UInt8], v: Int) {
  dst.push(((v >> 24) & 0xFF) as UInt8);
  dst.push(((v >> 16) & 0xFF) as UInt8);
  dst.push(((v >> 8) & 0xFF) as UInt8);
  dst.push((v & 0xFF) as UInt8);
}

// push_u64_be appends a 64-bit big-endian value to a byte vector.
fn push_u64_be(dst: &mut Vec[UInt8], v: Int) {
  var i = 56;
  while i >= 0 {
    dst.push(((v >> i) & 0xFF) as UInt8);
    i = i - 8;
  }
}

// read_u32_be reads a big-endian 32-bit value at pos (0..255 range safe).
fn read_u32_be(data: &Vec[UInt8], pos: Int) -> Int {
  var v: Int = 0;
  var i = 0;
  while i < 4 {
    v = v * 256 + (data[pos + i] as Int);
    i = i + 1;
  }
  v & 0xFFFFFFFF
}

// read_u64_be reads a big-endian 64-bit value at pos.
fn read_u64_be(data: &Vec[UInt8], pos: Int) -> Int {
  var v: Int = 0;
  var i = 0;
  while i < 8 {
    v = v * 256 + (data[pos + i] as Int);
    i = i + 1;
  }
  v
}

// fixed_to_f64 converts a 32-bit fixed-point value to seconds.
fn fixed_to_f64(v: Int) -> Float64 {
  (v as Float64) / 65536.0
}

// f64_to_fixed converts seconds to a 32-bit fixed-point value.
fn f64_to_fixed(v: Float64) -> Int {
  to_int(v * 65536.0)
}

/// Build a client request packet with the current transmit time.
/// Returns: an NtpPacket with LI=0, VN=4, Mode=3 (client), a zeroed header
///          and the transmit timestamp set to the current NTP time.
/// Complexity: O(1). Pure.
pub fn ntp_packet_new() -> NtpPacket {
  let now = io_time_secs();
  NtpPacket{
    li: 0;
    vn: 4;
    mode: 3;
    stratum: 0;
    poll: 0;
    precision: 0;
    root_delay: 0.0;
    root_dispersion: 0.0;
    ref_id: 0;
    ref_timestamp: 0;
    origin_timestamp: 0;
    recv_timestamp: 0;
    transmit_timestamp: now + NTP_UNIX_OFFSET;
  }
}

// io_time_secs returns the current unix time in seconds.
fn io_time_secs() -> Int {
  let t = io.time_now();
  t
}

/// Serialize an NTP packet to 48 bytes (RFC 5905 wire format).
/// Parameters: p — the packet.
/// Returns: the 48-byte big-endian packet.
/// Complexity: O(1). Pure.
pub fn ntp_packet_to_bytes(p: NtpPacket) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  let b0 = (p.li & 0x3) * 64 + (p.vn & 0x7) * 8 + (p.mode & 0x7);
  out.push(b0 as UInt8);
  out.push((p.stratum & 0xFF) as UInt8);
  out.push((p.poll & 0xFF) as UInt8);
  out.push((p.precision & 0xFF) as UInt8);
  push_u32_be(&mut out, f64_to_fixed(p.root_delay));
  push_u32_be(&mut out, f64_to_fixed(p.root_dispersion));
  push_u32_be(&mut out, p.ref_id);
  push_u64_be(&mut out, p.ref_timestamp);
  push_u64_be(&mut out, p.origin_timestamp);
  push_u64_be(&mut out, p.recv_timestamp);
  push_u64_be(&mut out, p.transmit_timestamp);
  out
}

/// Parse a 48-byte NTP packet.
/// Parameters: data — at least 48 bytes of packet data.
/// Returns: Ok(NtpPacket) for a readable packet, Err when too short.
/// Complexity: O(1). Pure.
pub fn ntp_packet_from_bytes(data: &Vec[UInt8]) -> Result[NtpPacket, Str] {
  if data.len() < NTP_PACKET_SIZE {
    return Err("NTP packet too short");
  }
  let b0 = data[0] as Int;
  let li = (b0 >> 6) & 0x3;
  let vn = (b0 >> 3) & 0x7;
  let mode = b0 & 0x7;
  Ok(NtpPacket{
    li: li;
    vn: vn;
    mode: mode;
    stratum: data[1] as Int;
    poll: data[2] as Int;
    precision: data[3] as Int;
    root_delay: fixed_to_f64(read_u32_be(data, 4));
    root_dispersion: fixed_to_f64(read_u32_be(data, 8));
    ref_id: read_u32_be(data, 12);
    ref_timestamp: read_u64_be(data, 16);
    origin_timestamp: read_u64_be(data, 24);
    recv_timestamp: read_u64_be(data, 32);
    transmit_timestamp: read_u64_be(data, 40);
  })
}

/// Sanity-check a received packet.
/// Parameters: p — the packet.
/// Returns: true when the version is 1..4, the mode is 1..7 (reserved 0
///          excluded) and the transmit timestamp is non-zero.
/// Complexity: O(1). Pure.
pub fn ntp_validate(p: NtpPacket) -> Bool {
  if p.vn < 1 || p.vn > 4 {
    return false;
  }
  if p.mode < 1 || p.mode > 7 {
    return false;
  }
  if p.transmit_timestamp == 0 {
    return false;
  }
  true
}

/// Compute the clock offset in seconds (RFC 5905: (T2 - T1) + (T3 - T4)) / 2.
/// Parameters: packet — the server reply; local_t0 — the client transmit time
///          (unix seconds); local_t1 — the client receive time (unix seconds).
/// Returns: the offset in seconds (positive = local clock is behind).
/// Complexity: O(1). Pure.
pub fn ntp_offset(packet: NtpPacket, local_t0: Int, local_t1: Int) -> Float64 {
  let t1 = local_t0 + NTP_UNIX_OFFSET;
  let t4 = local_t1 + NTP_UNIX_OFFSET;
  let a = packet.recv_timestamp - packet.origin_timestamp;
  let b = packet.transmit_timestamp - t4;
  ((a + b) as Float64) / 2.0
}

/// Compute the roundtrip delay in seconds (RFC 5905: (T4 - T1) - (T3 - T2)).
/// Parameters: packet — the server reply; local_t0 — the client transmit time
///          (unix seconds); local_t1 — the client receive time (unix seconds).
/// Returns: the roundtrip delay in seconds.
/// Complexity: O(1). Pure.
pub fn ntp_roundtrip(packet: NtpPacket, local_t0: Int, local_t1: Int) -> Float64 {
  let t1 = local_t0 + NTP_UNIX_OFFSET;
  let t4 = local_t1 + NTP_UNIX_OFFSET;
  let rtt = (t4 - t1) - (packet.transmit_timestamp - packet.recv_timestamp);
  rtt as Float64
}

/// Send an NTP request and read the reply packet.
/// NOT IMPLEMENTED: requires a UDP socket layer that the pure stdlib does not
/// expose. Use ntp_packet_new / ntp_packet_to_bytes / ntp_packet_from_bytes
/// for offline encode/decode.
/// Returns: Err("ntp_request: UDP sockets not available in the pure stdlib").
pub fn ntp_request(server: Str) -> Result[NtpPacket, Str] {
  let _ = server;
  Err("ntp_request: UDP sockets not available in the pure stdlib")
}

/// Fetch the server time as a unix timestamp.
/// NOT IMPLEMENTED: requires the UDP socket layer (see ntp_request).
/// Returns: Err("ntp_sync_time: UDP sockets not available in the pure stdlib").
pub fn ntp_sync_time(server: Str) -> Result[Int, Str] {
  let _ = server;
  Err("ntp_sync_time: UDP sockets not available in the pure stdlib")
}

/// One-shot SNTP client returning a unix timestamp.
/// NOT IMPLEMENTED: requires the UDP socket layer (see ntp_request).
/// Returns: Err("sntp_request: UDP sockets not available in the pure stdlib").
pub fn sntp_request(server: Str) -> Result[Int, Str] {
  let _ = server;
  Err("sntp_request: UDP sockets not available in the pure stdlib")
}
