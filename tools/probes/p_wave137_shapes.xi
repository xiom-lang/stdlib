// p_wave137_shapes.xi -- wave 137 lock (REL-20261014-1427-engine):
// byte-exact file IO -- copy_file now goes through read_file_bytes /
// write_file_bytes, so NUL-containing (binary) sources survive (the old
// read_file/write_file path truncated a PE DLL to "MZ\x90"). Locks the
// byte roundtrip, the PE-magic copy, append parity at the byte level and
// the unchanged text path. Fixture files live under out/ (untracked) and
// are removed at the end. Returns 0 when every case holds.

module p_wave137_shapes

use xiom.string;
use xiom.io as io;

fn eq_bytes(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var i: Int = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  };
  true
}

fn main() -> Int {
  // PE-magic-like binary fixture with NULs at 3, 7 and a 0xFF.
  var bin: Vec[UInt8] = Vec[UInt8].new();
  bin.push(0x4D as UInt8);
  bin.push(0x5A as UInt8);
  bin.push(0x90 as UInt8);
  bin.push(0 as UInt8);
  bin.push(1 as UInt8);
  bin.push(2 as UInt8);
  bin.push(0xFF as UInt8);
  bin.push(0 as UInt8);
  bin.push(0x7F as UInt8);

  // ---- write/read bytes roundtrip ----
  let w1 = io.write_file_bytes("out/pb_src.bin", &bin);
  if !w1.is_ok { return 1; }
  let sz1 = io.file_size("out/pb_src.bin");
  if !sz1.is_some { return 2; }
  if sz1.value != 9 { return 3; }
  let r1 = io.read_file_bytes("out/pb_src.bin");
  match r1 {
    Ok(v) => { if !eq_bytes(&v, &bin) { return 4; } },
    Err(_) => { return 5; },
  }

  // ---- copy_file is byte-exact (the reported defect) ----
  let cp = io.copy_file("out/pb_src.bin", "out/pb_dst.bin");
  if !cp.is_ok { return 6; }
  let sz2 = io.file_size("out/pb_dst.bin");
  if !sz2.is_some { return 7; }
  if sz2.value != 9 { return 8; }
  let r2 = io.read_file_bytes("out/pb_dst.bin");
  match r2 {
    Ok(v2) => { if !eq_bytes(&v2, &bin) { return 9; } },
    Err(_) => { return 10; },
  }

  // ---- append parity at the byte level ----
  var tail: Vec[UInt8] = Vec[UInt8].new();
  tail.push(0xAA as UInt8);
  tail.push(0 as UInt8);
  tail.push(0xBB as UInt8);
  let ap = io.append_file_bytes("out/pb_dst.bin", &tail);
  if !ap.is_ok { return 11; }
  let sz3 = io.file_size("out/pb_dst.bin");
  if !sz3.is_some { return 12; }
  if sz3.value != 12 { return 13; }
  let r3 = io.read_file_bytes("out/pb_dst.bin");
  match r3 {
    Ok(v3) => {
      if v3.len() != 12 { return 14; }
      if (v3[9] as Int) != 0xAA { return 15; }
      if (v3[10] as Int) != 0 { return 16; }
      if (v3[11] as Int) != 0xBB { return 17; }
    },
    Err(_) => { return 18; },
  }

  // ---- text path unchanged ----
  let w2 = io.write_file("out/pb_txt.txt", "hello\nworld");
  if !w2.is_ok { return 19; }
  let r4 = io.read_file("out/pb_txt.txt");
  match r4 {
    Ok(v4) => { if v4 != "hello\nworld" { return 20; } },
    Err(_) => { return 21; },
  }

  // ---- cleanup ----
  let d1 = io.remove_file("out/pb_src.bin");
  if !d1.is_ok { return 22; }
  let d2 = io.remove_file("out/pb_dst.bin");
  if !d2.is_ok { return 23; }
  let d3 = io.remove_file("out/pb_txt.txt");
  if !d3.is_ok { return 24; }

  return 0;
}
