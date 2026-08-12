module smoke_string_emoji

use xiom.string.emoji;
use xiom.io;
use xiom.convert;

fn chr(cp: Int) -> Char {
  match convert.int_to_char(cp) {
    Some(c) => { return c; }
    None => { return '?'; }
  }
}
fn main() -> Int {
// be constructed in a user module. TODO(compiler): BUG 26 #7.
if emoji.unicode_is_emoji('A') { io.println("EMJ2"); return 2; }
  let n1 = emoji.unicode_count_emoji("a😀b😀");
  if n1 != 2 { io.println("EMJ6"); return 6; }
  let n2 = emoji.unicode_count_emoji("abc");
  if n2 != 0 { io.println("EMJ7"); return 7; }
  if !emoji.unicode_has_emoji("x😀y") { io.println("EMJ8"); return 8; }
  if emoji.unicode_has_emoji("xyz") { io.println("EMJ9"); return 9; }
  if !emoji.unicode_has_emoji("a❤b") { io.println("EMJ10"); return 10; }
  io.println("OK");
  return 0;
}
