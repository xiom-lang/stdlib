// XIOM stdlib stress -- io.list_dir returns files
// Creates a directory with files, lists contents, verifies count.
// Returns 0 on success.

module smoke_stress_io_list_dir
use xiom.io;

fn main() -> Int {
  var dir = "__smk_listdir";
  io.create_dir(dir);
  io.write_file(dir + "/f1.txt", "a");
  io.write_file(dir + "/f2.txt", "b");
  var ls = io.list_dir(dir);
  io.remove_file(dir + "/f1.txt");
  io.remove_file(dir + "/f2.txt");
  io.remove_file(dir);
  match ls {
    Ok(files) => {
      if files.len() >= 2 { return 0; } else { return 1; }
    }
    Err(_) => { return 2; }
  }
}
