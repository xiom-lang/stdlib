// XIOM stdlib stress -- io.BufReader over a real file stream.
// Deterministic (no stdin reads): opens a temp file via io.open, reads it
// with BufReader.lines(), verifies content, closes and cleans up.
// Returns 0 on success, nonzero on failure.
//
// History: the original version passed io.stdin() (the numeric FD 0) to
// BufReader.new, which stores a stdio FILE* -- FD 0 cast to a null stream
// (0xC0000409). BufReader had no file-open API at all, so the fix also
// added io.open/io.close (FILE* wrappers). Sweep harnesses must still
// redirect stdin for any residual stdin-reading smokes.

module smoke_stress_io_bufreader
use xiom.io;

fn main() -> Int {
  var path = "__smk_bufreader.txt";
  // Pre-clean leftovers from aborted runs.
  var _pre = io.remove_file(path);

  var w = io.write_file(path, "line1\nline2\nline3\n");
  match w {
    Ok(_) => {},
    Err(_) => { return 1; },
  }

  var oh = io.open(path, "r");
  var h: Int = 0;
  match oh {
    Ok(v) => { h = v; },
    Err(e) => {
      io.println("bufreader: open failed");
      return 2;
    },
  }

  var br = io.BufReader.new(h);
  var lines = br.lines();

  var cr = io.close(h);
  var _rm = io.remove_file(path);
  match cr {
    Ok(_) => {},
    Err(_) => { return 3; },
  }

  if lines.len() != 3 { return 4; }
  if lines[0] != "line1" { return 5; }
  if lines[1] != "line2" { return 6; }
  if lines[2] != "line3" { return 7; }
  return 0;
}
