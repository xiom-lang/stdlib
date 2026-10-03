// p_wave60_shapes.xi -- wave 60 shape validation: xiom.net transport family
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-60 clauses on xiom.net.{socket, tcp, udp, unix, tls,
// tls_helper} (53 pub fns). Network entry points are probed through their
// early-error paths only; socket_tcp/udp create one local fd each and close
// it immediately (no connect/bind). Unix sockets are documented pure stubs.
// Returns 0 when every case holds.

module p_wave60_shapes

use xiom.net.socket;
use xiom.net.tcp;
use xiom.net.udp;
use xiom.net.unix;
use xiom.net.tls;
use xiom.net.tls_helper;
use xiom.net.unix.UnixSocket;

fn main() -> Int {
  // ---- socket constructors (create + close one local fd each)
  match socket.socket_tcp() {
    Ok(fd) => {
      if fd < 0 { return 1; }
      socket.socket_close(fd);
    },
    Err(_) => {},
  }
  match socket.socket_udp() {
    Ok(fd) => {
      if fd < 0 { return 2; }
      socket.socket_close(fd);
    },
    Err(_) => {},
  }
  // ---- socket early-error paths
  if socket.socket_bind(-1, "127.0.0.1", 80).is_ok { return 3; }
  if socket.socket_bind(3, "", 80).is_ok { return 4; }
  if socket.socket_bind(3, "h", 0).is_ok { return 5; }
  if socket.socket_bind(3, "h", 65536).is_ok { return 6; }
  if socket.socket_listen(-1, 5).is_ok { return 7; }
  if socket.socket_listen(3, -1).is_ok { return 8; }
  if socket.socket_accept(-1).is_ok { return 9; }
  if socket.socket_connect(-1, "h", 80).is_ok { return 10; }
  if socket.socket_connect(3, "", 80).is_ok { return 11; }
  if socket.socket_connect(3, "h", 65536).is_ok { return 12; }
  if socket.socket_send(-1, Vec[UInt8].new()).is_ok { return 13; }
  if socket.socket_recv(-1, 8).is_ok { return 14; }
  if socket.socket_recv(3, 0).is_ok { return 15; }
  if socket.socket_recv(3, -1).is_ok { return 16; }
  if socket.socket_send_to(-1, Vec[UInt8].new(), "h", 80).is_ok { return 17; }
  if socket.socket_send_to(3, Vec[UInt8].new(), "h", 0).is_ok { return 18; }
  if socket.socket_recv_from(-1, 8).is_ok { return 19; }
  if socket.socket_recv_from(3, -1).is_ok { return 20; }
  socket.socket_close(-1);
  if socket.socket_set_timeout(3, 100).is_ok { return 21; }
  if socket.socket_set_nonblocking(3, true).is_ok { return 22; }
  if socket.socket_shutdown(3, 3).is_ok { return 23; }
  if socket.socket_peer_addr(3).is_ok { return 24; }
  if socket.socket_local_addr(-1).is_ok { return 25; }
  if socket.socket_available(-1) != 0 { return 26; }
  if socket.socket_available(3) != 0 { return 27; }
  if socket.socket_reuse_addr(3, true).is_ok { return 28; }

  // ---- tcp / udp endpoints
  if tcp.tcp_validate_port(0) { return 29; }
  if !tcp.tcp_validate_port(65535) { return 30; }
  if tcp.tcp_validate_port(65536) { return 31; }
  if udp.udp_validate_port(-1) { return 32; }
  if !udp.udp_is_valid_port(80) { return 33; }
  if tcp.tcp_parse_endpoint("").is_some { return 34; }
  if tcp.tcp_parse_endpoint("host:").is_some { return 35; }
  if !tcp.tcp_parse_endpoint("host:80").is_some { return 36; }
  if !(tcp.tcp_format_endpoint("h", 80) == "h:80") { return 37; }
  if !(tcp.tcp_format_endpoint("", 0) == ":0") { return 38; }
  if udp.udp_parse_endpoint("").is_some { return 39; }
  if !udp.udp_parse_endpoint("h:1").is_some { return 40; }
  if !(udp.udp_format_endpoint("h", -1) == "h:-1") { return 41; }

  // ---- unix stubs (documented always-Err)
  var us = UnixSocket{ fd: 0; path: ""; listening: false; };
  if unix.unix_connect("").is_ok { return 42; }
  if unix.unix_listen("/tmp/x").is_ok { return 43; }
  if unix.unix_accept(us).is_ok { return 44; }
  if unix.unix_send(us, Vec[UInt8].new()).is_ok { return 45; }
  if unix.unix_recv(us, 0).is_ok { return 46; }
  unix.unix_close(us);
  if unix.unix_bind("").is_ok { return 47; }
  if unix.unix_connect_timeout("", -1).is_ok { return 48; }
  if unix.unix_socketpair().is_ok { return 49; }
  if unix.unix_peer_credentials(us).is_ok { return 50; }

  // ---- tls tables
  if tls.tls_default_port() != 443 { return 51; }
  if !(tls.tls_version_name(0x0303) == "TLSv1.2") { return 52; }
  if !(tls.tls_version_name(0x9999) == "unknown") { return 53; }
  if !(tls.tls_handshake_type_name(1) == "client_hello") { return 54; }
  if !(tls.tls_handshake_type_name(20) == "finished") { return 55; }
  if !(tls.tls_handshake_type_name(99) == "unknown") { return 56; }
  if !(tls.tls_alert_name(0) == "close_notify") { return 57; }
  if !(tls.tls_alert_name(120) == "no_application_protocol") { return 58; }
  if !(tls.tls_alert_name(999) == "unknown") { return 59; }
  if !(tls.tls_cipher_suite_name(0x1301) == "TLS_AES_128_GCM_SHA256") { return 60; }
  if !(tls.tls_cipher_suite_name(0xFFFF) == "unknown") { return 61; }

  // ---- tls_helper (pure DER/PEM)
  var empty8 = Vec[UInt8].new();
  if tls_helper.der_length_decode(&empty8, 0).is_ok { return 62; }
  var five = Vec[UInt8].new();
  five.push(5);
  if !tls_helper.der_length_decode(&five, 0).is_ok { return 63; }
  var trunc = Vec[UInt8].new();
  trunc.push(0x82);
  trunc.push(0x01);
  if tls_helper.der_length_decode(&trunc, 0).is_ok { return 64; }
  if tls_helper.der_length_decode(&five, -1).is_ok { return 65; }
  if tls_helper.asn1_read_oid(&empty8, 0).is_ok { return 66; }
  var oid = Vec[UInt8].new();
  oid.push(0x06);
  oid.push(0x03);
  oid.push(0x55);
  oid.push(0x04);
  oid.push(0x03);
  if !tls_helper.asn1_read_oid(&oid, 0).is_ok { return 67; }
  if tls_helper.cert_fingerprint_sha256(&empty8).len() != 32 { return 68; }
  var three = Vec[UInt8].new();
  three.push(1);
  three.push(2);
  three.push(3);
  if tls_helper.cert_fingerprint_sha1(&three).len() != 0 { return 69; }
  if tls_helper.cert_validity_dates(&empty8).is_ok { return 70; }
  if tls_helper.cert_subject_cn(&empty8).is_ok { return 71; }
  if tls_helper.cert_issuer_cn(&empty8).is_ok { return 72; }
  if tls_helper.cert_public_key_info(&empty8).is_ok { return 73; }
  if tls_helper.cert_is_self_signed(&empty8) { return 74; }
  var armor = tls_helper.pem_encode(&empty8, "CERTIFICATE");
  if !(armor.len() == 54) { return 75; }
  if tls_helper.pem_decode("").is_ok { return 76; }
  if tls_helper.pem_decode("not a pem").is_ok { return 77; }
  if !tls_helper.pem_decode(armor).is_ok { return 78; }
  if tls_helper.pem_parse_certificates("").is_ok { return 79; }
  var der2 = Vec[UInt8].new();
  der2.push(0x30);
  der2.push(0x00);
  if !tls_helper.pem_parse_certificates(tls_helper.pem_encode(&der2, "CERTIFICATE")).is_ok { return 80; }
  return 0;
}
