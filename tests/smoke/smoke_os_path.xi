// XIOM stdlib smoke test — xiom.os.{path,dir,file,fs}
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

  // --- file helpers via temp dir round-trip ---
  var fname = dir.dir_join(dir.dir_temp(), "_xiom_file_roundtrip_93817.txt");
  var fw = file.file_write(fname, "hello xiom");
  match fw {
    Ok(()) => {}
    Err(_) => {
      io.println("file-write");
      return 11;
    }
  }
  var fex = file.file_exists(fname);
  if fex != true {
    io.println("file-exists");
    return 12;
  }
  var fr = file.file_read(fname);
  match fr {
    Ok(s) => {
      if s != "hello xiom" {
        io.println("file-read");
        return 13;
      }
    }
    Err(_) => {
      io.println("file-read");
      return 13;
    }
  }
  var fsz = file.file_size(fname);
  match fsz {
    Ok(n) => {
      if n != 10 {
        io.println("file-size");
        return 14;
      }
    }
    Err(_) => {
      io.println("file-size");
      return 14;
    }
  }
  var ext = file.file_extension("archive.tar.gz");
  match ext {
    Some(v) => {
      if v != "gz" {
        io.println("file-ext");
        return 15;
      }
    }
    None => {
      io.println("file-ext");
      return 15;
    }
  }
  var fn2 = file.file_name("a/b/c.txt");
  match fn2 {
    Some(v) => {
      if v != "c.txt" {
        io.println("file-name");
        return 16;
      }
    }
    None => {
      io.println("file-name");
      return 16;
    }
  }
  var rem = file.file_remove(fname);
  match rem {
    Ok(()) => {}
    Err(_) => {
      io.println("file-remove");
      return 17;
    }
  }

  // --- path module (xiom.path) ---
  var is_abs = path.path_is_absolute_str("/x/y");
  if is_abs != true {
    io.println("path-abs");
    return 18;
  }
  var p = path.Path.new("a");
  var jp = p.join("b");
  var inner = jp.to_str();
  // Per stub: join uses the OS separator, so "a\b" on Windows, "a/b"
  // elsewhere. Accept either.
  if inner != "a/b" && inner != "a\\b" {
    io.println("path-join=[" + inner + "]");
    return 19;
  }
  var fn3 = p.file_name();
  match fn3 {
    Some(v) => {
      if v != "a" {
        io.println("path-name");
        return 20;
      }
    }
    None => {
      io.println("path-name");
      return 20;
    }
  }

  io.println("OK");
  return 0;
}
