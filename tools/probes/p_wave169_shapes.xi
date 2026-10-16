// p_wave169_shapes.xi -- wave 169 lock: the raw, format-preserving JSON
// member lookup + typed accessors on xiom.serialize.json (row 40 of
// docs/STDLIB-WISHLIST.md; packages sheet 2026-10-02: raw-byte lookup,
// boundary-checked key spans, scalar values, member offsets, byte-offset
// errors; requesters nats/oauth/dynamo/keymgmt/vault/elastic/cloudlog).
// Rows (0 = all hold):
//  1 -- json_find_member spans on a no-padding doc are exact offsets
//  2 -- spans on a padded doc: raw key/value slices match the source
//  3 -- format preservation: 1.50e+2, escaped string bytes, nested container
//  4 -- json_raw_get_str: escape decode, \u0042, surrogate pair -> UTF-8
//  5 -- malformed value tokens: invalid escape and raw control byte are Err;
//       a lone \uD800 is Err on decode (keymgmt surrogate rejection)
//  6 -- json_raw_get_int: 1 / -7 Ok; 1.5, 1e3, 20-nines all Err
//  7 -- missing key, empty input, array input, null input are Err
//  8 -- duplicate keys: the first match wins
//  9 -- errors carry the byte offset ("at byte")
// 10 -- escape-aware keys: \u0042 and \" in key tokens match decoded asks
// 11 -- typed accessors: as_str / as_bool / as_int / as_float (+ bounds)
// 12 -- raw/span consistency: span slice equals json_raw_get
// 13 -- whitespace tolerance and empty-object key-not-found
// Setup failures use 20+.

module p_wave169_shapes

use xiom.serialize.json as sjson;
use xiom.string;

fn _slice(s: Str, start: Int, end: Int) -> Str {
  if end <= start {
    return "";
  }
  var buf = Vec[UInt8].new();
  var i = start;
  while i < end {
    buf.push(s.byte_at(i));
    i = i + 1;
  };
  return Str::from_utf8(buf);
}

fn main() -> Int {
  // Row 1: exact spans on a no-padding doc.
  let d1 = "{\"k\":1}";
  let r1 = sjson.json_find_member(d1, "k");
  if r1.is_err { return 20; }
  let m1 = r1.value;
  if m1.key_start != 2 { return 1; }
  if m1.key_end != 3 { return 1; }
  if m1.value_start != 5 { return 1; }
  if m1.value_end != 6 { return 1; }
  if _slice(d1, m1.key_start, m1.key_end) != "k" { return 1; }
  if _slice(d1, m1.value_start, m1.value_end) != "1" { return 1; }

  // Row 2-3 fixtures: realistic padded doc.
  let doc = "{\n  \"server_id\" : \"S1\",\n  \"proto\" : 1,\n  \"max_payload\": 1048576,\n  \"neg\": -7,\n  \"factor\": 1.50e+2,\n  \"quoted\": \"a\\u0042c\",\n  \"esc\": \"a\\\"b\\\\c\",\n  \"emoji\": \"\\uD83D\\uDE00\",\n  \"nested\": {\"a\":1,\"b\":[1,2,{\"c\":true}]},\n  \"dup\": 1,\n  \"dup\": 2,\n  \"frac\": 1.5,\n  \"exp\": 1e3,\n  \"big\": 99999999999999999999,\n  \"badesc\": \"a\\q\"\n}";

  // Row 2: padded spans + raw slices.
  let r2 = sjson.json_find_member(doc, "server_id");
  if r2.is_err { return 20; }
  let m2 = r2.value;
  if _slice(doc, m2.key_start, m2.key_end) != "server_id" { return 2; }
  if _slice(doc, m2.value_start, m2.value_end) != "\"S1\"" { return 2; }
  let rp = sjson.json_find_member(doc, "proto");
  if rp.is_err { return 2; }
  let mp = rp.value;
  if _slice(doc, mp.value_start, mp.value_end) != "1" { return 2; }
  let rn = sjson.json_find_member(doc, "neg");
  if rn.is_err { return 2; }
  let rnraw = sjson.json_raw_get(doc, "neg");
  if rnraw.is_err { return 2; }
  if rnraw.value != "-7" { return 2; }

  // Row 3: format preservation.
  let rf = sjson.json_raw_get(doc, "factor");
  if rf.is_err { return 3; }
  if rf.value != "1.50e+2" { return 3; }
  let rq = sjson.json_raw_get(doc, "quoted");
  if rq.is_err { return 3; }
  if rq.value != "\"a\\u0042c\"" { return 3; }
  let rnest = sjson.json_raw_get(doc, "nested");
  if rnest.is_err { return 3; }
  if rnest.value != "{\"a\":1,\"b\":[1,2,{\"c\":true}]}" { return 3; }

  // Row 4: decoded string values.
  let rqs = sjson.json_raw_get_str(doc, "quoted");
  if rqs.is_err { return 4; }
  if rqs.value != "aBc" { return 4; }
  let res = sjson.json_raw_get_str(doc, "esc");
  if res.is_err { return 4; }
  if res.value != "a\"b\\c" { return 4; }
  let rem = sjson.json_raw_get_str(doc, "emoji");
  if rem.is_err { return 4; }
  if rem.value.len() != 4 { return 4; }
  if (rem.value.byte_at(0) as Int) != 0xF0 { return 4; }
  if (rem.value.byte_at(1) as Int) != 0x9F { return 4; }
  if (rem.value.byte_at(2) as Int) != 0x98 { return 4; }
  if (rem.value.byte_at(3) as Int) != 0x80 { return 4; }
  let rnotstr = sjson.json_raw_get_str(doc, "proto");
  if rnotstr.is_ok { return 4; }

  // Row 5: malformed value tokens.
  let rb = sjson.json_find_member(doc, "badesc");
  if rb.is_ok { return 5; }
  let ctl_doc = "{\"ctl\": \"a" + "\n" + "b\"}";
  let rc = sjson.json_find_member(ctl_doc, "ctl");
  if rc.is_ok { return 5; }
  let lonely_doc = "{\"lonely\": \"\\uD800\"}";
  let rl = sjson.json_find_member(lonely_doc, "lonely");
  if rl.is_err { return 5; }
  let rls = sjson.json_raw_get_str(lonely_doc, "lonely");
  if rls.is_ok { return 5; }

  // Row 6: flat integer lookups.
  let ri = sjson.json_raw_get_int(doc, "proto");
  if ri.is_err { return 6; }
  if ri.value != 1 { return 6; }
  let rneg = sjson.json_raw_get_int(doc, "neg");
  if rneg.is_err { return 6; }
  if rneg.value != (0 - 7) { return 6; }
  let rmax = sjson.json_raw_get_int(doc, "max_payload");
  if rmax.is_err { return 6; }
  if rmax.value != 1048576 { return 6; }
  let rfrac = sjson.json_raw_get_int(doc, "frac");
  if rfrac.is_ok { return 6; }
  let rexp = sjson.json_raw_get_int(doc, "exp");
  if rexp.is_ok { return 6; }
  let rbig = sjson.json_raw_get_int(doc, "big");
  if rbig.is_ok { return 6; }
  let rintstr = sjson.json_raw_get_int(doc, "quoted");
  if rintstr.is_ok { return 6; }

  // Row 7: not-found / non-object inputs.
  let r7a = sjson.json_find_member(doc, "nope");
  if r7a.is_ok { return 7; }
  let r7b = sjson.json_find_member("", "k");
  if r7b.is_ok { return 7; }
  let r7c = sjson.json_find_member("[1,2]", "k");
  if r7c.is_ok { return 7; }
  let r7d = sjson.json_find_member("null", "k");
  if r7d.is_ok { return 7; }
  let r7e = sjson.json_raw_get("", "k");
  if r7e.is_ok { return 7; }
  let r7f = sjson.json_raw_get_str("", "k");
  if r7f.is_ok { return 7; }
  let r7g = sjson.json_raw_get_int("", "k");
  if r7g.is_ok { return 7; }

  // Row 8: duplicate keys -- first match wins.
  let r8 = sjson.json_raw_get(doc, "dup");
  if r8.is_err { return 8; }
  if r8.value != "1" { return 8; }

  // Row 9: byte-offset errors.
  let r9a = sjson.json_find_member("{\"a\":1}", "zz");
  if r9a.is_err == false { return 9; }
  if string.str_contains(r9a.error, "at byte") == false { return 9; }
  let r9b = sjson.json_find_member("{\"a\": \"x}", "a");
  if r9b.is_err == false { return 9; }
  if string.str_contains(r9b.error, "at byte") == false { return 9; }

  // Row 10: escape-aware key tokens.
  let d10 = "{\"a\\u0042c\": 1}";
  let r10 = sjson.json_find_member(d10, "aBc");
  if r10.is_err { return 10; }
  let r10raw = sjson.json_raw_get(d10, "aBc");
  if r10raw.is_err { return 10; }
  if r10raw.value != "1" { return 10; }
  let d10b = "{\"x\\\"y\": 2}";
  let r10b = sjson.json_find_member(d10b, "x\"y");
  if r10b.is_err { return 10; }
  let r10braw = sjson.json_raw_get(d10b, "x\"y");
  if r10braw.is_err { return 10; }
  if r10braw.value != "2" { return 10; }
  let r10c = sjson.json_find_member(d10, "abc");
  if r10c.is_ok { return 10; }

  // Row 11: typed DOM accessors.
  let as1 = sjson.json_as_str(sjson.json_string("hi"));
  match as1 {
    Some(v) => { if v != "hi" { return 11; } },
    None => { return 11; },
  };
  let as2 = sjson.json_as_str(sjson.json_number(1.0));
  if as2.is_some { return 11; }
  let ab1 = sjson.json_as_bool(sjson.json_bool(true));
  match ab1 {
    Some(v) => { if v == false { return 11; } },
    None => { return 11; },
  };
  let ab2 = sjson.json_as_bool(sjson.json_string("true"));
  if ab2.is_some { return 11; }
  let ai1 = sjson.json_as_int(sjson.json_number(42.0));
  match ai1 {
    Some(v) => { if v != 42 { return 11; } },
    None => { return 11; },
  };
  let ai2 = sjson.json_as_int(sjson.json_number(0 - 7.0));
  match ai2 {
    Some(v) => { if v != (0 - 7) { return 11; } },
    None => { return 11; },
  };
  let ai3 = sjson.json_as_int(sjson.json_number(1.5));
  if ai3.is_some { return 11; }
  let ai4 = sjson.json_as_int(sjson.json_number(9007199254740992.0));
  match ai4 {
    Some(v) => { if v != 9007199254740992 { return 11; } },
    None => { return 11; },
  };
  let ai5 = sjson.json_as_int(sjson.json_number(9007199254740994.0));
  if ai5.is_some { return 11; }
  let ai6 = sjson.json_as_int(sjson.json_string("42"));
  if ai6.is_some { return 11; }
  let af1 = sjson.json_as_float(sjson.json_number(1.5));
  match af1 {
    Some(v) => { if v != 1.5 { return 11; } },
    None => { return 11; },
  };
  let af2 = sjson.json_as_float(sjson.json_bool(true));
  if af2.is_some { return 11; }

  // Row 12: span slice equals json_raw_get.
  let r12 = sjson.json_find_member(doc, "nested");
  if r12.is_err { return 12; }
  let m12 = r12.value;
  let span_slice = _slice(doc, m12.value_start, m12.value_end);
  let raw12 = sjson.json_raw_get(doc, "nested");
  if raw12.is_err { return 12; }
  if span_slice != raw12.value { return 12; }

  // Row 13: whitespace tolerance + empty object.
  let d13 = "  {  \"a\"  :  \"b\"  }  ";
  let r13 = sjson.json_raw_get_str(d13, "a");
  if r13.is_err { return 13; }
  if r13.value != "b" { return 13; }
  let r13b = sjson.json_find_member("{}", "a");
  if r13b.is_ok { return 13; }
  if string.str_contains(r13b.error, "not found") == false { return 13; }
  let r13c = sjson.json_find_member("  {  }  ", "a");
  if r13c.is_ok { return 13; }

  return 0;
}
