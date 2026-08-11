// XIOM - Networking: IP Addresses
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.ip

// Depends on: xiom.net + xiom.string

// ============================================================================
// IPv4/IPv6 parsing, formatting, classification, masking and subnet tests.
// NOTE: current implementation lives in net.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type IpAddr - an IP address enum: V4 holding four octets, V6 holding eight 16-bit parts.
// fn ipv4_parse(s: Str) -> Option[Vec[UInt8]] - parse a dotted-quad IPv4 string into four octets. TODO(compiler): implement.
// fn ipv4_to_string(octets: &Vec[UInt8]) -> Str - format four octets as a dotted-quad IPv4 string. TODO(compiler): implement.
// fn ipv6_parse(s: Str) -> Option[Vec[UInt16]] - parse an IPv6 string (with :: compression) into eight 16-bit parts. TODO(compiler): implement.
// fn ipv6_to_string(parts: &Vec[UInt16]) -> Str - format eight 16-bit parts as an IPv6 string. TODO(compiler): implement.
// fn ip_parse(s: Str) -> Option[IpAddr] - parse an IPv4 or IPv6 string into an IpAddr. TODO(compiler): implement.
// fn ip_is_loopback(s: Str) -> Bool - true for loopback addresses (127.0.0.0/8, ::1). TODO(compiler): implement.
// fn ip_is_private(s: Str) -> Bool - true for private-use ranges (10/8, 172.16/12, 192.168/16, fc00::/7). TODO(compiler): implement.
// fn ip_is_link_local(s: Str) -> Bool - true for link-local ranges (169.254/16, fe80::/10). TODO(compiler): implement.
// fn ip_is_multicast(s: Str) -> Bool - true for multicast ranges (224.0.0.0/4, ff00::/8). TODO(compiler): implement.
// fn ip_is_unspecified(s: Str) -> Bool - true for the all-zero address. TODO(compiler): implement.
// fn ip_masked(s: Str, prefix: Int) -> Str - apply a CIDR prefix mask to an address. TODO(compiler): implement.
// fn ip_in_subnet(ip: Str, subnet: Str) -> Bool - test whether ip falls inside a CIDR subnet. TODO(compiler): implement.
// fn ip_compress(s: Str) -> Str - compress an IPv6 string using :: and leading-zero elision. TODO(compiler): implement.
// fn ip_expand(s: Str) -> Str - expand an IPv6 string to the full eight-part form. TODO(compiler): implement.
// fn ip_octets(s: Str) -> Vec[Int] - split an IPv4 string into its numeric octets. TODO(compiler): implement.
