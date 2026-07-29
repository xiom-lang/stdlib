module smoke_char_case_convert
use xiom.char;

fn main() -> Int {
  if char.to_lowercase('A') != 'a' { return 1; }
  if char.to_lowercase('Z') != 'z' { return 2; }
  if char.to_lowercase('M') != 'm' { return 3; }
  if char.to_lowercase('a') != 'a' { return 4; }
  if char.to_lowercase('5') != '5' { return 5; }
  if char.to_lowercase('!') != '!' { return 6; }

  if char.to_uppercase('a') != 'A' { return 7; }
  if char.to_uppercase('z') != 'Z' { return 8; }
  if char.to_uppercase('m') != 'M' { return 9; }
  if char.to_uppercase('A') != 'A' { return 10; }
  if char.to_uppercase('5') != '5' { return 11; }

  var roundtrip = char.to_lowercase(char.to_uppercase('x'));
  if roundtrip != 'x' { return 12; }

  var roundtrip2 = char.to_uppercase(char.to_lowercase('K'));
  if roundtrip2 != 'K' { return 13; }

  return 0;
}
