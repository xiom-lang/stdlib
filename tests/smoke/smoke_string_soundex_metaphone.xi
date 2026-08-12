module smoke_string_soundex_metaphone

use xiom.string.soundex;
use xiom.string.metaphone;
use xiom.io;

fn main() -> Int {
  if soundex.soundex("Robert") != "R163" { io.println("SDX1"); return 1; }
  if soundex.soundex("Rupert") != "R163" { io.println("SDX2"); return 2; }
  if soundex.soundex("Ashcraft") != "A261" { io.println("SDX3"); return 3; }
  if soundex.soundex("Tymczak") != "T522" { io.println("SDX4"); return 4; }
  if soundex.soundex("Pfister") != "P236" { io.println("SDX5"); return 5; }
  if soundex.soundex("") != "" { io.println("SDX6"); return 6; }
  if !soundex.soundex_compare("Robert", "Rupert") { io.println("SDX7"); return 7; }
  if soundex.soundex_compare("Robert", "Ashcraft") { io.println("SDX8"); return 8; }
  let m1 = metaphone.metaphone("knight");
  if m1 != "NT" { io.println("MTP1 m1=" + m1); return 11; }
  let m2 = metaphone.metaphone("GNOME");
  if m2 != "GNM" { io.println("MTP2 m2=" + m2); return 12; }
  if metaphone.metaphone("") != "" { io.println("MTP3"); return 13; }
  if !metaphone.metaphone_compare("knight", "night") { io.println("MTP4"); return 14; }
  if metaphone.metaphone_compare("knight", "day") { io.println("MTP5"); return 15; }
  io.println("OK");
  return 0;
}
