module smoke_string_block_escape
use xiom.string.block;
use xiom.string.escape;
use xiom.io;

fn main() -> Int {
  // ---- unicode_block ----
  if block.unicode_block('A') != "Basic Latin" { io.println("blk-1"); return 1; }
  if block.unicode_block(to_char(233)) != "Latin-1 Supplement" { io.println("blk-2"); return 2; }
  if block.unicode_block(to_char(937)) != "Greek and Coptic" { io.println("blk-3"); return 3; }
  if block.unicode_block(to_char(26085)) != "CJK Unified Ideographs" { io.println("blk-4"); return 4; }
  if block.unicode_block('\t') != "Basic Latin" { io.println("blk-5"); return 5; }

  // ---- unicode_block_name ----
  if block.unicode_block_name("1F600") != "Emoticons" { io.println("blkn-1"); return 11; }
  if block.unicode_block_name("0x41") != "Basic Latin" { io.println("blkn-2"); return 12; }
  if block.unicode_block_name("U+03A9") != "Greek and Coptic" { io.println("blkn-3"); return 13; }
  if block.unicode_block_name("zz") != "Undefined" { io.println("blkn-4"); return 14; }
  if block.unicode_block_name("") != "Undefined" { io.println("blkn-5"); return 15; }
  if block.unicode_block_name("2A6DF") != "CJK Unified Ideographs Extension B" { io.println("blkn-6"); return 16; }

  // ---- escape ----
  if escape.str_escape("a\nb\tc\"d\\e") != "a\\nb\\tc\\\"d\\\\e" { io.println("esc-1"); return 21; }
  if escape.str_escape("plain") != "plain" { io.println("esc-2"); return 22; }

  // ---- unescape ----
  if escape.str_unescape("a\\nb\\tc") != "a\nb\tc" { io.println("uesc-1"); return 31; }
  if escape.str_unescape("plain") != "plain" { io.println("uesc-2"); return 32; }

  // ---- escape/unescape round-trip ----
  var round = "a\nb\tc\"d\\e\rf";
  var esc = escape.str_escape(round);
  if escape.str_unescape(esc) != round { io.println("rt-1"); return 41; }

  // ---- escape_ascii ----
  if escape.str_escape_ascii("café") != "caf\\xc3\\xa9" { io.println("escA-1"); return 51; }
  if escape.str_escape_ascii("abc") != "abc" { io.println("escA-2"); return 52; }

  // ---- escape_unicode ----
  if escape.str_escape_unicode("é") != "\\u00e9" { io.println("escU-1"); return 61; }
  if escape.str_escape_unicode("Ω") != "\\u03a9" { io.println("escU-2"); return 62; }
  if escape.str_escape_unicode("abc") != "abc" { io.println("escU-3"); return 63; }

  io.println("smoke_string_block_escape: OK");
  return 0;
}
