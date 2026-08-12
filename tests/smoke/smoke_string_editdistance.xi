// Smoke test for xiom.string.editdistance
// Returns 0 on success, non-zero on the first failing assertion.

module smoke_string_editdistance
use xiom.string.editdistance;
use xiom.io;

fn main() -> Int {
  if editdistance.edit_distance("kitten", "sitting") != 3 { io.println("ed kitten"); return 1; }
  if editdistance.edit_distance("", "") != 0 { io.println("ed empty"); return 2; }
  if editdistance.edit_distance("abc", "abc") != 0 { io.println("ed equal"); return 3; }
  if editdistance.edit_distance_limited("kitten", "sitting", 3) != 3 { io.println("ed lim exact"); return 4; }
  if editdistance.edit_distance_limited("kitten", "sitting", 2) != 2 { io.println("ed lim cap"); return 5; }
  if editdistance.edit_distance_limited("kitten", "sitting", 100) != 3 { io.println("ed lim large"); return 6; }
  if editdistance.edit_distance_limited("", "abc", 2) != 2 { io.println("ed lim empty"); return 7; }
  if editdistance.edit_distance_limited("abc", "", 1) != 1 { io.println("ed lim empty2"); return 8; }
  if editdistance.edit_distance_limited("abc", "def", 2) != 2 { io.println("ed lim no path"); return 9; }
  if editdistance.edit_distance_limited("abc", "def", 3) != 3 { io.println("ed lim full"); return 10; }
  if editdistance.edit_distance_limited("abc", "axc", 1) != 1 { io.println("ed lim sub"); return 11; }
  if editdistance.edit_distance_limited("kitten", "sitting", 0) != 0 { io.println("ed lim zero"); return 12; }
  io.println("smoke_string_editdistance: OK");
  return 0;
}
