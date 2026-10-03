// p_wave61_shapes.xi -- wave 61 shape validation: xiom.net protocol family
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-61 clauses on xiom.net.{proto, smtp, ftp, ntp, ping}
// (48 pub fns). All KATs are pure/no-socket; the nine network entry points
// are documented Err stubs. Option payloads stay presence-only; NTP
// packets are built via from_bytes so no struct literal field order is
// assumed. Returns 0 when every case holds.

module p_wave61_shapes

use xiom.net.proto;
use xiom.net.smtp;
use xiom.net.ftp;
use xiom.net.ntp;
use xiom.net.ping;

fn main() -> Int {
  // ---- proto
  if !(proto.jsonrpc_request(1, "m", "{}") == "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"m\",\"params\":{}}") { return 1; }
  if !(proto.jsonrpc_success(2, "null") == "{\"jsonrpc\":\"2.0\",\"id\":2,\"result\":null}") { return 2; }
  if !(proto.jsonrpc_error(3, -32601, "nope") == "{\"jsonrpc\":\"2.0\",\"id\":3,\"error\":{\"code\":-32601,\"message\":\"nope\"}}") { return 3; }
  if !(proto.sse_format_event("ping", "") == "event: ping\ndata: \n\n") { return 4; }
  if !(proto.sse_format_event("e", "a\nb") == "event: e\ndata: a\ndata: b\n\n") { return 5; }
  if !(proto.sse_format_data("hi") == "data: hi\n\n") { return 6; }
  var hdrs = proto.http_header_parse("A: 1\r\nB:2\n");
  if hdrs.len() != 2 { return 7; }
  if !(hdrs[0].0 == "A" && hdrs[0].1 == "1") { return 8; }
  if proto.http_header_parse("").len() != 0 { return 9; }
  if !proto.http_header_get(hdrs, "a").is_some { return 10; }
  if proto.http_header_get(hdrs, "z").is_some { return 11; }
  if !(proto.basic_auth_header("user", "pass") == "Basic dXNlcjpwYXNz") { return 12; }
  if !(proto.bearer_auth_header("tok") == "Bearer tok") { return 13; }
  if !(proto.http_status_text(404) == "Not Found") { return 14; }
  if !(proto.http_status_text(599) == "Unknown") { return 15; }

  // ---- smtp
  if smtp.smtp_default_port() != 25 { return 16; }
  if !(smtp.smtp_command_helo("h") == "HELO h\r\n") { return 17; }
  if !(smtp.smtp_command_ehlo("h") == "EHLO h\r\n") { return 18; }
  if !(smtp.smtp_command_mail_from("a@b") == "MAIL FROM:<a@b>\r\n") { return 19; }
  if !(smtp.smtp_command_rcpt_to("a@b") == "RCPT TO:<a@b>\r\n") { return 20; }
  if !(smtp.smtp_command_data() == "DATA\r\n") { return 21; }
  if !(smtp.smtp_command_quit() == "QUIT\r\n") { return 22; }
  if !(smtp.smtp_command_noop() == "NOOP\r\n") { return 23; }
  if !(smtp.smtp_command_rset() == "RSET\r\n") { return 24; }
  if !(smtp.smtp_command_auth_login() == "AUTH LOGIN\r\n") { return 25; }
  if !(smtp.smtp_body_end() == "\r\n.\r\n") { return 26; }
  if !smtp.smtp_parse_reply("250 OK").is_some { return 27; }
  if smtp.smtp_parse_reply("2a0").is_some { return 28; }
  if smtp.smtp_parse_reply("25").is_some { return 29; }
  if !smtp.smtp_reply_is_success(250) { return 30; }
  if smtp.smtp_reply_is_success(199) { return 31; }
  if smtp.smtp_reply_is_success(300) { return 32; }

  // ---- ftp
  if ftp.ftp_default_port() != 21 { return 33; }
  if !(ftp.ftp_command_user("u") == "USER u\r\n") { return 34; }
  if !(ftp.ftp_command_pass("p") == "PASS p\r\n") { return 35; }
  if !(ftp.ftp_command_retr("/f") == "RETR /f\r\n") { return 36; }
  if !(ftp.ftp_command_stor("/f") == "STOR /f\r\n") { return 37; }
  if !(ftp.ftp_command_list("") == "LIST\r\n") { return 38; }
  if !(ftp.ftp_command_list("/pub") == "LIST /pub\r\n") { return 39; }
  if !(ftp.ftp_command_quit() == "QUIT\r\n") { return 40; }
  if !(ftp.ftp_command_cwd("/d") == "CWD /d\r\n") { return 41; }
  if !(ftp.ftp_command_type("I") == "TYPE I\r\n") { return 42; }
  if !ftp.ftp_parse_reply("220 Ready").is_some { return 43; }
  if ftp.ftp_parse_reply("22").is_some { return 44; }
  if !ftp.ftp_reply_is_success(299) { return 45; }
  if ftp.ftp_reply_is_success(300) { return 46; }
  if !ftp.ftp_reply_is_positive_preliminary(100) { return 47; }

  // ---- ntp (packets via from_bytes)
  var zero48 = Vec[UInt8].new();
  var z = 0;
  while z < 48 { zero48.push(0); z = z + 1; }
  match ntp.ntp_packet_from_bytes(&zero48) {
    Ok(p) => {
      if ntp.ntp_validate(p) { return 48; }
      if !(ntp.ntp_packet_to_bytes(p).len() == 48) { return 49; }
      if !(ntp.ntp_packet_to_bytes(p)[0] == (0x00 as UInt8)) { return 50; }
      if !(ntp.ntp_offset(p, 0, 0) == -1104494400.0) { return 51; }
      if !(ntp.ntp_roundtrip(p, 100, 110) == 10.0) { return 52; }
    },
    Err(_) => { return 53; },
  }
  if ntp.ntp_packet_from_bytes(&Vec[UInt8].new()).is_ok { return 54; }
  var short47 = Vec[UInt8].new();
  var s = 0;
  while s < 47 { short47.push(0); s = s + 1; }
  if ntp.ntp_packet_from_bytes(&short47).is_ok { return 55; }
  var live = Vec[UInt8].new();
  live.push(0x23);
  var l = 1;
  while l < 48 { live.push(0); l = l + 1; }
  live.push(0);
  match ntp.ntp_packet_from_bytes(&live) {
    Ok(p2) => {
      if p2.vn != 4 { return 56; }
      if p2.mode != 3 { return 57; }
    },
    Err(_) => { return 58; },
  }
  var pkt = ntp.ntp_packet_new();
  if !(pkt.li == 0 && pkt.vn == 4 && pkt.mode == 3) { return 59; }
  if ntp.ntp_packet_to_bytes(pkt).len() != 48 { return 60; }
  if !ntp.ntp_request("localhost").is_err { return 61; }
  if !ntp.ntp_sync_time("localhost").is_err { return 62; }
  if !ntp.sntp_request("localhost").is_err { return 63; }

  // ---- ping
  var empty_ping = Vec[UInt8].new();
  let ck_empty = ping.icmp_checksum(&empty_ping);
  if !(ck_empty == 65535) { return 64; }
  var two = Vec[UInt8].new();
  two.push(0);
  two.push(1);
  let ck_two = ping.icmp_checksum(&two);
  if !(ck_two == 65534) { return 65; }
  var icmp = Vec[UInt8].new();
  icmp.push(8);
  icmp.push(0);
  icmp.push(0);
  icmp.push(0);
  icmp.push(0);
  icmp.push(1);
  icmp.push(0);
  icmp.push(1);
  let ck_icmp = ping.icmp_checksum(&icmp);
  if !(ck_icmp == 63485) { return 66; }
  if !ping.ping_send_echo("127.0.0.1", 1, 1, Vec[UInt8].new()).is_err { return 67; }
  if !ping.ping_recv_echo(100).is_err { return 68; }
  if !ping.ping_once("127.0.0.1", 100).is_err { return 69; }
  if !ping.ping("127.0.0.1", 100).is_err { return 70; }
  if !ping.traceroute_hop("127.0.0.1", 1, 100).is_err { return 71; }
  if !ping.traceroute("127.0.0.1", 3, 100).is_err { return 72; }

  return 0;
}
