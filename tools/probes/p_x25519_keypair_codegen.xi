// p_x25519_keypair_codegen.xi -- minimal probe for the x25519_keypair
// codegen failure found 2026-09-17 by p_never_called_zeroarg.
// Expected (correct): compiles and prints 0.
// Observed on compiler tag v0.60.0:
//   error[C001]: codegen: cannot take a reference to 'v': it is already a
//   reference (remove the leading '&')
// Ownership: compiler lane -- record with this probe.
module p_x25519_keypair_codegen
use xiom.crypto.keyx;

fn main() -> Int {
  xiom.crypto.keyx.x25519_keypair();
  return 0;
}
