// p_wave198_long_tail.xi -- wave 198: long-tail contract-clause lock.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every listed call re-evaluates a wave-198 requires/ensures at runtime, so a
// violated clause aborts the probe. Cases:
// 1. string: char case/digit/UTF-8, block names, builder length, natural
//    collation range, word-shuffle/rotate length, ignore-case equality,
//    display truncation, emoji classification, normalized distance, line
//    cursor/span/slice, view length/equality/prefix/find, alphanumeric and
//    whitespace predicates, strip lengths, reversed-word length.
// 2. convert: code-point domain, clock field ranges, url_build length.
// 3. crypto.kdf: scrypt output length for requested and zero key lengths.
// 4. io/text/sync: dir_exists alias, diff_apply error text, channel try
//    semantics and count-down latch bounds.
// 5. compress/num/bits: gzip file postcondition, BigFloat integer-rounding
//    structure, BigInt zero predicate, fraction accessors, BitArray resize.
// 6. net/log: request-line length, status bounds, URL codec bounds,
//    header-parse law, log timestamp/sink fields.
// Returns 0 when every case holds.
// NOTE: log.json and xiom.serialize cannot share a program on v0.64.8
// (Map.insert_LogEntry_JsonValue lowers enum equality to an invalid icmp on
// %struct.LogLevel); serialize's clause is compile-checked by check_modules.

module p_wave198_long_tail

use xiom.string;
use xiom.string.block;
use xiom.string.builder;
use xiom.string.char;
use xiom.string.collate;
use xiom.string.combinatorics;
use xiom.string.compare;
use xiom.string.ea_width;
use xiom.string.emoji;
use xiom.string.levenshtein;
use xiom.string.lines;
use xiom.string.lowercase;
use xiom.string.reverse;
use xiom.string.strip;
use xiom.string.unicode;
use xiom.string.uppercase;
use xiom.string.utf8;
use xiom.string.view;
use xiom.convert;
use xiom.convert.date;
use xiom.convert.datetime;
use xiom.convert.from;
use xiom.convert.toint;
use xiom.convert.uri;
use xiom.convert.url;
use xiom.crypto.kdf;
use xiom.io;
use xiom.text.diff;
use xiom.sync;
use xiom.sync.channel;
use xiom.compress.gzip;
use xiom.num;
use xiom.num.bigfloat;
use xiom.num.bigint;
use xiom.bits.bitarray;
use xiom.net.https;
use xiom.log.json;
use xiom.log.sinks;
use xiom.test.assert;

fn main() -> Int {
  // 1: string -- char mappings and UTF-8 encoding.
  if char.to_lowercase('A') != 'a' { return 1; }
  if char.to_uppercase('a') != 'A' { return 2; }
  if char.to_title_case('a') != 'A' { return 3; }
  if char.char_to_digit_value('7').value != 7 { return 4; }
  if char.digit_value_to_char(7).value != '7' { return 5; }
  if char.digit_value_to_char(10).is_some { return 6; }
  var enc = Vec[UInt8].new();
  char.encode_utf8(to_char(0xE9), &mut enc);
  if enc.len() != 2 { return 7; }
  if lowercase.char_lowercase('A') != 'a' { return 8; }
  if uppercase.char_uppercase('a') != 'A' { return 9; }

  // 1: string -- block/builder/collation/combinatorics/compare/width.
  if block.unicode_block('A').len() == 0 { return 10; }
  var bb = Vec[UInt8].new();
  bb.push(65);
  bb.push(66);
  let bs = builder.sb_into_str(bb);
  if bs.len() != 2 { return 11; }
  if collate.collate_compare_numeric("file2", "file10") >= 0 { return 12; }
  if combinatorics.str_shuffle_words_seeded("a  b", 3).len() > 4 { return 13; }
  if combinatorics.str_rotate_word("a b c", 1).len() > 5 { return 14; }
  if !compare.str_eq_ignore_case("Ab", "aB") { return 15; }
  if ea_width.unicode_truncate_display("abc", 2).len() != 2 { return 16; }
  if ea_width.unicode_truncate_display("abc", 0).len() != 0 { return 17; }
  if levenshtein.levenshtein_normalized("a", "b") < 0.0 { return 18; }
  if levenshtein.levenshtein_normalized("a", "b") > 1.0 { return 19; }
  if reverse.str_reverse_words("a b").len() != 3 { return 20; }

  // 1: string -- predicates, strip, lines, views, utf8.
  let ideo = to_char(0x6F22);
  if !unicode.unicode_is_ideographic(ideo) { return 21; }
  if !unicode.unicode_is_whitespace(' ') { return 22; }
  if !unicode.unicode_is_numeric('7') { return 23; }
  if !unicode.unicode_is_alphabetic('A') { return 24; }
  if !unicode.unicode_emoji_presentation(to_char(0x1F600)) { return 25; }
  if !unicode.unicode_has_emoji("x😀") { return 26; }
  if !emoji.unicode_is_emoji(to_char(0x1F600)) { return 27; }
  let sp = strip.str_strip_prefix("abc", "a");
  if !sp.is_some { return 28; }
  if sp.value.len() != 2 { return 29; }
  let ss = strip.str_strip_suffix("abc", "c");
  if !ss.is_some { return 30; }
  if ss.value.len() != 2 { return 31; }
  var lc = lines.lines_new("a\nb");
  if lc.len != 3 || lc.pos != 0 || lc.line != 0 { return 32; }
  if lines.lines_newline_index("a\nb").len() != 1 { return 33; }
  if !lines.lines_span("a\nb", 0).is_some { return 34; }
  if lines.lines_span("a\nb", 9).is_some { return 35; }
  var ln1 = lines.lines_next(&mut lc);
  if !ln1.is_some { return 36; }
  var ln2 = lines.lines_next(&mut lc);
  if !ln2.is_some { return 37; }
  var ln3 = lines.lines_next(&mut lc);
  if ln3.is_some { return 38; }
  let lsl = lines.lines_slice("a\nb", 1);
  if !lsl.is_some { return 39; }
  if lsl.value.len() > 3 { return 40; }
  let v = view.view_of("abc");
  let ve = view.view_of("");
  if view.view_is_empty(&v) { return 41; }
  if !view.view_is_empty(&ve) { return 42; }
  if view.view_eq(&v, &ve) { return 43; }
  if !view.view_starts_with(&v, "ab") { return 44; }
  let vf = view.view_find(&v, "bc");
  if !vf.is_some { return 45; }
  if vf.value != 1 { return 46; }
  var empty_bytes = Vec[UInt8].new();
  if !utf8.utf8_validate(&empty_bytes) { return 47; }
  if !utf8.utf8_is_continuation(0x80) { return 48; }
  if utf8.utf8_is_continuation(0x41) { return 49; }

  // 2: convert.
  if convert.char_to_int('A') != 65 { return 50; }
  if from.from_char('A') != 65 { return 51; }
  if toint.to_int(0.0) != 0 { return 52; }
  let dn = date.date_now();
  if dn.month < 1 || dn.month > 12 || dn.day < 1 || dn.day > 31 { return 53; }
  let dtn = datetime.datetime_now();
  if dtn.hour < 0 || dtn.hour > 23 { return 54; }
  if dtn.minute < 0 || dtn.minute > 59 { return 55; }
  if dtn.second < 0 || dtn.second > 59 { return 56; }
  let built = url.url_build("https", "example.com", 0, "/", "");
  if built != "https://example.com/" { return 57; }
  if !uri.uri_resolve("http://a/b/c", "d").is_ok { return 58; }

  // 3: crypto.kdf scrypt length laws.
  var pw = Vec[UInt8].new();
  pw.push(112);
  var salt = Vec[UInt8].new();
  salt.push(115);
  if kdf.scrypt(&pw, &salt, 2, 1, 1, 8).len() != 8 { return 59; }
  if kdf.scrypt(&pw, &salt, 2, 1, 1, 0).len() != 0 { return 60; }

  // 4: io/text/sync.
  if !io.dir_exists(".") { return 61; }
  let bad_patch = diff.diff_apply("x", "bogus");
  if !bad_patch.is_err { return 62; }
  if bad_patch.value.len() == 0 { return 63; }
  var latch = sync.cdl_new(2);
  sync.cdl_count_down(&mut latch);
  sync.cdl_count_down(&mut latch);
  sync.cdl_count_down(&mut latch);
  if latch.remaining != 0 { return 64; }
  var ch = channel.channel_new(0);
  if !channel.channel_try_send(&mut ch, 5) { return 65; }
  let cr = channel.channel_try_recv(&mut ch);
  if !cr.is_some || cr.value != 5 { return 66; }
  var ch2 = channel.channel_new(1);
  let cr2 = channel.channel_try_recv(&mut ch2);
  if cr2.is_some { return 67; }

  // 5: compress/num/bits.
  let gzpath = "p_wave198_long_tail_tmp.txt";
  let _ = io.remove_file(gzpath);
  let _ = io.remove_file(gzpath + ".gz");
  let wr = io.write_file(gzpath, "wave198");
  if wr.is_err { return 68; }
  let gz = gzip.gzip_compress_file(gzpath);
  if gz.is_err { return 69; }
  let _ = io.remove_file(gzpath);
  let _ = io.remove_file(gzpath + ".gz");
  let bf = bigfloat.bigfloat_from_int(5);
  let bt = bigfloat.bigfloat_trunc(&bf);
  if bt.exponent != 0 || bt.precision != bf.precision { return 70; }
  let bfl = bigfloat.bigfloat_floor(&bf);
  if bfl.exponent != 0 { return 71; }
  let bce = bigfloat.bigfloat_ceil(&bf);
  if bce.exponent != 0 { return 72; }
  let brd = bigfloat.bigfloat_round(&bf);
  if brd.exponent != 0 { return 73; }
  if !bigfloat.bigfloat_eq(&bf, &bf) { return 74; }
  if bigfloat.bigfloat_lt(&bf, &bf) { return 75; }
  if !bigfloat.bigfloat_le(&bf, &bf) { return 76; }
  if bigfloat.bigfloat_gt(&bf, &bf) { return 77; }
  if !bigfloat.bigfloat_ge(&bf, &bf) { return 78; }
  let bz = bigint.bigint_zero();
  if !bigint.bigint_is_zero(&bz) { return 79; }
  let fr = num.fraction_new(-6, 4);
  if num.fraction_num(fr) != -3 { return 80; }
  if num.fraction_den(fr) != 2 { return 81; }
  var ba = bitarray.bit_array_new(10);
  bitarray.bit_array_set(&mut ba, 3);
  bitarray.bit_array_clear(&mut ba, 3);
  bitarray.bit_array_flip(&mut ba, 3);
  if ba.len != 10 || ba.bits.len() != 2 { return 82; }

  // 6: net/log/serialize.
  if https.https_request_line("GET", "/").len() != 14 { return 83; }
  let st = https.https_response_status("HTTP/1.1 200 OK\r\n");
  if !st.is_some || st.value != 200 { return 84; }
  if https.https_parse_response_headers("").len() != 0 { return 85; }
  if https.https_parse_response_headers("HTTP/1.1 200 OK\r\nA: b\r\n\r\n").len() == 0 { return 86; }
  let he = https.https_url_encode("a b");
  if he.len() < 3 || he.len() > 9 { return 87; }
  let hd = https.https_url_decode("a%20b");
  if !hd.is_ok || hd.value != "a b" { return 88; }
  var hs = Vec[(Str, Str)].new();
  hs.push(("X", "y"));
  var body = Vec[UInt8].new();
  let req = https.https_build_request("GET", "https://example.com/", &hs, &body);
  if !req.is_ok || req.value.len() < 18 { return 89; }
  if json.log_json_timestamp().len() == 0 { return 90; }
  let sinkpath = "p_wave198_long_tail_sink.log";
  let _ = io.remove_file(sinkpath);
  let sf = sinks.log_sink_file(sinkpath);
  if !sf.is_ok { return 92; }
  if sf.value.target != 3 || sf.value.bytes != 0 { return 93; }
  if sf.value.path.len() != sinkpath.len() { return 94; }
  let _ = io.remove_file(sinkpath);

  // 7: test assertions (normal-return postconditions).
  assert.assert_near(1.0, 1.0000001, 0.001, "near");
  assert.assert_matches("abc", "b", "match");

  return 0;
}
