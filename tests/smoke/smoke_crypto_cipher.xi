// XIOM stdlib smoke test — xiom.crypto.cipher (+ aead dependency surface)
// Tests the paths that the current compiler build can execute reliably:
//   - ChaCha20 stream round-trip with explicit counter
//   - AES key generation and passphrase-derived keys (PBKDF2-HMAC-SHA256)
//   - AES key length validation (16/24/32)
// NOTE: AES block modes (ECB/CBC/CTR/GCM/CFB/OFB) and ChaCha20-Poly1305 are
// implemented but their execution is blocked by compiler codegen bugs in this
// build (heap corruption / &Vec length corruption / traps); see report.
// Returns 0 on success, unique error code on failure.

module smoke_crypto_cipher
use xiom.crypto.cipher;

fn main() -> Int {
  // ChaCha20 round-trip with counter 0.
  var key = Vec[UInt8].new();
  var i = 0;
  while i < 32 { key.push(i as UInt8); i = i + 1; }
  var n12 = Vec[UInt8].new();
  i = 0;
  while i < 12 { n12.push(50 + i as UInt8); i = i + 1; }
  var msg = Vec[UInt8].new();
  push_str(&msg, "The quick brown fox jumps over the lazy dog");
  var cc = cipher.chacha20_encrypt(&key, &n12, 0, &msg);
  if cc.len() != msg.len() { return 1; }
  var dc = cipher.chacha20_decrypt(&key, &n12, 0, &cc);
  if !eq(&dc, &msg) { return 2; }

  // AES key generation: 256-bit.
  var k32 = cipher.aes_generate_key();
  if k32.len() != 32 { return 3; }

  // Passphrase-derived AES key (32 bytes).
  var salt = Vec[UInt8].new();
  salt.push(1u8); salt.push(2u8); salt.push(3u8); salt.push(4u8);
  var pass = Vec[UInt8].new();
  push_str(&pass, "correct horse battery staple");
  var pk = cipher.aes_key_from_passphrase(&pass, &salt, 32);
  if pk.len() != 32 { return 4; }

  // Key-length validation paths must reject bad keys (16/24/32 accepted).
  var blk = Vec[UInt8].new();
  i = 0;
  while i < 16 { blk.push(i as UInt8); i = i + 1; }
  var badkey = Vec[UInt8].new();
  badkey.push(1u8);
  var r = cipher.aes_block_encrypt(&badkey, &blk);
  match r {
    Ok(_) => { return 5; }
    Err(_) => {}
  }
  var r2 = cipher.aes_block_encrypt(&key, &blk);
  match r2 {
    Ok(_) => {}
    Err(_) => { return 6; }
  }

  return 0;
}

fn eq(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  }
  return true;
}

fn push_str(v: &mut Vec[UInt8], s: Str) {
  var i = 0;
  while i < s.len() {
    var opt = xiom.string.char_at(s, i);
    if opt.is_some {
      v.push(opt.value as UInt8);
    }
    i = i + 1;
}
