// XIOM stdlib smoke test -- xiom.crypto (enhanced)
// Tests: sha256 raw, sha256_hex, known-vector verification
// Returns 0 on success, unique error code on failure.

module smoke_crypto
use xiom.crypto;
use xiom.string;

fn main() -> Int {
  // 1. SHA-256 of empty string produces 32-byte result
  var empty: Vec[UInt8] = Vec[UInt8].new();
  var hash = crypto.sha256(&empty);
  if hash.len() != 32 { return 1; }

  // 2. SHA-256 hex of empty string produces 64-char result
  var empty_buf: Vec[UInt8] = Vec[UInt8].new();
  var hash_hex = crypto.sha256_hex(&empty_buf);
  if hash_hex.len() != 64 { return 2; }

  // 3. SHA-256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  var known_empty = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
  if hash_hex != known_empty { return 3; }

  // 4. SHA-256 hex of "abc" matches known vector
  // Convert string to bytes via the crypto.sha256_bytes helper or use Vec literal
  var abc_buf: Vec[UInt8] = Vec[UInt8].new();
  abc_buf.push(97); abc_buf.push(98); abc_buf.push(99); // 'a', 'b', 'c'
  var abc_hex = crypto.sha256_hex(&abc_buf);
  var known_abc = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
  if abc_hex != known_abc { return 4; }

  // 5. Deterministic: same input twice produces same output
  var hello_buf: Vec[UInt8] = Vec[UInt8].new();
  hello_buf.push(104); hello_buf.push(101); hello_buf.push(108); hello_buf.push(108); hello_buf.push(111); // "hello"
  var hex1 = crypto.sha256_hex(&hello_buf);
  var hex2 = crypto.sha256_hex(&hello_buf);
  if hex1 != hex2 { return 5; }

  // 6. Different inputs produce different outputs
  var alpha_buf: Vec[UInt8] = Vec[UInt8].new();
  alpha_buf.push(97); alpha_buf.push(108); alpha_buf.push(112); alpha_buf.push(104); alpha_buf.push(97); // "alpha"
  var beta_buf: Vec[UInt8] = Vec[UInt8].new();
  beta_buf.push(98); beta_buf.push(101); beta_buf.push(116); beta_buf.push(97); // "beta"
  var hex_a = crypto.sha256_hex(&alpha_buf);
  var hex_b = crypto.sha256_hex(&beta_buf);
  if hex_a == hex_b { return 6; }

  return 0;
}
