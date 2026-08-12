// XIOM stdlib smoke test - xiom.format.numbering
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_format_numbering
use xiom.format.numbering;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var w = number_to_words(123);
  if !string.str_contains(w, "one hundred twenty-three") {
    io.println("numbering: words(123) wrong");
    return 1;
  }
  var w2 = number_to_words(1000001);
  if !string.str_contains(w2, "million") {
    io.println("numbering: words(1000001) missing million");
    return 2;
  }
  var o = number_to_ordinal_words(21);
  if o != "twenty-first" {
    io.println("numbering: ordinal(21) wrong: " + o);
    return 3;
  }
  var cn = number_to_chinese(15);
  if cn.len() != 6 {
    io.println("numbering: chinese(15) wrong length");
    return 4;
  }
  var cn2 = number_to_chinese(100000001);
  if cn2.len() < 6 {
    io.println("numbering: chinese(100000001) too short");
    return 5;
  }
  var jp = number_to_japanese(15);
  if jp.len() != 6 {
    io.println("numbering: japanese(15) wrong length");
    return 6;
  }
  var kr = number_to_korean(15);
  if kr.len() != 6 {
    io.println("numbering: korean(15) wrong length");
    return 7;
  }
  var ind = number_to_indian_words(1234567);
  if !string.str_contains(ind, "lakh") {
    io.println("numbering: indian words missing lakh");
    return 8;
  }
  var grp = number_to_indian_grouping(1234567);
  if grp != "12,34,567" {
    io.println("numbering: indian grouping wrong: " + grp);
    return 9;
  }
  var money = money_to_words(12345, "USD");
  if !string.str_contains(money, "dollars") {
    io.println("numbering: money missing dollars");
    return 10;
  }
  if !string.str_contains(money, "cents") {
    io.println("numbering: money missing cents");
    return 11;
  }
  var neg = number_to_words(-42);
  if !string.str_contains(neg, "minus") {
    io.println("numbering: negative missing minus");
    return 12;
  }
  var uk = number_to_words_uk(1000000000000);
  if !string.str_contains(uk, "billion") {
    io.println("numbering: uk scale wrong");
    return 13;
  }
  if number_to_words(0) != "zero" {
    io.println("numbering: zero wrong");
    return 14;
  }

  io.println("OK");
  return 0;
}
