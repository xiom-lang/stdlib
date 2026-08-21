// XIOM stdlib stress -- io.rename source-gone, dest-present
// Renames a file, verifies old path gone and new path exists.
// Returns 0 on success.

module smoke_stress_io_rename_file
use xiom.io;

fn main() -> Int {
  var src = "__smk_rename_src.txt";
  var dst = "__smk_rename_dst.txt";
  io.write_file(src, "rename me");
  io.rename(src, dst);
  var ok = io.file_exists(dst) && not io.file_exists(src);
  io.remove_file(dst);
  if ok { return 0; } else { return 1; }
}
