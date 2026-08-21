// XIOM stdlib smoke test -- xiom.crypto.mac
// Tests: hmac_sha256 (RFC 4231 test case 1 known answer), hmac_verify
// (constant-time), incremental hmac_new/update/final, constant_time_eq /
// constant_time_select, poly1305_mac/verify.
// Returns 0 on success, unique error code on failure.

module smoke_crypto_mac
use xiom.crypto.mac;
use xiom.encoding;

fn main() -> Int {
  // RFC 4231 test case 1: key = 0x0b * 20, data = "Hi There".
  var key = Vec[UInt8].new();
  var i = 0;
  while i < 20 { key.push(11u8); i = i + 1; }
  var data = Vec[UInt8].new();
  data.push(72u8); data.push(105u8); data.push(32u8);
  data.push(84u8); data.push(104u8); data.push(101u8); data.push(114u8); data.push(101u8);

  // One-shot HMAC-SHA256.
  var hm = mac.hmac_sha256(&key, &data);
  var hmhex = encoding.hex_encode(&hm);
  if hmhex != "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7" { return 1; }

  // Verify accepts the correct tag and rejects a corrupted one.
  if mac.hmac_verify(&key, &data, &hm) == false { return 2; }
  var bad_tag = Vec[UInt8].new();
  i = 0;
  while i < 32 { bad_tag.push(0u8); i = i + 1; }
  if mac.hmac_verify(&key, &data, &bad_tag) { return 3; }

  // Incremental HMAC produces the same tag.
  var ctx = mac.hmac_new(&key, 1);
  mac.hmac_update(&mut ctx, &data);
  var fin = mac.hmac_final(ctx);
  if encoding.hex_encode(&fin) != hmhex { return 4; }

  // constant_time_eq / constant_time_select.
  var a = Vec[UInt8].new();
  var b = Vec[UInt8].new();
  a.push(1u8); a.push(2u8); a.push(3u8);
  b.push(1u8); b.push(2u8); b.push(3u8);
  if mac.constant_time_eq(&a, &b) == false { return 5; }
  var c = Vec[UInt8].new();
  c.push(1u8); c.push(2u8); c.push(4u8);
  if mac.constant_time_eq(&a, &c) { return 6; }
  if mac.constant_time_select(7, 9, true) != 7 { return 7; }
  if mac.constant_time_select(7, 9, false) != 9 { return 8; }

  // Poly1305 one-shot + verify (self-consistency; vector tested in probes).
  var pkey = Vec[UInt8].new();
  i = 0;
  while i < 32 { pkey.push(i as UInt8); i = i + 1; }
  var pm = mac.poly1305_mac(&pkey, &data);
  if pm.len() != 16 { return 9; }
  if mac.poly1305_verify(&pkey, &data, &pm) == false { return 10; }

  return 0;
}
