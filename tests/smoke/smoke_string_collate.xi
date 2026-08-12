module smoke_string_collate
use xiom.string.collate;
use xiom.io;

fn main() -> Int {
  // byte-wise ordering
  if collate.collate_compare("abc", "abd") >= 0 { io.println("collate-1"); return 1; }
  if collate.collate_compare("abd", "abc") <= 0 { io.println("collate-2"); return 2; }
  if collate.collate_compare("abc", "abc") != 0 { io.println("collate-3"); return 3; }
  if collate.collate_compare("ab", "abc") >= 0 { io.println("collate-4"); return 4; }
  if collate.collate_compare("abc", "ab") <= 0 { io.println("collate-5"); return 5; }
  if collate.collate_compare("", "a") >= 0 { io.println("collate-6"); return 6; }
  if collate.collate_compare("a", "") <= 0 { io.println("collate-7"); return 7; }
  if collate.collate_compare("", "") != 0 { io.println("collate-8"); return 8; }

  // numeric ordering: file2 < file10
  if collate.collate_compare_numeric("file2", "file10") >= 0 { io.println("num-1"); return 9; }
  if collate.collate_compare_numeric("file10", "file2") <= 0 { io.println("num-2"); return 10; }
  if collate.collate_compare_numeric("img1", "img1") != 0 { io.println("num-3"); return 11; }
  if collate.collate_compare_numeric("a1b", "a01b") != 0 { io.println("num-4"); return 12; }

  // collation keys: case-insensitive
  if collate.collate_compare(collate.collate_key("ABC"), collate.collate_key("abc")) != 0 { io.println("key-1"); return 13; }
  if collate.collate_compare(collate.collate_key("Zed"), collate.collate_key("apple")) <= 0 { io.println("key-2"); return 14; }
  if collate.collate_key("") != "" { io.println("key-3"); return 15; }
  if collate.collate_key("aZ") != "az" { io.println("key-4"); return 16; }

  io.println("smoke_string_collate: OK");
  return 0;
}
