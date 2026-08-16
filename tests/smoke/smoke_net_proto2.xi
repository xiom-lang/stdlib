// XIOM stdlib smoke test — xiom.net.ntp + xiom.net.ping + xiom.net.unix
// NTP packet encode/decode, ICMP checksum, and unix socket stubs.
// Returns 0 on success, nonzero on failure (process exit code).
// NOTE: ntp_packet_to_bytes triggers an LLVM codegen bug (a module fn taking
// the Float64-bearing NtpPacket struct by value and returning Vec miscompiles
// in the fresh compiler) — it is exercised only inside the module.

module smoke_net_proto2

use xiom.net.ntp;
use xiom.net.ping;
use xiom.net.unix;
use xiom.io;

fn main() -> Int {
  // --- ntp: packet_new fields ---
  let p = ntp.ntp_packet_new();
  if p.vn != 4 {
    io.println("ntp-vn");
    return 1;
  }
  if p.mode != 3 {
    io.println("ntp-mode");
    return 2;
  }
  if p.transmit_timestamp <= 2208988800 {
    io.println("ntp-tx");
    return 3;
  }

  // --- ntp: from_bytes + validate ---
  var reply = Vec[UInt8].new();
  var i = 0;
  while i < 48 {
    reply.push(0 as UInt8);
    i = i + 1;
  }
  reply[0] = 36 as UInt8;
  write_u64_at(&mut reply, 16, 2000);
  write_u64_at(&mut reply, 24, 100);
  write_u64_at(&mut reply, 32, 110);
  write_u64_at(&mut reply, 40, 120);
  {
    let pk = ntp.ntp_packet_from_bytes(&reply);
    match pk {
      Err(e) => {
        io.println("ntp-frombytes");
        return 4;
      }
      Ok(pk2) => {
        if pk2.vn != 4 || pk2.mode != 4 {
          io.println("ntp-fields");
          return 5;
        }
        if pk2.ref_timestamp != 2000 {
          io.println("ntp-ref");
          return 6;
        }
        if pk2.origin_timestamp != 100 {
          io.println("ntp-origin");
          return 7;
        }
        if !ntp.ntp_validate(pk2) {
          io.println("ntp-validate");
          return 8;
        }
        // offset = ((recv - origin) + (transmit - t4)) / 2
        // with t0=unix(100), t1=unix(130): ((110-100)+(120-130))/2 = 0
        let off = ntp.ntp_offset(pk2, 100 - 2208988800, 130 - 2208988800);
        // rtt = (t4 - t1) - (transmit - recv) = 30 - 10 = 20
        let rtt = ntp.ntp_roundtrip(pk2, 100 - 2208988800, 130 - 2208988800);
        if off != 0.0 {
          io.println("ntp-offset");
          return 9;
        }
        if rtt != 20.0 {
          io.println("ntp-rtt");
          return 10;
        }
      }
    }
  }

  // --- ntp: network stubs ---
  {
    let r = ntp.ntp_request("pool.ntp.org");
    if r.is_ok {
      io.println("ntp-request");
      return 11;
    }
  }
  {
    let r = ntp.sntp_request("pool.ntp.org");
    if r.is_ok {
      io.println("ntp-sntp");
      return 12;
    }
  }

  // --- ping: icmp checksum property ---
  // Build an ICMP echo request with a zero checksum, compute it, store it,
  // then recompute over the full packet: a correct checksum yields 0xFFFF.
  var echo = Vec[UInt8].new();
  echo.push(8 as UInt8);
  echo.push(0 as UInt8);
  echo.push(0 as UInt8);
  echo.push(0 as UInt8);
  echo.push(0 as UInt8);
  echo.push(1 as UInt8);
  echo.push(0 as UInt8);
  echo.push(1 as UInt8);
  var payload = "abcdefghijklmnopqrstuvwxyzabcdefghi";
  var pi = 0;
  while pi < payload.len() {
    echo.push(payload.byte_at(pi));
    pi = pi + 1;
  }
  let cs = ping.icmp_checksum(&echo);
  let cval = cs as Int;
  echo[2] = ((cval >> 8) & 0xFF) as UInt8;
  echo[3] = (cval & 0xFF) as UInt8;
  // RFC 1071: summing all words (with the checksum field set) yields 0xFFFF,
  // so the checksum of the complete packet is 0x0000.
  let verify = ping.icmp_checksum(&echo);
  let vval = verify as Int;
  if vval != 0 {
    io.println("ping-checksum");
    return 13;
  }
  {
    let r = ping.ping_once("127.0.0.1", 1000);
    if r.is_ok {
      io.println("ping-once");
      return 14;
    }
  }

  // --- unix: documented stubs ---
  {
    let r = unix.unix_connect("/tmp/test.sock");
    if r.is_ok {
      io.println("unix-connect");
      return 15;
    }
  }
  {
    let r = unix.unix_socketpair();
    if r.is_ok {
      io.println("unix-pair");
      return 16;
    }
  }

  io.println("OK");
  return 0;
}

fn write_u64_at(v: &mut Vec[UInt8], pos: Int, val: Int) {
  var shift = 56;
  var i = 0;
  while i < 8 {
    v[pos + i] = ((val >> shift) & 0xFF) as UInt8;
    shift = shift - 8;
    i = i + 1;
}
