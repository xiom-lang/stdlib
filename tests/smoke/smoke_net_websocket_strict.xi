// XIOM stdlib smoke -- strict WebSocket frame validation (RFC 6455 negative corpus).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Regression corpus for REL-20261107-1349-pulse: a 64-bit length with the
// MSB set must not produce a negative consumed count; non-minimal lengths,
// RSV bits, invalid opcodes/control frames, oversize declarations, invalid
// close codes and invalid UTF-8 text are rejected.

module smoke_net_websocket_strict
use xiom.net.websocket;
use xiom.io;

fn is_err(b: &Vec[UInt8]) -> Bool {
  match websocket.ws_frame_take(b) {
    Ok(_) => false,
    Err(_) => true,
  }
}

fn is_ok(b: &Vec[UInt8]) -> Bool {
  match websocket.ws_frame_take(b) {
    Ok(_) => true,
    Err(_) => false,
  }
}

fn main() -> Int {
  // MSB-set 64-bit length, masked FIN text, no payload: the old parser
  // returned a negative consumed count here.
  var f = Vec[UInt8].new();
  f.push(0x81u8); f.push(0xFFu8);
  f.push(0x80u8); f.push(0x00u8); f.push(0x00u8); f.push(0x00u8);
  f.push(0x00u8); f.push(0x00u8); f.push(0x00u8); f.push(0x00u8);
  f.push(0x01u8); f.push(0x02u8); f.push(0x03u8); f.push(0x04u8);
  if !is_err(&f) { return 10; }

  // Non-minimal 16-bit length (5 encoded as 126).
  var f16 = Vec[UInt8].new();
  f16.push(0x81u8); f16.push(0xFEu8); f16.push(0x00u8); f16.push(0x05u8);
  f16.push(0x01u8); f16.push(0x02u8); f16.push(0x03u8); f16.push(0x04u8);
  f16.push(0x61u8); f16.push(0x61u8); f16.push(0x61u8); f16.push(0x61u8); f16.push(0x61u8);
  if !is_err(&f16) { return 11; }

  // Non-minimal 64-bit length (5 encoded as 127).
  var f64 = Vec[UInt8].new();
  f64.push(0x81u8); f64.push(0xFFu8);
  f64.push(0x00u8); f64.push(0x00u8); f64.push(0x00u8); f64.push(0x00u8);
  f64.push(0x00u8); f64.push(0x00u8); f64.push(0x00u8); f64.push(0x05u8);
  f64.push(0x01u8); f64.push(0x02u8); f64.push(0x03u8); f64.push(0x04u8);
  f64.push(0x61u8); f64.push(0x61u8); f64.push(0x61u8); f64.push(0x61u8); f64.push(0x61u8);
  if !is_err(&f64) { return 12; }

  // RSV1 set.
  var rsv = Vec[UInt8].new(); rsv.push(0xC1u8); rsv.push(0x00u8);
  if !is_err(&rsv) { return 13; }

  // Reserved opcode 3.
  var op = Vec[UInt8].new(); op.push(0x83u8); op.push(0x00u8);
  if !is_err(&op) { return 14; }

  // Fragmented ping and a control frame using an extended length.
  var frag = Vec[UInt8].new(); frag.push(0x09u8); frag.push(0x00u8);
  if !is_err(&frag) { return 15; }
  var bigctl = Vec[UInt8].new(); bigctl.push(0x89u8); bigctl.push(0x7Eu8);
  if !is_err(&bigctl) { return 16; }

  // Invalid close codes 1005 and 999, and a 1-byte close payload.
  var c1005 = Vec[UInt8].new();
  c1005.push(0x88u8); c1005.push(0x02u8); c1005.push(0x03u8); c1005.push(0xEDu8);
  if !is_err(&c1005) { return 20; }
  var c999 = Vec[UInt8].new();
  c999.push(0x88u8); c999.push(0x02u8); c999.push(0x03u8); c999.push(0xE7u8);
  if !is_err(&c999) { return 21; }
  var c1 = Vec[UInt8].new();
  c1.push(0x88u8); c1.push(0x01u8); c1.push(0x03u8);
  if !is_err(&c1) { return 22; }

  // Invalid UTF-8 in a final text frame.
  var badutf = Vec[UInt8].new();
  badutf.push(0x81u8); badutf.push(0x02u8); badutf.push(0xC3u8); badutf.push(0x28u8);
  if !is_err(&badutf) { return 23; }

  // Oversize 64-bit declaration (1 << 40) is rejected before buffering.
  var huge = Vec[UInt8].new();
  huge.push(0x81u8); huge.push(0x7Fu8);
  huge.push(0x00u8); huge.push(0x00u8); huge.push(0x01u8); huge.push(0x00u8);
  huge.push(0x00u8); huge.push(0x00u8); huge.push(0x00u8); huge.push(0x00u8);
  if !is_err(&huge) { return 24; }

  // Valid unfragmented text, masked and unmasked.
  var ok1 = Vec[UInt8].new();
  ok1.push(0x81u8); ok1.push(0x02u8); ok1.push(0x68u8); ok1.push(0x69u8);
  if !is_ok(&ok1) { return 30; }
  var ok2 = Vec[UInt8].new();
  ok2.push(0x81u8); ok2.push(0x82u8);
  ok2.push(0x01u8); ok2.push(0x02u8); ok2.push(0x03u8); ok2.push(0x04u8);
  ok2.push(0x69u8); ok2.push(0x6Bu8);
  if !is_ok(&ok2) { return 31; }

  // Valid close 1000 with a UTF-8 reason.
  var okc = Vec[UInt8].new();
  okc.push(0x88u8); okc.push(0x05u8);
  okc.push(0x03u8); okc.push(0xE8u8);
  okc.push(0x62u8); okc.push(0x79u8); okc.push(0x65u8);
  if !is_ok(&okc) { return 32; }

  io.println("OK");
  return 0;
}
