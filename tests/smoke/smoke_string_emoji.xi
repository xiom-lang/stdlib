module smoke_string_emoji

use xiom.string.emoji;
use xiom.io;

fn main() -> Int {
  if !emoji.unicode_is_emoji(to_char(0x1F600)) { io.println("EMJ1"); return 1; }
  if emoji.unicode_is_emoji('A') { io.println("EMJ2"); return 2; }
  if !emoji.unicode_is_emoji(to_char(0x1F3FB)) { io.println("EMJ3"); return 3; }
  if !emoji.unicode_is_emoji(to_char(0xFE0F)) { io.println("EMJ4"); return 4; }
  if !emoji.unicode_is_emoji(to_char(0x2764)) { io.println("EMJ5"); return 5; }
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
