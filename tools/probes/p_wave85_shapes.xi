// p_wave85_shapes.xi -- wave 85 shape validation: ip/lossy/network/timestamp
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-85 clause guards: the ip length guards (is_valid_ipv4
// < 7 / > 15, is_valid_ipv6 < 2), the empty-input identities on
// ipv4_to_string / string_to_ipv4 / ip_parse / ip_to_bytes, the lossy
// empty/sign-only zero pins, the NaN and 2^63 clamp mirrors of
// lossy_from_float, the exact byte-swap mirrors of the network family and
// the epoch pins of timestamp_to_date / timestamp_to_datetime /
// timestamp_from_date / timestamp_from_datetime. Values returned from the
// module surface are bound before comparing/reading. Returns 0 when every
// case holds.

module p_wave85_shapes

use xiom.string;
use xiom.time;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;
use xiom.convert.ip as cip;
use xiom.convert.lossy as closs;
use xiom.convert.network as cnet;
use xiom.convert.timestamp as cts;

fn main() -> Int {
  // ---- ip: validators
  if cip.is_valid_ipv4("") { return 1; }
  if cip.is_valid_ipv4("1.2.3.4") == false { return 2; }
  if cip.is_valid_ipv4("192.168.1") { return 3; }
  if cip.is_valid_ipv6("") { return 4; }
  if cip.is_valid_ipv6("::1") == false { return 5; }
  if cip.is_valid_ipv6("2001:::1") { return 6; }
  if cip.is_valid_ipv4("192.168.0001.1111") { return 57; }

  // ---- ip: formatting
  let oct0 = Vec[UInt8].new();
  let s0 = cip.ipv4_to_string(&oct0);
  if s0 != "" { return 7; }
  let oct4 = Vec[UInt8].new();
  oct4.push(255);
  oct4.push(255);
  oct4.push(255);
  oct4.push(255);
  let s4 = cip.ipv4_to_string(&oct4);
  if s4.len() != 15 { return 8; }
  let oct192 = Vec[UInt8].new();
  oct192.push(192);
  oct192.push(168);
  oct192.push(1);
  oct192.push(1);
  let s192 = cip.ipv4_to_string(&oct192);
  if s192 != "192.168.1.1" { return 9; }

  // ---- ip: parsers (presence + payload shape through match)
  if cip.string_to_ipv4("").is_some { return 10; }
  if cip.string_to_ipv4("1.2.3.4").is_none { return 11; }
  if cip.string_to_ipv4("300.1.1.1").is_some { return 12; }
  if cip.string_to_ipv4("192.168.0001.1111").is_some { return 58; }
  if cip.ip_parse("").is_some { return 13; }
  let p4 = cip.ip_parse("1.2.3.4");
  match p4 {
    Some(c4) => { if c4 != "1.2.3.4" { return 14; } },
    None => { return 15; },
  }
  let p6 = cip.ip_parse("2001:db8::1");
  match p6 {
    Some(c6) => { if c6 != "2001:db8::1" { return 16; } },
    None => { return 17; },
  }
  if cip.ip_to_bytes("").is_some { return 18; }
  let b4 = cip.ip_to_bytes("1.2.3.4");
  match b4 {
    Some(v4) => { if v4.len() != 4 { return 19; } },
    None => { return 20; },
  }
  let b6 = cip.ip_to_bytes("::1");
  match b6 {
    Some(v6) => { if v6.len() != 16 { return 21; } },
    None => { return 22; },
  }

  // ---- lossy: string parse
  if closs.lossy_from_str("") != 0 { return 23; }
  if closs.lossy_from_str("-") != 0 { return 24; }
  if closs.lossy_from_str("+") != 0 { return 25; }
  if closs.lossy_from_str("42") != 42 { return 26; }
  if closs.lossy_from_str("-17") != 0 - 17 { return 27; }
  if closs.lossy_from_str("12x") != 0 { return 28; }

  // ---- lossy: float parse
  let nan = 0.0 / 0.0;
  if closs.lossy_from_float(nan) != 0 { return 29; }
  if closs.lossy_from_float(1.0e300) != INT_MAX { return 30; }
  if closs.lossy_from_float(-1.0e300) != INT_MIN { return 31; }
  if closs.lossy_from_float(2.7) != 2 { return 32; }

  // ---- lossy: to_float / char
  if closs.lossy_to_float("") != 0.0 { return 33; }
  if closs.lossy_to_float("-") != 0.0 { return 34; }
  if closs.lossy_to_float("2.5") != 2.5 { return 35; }
  if closs.lossy_char("") != '\0' { return 36; }
  if closs.lossy_char("abc") != 'a' { return 37; }

  // ---- network: byte swaps
  if cnet.host_to_network16(0x1234) != 0x3412 { return 38; }
  if cnet.network_to_host16(0x3412) != 0x1234 { return 39; }
  if cnet.host_to_network32(0x12345678) != 0x78563412 { return 40; }
  if cnet.network_to_host32(0x78563412) != 0x12345678 { return 41; }
  if cnet.htonll(0x1122334455667788) != 0x8877665544332211 { return 42; }
  if cnet.ntohll(0x8877665544332211) != 0x1122334455667788 { return 43; }
  if cnet.host_to_network16(0) != 0 { return 44; }
  if cnet.htonll(0) != 0 { return 45; }
  if cnet.htonll(1) != 0x0100000000000000 { return 46; }
  if cnet.htonll(255) != 0 - 72057594037927936 { return 59; }
  if cnet.ntohll(0 - 72057594037927936) != 255 { return 60; }

  // ---- timestamp: clock + epoch pins
  let now = cts.timestamp_now();
  if now <= 0 { return 47; }
  let d0 = cts.timestamp_to_date(0);
  if d0.year != 1970 || d0.month != 1 || d0.day != 1 { return 48; }
  let d86399 = cts.timestamp_to_date(86399);
  if d86399.year != 1970 || d86399.month != 1 || d86399.day != 1 { return 49; }
  let d86400 = cts.timestamp_to_date(86400);
  if d86400.day != 2 { return 50; }
  let dt0 = cts.timestamp_to_datetime(0);
  if dt0.year != 1970 || dt0.hour != 0 || dt0.minute != 0 || dt0.second != 0 { return 51; }
  let dt3661 = cts.timestamp_to_datetime(3661);
  if dt3661.hour != 1 || dt3661.minute != 1 || dt3661.second != 1 { return 52; }
  let dneg = cts.timestamp_to_date(0 - 1);
  if dneg.year != 1969 || dneg.month != 12 || dneg.day != 31 { return 61; }
  let dtneg = cts.timestamp_to_datetime(0 - 1);
  if dtneg.year != 1969 || dtneg.month != 12 || dtneg.day != 31 { return 62; }
  if dtneg.hour != 23 || dtneg.minute != 59 || dtneg.second != 59 { return 63; }

  let epoch_date = Date{ year: 1970; month: 1; day: 1; };
  if cts.timestamp_from_date(&epoch_date) != 0 { return 53; }
  let epoch_dt = DateTime{ year: 1970; month: 1; day: 1; hour: 0; minute: 0; second: 0; weekday: 4; };
  if cts.timestamp_from_datetime(&epoch_dt) != 0 { return 54; }
  let next_dt = DateTime{ year: 1970; month: 1; day: 2; hour: 0; minute: 0; second: 1; weekday: 5; };
  if cts.timestamp_from_datetime(&next_dt) != 86401 { return 55; }
  let round = cts.timestamp_from_date(&Date{ year: 2026; month: 8; day: 12; });
  let back = cts.timestamp_to_date(round);
  if back.year != 2026 || back.month != 8 || back.day != 12 { return 56; }

  return 0;
}
