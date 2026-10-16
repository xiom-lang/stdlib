// p_wave148_shapes.xi -- wave 148 guard: the save_write overwrite chain
// (write_file_bytes to a tmp path + rename replace, byte-exact read-back)
// must hold across a 300-iteration loop on the official pin. Guards the
// REL-20261011-1513-engine transient-flake class: pre-fix, ~1 in 1000 ops
// failed with a sharing violation inside MoveFileExA (scanner handles); the
// runtime now retries transient sharing/lock errors (5x, 10ms) -- wave 148.
// The witness run: out/scratch_save_write_stress.xi failed 1/5 passes
// pre-fix and 0/10 passes (2000 ops) post-fix. Returns 0 when all hold.

module p_wave148_shapes

use xiom.io;

fn main() -> Int {
  let tmp = "out\\w148_stress.tmp";
  let dst = "out\\w148_stress.dat";
  var i = 0;
  while i < 300 {
    var b: Vec[UInt8] = Vec[UInt8].new();
    b.push(0 as UInt8);
    b.push(77 as UInt8);
    b.push(90 as UInt8);
    b.push((i % 256) as UInt8);
    b.push(0 as UInt8);
    let w = io.write_file_bytes(tmp, &b);
    if w.is_err { return 1; }
    let r = io.rename(tmp, dst);
    if r.is_err { return 2; }
    i = i + 1;
  };
  let rb = io.read_file_bytes(dst);
  match rb {
    Ok(v) => {
      if v.len() != 5 { return 3; }
      if v[0] != 0 as UInt8 { return 4; }
      if v[1] != 77 as UInt8 { return 5; }
      if v[3] != (299 % 256) as UInt8 { return 6; }
    }
    Err(_) => { return 7; }
  };
  return 0;
}
