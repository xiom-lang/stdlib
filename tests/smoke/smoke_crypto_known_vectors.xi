// XIOM — SHA-256 Known-Vector Tests
// Tests SHA-256 correctness against RFC 6234 test vectors.
//
// STATUS: FAILING — pure-XIOM SHA-256 algorithm produces wrong hashes.
// Root cause: the algorithm logic is correct but produces output that
// does not match standard SHA-256 test vectors. This indicates a
// subtle codegen-level issue in XIOM's 32-bit arithmetic operations
// (_u32_mask, _u32_add, _u32_rotr, etc.) that manifests differently
// when these are composed in the full compression function.
//
// The C runtime xiom_shani_sha256_compress is a no-op stub on all
// architectures (comment says "software fallback is in crypto.xi").
// Adding a correct C software fallback crashes at runtime due to
// pointer/linking issues between XIOM and the C runtime.
//
// All individual operations (_u32_mask, _u32_add, _u32_rotr) test
// correctly in isolation. The bug manifests only in the full
// composition of the compression function across 64 rounds.
//
// Returns 0 if all known-vectors pass, nonzero otherwise.
module test_sha256_known_vectors
use xiom.crypto;

fn main() -> Int {
  // Test 1: SHA-256("") = e3b0c4...
  var empty = Vec[UInt8].new();
  var h1 = xiom.crypto.sha256_hex(&empty);
  if h1 != "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" {
    return 1;
  }
  // Test 2: SHA-256("abc") = ba7816bf...
  var abc = Vec[UInt8].new();
  abc.push(97); abc.push(98); abc.push(99);
  var h2 = xiom.crypto.sha256_hex(&abc);
  if h2 != "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" {
    return 2;
  }
  return 0;
}
