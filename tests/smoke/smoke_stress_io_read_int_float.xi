// XIOM stdlib stress -- io integer/float parsing.
// The stdin line readers (io.read_int / io.read_float) cannot be exercised
// deterministically in-process, so this smoke pins their exposed parsing
// cores io.parse_int / io.parse_float. Do NOT call read_int()/read_float()
// from smokes: they block on an open stdin in harnesses.
module smoke_stress_io_read_int_float
use xiom.io;

fn main() -> Int {
  // --- parse_int ---
  match io.parse_int("42") {
    Ok(v) => { if v != 42 { return 1; } },
    Err(_) => { return 2; },
  }
  match io.parse_int(" -7 ") {
    Ok(v) => { if v != -7 { return 3; } },
    Err(_) => { return 4; },
  }
  match io.parse_int("+13") {
    Ok(v) => { if v != 13 { return 5; } },
    Err(_) => { return 6; },
  }
  match io.parse_int("") {
    Ok(_) => { return 7; },
    Err(_) => {},
  }
  match io.parse_int("12x") {
    Ok(_) => { return 8; },
    Err(_) => {},
  }
  match io.parse_int("-") {
    Ok(_) => { return 9; },
    Err(_) => {},
  }

  // --- parse_float ---
  match io.parse_float("3.5") {
    Ok(v) => { if v < 3.49 || v > 3.51 { return 10; } },
    Err(_) => { return 11; },
  }
  match io.parse_float("-0.5") {
    Ok(v) => { if v > -0.49 || v < -0.51 { return 12; } },
    Err(_) => { return 13; },
  }
  match io.parse_float("2") {
    Ok(v) => { if v < 1.99 || v > 2.01 { return 14; } },
    Err(_) => { return 15; },
  }
  match io.parse_float("") {
    Ok(_) => { return 16; },
    Err(_) => {},
  }
  match io.parse_float("1.2.3") {
    Ok(_) => { return 17; },
    Err(_) => {},
  }
  return 0;
}
