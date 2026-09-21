// XIOM - Format: Numbering
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.format.numbering

// Depends on: xiom.string, xiom.num

use xiom.string;
use xiom.convert;

// ============================================================================
// Human number words: English (US short scale / UK long scale / Indian
// lakh-crore system), ordinals, Chinese (simplified/traditional), Japanese,
// Korean, plus Indian digit grouping and money amounts. Pure computation with
// zero external dependencies; the full signed 64-bit range is handled by
// converting through the decimal digit string (no integer overflow).
//
// Lookup tables are kept as space-delimited strings scanned by _word_at:
// reading elements of a Vec[Str] (whether returned by another catalog module
// or built locally) yields garbage pointer values in the current compiler, so
// no Vec[Str] element is ever dereferenced in this module.
// ============================================================================

/// Byte length of a UTF-8 sequence from its lead byte.
fn _utf8_len(b: UInt8) -> Int {
  var v = b as Int;
  if v <= 0x7F {
    return 1;
  };
  if (v & 0xE0) == 0xC0 {
    return 2;
  };
  if (v & 0xF0) == 0xE0 {
    return 3;
  };
  return 4;
}

/// The nth space-separated word of `s` (0-based), or "" when out of range.
/// UTF-8 aware: characters are copied whole, so multi-byte words survive.
fn _word_at(s: Str, n: Int) -> Str {
  var idx = 0;
  var word = "";
  var i = 0;
  var len = s.len();
  while i < len {
    var b = string.byte_at(s, i);
    if b == 32 {
      if word.len() > 0 {
        if idx == n {
          return word;
        };
        word = "";
        idx = idx + 1;
      };
      i = i + 1;
    } else {
      var bl = _utf8_len(b);
      word = word + string.str_slice(s, i, i + bl);
      i = i + bl;
    };
  }
  if word.len() > 0 {
    if idx == n {
      return word;
    };
  };
  return "";
}

fn _ones(n: Int) -> Str {
  var v = n;
  if v < 0 {
    v = 0;
  };
  if v > 19 {
    v = 19;
  };
  return _word_at("zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen", v);
}

fn _tens(n: Int) -> Str {
  var v = n;
  if v < 0 {
    v = 0;
  };
  if v > 9 {
    v = 9;
  };
  return _word_at("zero zero twenty thirty forty fifty sixty seventy eighty ninety", v);
}

/// English words for 0..999 (US scale style).
fn _triple_words(v: Int) -> Str {
  var val = v;
  if val < 0 {
    val = 0;
  };
  if val > 999 {
    val = 999;
  };
  if val == 0 {
    return "zero";
  };
  var result = "";
  var hundreds = val / 100;
  var rest = val % 100;
  if hundreds > 0 {
    result = _ones(hundreds) + " hundred";
    if rest > 0 {
      result = result + " ";
    };
  };
  if rest > 0 {
    if rest < 20 {
      result = result + _ones(rest);
    } else {
      var t = rest / 10;
      var o = rest % 10;
      result = result + _tens(t);
      if o > 0 {
        result = result + "-" + _ones(o);
      };
    };
  };
  return result;
}

/// Convert a digit string (no sign) to words using `scales` (space-separated
/// scale names, index 0 = ones).
fn _digits_to_words(digits: Str, scales: Str) -> Str {
  var padded = digits;
  while padded.len() % 3 != 0 {
    padded = "0" + padded;
  }
  var result = "";
  var groups = padded.len() / 3;
  var g = 0;
  while g < groups {
    var triple = string.str_slice(padded, g * 3, g * 3 + 3);
    var t0 = string.byte_at(triple, 0) as Int - 48;
    var t1 = string.byte_at(triple, 1) as Int - 48;
    var t2 = string.byte_at(triple, 2) as Int - 48;
    var value = t0 * 100 + t1 * 10 + t2;
    if value > 0 {
      var tw = _triple_words(value);
      var scale_idx = groups - 1 - g;
      var scale = "";
      if scale_idx > 0 {
        scale = _word_at(scales, scale_idx);
      };
      if result.len() > 0 {
        result = result + " ";
      };
      result = result + tw;
      if scale.len() > 0 {
        result = result + " " + scale;
      };
    };
    g = g + 1;
  }
  return result;
}

/// Split an Int into its decimal digit string and sign (struct, not a tuple:
/// Bool-in-tuple returns miscompile per BUG 25 #4).
type DigitPair = {
  neg: Bool;
  digits: Str;
}

fn _digits_of(n: Int) -> DigitPair {
  var s = convert.int_to_string(n);
  if s.len() == 0 {
    return DigitPair{ neg: false; digits: "0"; };
  };
  var first = string.byte_at(s, 0);
  if first == 45 {
    return DigitPair{ neg: true; digits: string.str_slice(s, 1, s.len()); };
  };
  return DigitPair{ neg: false; digits: s; };
}

/// Spell `n` in English words using the US short scale (billion = 10^9).
/// "minus" precedes negative values. Complexity: O(log10 n).
pub fn number_to_words(n: Int) -> Str {
  if n == 0 {
    return "zero";
  };
  var d = _digits_of(n);
  var neg = d.neg;
  var words = _digits_to_words(d.digits, "zero thousand million billion trillion quadrillion quintillion");
  if neg {
    return "minus " + words;
  };
  return words;
}

/// Spell `n` in English words using the UK long scale (billion = 10^12,
/// milliard = 10^9). Complexity: O(log10 n).
pub fn number_to_words_uk(n: Int) -> Str {
  if n == 0 {
    return "zero";
  };
  var d = _digits_of(n);
  var neg = d.neg;
  var words = _digits_to_words(d.digits, "zero thousand million milliard billion billiard trillion");
  if neg {
    return "minus " + words;
  };
  return words;
}

/// Convert a cardinal word into its ordinal form ("one" -> "first",
/// "twenty-one" -> "twenty-first").
fn _ordinal_of(word: Str) -> Str {
  var hi = -1;
  var i = 0;
  while i < word.len() {
    var b = string.byte_at(word, i);
    if b == 45 {
      hi = i;
    };
    i = i + 1;
  }
  if hi >= 0 {
    var tail = string.str_slice(word, hi + 1, word.len());
    return string.str_slice(word, 0, hi + 1) + _ordinal_of(tail);
  };
  if word == "one" {
    return "first";
  };
  if word == "two" {
    return "second";
  };
  if word == "three" {
    return "third";
  };
  if word == "five" {
    return "fifth";
  };
  if word == "eight" {
    return "eighth";
  };
  if word == "nine" {
    return "ninth";
  };
  if word == "twelve" {
    return "twelfth";
  };
  if word == "zero" {
    return "zeroth";
  };
  var wlen = word.len();
  if wlen > 0 {
    var last = string.byte_at(word, wlen - 1);
    if last == 121 {
      return string.str_slice(word, 0, wlen - 1) + "ieth";
    };
  };
  return word + "th";
}

/// The last space-separated word of `s`, or "" when empty.
fn _last_word(s: Str) -> Str {
  var word = "";
  var i = 0;
  var len = s.len();
  while i < len {
    var b = string.byte_at(s, i);
    if b == 32 {
      word = "";
    } else {
      word = word + string.str_slice(s, i, i + 1);
    };
    i = i + 1;
  }
  return word;
}

/// `s` with the last word removed (trailing space stripped).
fn _drop_last_word(s: Str) -> Str {
  var last_space = -1;
  var i = 0;
  var len = s.len();
  while i < len {
    var b = string.byte_at(s, i);
    if b == 32 {
      last_space = i;
    };
    i = i + 1;
  }
  if last_space < 0 {
    return "";
  };
  return string.str_slice(s, 0, last_space);
}

/// Spell `n` as an English ordinal word ("21" -> "twenty-first").
pub fn number_to_ordinal_words(n: Int) -> Str {
  var words = number_to_words(n);
  if words.len() == 0 {
    return "zeroth";
  };
  var last = _last_word(words);
  var ordinal = _ordinal_of(last);
  var prefix = _drop_last_word(words);
  if prefix.len() > 0 {
    return prefix + " " + ordinal;
  };
  return ordinal;
}

/// Format a 0..9999 group in Chinese/Japanese/Korean numerals.
/// `dig` is a space-separated digit list, `units` the (十, 百, 千) units in
/// the language's script, `zero` the zero character. Omits the leading "one"
/// before the tens unit for 10..99.
fn _cn_group(v: Int, dig: Str, units: Str, zero: Str) -> Str {
  var val = v;
  if val < 0 {
    val = 0;
  };
  if val > 9999 {
    val = 9999;
  };
  if val == 0 {
    return "";
  };
  var thousands = val / 1000;
  var hundreds = (val / 100) % 10;
  var tens = (val / 10) % 10;
  var ones = val % 10;
  var s = "";
  if thousands > 0 {
    s = s + _word_at(dig, thousands) + _word_at(units, 2);
  };
  if hundreds > 0 {
    s = s + _word_at(dig, hundreds) + _word_at(units, 1);
  } elif thousands > 0 {
    if tens > 0 || ones > 0 {
      s = s + zero;
    };
  };
  if tens > 0 {
    s = s + _word_at(dig, tens) + _word_at(units, 0);
  } elif thousands > 0 || hundreds > 0 {
    if ones > 0 {
      s = s + zero;
    };
  };
  if ones > 0 {
    s = s + _word_at(dig, ones);
  };
  if val >= 10 && val < 100 {
    if string.str_starts_with(s, _word_at(dig, 1) + _word_at(units, 0)) {
      var first_len = _utf8_len(string.byte_at(s, 0));
      s = string.str_slice(s, first_len, s.len());
    };
  };
  return s;
}

/// Core CJK converter over digit strings. `dig` digits, `units` (十百千),
/// `zero` char, and the 万/亿 scale chars for the 4-digit groups.
fn _cjk_mag(digits: Str, dig: Str, units: Str, zero: Str, wan: Str, yi: Str) -> Str {
  if digits == "0" {
    return zero;
  };
  var padded = digits;
  while padded.len() % 4 != 0 {
    padded = "0" + padded;
  }
  var groups = padded.len() / 4;
  var result = "";
  var g = 0;
  while g < groups {
    var quad = string.str_slice(padded, g * 4, g * 4 + 4);
    var q0 = string.byte_at(quad, 0) as Int - 48;
    var q1 = string.byte_at(quad, 1) as Int - 48;
    var q2 = string.byte_at(quad, 2) as Int - 48;
    var q3 = string.byte_at(quad, 3) as Int - 48;
    var value = q0 * 1000 + q1 * 100 + q2 * 10 + q3;
    if value > 0 {
      if result.len() > 0 {
        if value < 1000 {
          result = result + zero;
        };
      };
      result = result + _cn_group(value, dig, units, zero);
      var gi = groups - 1 - g;
      if gi == 1 {
        result = result + wan;
      } elif gi == 2 {
        result = result + yi;
      } elif gi == 3 {
        result = result + yi + wan;
      };
    };
    g = g + 1;
  }
  return result;
}

fn _cn_digits_simp() -> Str {
  return "零 一 二 三 四 五 六 七 八 九";
}

fn _cn_units_cn() -> Str {
  return "\u{5341} \u{767e} \u{5343}";
}

fn _cn_digits_jp() -> Str {
  return "〇 一 二 三 四 五 六 七 八 九";
}

fn _cn_digits_kr() -> Str {
  return "영 일 이 삼 사 오 육 칠 팔 구";
}

fn _cn_units_kr() -> Str {
  return "\u{c2ed} \u{bc31} \u{cc9c}";
}

/// Spell `n` in Chinese numerals (simplified: 一亿零一, 十五, 一百零一).
pub fn number_to_chinese(n: Int) -> Str {
  return number_to_chinese_simplified(n);
}

/// Spell `n` in simplified Chinese numerals (万/亿).
pub fn number_to_chinese_simplified(n: Int) -> Str {
  var d = _digits_of(n);
  var body = _cjk_mag(d.digits, _cn_digits_simp(), _cn_units_cn(), "\u{96f6}", "\u{4e07}", "\u{4ebf}");
  if d.neg {
    return "\u{8d1f}" + body;
  };
  return body;
}

/// Spell `n` in traditional Chinese numerals (萬/億).
pub fn number_to_chinese_traditional(n: Int) -> Str {
  var d = _digits_of(n);
  var body = _cjk_mag(d.digits, _cn_digits_simp(), _cn_units_cn(), "\u{96f6}", "\u{842c}", "\u{5104}");
  if d.neg {
    return "\u{8d1f}" + body;
  };
  return body;
}

/// Spell `n` in Japanese numerals (〇 一 二 三 ... 十 百 千 万 億).
pub fn number_to_japanese(n: Int) -> Str {
  var d = _digits_of(n);
  var body = _cjk_mag(d.digits, _cn_digits_jp(), _cn_units_cn(), "\u{3007}", "\u{4e07}", "\u{5104}");
  if d.neg {
    return "\u{30de}\u{30a4}\u{30ca}\u{30b9}" + body;
  };
  return body;
}

/// Spell `n` in Sino-Korean numerals (영 일 이 삼 ... 십 백 천 만 억).
pub fn number_to_korean(n: Int) -> Str {
  var d = _digits_of(n);
  var body = _cjk_mag(d.digits, _cn_digits_kr(), _cn_units_kr(), "\u{c601}", "\u{b9cc}", "\u{c5b5}");
  if d.neg {
    return "\u{c601}" + body;
  };
  return body;
}

/// Spell `n` in Indian-system English words (lakh = 10^5, crore = 10^7).
/// Complexity: O(log10 n).
pub fn number_to_indian_words(n: Int) -> Str {
  if n == 0 {
    return "zero";
  };
  var d = _digits_of(n);
  var digits = d.digits;
  var neg = d.neg;
  var scales = "zero thousand lakh crore arab kharab nil padma";
  var padded = digits;
  while padded.len() % 3 != 0 {
    padded = "0" + padded;
  }
  var groups = padded.len() / 3;
  var result = "";
  var g = 0;
  while g < groups {
    var triple = string.str_slice(padded, g * 3, g * 3 + 3);
    var t0 = string.byte_at(triple, 0) as Int - 48;
    var t1 = string.byte_at(triple, 1) as Int - 48;
    var t2 = string.byte_at(triple, 2) as Int - 48;
    var value = t0 * 100 + t1 * 10 + t2;
    if value > 0 {
      var tw = _triple_words(value);
      var scale_idx = groups - 1 - g;
      var scale = "";
      if scale_idx > 0 {
        scale = _word_at(scales, scale_idx);
      };
      if result.len() > 0 {
        result = result + " ";
      };
      result = result + tw;
      if scale.len() > 0 {
        result = result + " " + scale;
      };
    };
    g = g + 1;
  }
  if neg {
    return "minus " + result;
  };
  return result;
}

/// Group `n` using Indian digit grouping (1234567 -> "12,34,567").
/// Complexity: O(log10 n).
pub fn number_to_indian_grouping(n: Int) -> Str {
  var d = _digits_of(n);
  var digits = d.digits;
  var neg = d.neg;
  var result = "";
  var dl = digits.len();
  if dl <= 3 {
    result = digits;
  } else {
    var tail = string.str_slice(digits, dl - 3, dl);
    var head = string.str_slice(digits, 0, dl - 3);
    result = tail;
    var hl = head.len();
    var hi = hl - 2;
    while hi >= 0 {
      var pair = string.str_slice(head, hi, hi + 2);
      result = pair + "," + result;
      hi = hi - 2;
    }
    if hl % 2 != 0 {
      result = string.str_slice(head, 0, 1) + "," + result;
    };
  };
  if neg {
    return "-" + result;
  };
  return result;
}

type MoneyNames = {
  unit: Str;
  sub: Str;
  has_sub: Bool;
}

fn _currency_names(currency: Str) -> MoneyNames {
  if currency == "USD" {
    return MoneyNames{ unit: "dollar"; sub: "cent"; has_sub: true; };
  };
  if currency == "EUR" {
    return MoneyNames{ unit: "euro"; sub: "cent"; has_sub: true; };
  };
  if currency == "GBP" {
    return MoneyNames{ unit: "pound"; sub: "pence"; has_sub: true; };
  };
  if currency == "JPY" {
    return MoneyNames{ unit: "yen"; sub: "yen"; has_sub: false; };
  };
  if currency == "INR" {
    return MoneyNames{ unit: "rupee"; sub: "paisa"; has_sub: true; };
  };
  if currency == "AUD" {
    return MoneyNames{ unit: "dollar"; sub: "cent"; has_sub: true; };
  };
  if currency == "CAD" {
    return MoneyNames{ unit: "dollar"; sub: "cent"; has_sub: true; };
  };
  return MoneyNames{ unit: "unit"; sub: "cent"; has_sub: true; };
}

/// Spell a money amount in words: amount_cents is the value in the currency's
/// smallest unit (e.g. 12345 cents for $123.45). Known currencies: USD, EUR,
/// GBP, JPY, INR, AUD, CAD; anything else falls back to "unit/cent".
pub fn money_to_words(amount_cents: Int, currency: Str) -> Str {
  var names = _currency_names(currency);
  var neg = amount_cents < 0;
  var cents = amount_cents;
  if neg {
    cents = 0 - cents;
  };
  var units = cents / 100;
  var rem = cents % 100;
  var result = "";
  if units == 0 && !names.has_sub {
    result = number_to_words(rem) + " " + names.unit;
  } else {
    result = number_to_words(units);
    var uname = names.unit;
    if units != 1 {
      uname = uname + "s";
    };
    result = result + " " + uname;
    if names.has_sub {
      var sname = names.sub;
      if sname != "pence" && sname != "yen" {
        if rem != 1 {
          sname = sname + "s";
        };
      };
      result = result + " and " + number_to_words(rem) + " " + sname;
    };
  };
  if neg {
    return "minus " + result;
  };
  return result;
}
