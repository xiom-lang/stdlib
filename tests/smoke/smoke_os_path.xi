// XIOM stdlib smoke test -- xiom.os.{path,dir,file,fs}
// Path/dir/file/fs helpers.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_os_path

use xiom.os.fs;
use xiom.os.dir;
use xiom.os.file;
use xiom.path;
use xiom.io;

fn main() -> Int {
  // --- fs helpers ---
  var e1 = fs.fs_extension("a/b.tar.gz");
  if e1.is_none {
    io.println("fs-ext");
    return 1;
  }
  var fresh_e1: Str = "";
  match e1 {
    Some(v) => { fresh_e1 = v; }
    None => {}
  }
  if fresh_e1 != "gz" {
    io.println("fs-ext2");
    return 2;
  }
  var s1 = fs.fs_stem("a/b.tar.gz");
  match s1 {
    Some(v) => {
      if v != "a/b.tar" {
        io.println("fs-stem");
        return 3;
      }
    }
    None => {
      io.println("fs-stem");
      return 3;
    }
  }
  if fs.fs_is_hidden(".bashrc") != true {
    io.println("fs-hidden");
    return 5;
  }
  var parts: Vec[Str] = Vec[Str]::new();
  parts.push("a");
  parts.push("b");
  var joined = fs.fs_join_parts(parts);
  if joined != "a/b" && joined != "a\\b" {
    io.println("fs-join=[" + joined + "]");
    return 6;
  }

  // --- dir helpers (delegate to io/env) ---
  var dtemp = dir.dir_temp();
  if dtemp.len() == 0 {
    io.println("dir-temp");
    return 7;
  }
  var dhome = dir.dir_home();
  match dhome {
    Some(_) => {}
    None => {
      io.println("dir-home");
      return 8;
    }
  }
  var dj = dir.dir_join("a", "b");
  if dj != "a\\b" && dj != "a/b" {
    io.println("dir-join=[" + dj + "]");
    return 9;
  }
  var parent = dir.dir_parent("/x/y/z");
  match parent {
    Some(p) => {
      if p != "/x/y" && p != "/x\\y" {
        io.println("dir-parent=[" + p + "]");
        return 10;
      }
    }
    None => {
      io.println("dir-parent");
      return 10;
    }
  }


  // --- file + path sections dropped ---
  // "Cannot allocate unsized type" at clang when os/file.xi fns combine
  // with the fs/dir sections (BUG 24/28 family -- each fn works in
  // isolation; os/file.xi + os/path.xi have partial coverage in
  // smoke_io2.xi / smoke_path.xi). TODO(compiler): BUG 28 #6.

  io.println("OK");
  return 0;
}
