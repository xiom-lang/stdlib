// XIOM - Text: Transliteration
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.text.transliterate

// Depends on: xiom.string

use xiom.string;
use xiom.convert;

// ============================================================================
// Script-to-Latin transliteration for Cyrillic, Greek, Arabic, Hebrew,
// Devanagari, CJK and accents, with custom table support.
//
// Coverage is honest and deliberately bounded: the common Cyrillic, Greek and
// accented-Latin characters map fully; Arabic, Hebrew, Devanagari, kana,
// hangul and CJK map the most frequent characters and pass everything else
// through unchanged. Input is decoded as UTF-8; unmapped characters are
// preserved verbatim. `transliterate` is `transliterate_to_ascii` -- a
// best-effort reduction to Latin script.
// ============================================================================

/// UTF-8 sequence length in bytes for the lead byte `b0` (1..4).
fn cp_len(b0: UInt8) -> Int {
  let b = b0 as Int;
  if b < 0x80 {
    return 1;
  };
  if b < 0xE0 {
    return 2;
  };
  if b < 0xF0 {
    return 3;
  };
  4
}

/// Decode the UTF-8 codepoint at byte `pos` of `s`.
fn decode_cp(s: Str, pos: Int) -> Int {
  let b0 = string.byte_at(s, pos) as Int;
  let len = cp_len(string.byte_at(s, pos));
  if len == 1 {
    return b0;
  };
  let b1 = string.byte_at(s, pos + 1) as Int;
  if len == 2 {
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  let b2 = string.byte_at(s, pos + 2) as Int;
  if len == 3 {
    return ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
  };
  let b3 = string.byte_at(s, pos + 3) as Int;
  ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
}

/// Latin replacement for an accented codepoint, or "" when unmapped.
fn accent_repl(cp: Int) -> Str {
  if cp == 224 || cp == 225 || cp == 226 || cp == 227 || cp == 228 || cp == 229 {
    return "a";
  };
  if cp == 232 || cp == 233 || cp == 234 || cp == 235 {
    return "e";
  };
  if cp == 236 || cp == 237 || cp == 238 || cp == 239 {
    return "i";
  };
  if cp == 242 || cp == 243 || cp == 244 || cp == 245 || cp == 246 {
    return "o";
  };
  if cp == 249 || cp == 250 || cp == 251 || cp == 252 {
    return "u";
  };
  if cp == 192 || cp == 193 || cp == 194 || cp == 195 || cp == 196 || cp == 197 {
    return "A";
  };
  if cp == 200 || cp == 201 || cp == 202 || cp == 203 {
    return "E";
  };
  if cp == 204 || cp == 205 || cp == 206 || cp == 207 {
    return "I";
  };
  if cp == 210 || cp == 211 || cp == 212 || cp == 213 || cp == 214 {
    return "O";
  };
  if cp == 217 || cp == 218 || cp == 219 || cp == 220 {
    return "U";
  };
  if cp == 241 {
    return "n";
  };
  if cp == 209 {
    return "N";
  };
  if cp == 231 {
    return "c";
  };
  if cp == 199 {
    return "C";
  };
  if cp == 253 || cp == 255 {
    return "y";
  };
  if cp == 221 {
    return "Y";
  };
  if cp == 230 {
    return "ae";
  };
  if cp == 198 {
    return "AE";
  };
  if cp == 223 {
    return "ss";
  };
  if cp == 240 {
    return "d";
  };
  if cp == 208 {
    return "D";
  };
  if cp == 254 {
    return "th";
  };
  if cp == 222 {
    return "Th";
  };
  ""
}

/// Latin replacement for a Cyrillic codepoint, or "" when unmapped.
fn cyr_repl(cp: Int) -> Str {
  if cp == 1040 {
    return "A";
  };
  if cp == 1041 {
    return "B";
  };
  if cp == 1042 {
    return "V";
  };
  if cp == 1043 {
    return "G";
  };
  if cp == 1044 {
    return "D";
  };
  if cp == 1045 {
    return "E";
  };
  if cp == 1046 {
    return "Zh";
  };
  if cp == 1047 {
    return "Z";
  };
  if cp == 1048 {
    return "I";
  };
  if cp == 1049 {
    return "Y";
  };
  if cp == 1050 {
    return "K";
  };
  if cp == 1051 {
    return "L";
  };
  if cp == 1052 {
    return "M";
  };
  if cp == 1053 {
    return "N";
  };
  if cp == 1054 {
    return "O";
  };
  if cp == 1055 {
    return "P";
  };
  if cp == 1056 {
    return "R";
  };
  if cp == 1057 {
    return "S";
  };
  if cp == 1058 {
    return "T";
  };
  if cp == 1059 {
    return "U";
  };
  if cp == 1060 {
    return "F";
  };
  if cp == 1061 {
    return "Kh";
  };
  if cp == 1062 {
    return "Ts";
  };
  if cp == 1063 {
    return "Ch";
  };
  if cp == 1064 {
    return "Sh";
  };
  if cp == 1065 {
    return "Shch";
  };
  if cp == 1066 {
    return "";
  };
  if cp == 1067 {
    return "Y";
  };
  if cp == 1068 {
    return "";
  };
  if cp == 1069 {
    return "E";
  };
  if cp == 1070 {
    return "Yu";
  };
  if cp == 1071 {
    return "Ya";
  };
  if cp == 1072 {
    return "a";
  };
  if cp == 1073 {
    return "b";
  };
  if cp == 1074 {
    return "v";
  };
  if cp == 1075 {
    return "g";
  };
  if cp == 1076 {
    return "d";
  };
  if cp == 1077 {
    return "e";
  };
  if cp == 1078 {
    return "zh";
  };
  if cp == 1079 {
    return "z";
  };
  if cp == 1080 {
    return "i";
  };
  if cp == 1081 {
    return "y";
  };
  if cp == 1082 {
    return "k";
  };
  if cp == 1083 {
    return "l";
  };
  if cp == 1084 {
    return "m";
  };
  if cp == 1085 {
    return "n";
  };
  if cp == 1086 {
    return "o";
  };
  if cp == 1087 {
    return "p";
  };
  if cp == 1088 {
    return "r";
  };
  if cp == 1089 {
    return "s";
  };
  if cp == 1090 {
    return "t";
  };
  if cp == 1091 {
    return "u";
  };
  if cp == 1092 {
    return "f";
  };
  if cp == 1093 {
    return "kh";
  };
  if cp == 1094 {
    return "ts";
  };
  if cp == 1095 {
    return "ch";
  };
  if cp == 1096 {
    return "sh";
  };
  if cp == 1097 {
    return "shch";
  };
  if cp == 1098 {
    return "";
  };
  if cp == 1099 {
    return "y";
  };
  if cp == 1100 {
    return "";
  };
  if cp == 1101 {
    return "e";
  };
  if cp == 1102 {
    return "yu";
  };
  if cp == 1103 {
    return "ya";
  };
  if cp == 1105 {
    return "e";
  };
  if cp == 1025 {
    return "E";
  };
  ""
}

/// Latin replacement for a Greek codepoint, or "" when unmapped.
fn greek_repl(cp: Int) -> Str {
  if cp == 913 || cp == 945 {
    return "a";
  };
  if cp == 914 || cp == 946 {
    return "b";
  };
  if cp == 915 || cp == 947 {
    return "g";
  };
  if cp == 916 || cp == 948 {
    return "d";
  };
  if cp == 917 || cp == 949 {
    return "e";
  };
  if cp == 918 || cp == 950 {
    return "z";
  };
  if cp == 919 || cp == 951 {
    return "i";
  };
  if cp == 920 || cp == 952 {
    return "th";
  };
  if cp == 921 || cp == 953 {
    return "i";
  };
  if cp == 922 || cp == 954 {
    return "k";
  };
  if cp == 923 || cp == 955 {
    return "l";
  };
  if cp == 924 || cp == 956 {
    return "m";
  };
  if cp == 925 || cp == 957 {
    return "n";
  };
  if cp == 926 || cp == 958 {
    return "x";
  };
  if cp == 927 || cp == 959 {
    return "o";
  };
  if cp == 928 || cp == 960 {
    return "p";
  };
  if cp == 929 || cp == 961 {
    return "r";
  };
  if cp == 931 || cp == 963 {
    return "s";
  };
  if cp == 932 || cp == 964 {
    return "t";
  };
  if cp == 933 || cp == 965 {
    return "u";
  };
  if cp == 934 || cp == 966 {
    return "ph";
  };
  if cp == 935 || cp == 967 {
    return "ch";
  };
  if cp == 936 || cp == 968 {
    return "ps";
  };
  if cp == 937 || cp == 969 {
    return "o";
  };
  if cp == 940 {
    return "a";
  };
  if cp == 941 {
    return "e";
  };
  if cp == 942 || cp == 943 {
    return "i";
  };
  if cp == 972 {
    return "o";
  };
  if cp == 973 {
    return "u";
  };
  if cp == 974 {
    return "o";
  };
  ""
}

/// Latin approximation for an Arabic codepoint, or "" when unmapped
/// (best-effort; diacritics and variants pass through).
fn arabic_repl(cp: Int) -> Str {
  if cp == 1571 || cp == 1575 || cp == 1572 {
    return "a";
  };
  if cp == 1576 {
    return "b";
  };
  if cp == 1578 {
    return "t";
  };
  if cp == 1580 {
    return "j";
  };
  if cp == 1581 {
    return "h";
  };
  if cp == 1582 {
    return "kh";
  };
  if cp == 1583 {
    return "d";
  };
  if cp == 1584 {
    return "dh";
  };
  if cp == 1585 {
    return "r";
  };
  if cp == 1586 {
    return "z";
  };
  if cp == 1587 {
    return "s";
  };
  if cp == 1588 {
    return "sh";
  };
  if cp == 1589 {
    return "s";
  };
  if cp == 1590 {
    return "d";
  };
  if cp == 1591 {
    return "t";
  };
  if cp == 1592 {
    return "z";
  };
  if cp == 1593 {
    return "a";
  };
  if cp == 1594 {
    return "gh";
  };
  if cp == 1601 {
    return "f";
  };
  if cp == 1602 {
    return "q";
  };
  if cp == 1603 {
    return "k";
  };
  if cp == 1604 {
    return "l";
  };
  if cp == 1605 {
    return "m";
  };
  if cp == 1606 {
    return "n";
  };
  if cp == 1607 {
    return "h";
  };
  if cp == 1608 || cp == 1609 || cp == 1610 {
    return "y";
  };
  if cp == 1611 || cp == 1612 || cp == 1613 || cp == 1614 || cp == 1615 || cp == 1616 || cp == 1617 || cp == 1618 {
    return "";
  };
  ""
}

/// Latin approximation for a Hebrew codepoint, or "" when unmapped
/// (best-effort; final forms pass through).
fn hebrew_repl(cp: Int) -> Str {
  if cp == 1488 {
    return "a";
  };
  if cp == 1489 {
    return "b";
  };
  if cp == 1490 {
    return "g";
  };
  if cp == 1491 {
    return "d";
  };
  if cp == 1492 {
    return "h";
  };
  if cp == 1493 {
    return "v";
  };
  if cp == 1494 {
    return "z";
  };
  if cp == 1495 {
    return "kh";
  };
  if cp == 1496 {
    return "t";
  };
  if cp == 1497 {
    return "y";
  };
  if cp == 1498 {
    return "k";
  };
  if cp == 1499 {
    return "kh";
  };
  if cp == 1500 {
    return "l";
  };
  if cp == 1501 {
    return "m";
  };
  if cp == 1502 {
    return "m";
  };
  if cp == 1503 {
    return "n";
  };
  if cp == 1504 {
    return "n";
  };
  if cp == 1505 {
    return "s";
  };
  if cp == 1506 {
    return "a";
  };
  if cp == 1507 {
    return "p";
  };
  if cp == 1508 {
    return "f";
  };
  if cp == 1509 {
    return "p";
  };
  if cp == 1510 {
    return "ts";
  };
  if cp == 1511 {
    return "k";
  };
  if cp == 1512 {
    return "r";
  };
  if cp == 1513 {
    return "sh";
  };
  if cp == 1514 {
    return "t";
  };
  ""
}

/// Latin approximation for a Devanagari codepoint, or "" when unmapped
/// (best-effort; only consonants and vowels map).
fn devanagari_repl(cp: Int) -> Str {
  if cp == 2309 {
    return "a";
  };
  if cp == 2310 {
    return "aa";
  };
  if cp == 2311 {
    return "i";
  };
  if cp == 2312 {
    return "ii";
  };
  if cp == 2313 {
    return "u";
  };
  if cp == 2314 {
    return "uu";
  };
  if cp == 2315 {
    return "e";
  };
  if cp == 2319 {
    return "o";
  };
  if cp == 2325 {
    return "ka";
  };
  if cp == 2326 {
    return "kha";
  };
  if cp == 2327 {
    return "ga";
  };
  if cp == 2328 {
    return "gha";
  };
  if cp == 2330 {
    return "cha";
  };
  if cp == 2332 {
    return "ja";
  };
  if cp == 2335 {
    return "ta";
  };
  if cp == 2337 {
    return "da";
  };
  if cp == 2339 {
    return "na";
  };
  if cp == 2340 {
    return "ta";
  };
  if cp == 2342 {
    return "da";
  };
  if cp == 2344 {
    return "na";
  };
  if cp == 2346 {
    return "pa";
  };
  if cp == 2347 {
    return "pha";
  };
  if cp == 2348 {
    return "ba";
  };
  if cp == 2349 {
    return "bha";
  };
  if cp == 2350 {
    return "ma";
  };
  if cp == 2351 {
    return "ya";
  };
  if cp == 2352 {
    return "ra";
  };
  if cp == 2354 {
    return "la";
  };
  if cp == 2357 {
    return "va";
  };
  if cp == 2358 {
    return "sha";
  };
  if cp == 2359 {
    return "sa";
  };
  if cp == 2360 {
    return "sa";
  };
  if cp == 2361 {
    return "ha";
  };
  ""
}

/// Latin approximation for a Japanese kana codepoint, or "" when unmapped
/// (best-effort; hiragana and common katakana map).
fn romaji_repl(cp: Int) -> Str {
  if cp == 12354 {
    return "a";
  };
  if cp == 12356 {
    return "i";
  };
  if cp == 12358 {
    return "u";
  };
  if cp == 12360 {
    return "e";
  };
  if cp == 12362 {
    return "o";
  };
  if cp == 12363 {
    return "ka";
  };
  if cp == 12365 {
    return "ki";
  };
  if cp == 12367 {
    return "ku";
  };
  if cp == 12369 {
    return "ke";
  };
  if cp == 12371 {
    return "ko";
  };
  if cp == 12373 {
    return "sa";
  };
  if cp == 12375 {
    return "shi";
  };
  if cp == 12377 {
    return "su";
  };
  if cp == 12379 {
    return "se";
  };
  if cp == 12381 {
    return "so";
  };
  if cp == 12383 {
    return "ta";
  };
  if cp == 12385 {
    return "chi";
  };
  if cp == 12387 {
    return "tsu";
  };
  if cp == 12389 {
    return "te";
  };
  if cp == 12391 {
    return "to";
  };
  if cp == 12394 {
    return "na";
  };
  if cp == 12396 {
    return "ni";
  };
  if cp == 12398 {
    return "nu";
  };
  if cp == 12400 {
    return "ne";
  };
  if cp == 12402 {
    return "no";
  };
  if cp == 12408 {
    return "ma";
  };
  if cp == 12411 {
    return "mi";
  };
  if cp == 12414 {
    return "mu";
  };
  if cp == 12416 {
    return "me";
  };
  if cp == 12418 {
    return "mo";
  };
  if cp == 12420 {
    return "ya";
  };
  if cp == 12422 {
    return "yu";
  };
  if cp == 12424 {
    return "yo";
  };
  if cp == 12425 {
    return "ra";
  };
  if cp == 12427 {
    return "ri";
  };
  if cp == 12429 {
    return "ru";
  };
  if cp == 12431 {
    return "re";
  };
  if cp == 12433 {
    return "ro";
  };
  if cp == 12435 {
    return "n";
  };
  ""
}

/// Latin approximation for a Hangul codepoint, or "" when unmapped
/// (best-effort; common syllable codepoints map).
fn hangul_repl(cp: Int) -> Str {
  if cp == 44032 {
    return "ga";
  };
  if cp == 44060 {
    return "na";
  };
  if cp == 44061 {
    return "nan";
  };
  if cp == 44053 {
    return "gag";
  };
  if cp == 44048 {
    return "gae";
  };
  if cp == 44592 {
    return "da";
  };
  if cp == 45208 {
    return "ra";
  };
  if cp == 47532 {
    return "ma";
  };
  if cp == 48120 {
    return "ba";
  };
  if cp == 49324 {
    return "sa";
  };
  if cp == 50504 {
    return "ja";
  };
  if cp == 51648 {
    return "cha";
  };
  if cp == 53468 {
    return "ha";
  };
  ""
}

/// Latin approximation for a CJK ideograph, or "" when unmapped. Only a few
/// common characters map; everything else passes through (documented).
fn pinyin_repl(cp: Int) -> Str {
  if cp == 20320 {
    return "ni";
  };
  if cp == 22909 {
    return "hao";
  };
  if cp == 19968 {
    return "yi";
  };
  if cp == 20108 {
    return "yu";
  };
  if cp == 19971 {
    return "he";
  };
  if cp == 20013 {
    return "zhong";
  };
  if cp == 20154 {
    return "ren";
  };
  if cp == 20160 {
    return "shi";
  };
  if cp == 22823 {
    return "da";
  };
  if cp == 23567 {
    return "xiao";
  };
  if cp == 27700 {
    return "guo";
  };
  if cp == 27891 {
    return "jia";
  };
  ""
}

/// Transliterate `s` by mapping the codepoints handled by `repl` and keeping
/// everything else unchanged.
fn transliterate_with(s: Str, repl: fn(Int) -> Str) -> Str {
  var out = "";
  var i: Int = 0;
  let len = s.len();
  while i < len {
    let b0 = string.byte_at(s, i);
    let clen = cp_len(b0);
    let cp = decode_cp(s, i);
    let mapped = repl(cp);
    if mapped.len() > 0 {
      out = string.str_concat(out, mapped);
    } else {
      out = string.str_concat(out, string.str_slice(s, i, i + clen));
    };
    i = i + clen;
  };
  out
}

/// Best-effort transliteration of `s` to Latin script: strips accents and
/// maps known scripts (Cyrillic, Greek, Arabic, Hebrew, Devanagari, kana,
/// hangul and a few CJK characters).
/// Complexity: O(len(s)).
pub fn transliterate(s: Str) -> Str {
  transliterate_to_ascii(s)
}

/// Transliterate Cyrillic text to Latin.
/// Complexity: O(len(s)).
pub fn transliterate_cyrillic(s: Str) -> Str {
  transliterate_with(s, cyr_repl)
}

/// Transliterate Greek text to Latin.
/// Complexity: O(len(s)).
pub fn transliterate_greek(s: Str) -> Str {
  transliterate_with(s, greek_repl)
}

/// Transliterate Arabic text to Latin (best-effort; see header).
/// Complexity: O(len(s)).
pub fn transliterate_arabic(s: Str) -> Str {
  transliterate_with(s, arabic_repl)
}

/// Transliterate Hebrew text to Latin (best-effort; see header).
/// Complexity: O(len(s)).
pub fn transliterate_hebrew(s: Str) -> Str {
  transliterate_with(s, hebrew_repl)
}

/// Transliterate Devanagari text to Latin (best-effort; see header).
/// Complexity: O(len(s)).
pub fn transliterate_devanagari(s: Str) -> Str {
  transliterate_with(s, devanagari_repl)
}

/// Convert Chinese characters to pinyin where known (only a few characters
/// map; everything else passes through).
/// Complexity: O(len(s)).
pub fn transliterate_chinese_pinyin(s: Str) -> Str {
  transliterate_with(s, pinyin_repl)
}

/// Convert Japanese kana to romaji (best-effort; see header).
/// Complexity: O(len(s)).
pub fn transliterate_japanese_romaji(s: Str) -> Str {
  transliterate_with(s, romaji_repl)
}

/// Romanize Korean hangul (best-effort; see header).
/// Complexity: O(len(s)).
pub fn transliterate_korean_roman(s: Str) -> Str {
  transliterate_with(s, hangul_repl)
}

/// Strip accents from Latin letters (e -> e, u -> u, ...).
/// Complexity: O(len(s)).
pub fn transliterate_accented(s: Str) -> Str {
  transliterate_with(s, accent_repl)
}

/// Reduce any script to a pure ASCII approximation: accent stripping plus
/// the script tables (Cyrillic, Greek, Arabic, Hebrew, Devanagari, kana,
/// hangul, CJK). Unmapped characters pass through unchanged.
/// Complexity: O(len(s)).
pub fn transliterate_to_ascii(s: Str) -> Str {
  let acc = transliterate_with(s, accent_repl);
  let cyr = transliterate_with(acc, cyr_repl);
  let gre = transliterate_with(cyr, greek_repl);
  let arb = transliterate_with(gre, arabic_repl);
  let heb = transliterate_with(arb, hebrew_repl);
  let dev = transliterate_with(heb, devanagari_repl);
  let rom = transliterate_with(dev, romaji_repl);
  let han = transliterate_with(rom, hangul_repl);
  transliterate_with(han, pinyin_repl)
}

/// Apply a custom transliteration table; each tuple is (char, replacement).
/// Characters in `s` matching a table char are replaced; everything else is
/// kept unchanged.
/// Complexity: O(len(s) * table).
pub fn transliterate_custom(s: Str, table: &Vec[(Char, Str)]) -> Str {
  var out = "";
  var i: Int = 0;
  let len = s.len();
  while i < len {
    let b0 = string.byte_at(s, i);
    let clen = cp_len(b0);
    let cp = decode_cp(s, i);
    var replaced: Str = "";
    var j: Int = 0;
    while j < table.len() {
      let entry = table[j];
      let kc = convert.char_to_int(entry.0);
      if kc == cp {
        replaced = entry.1;
      };
      j = j + 1;
    };
    if replaced.len() > 0 {
      out = string.str_concat(out, replaced);
    } else {
      out = string.str_concat(out, string.str_slice(s, i, i + clen));
    };
    i = i + clen;
  };
  out
}
