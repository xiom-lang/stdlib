// XIOM - Network: ICMP Ping and Traceroute
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.ping

// Depends on: xiom.net

// ============================================================================
// ICMP echo (ping) and traceroute via raw sockets through minimal FFI.
// Echo send/receive, checksum math, and per-hop traversal helpers.
// ============================================================================

// struct PingStats { sent: Int; received: Int; min_ms: Int; avg_ms: Int; max_ms: Int }

// (Int, Int, Int) - recv_echo result: id, seq, rtt_ms.

// fn ping(host: Str, timeout_ms: Int) -> Result[PingStats, Str] - run a ping burst and return aggregate stats. TODO(compiler): implement.
// fn ping_once(host: Str, timeout_ms: Int) -> Result[Int, Str] - send one echo and return the rtt in ms. TODO(compiler): implement.
// fn ping_send_echo(host: Str, id: Int, seq: Int, payload: &Vec[UInt8]) -> Result[Int, Str] - send one ICMP echo request. TODO(compiler): implement.
// fn ping_recv_echo(timeout_ms: Int) -> Result[(Int, Int, Int), Str] - wait for one echo reply. TODO(compiler): implement.
// fn icmp_checksum(data: &Vec[UInt8]) -> UInt16 - compute the ICMP header checksum. TODO(compiler): implement.
// fn traceroute(host: Str, max_hops: Int, timeout_ms: Int) -> Result[Vec[Str], Str] - trace the route to a host by hop. TODO(compiler): implement.
// fn traceroute_hop(host: Str, ttl: Int, timeout_ms: Int) -> Result[Str, Str] - probe a single hop and return its address. TODO(compiler): implement.
