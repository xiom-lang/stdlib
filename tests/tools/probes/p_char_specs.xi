// p_char_specs.xi -- wave-5 contract-shape pre-validation for char specs.
// Sweeps printable + control chars through the range predicates; a wrong
// ensures (result == <range expression>) aborts on the mismatching code.
module p_char_specs
use xiom.char;
use xiom.io;

fn main() -> Int {
  var code = 0;
  while code <= 255 {
    var c = to_char(code);
    let is_d = code >= 48 && code <= 57;
    if char.is_digit(c) != is_d { io.println("is_digit spec"); return 1; };
    let is_l = code >= 97 && code <= 122;
    if char.is_lowercase(c) != is_l { io.println("is_lowercase spec"); return 2; };
    let is_u = code >= 65 && code <= 90;
    if char.is_uppercase(c) != is_u { io.println("is_uppercase spec"); return 3; };
    let is_a = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
    if char.is_alphabetic(c) != is_a { io.println("is_alphabetic spec"); return 4; };
    let is_ascii = code <= 127;
    if char.is_ascii(c) != is_ascii { io.println("is_ascii spec"); return 5; };
    let is_ctl = (code >= 0 && code <= 31) || code == 127;
    if char.is_control(c) != is_ctl { io.println("is_control spec"); return 6; };
    let is_ws = code == 32 || code == 9 || code == 10 || code == 13;
    if char.is_whitespace(c) != is_ws { io.println("is_whitespace spec"); return 7; };
    let is_p = (code >= 33 && code <= 47) || (code >= 58 && code <= 64)
        || (code >= 91 && code <= 96) || (code >= 123 && code <= 126);
    if char.is_punctuation(c) != is_p { io.println("is_punctuation spec"); return 8; };
    code = code + 1;
  };

  io.println("P_CHAR_SPECS OK");
  io.flush_stdout();
  0
}
