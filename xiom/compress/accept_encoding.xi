// XIOM - Compression: Accept-Encoding negotiation (RFC 9110 12.5.3)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress.accept_encoding

// ============================================================================
// Pure Accept-Encoding negotiation, shared by the http/static consumers that
// must pick a Content-Encoding. Parses the field (case-insensitive tokens,
// q-values with up to three fraction digits, `x-gzip` alias for gzip,
// wildcard `*`, q=0 exclusion, extra parameters ignored, empty/malformed
// entries tolerated) and selects against a supported set:
//
//   accept_encoding_q(header, enc)      -> effective q (per-mille, 0..1000);
//                                          -1 when unmentioned (no entry and
//                                          no wildcard).
//   accept_encoding_choose(header, set) -> the accepted supported entry with
//                                          the highest q (ties: earlier header
//                                          entry, then `set` order), falling
//                                          back to "identity" when no coding
//                                          is acceptable, "" when nothing is.
//
// An empty/absent field yields "identity" (no compression unless asked).
// Identity is the fallback: it is acceptable unless excluded via
// `identity;q=0` or a wildcard q=0 without a more specific entry, and it
// only outranks a coding when the client explicitly ranks it higher
// (e.g. `gzip;q=0.3, identity;q=0.5`).
// ============================================================================

/// One parsed `coding;q=...` entry (name lowercased, aliases NOT folded yet).
type AeEntry = {
  name: Str;
  q: Int;
}

fn _ae_fold(b: UInt8) -> UInt8 {
  if b >= 65 && b <= 90 {
    return (b + 32) as UInt8;
  };
  return b;
}

fn _ae_lower(s: Str) -> Str {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(_ae_fold(s.byte_at(i)));
    i = i + 1;
  };
  return Str::from_utf8(v);
}

fn _ae_slice(s: Str, a: Int, b: Int) -> Str {
  var v = Vec[UInt8].new();
  var i = a;
  while i < b {
    v.push(s.byte_at(i));
    i = i + 1;
  };
  return Str::from_utf8(v);
}

fn _ae_find_eq(s: Str) -> Int {
  var i = 0;
  while i < s.len() {
    if s.byte_at(i) == 61 {
      return i;
    };
    i = i + 1;
  };
  return -1;
}

// Parse a qvalue string ("0", "1", "0.5", "1.000", ...) into per-mille.
// Malformed input returns -1 (callers treat that as the q=1.0 default);
// values above 1 are tolerated and clamp to 1000.
fn _ae_q_parse(s: Str) -> Int {
  let t = xiom.string.str_trim(s);
  let n = t.len();
  if n == 0 {
    return -1;
  };
  let b0 = t.byte_at(0);
  if b0 == 48 {
    if n == 1 {
      return 0;
    };
    if t.byte_at(1) != 46 {
      return -1;
    };
    var v = 0;
    var k = 2;
    var digits = 0;
    while k < n && digits < 3 {
      let d = t.byte_at(k);
      if d < 48 || d > 57 {
        return -1;
      };
      v = v * 10 + ((d - 48) as Int);
      k = k + 1;
      digits = digits + 1;
    };
    while k < n {
      let d2 = t.byte_at(k);
      if d2 < 48 || d2 > 57 {
        return -1;
      };
      k = k + 1;
    };
    while digits < 3 {
      v = v * 10;
      digits = digits + 1;
    };
    return v;
  };
  if b0 == 49 {
    if n == 1 {
      return 1000;
    };
    if t.byte_at(1) != 46 {
      return -1;
    };
    var k2 = 2;
    while k2 < n {
      let d3 = t.byte_at(k2);
      if d3 < 48 || d3 > 57 {
        return -1;
      };
      k2 = k2 + 1;
    };
    return 1000;
  };
  return -1;
}

fn _ae_norm(n: Str) -> Str {
  if n == "x-gzip" {
    return "gzip";
  };
  return n;
}

fn _ae_parse(header: Str) -> Vec[AeEntry] {
  var out = Vec[AeEntry].new();
  let parts = xiom.string.str_split(header, ",");
  var i = 0;
  while i < parts.len() {
    let raw = xiom.string.str_trim(parts[i]);
    if raw.len() > 0 {
      let segs = xiom.string.str_split(raw, ";");
      let name = _ae_norm(_ae_lower(xiom.string.str_trim(segs[0])));
      if name.len() > 0 {
        var q = 1000;
        var s = 1;
        while s < segs.len() {
          let seg = xiom.string.str_trim(segs[s]);
          let eq = _ae_find_eq(seg);
          if eq > 0 {
            let pname = _ae_lower(xiom.string.str_trim(_ae_slice(seg, 0, eq)));
            if pname == "q" {
              let qv = _ae_q_parse(_ae_slice(seg, eq + 1, seg.len()));
              if qv >= 0 {
                q = qv;
              };
            };
          };
          s = s + 1;
        };
        out.push(AeEntry{ name: name; q: q; });
      };
    };
    i = i + 1;
  };
  return out;
}

fn _ae_q_of(entries: &Vec[AeEntry], enc: Str) -> Int {
  var q = -1;
  var i = 0;
  while i < entries.len() {
    if entries[i].name == enc {
      if entries[i].q > q {
        q = entries[i].q;
      };
    };
    i = i + 1;
  };
  return q;
}

fn _ae_pos_of(entries: &Vec[AeEntry], enc: Str) -> Int {
  var i = 0;
  while i < entries.len() {
    if entries[i].name == enc {
      return i;
    };
    i = i + 1;
  };
  return -1;
}

/// Effective q-value of `encoding` in `header`, in per-mille (0..1000).
/// Returns -1 when the field neither names the coding nor carries a `*`
/// wildcard. `x-gzip` counts as `gzip`; matching is case-insensitive. O(|h|).
pub fn accept_encoding_q(header: Str, encoding: Str) -> Int
  ensures: result >= -1
  ensures: result <= 1000
{
  var entries = _ae_parse(header);
  var enc = _ae_norm(_ae_lower(xiom.string.str_trim(encoding)));
  var q = _ae_q_of(&entries, enc);
  if q == -1 {
    q = _ae_q_of(&entries, "*");
  };
  return q;
}

/// Choose a content coding against `supported`: highest q wins; ties prefer
/// a non-identity coding, then the earlier header entry, then the earlier
/// entry in `supported`. Returns the supported entry itself, "identity" when
/// that is the only acceptable option (including the empty header), or ""
/// when nothing is acceptable. O(|header| * |supported|).
pub fn accept_encoding_choose(header: Str, supported: &Vec[Str]) -> Str
  ensures: result.len() >= 0
{
  var entries = _ae_parse(header);
  if entries.len() == 0 {
    return "identity";
  };
  var idq = _ae_q_of(&entries, "identity");
  var wq = _ae_q_of(&entries, "*");
  var identity_ok = false;
  if idq >= 0 {
    identity_ok = idq > 0;
  } elif wq >= 0 {
    identity_ok = wq > 0;
  } else {
    identity_ok = true;
  };
  var best = "";
  var best_q = 0;
  var best_pos = 2147483647;
  var wpos = _ae_pos_of(&entries, "*");
  var i = 0;
  while i < supported.len() {
    var name = _ae_norm(_ae_lower(xiom.string.str_trim(supported[i])));
    if name != "identity" {
      var q = _ae_q_of(&entries, name);
      var pos = _ae_pos_of(&entries, name);
      if q == -1 {
        q = wq;
        pos = wpos;
      };
      if q > 0 {
        var better = false;
        if q > best_q {
          better = true;
        } elif q == best_q && pos < best_pos {
          better = true;
        };
        if better {
          best = supported[i];
          best_q = q;
          best_pos = pos;
        };
      };
    };
    i = i + 1;
  };
  if best_q > 0 && best.len() > 0 {
    if idq >= 0 && idq > best_q {
      return "identity";
    };
    return best;
  };
  if identity_ok {
    return "identity";
  };
  return "";
}
