// p_legacy_modules.xi -- post-move resolution probe: the three quarantined
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// legacy crypto modules must remain importable by their frozen module names
// (xiom.des / xiom.crypto.md5 / xiom.crypto.sha) from crypto/legacy/.
module p_legacy_modules
use xiom.des;
use xiom.crypto.md5;
use xiom.crypto.sha;
use xiom.io;

fn main() -> Int {
  let e = des.des_encrypt_block(0x0123456789ABCDEF, 0x133457799BBCDFF1);
  let d = des.des_decrypt_block(e, 0x133457799BBCDFF1);
  if d != 0x0123456789ABCDEF { io.println("des roundtrip"); return 1; }

  var m = Vec[Int].new();
  m.push(97); m.push(98); m.push(99);

  let h = md5_hex(&m);
  if h.len() != 32 { io.println("md5_hex len"); return 2; }

  let hs = sha256(&m);
  if hs.len() != 32 { io.println("sha256 len"); return 3; }

  io.println("LEGACY MODULES OK");
  return 0;
}
