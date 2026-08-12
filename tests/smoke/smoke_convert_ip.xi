// XIOM stdlib smoke — xiom.convert.{ip,network,mac,uuid}
// Returns 0 on success, nonzero on failure (process exit code).
module smoke_convert_ip
use xiom.io;
use xiom.convert.ip;
use xiom.convert.network;
use xiom.convert.mac;
use xiom.convert.uuid;

fn main() -> Int {
  // network byte order (16/32/64-bit swaps)
  var h16 = network.host_to_network16(0x1234);
  if h16 != 0x3412 {
    io.println("smoke_convert_ip: host_to_network16 failed");
    return 1;
  }
  var h32 = network.host_to_network32(0x12345678);
  if h32 != 0x78563412 {
    io.println("smoke_convert_ip: host_to_network32 failed");
    return 2;
  }
  var n16 = network.network_to_host16(0x3412);
  if n16 != 0x1234 {
    io.println("smoke_convert_ip: network_to_host16 failed");
    return 3;
  }
  var n32 = network.network_to_host32(0x78563412);
  if n32 != 0x12345678 {
    io.println("smoke_convert_ip: network_to_host32 failed");
    return 4;
  }
  var hll = network.htonll(0x1122334455667788);
  if hll != 0x8877665544332211 {
    io.println("smoke_convert_ip: htonll failed");
    return 5;
  }
  var nh = network.ntohll(0x8877665544332211);
  if nh != 0x1122334455667788 {
    io.println("smoke_convert_ip: ntohll failed");
    return 6;
  }

  // ip v4: validation + formatting
  if !ip.is_valid_ipv4("192.168.1.1") {
    io.println("smoke_convert_ip: is_valid_ipv4 failed");
    return 10;
  }
  if ip.is_valid_ipv4("192.168.1.256") {
    io.println("smoke_convert_ip: is_valid_ipv4 accepted 256");
    return 11;
  }
  if ip.is_valid_ipv4("192.168.1") {
    io.println("smoke_convert_ip: is_valid_ipv4 accepted short");
    return 12;
  }
  var oct = Vec[UInt8].new();
  oct.push(192);
  oct.push(168);
  oct.push(1);
  oct.push(1);
  var v4s = ip.ipv4_to_string(&oct);
  if v4s != "192.168.1.1" {
    io.println("smoke_convert_ip: ipv4_to_string failed: " + v4s);
    return 13;
  }

  // ip v6: validation
  if !ip.is_valid_ipv6("2001:db8::1") {
    io.println("smoke_convert_ip: is_valid_ipv6 failed");
    return 14;
  }
  if ip.is_valid_ipv6("2001:::1") {
    io.println("smoke_convert_ip: is_valid_ipv6 accepted bad");
    return 15;
  }

  // mac: validation + random
  if !mac.mac_is_valid("aa:bb:cc:dd:ee:ff") {
    io.println("smoke_convert_ip: mac_is_valid failed");
    return 20;
  }
  if !mac.mac_is_valid("AA-BB-CC-DD-EE-FF") {
    io.println("smoke_convert_ip: mac_is_valid hyphen failed");
    return 21;
  }
  if mac.mac_is_valid("aa:bb:cc:dd:ee") {
    io.println("smoke_convert_ip: mac_is_valid accepted short");
    return 22;
  }
  var mr = mac.mac_random();
  if mr.len() != 17 {
    io.println("smoke_convert_ip: mac_random len failed");
    return 23;
  }
  if !mac.mac_is_valid(mr) {
    io.println("smoke_convert_ip: mac_random invalid");
    return 24;
  }

  // uuid: generate, format, validate
  var u = uuid.uuid_v4();
  if u.len() != 36 {
    io.println("smoke_convert_ip: uuid_v4 len failed");
    return 30;
  }
  if !uuid.uuid_is_valid(u) {
    io.println("smoke_convert_ip: uuid_is_valid failed: " + u);
    return 31;
  }
  if !uuid.uuid_is_valid("123e4567-e89b-12d3-a456-426614174000") {
    io.println("smoke_convert_ip: uuid_is_valid known failed");
    return 32;
  }
  if uuid.uuid_is_valid("123e4567e89b12d3a456426614174000") {
    io.println("smoke_convert_ip: uuid_is_valid accepted bad");
    return 33;
  }
  var ub = uuid.uuid_v4_bytes();
  if ub.len() != 16 {
    io.println("smoke_convert_ip: uuid_v4_bytes len failed");
    return 34;
  }

  io.println("OK");
  return 0;
}
