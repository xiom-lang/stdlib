module smoke_string_breaks

use xiom.string.linebreak;
use xiom.string.sentencebreak;
use xiom.string.wordbreak;
use xiom.string;
use xiom.io;

fn main() -> Int {
  let lb = linebreak.unicode_line_break_points("hello world");
  if lb.len() != 1 { io.println("LBK1"); return 1; }
  if lb[0] != 6 { io.println("LBK2"); return 2; }
  let lines = linebreak.unicode_split_lines("hello world");
  if lines.len() != 2 { io.println("LBK3"); return 3; }
  let l0 = lines[0];
  if l0 != "hello " { io.println("LBK4 l0=" + l0); return 4; }
  let lb2 = linebreak.unicode_line_break_points("ab\ncd");
  if lb2.len() != 1 { io.println("LBK5"); return 5; }
  if lb2[0] != 3 { io.println("LBK6"); return 6; }
  let sb = sentencebreak.unicode_sentence_boundaries("Hello world. Foo bar.");
  if sb.len() != 1 { io.println("SBK1"); return 11; }
  if sb[0] != 13 { io.println("SBK2"); return 12; }
  let sents = sentencebreak.unicode_split_sentences("Hello world. Foo bar.");
  if sents.len() != 2 { io.println("SBK3"); return 13; }
  let sb2 = sentencebreak.unicode_sentence_boundaries("One. Two.");
  if sb2.len() != 1 { io.println("SBK4"); return 14; }
  if sb2[0] != 5 { io.println("SBK5"); return 15; }
  let wb = wordbreak.unicode_word_boundaries("Hello,world");
  if wb.len() != 2 { io.println("WBK1"); return 21; }
  if wb[0] != 5 { io.println("WBK2"); return 22; }
  if wb[1] != 6 { io.println("WBK3"); return 23; }
  let words = wordbreak.unicode_split_words("Hello,world");
  if words.len() != 3 { io.println("WBK4"); return 24; }
  let w0 = words[0];
  if w0 != "Hello" { io.println("WBK5"); return 25; }
  let w1 = words[1];
  if w1 != "," { io.println("WBK6"); return 26; }
  let w2 = words[2];
  if w2 != "world" { io.println("WBK7"); return 27; }
  let words2 = wordbreak.unicode_split_words("don't");
  if words2.len() != 1 { io.println("WBK8"); return 28; }
  let words3 = wordbreak.unicode_split_words("a b c");
  if words3.len() != 3 { io.println("WBK9"); return 29; }
  io.println("OK");
  return 0;
}
