// XIOM - Network: NTP / SNTP
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.ntp

// ============================================================================
// NTP/SNTP client over UDP datagrams per RFC 5905 / RFC 4330.
// Packet encode/decode, offset and roundtrip math, and sync-time helpers.
// ============================================================================

// struct NtpPacket { li: Int; vn: Int; mode: Int; stratum: Int; poll: Int; precision: Int; root_delay: Float64; root_dispersion: Float64; ref_id: Int; ref_timestamp: Int; origin_timestamp: Int; recv_timestamp: Int; transmit_timestamp: Int }

// fn ntp_request(server: Str) -> Result[NtpPacket, Str] - send an NTP request and read the reply packet. TODO(compiler): implement.
// fn ntp_offset(packet: NtpPacket, local_t0: Int, local_t1: Int) -> Float64 - compute clock offset in seconds. TODO(compiler): implement.
// fn ntp_roundtrip(packet: NtpPacket, local_t0: Int, local_t1: Int) -> Float64 - compute roundtrip delay in seconds. TODO(compiler): implement.
// fn ntp_sync_time(server: Str) -> Result[Int, Str] - fetch the server time as a unix timestamp. TODO(compiler): implement.
// fn ntp_packet_new() -> NtpPacket - build a client request packet with current transmit time. TODO(compiler): implement.
// fn ntp_packet_to_bytes(p: NtpPacket) -> Vec[UInt8] - serialize an NTP packet to 48 bytes. TODO(compiler): implement.
// fn ntp_packet_from_bytes(data: &Vec[UInt8]) -> Result[NtpPacket, Str] - parse a 48-byte NTP packet. TODO(compiler): implement.
// fn ntp_validate(p: NtpPacket) -> Bool - sanity-check a received packet. TODO(compiler): implement.
// fn sntp_request(server: Str) -> Result[Int, Str] - one-shot SNTP client returning a unix timestamp. TODO(compiler): implement.
