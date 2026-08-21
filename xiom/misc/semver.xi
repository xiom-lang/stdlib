// XIOM - Misc: Semantic Versioning
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.misc.semver

// Depends on: xiom.string

// ============================================================================
// SemVer parsing, comparison, constraint matching (caret, tilde, range),
// incrementing and serialization. Follows semver.org 2.0.0.
// ============================================================================

use xiom.string;
use xiom.convert;

/// A semantic version: major, minor, patch, prerelease and build metadata.
/// prerelease and build are the raw dot-separated identifier strings (without
/// the '-' / '+' prefix); empty when absent.
pub type SemVer = { major: Int; minor: Int; patch: Int; prerelease: Str; build: Str; }

/// Parse a semantic version string such as "1.2.3", "1.2.3-alpha.1" or
/// "1.2.3+build.5". An optional leading 'v'/'V' is accepted. Returns None for
/// malformed input (missing parts, non-numeric core, invalid identifiers).
pub fn semver_parse(s: Str) -> Option[SemVer] {
  var text = s;
  if text.len() > 0 && (text.char_at(0) == 'v' || text.char_at(0) == 'V') {
    text = xiom.string.str_slice(text, 1, text.len());
  }
  var core = text;
  var prerelease = "";
  var build = "";
  // NOTE: plain `match` only -- `if x is Some { match x {...} }` double-check
  // binds the payload as 0 (TODO(compiler): BUG 38).
  var plus = xiom.string.str_index_of(text, "+");
  match plus {
    Some(pos) => {
      core = xiom.string.str_slice(text, 0, pos);
      build = xiom.string.str_slice(text, pos + 1, text.len());
    },
    None => {},
  }
  var dash = xiom.string.str_index_of(core, "-");
  match dash {
    Some(pos) => {
      prerelease = xiom.string.str_slice(core, pos + 1, core.len());
      core = xiom.string.str_slice(core, 0, pos);
    },
    None => {},
  }
  var parts = xiom.string.str_split(core, ".");
  if parts.len() != 3 { return None; }
  var maj = parts[0];
  var min = parts[1];
  var pat = parts[2];
  if !is_number(maj) || !is_number(min) || !is_number(pat) {
    return None;
  }
  if !valid_identifiers(prerelease) { return None; }
  if !valid_identifiers(build) { return None; }
  var major_val = 0;
  var minor_val = 0;
  var patch_val = 0;
  var rm = xiom.string.str_to_int(maj);
  match rm {
    Ok(v) => { major_val = v; },
    Err(_) => { return None; },
  }
  var rn = xiom.string.str_to_int(min);
  match rn {
    Ok(v) => { minor_val = v; },
    Err(_) => { return None; },
  }
  var rp = xiom.string.str_to_int(pat);
  match rp {
    Ok(v) => { patch_val = v; },
    Err(_) => { return None; },
  }
  Some(SemVer { major: major_val; minor: minor_val; patch: patch_val; prerelease: prerelease; build: build; })
}

/// Whether every dot-separated identifier is non-empty and made of ASCII
/// alphanumerics and hyphens.
fn valid_identifiers(s: Str) -> Bool {
  if s.len() == 0 { return true; }
  var parts = xiom.string.str_split(s, ".");
  var i = 0;
  while i < parts.len() {
    var part = parts[i];
    if xiom.string.str_len(part) == 0 { return false; }
    var j = 0;
    while j < xiom.string.str_len(part) {
      var v = xiom.string.byte_at(part, j) as Int;
      var ok = (v >= 48 && v <= 57) || (v >= 65 && v <= 90) || (v >= 97 && v <= 122) || v == 45;
      if !ok { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  true
}

/// Whether s is a non-empty string of digits with no leading zeros (unless it
/// is exactly "0").
fn is_number(s: Str) -> Bool {
  var n = xiom.string.str_len(s);
  if n == 0 { return false; }
  if n > 1 && xiom.string.byte_at(s, 0) == 48 { return false; }
  var i = 0;
  while i < n {
    var v = xiom.string.byte_at(s, i) as Int;
    if v < 48 || v > 57 { return false; }
    i = i + 1;
  }
  true
}

/// Compare two SemVer values by precedence: -1, 0, or 1. Build metadata is
/// ignored; a version without prerelease outranks one with a prerelease.
pub fn semver_compare(a: SemVer, b: SemVer) -> Int {
  if a.major < b.major { return -1; }
  if a.major > b.major { return 1; }
  if a.minor < b.minor { return -1; }
  if a.minor > b.minor { return 1; }
  if a.patch < b.patch { return -1; }
  if a.patch > b.patch { return 1; }
  pre_compare(a.prerelease, b.prerelease)
}

/// Compare two prerelease strings per semver rules: numeric identifiers
/// compare numerically, numeric < alphanumeric, alphanumeric compares
/// lexicographically; a shorter list is lower when it is a prefix.
fn pre_compare(a: Str, b: Str) -> Int {
  if a.len() == 0 && b.len() == 0 { return 0; }
  if a.len() == 0 { return 1; }
  if b.len() == 0 { return -1; }
  var pa = xiom.string.str_split(a, ".");
  var pb = xiom.string.str_split(b, ".");
  var i = 0;
  while i < pa.len() && i < pb.len() {
    var ia = pa[i];
    var ib = pb[i];
    var na_is_num = is_number(ia);
    var nb_is_num = is_number(ib);
    if na_is_num && nb_is_num {
      var va = 0;
      var vb = 0;
      var ra = xiom.string.str_to_int(ia);
      match ra {
        Ok(v) => { va = v; },
        Err(_) => {},
      }
      var rb = xiom.string.str_to_int(ib);
      match rb {
        Ok(v) => { vb = v; },
        Err(_) => {},
      }
      if va < vb { return -1; }
      if va > vb { return 1; }
    } elif na_is_num {
      return -1;
    } elif nb_is_num {
      return 1;
    } else {
      var c = lex_cmp(ia, ib);
      if c != 0 { return c; }
    }
    i = i + 1;
  }
  if pa.len() < pb.len() { return -1; }
  if pa.len() > pb.len() { return 1; }
  0
}

/// Plain lexicographic comparison of two strings by code point.
fn lex_cmp(a: Str, b: Str) -> Int {
  var n = a.len();
  if b.len() < n { n = b.len(); }
  var i = 0;
  while i < n {
    var ca = a.char_at(i);
    var cb = b.char_at(i);
    if (ca as Int) < (cb as Int) { return -1; }
    if (ca as Int) > (cb as Int) { return 1; }
    i = i + 1;
  }
  if a.len() < b.len() { return -1; }
  if a.len() > b.len() { return 1; }
  0
}

/// Whether s is a valid semantic version string. O(n).
pub fn semver_valid(s: Str) -> Bool {
  var parsed = semver_parse(s);
  match parsed {
    Some(_) => { return true; },
    None => {},
  }
  false
}

/// Whether a version string satisfies a constraint string. Supports operator
/// prefixes (>=, <=, >, <, =), caret (^), tilde (~), bare versions, partial
/// versions ("1.2", "1", "1.2.x") and space-separated AND groups.
pub fn semver_matches(version: Str, constraint: Str) -> Bool {
  var parsed = semver_parse(version);
  match parsed {
    None => { return false; },
    Some(v) => {
      var groups = xiom.string.str_split(constraint, " ");
      var i = 0;
      while i < groups.len() {
        var g = groups[i];
        if xiom.string.str_len(g) == 0 {
          i = i + 1;
        } else {
          var ok = single_constraint_matches(v, g);
          if !ok { return false; }
          i = i + 1;
        }
      }
      return true;
    },
  }
}

/// Match one constraint group against a parsed version.
fn single_constraint_matches(v: SemVer, c: Str) -> Bool {
  var first = c.char_at(0);
  if first == '>' || first == '<' || first == '=' {
    var op = c;
    var target = c;
    if c.len() >= 2 && c.char_at(1) == '=' {
      op = xiom.string.str_slice(c, 0, 2);
      target = xiom.string.str_slice(c, 2, c.len());
    } else {
      op = xiom.string.str_slice(c, 0, 1);
      target = xiom.string.str_slice(c, 1, c.len());
    }
    var tv = semver_parse(target);
    var tok = false;
    match tv {
      Some(_) => { tok = true; },
      None => {},
    }
    if !tok {
      var tvp = semver_parse_partial(target);
      match tvp {
        Some(_) => { tok = true; },
        None => {},
      }
      return partial_op_matches(v, op, target);
    }
    match tv {
      Some(tvv) => {
        var cmp = semver_compare(v, tvv);
        if op == ">" { return cmp > 0; }
        if op == ">=" { return cmp >= 0; }
        if op == "<" { return cmp < 0; }
        if op == "<=" { return cmp <= 0; }
        return cmp == 0;
      },
      None => { return false; },
    }
  }
  if first == '^' {
    return caret_matches(v, xiom.string.str_slice(c, 1, c.len()));
  }
  if first == '~' {
    return tilde_matches(v, xiom.string.str_slice(c, 1, c.len()));
  }
  bare_matches(v, c)
}

/// Compare against an operator with a partial target like "1.2" or "1".
fn partial_op_matches(v: SemVer, op: Str, target: Str) -> Bool {
  var parts = xiom.string.str_split(target, ".");
  var t_major = 0;
  var t_minor = 0;
  var t_patch = 0;
  var has_minor = false;
  var has_patch = false;
  if parts.len() >= 1 {
    var r = xiom.string.str_to_int(parts[0]);
    match r {
      Ok(val) => { t_major = val; },
      Err(_) => { return false; },
    }
  }
  if parts.len() >= 2 {
    var r = xiom.string.str_to_int(parts[1]);
    match r {
      Ok(val) => { t_minor = val; has_minor = true; },
      Err(_) => {},
    }
  }
  if parts.len() >= 3 {
    var r = xiom.string.str_to_int(parts[2]);
    match r {
      Ok(val) => { t_patch = val; has_patch = true; },
      Err(_) => {},
    }
  }
  var cmp = 0;
  if v.major < t_major { cmp = -1; }
  elif v.major > t_major { cmp = 1; }
  elif has_minor && v.minor < t_minor { cmp = -1; }
  elif has_minor && v.minor > t_minor { cmp = 1; }
  elif has_patch && v.patch < t_patch { cmp = -1; }
  elif has_patch && v.patch > t_patch { cmp = 1; }
  if op == ">" { return cmp > 0; }
  if op == ">=" { return cmp >= 0; }
  if op == "<" { return cmp < 0; }
  if op == "<=" { return cmp <= 0; }
  cmp == 0
}

/// Caret matching: ^major.minor.patch keeps the leftmost non-zero component
/// fixed. ^1.2.3 -> >=1.2.3 <2.0.0; ^0.2.3 -> >=0.2.3 <0.3.0;
/// ^0.0.3 -> >=0.0.3 <0.0.4.
fn caret_matches(v: SemVer, target: Str) -> Bool {
  var parts = xiom.string.str_split(target, ".");
  var maj = 0;
  var min = 0;
  var pat = 0;
  var r = xiom.string.str_to_int(parts[0]);
  match r {
    Ok(val) => { maj = val; },
    Err(_) => { return false; },
  }
  if parts.len() >= 2 {
    var r2 = xiom.string.str_to_int(parts[1]);
    match r2 {
      Ok(val) => { min = val; },
      Err(_) => {},
    }
  }
  if parts.len() >= 3 {
    var r3 = xiom.string.str_to_int(parts[2]);
    match r3 {
      Ok(val) => { pat = val; },
      Err(_) => {},
    }
  }
  if v.major != maj { return false; }
  if maj > 0 {
    if v.minor > min { return true; }
    if v.minor == min && v.patch >= pat { return true; }
    return false;
  }
  if v.minor != min { return false; }
  if min > 0 {
    return v.patch >= pat;
  }
  v.patch == pat
}

/// Tilde matching: ~1.2.3 -> >=1.2.3 <1.3.0; ~1.2 -> >=1.2.0 <1.3.0;
/// ~1 -> >=1.0.0 <2.0.0.
fn tilde_matches(v: SemVer, target: Str) -> Bool {
  var parts = xiom.string.str_split(target, ".");
  var maj = 0;
  var min = 0;
  var pat = 0;
  var r = xiom.string.str_to_int(parts[0]);
  match r {
    Ok(val) => { maj = val; },
    Err(_) => { return false; },
  }
  if parts.len() >= 2 {
    var r2 = xiom.string.str_to_int(parts[1]);
    match r2 {
      Ok(val) => { min = val; },
      Err(_) => {},
    }
  }
  if parts.len() >= 3 {
    var r3 = xiom.string.str_to_int(parts[2]);
    match r3 {
      Ok(val) => { pat = val; },
      Err(_) => {},
    }
  }
  if parts.len() == 1 {
    if v.major < maj { return false; }
    if v.major > maj { return false; }
    return true;
  }
  if v.major != maj { return false; }
  if v.minor < min { return false; }
  if v.minor > min { return false; }
  if parts.len() >= 3 {
    return v.patch >= pat;
  }
  true
}

/// Bare (exact or partial) matching: "1.2.3" exact; "1.2" any patch;
/// "1" any minor/patch; "1.2.x" wildcard patch.
fn bare_matches(v: SemVer, target: Str) -> Bool {
  var parts = xiom.string.str_split(target, ".");
  if parts.len() == 0 { return false; }
  var p0 = parts[0];
  if str_eq(p0, "x") || str_eq(p0, "X") || str_eq(p0, "*") { return true; }
  var maj = 0;
  var r = xiom.string.str_to_int(p0);
  match r {
    Ok(val) => { maj = val; },
    Err(_) => { return false; },
  }
  if v.major != maj { return false; }
  if parts.len() == 1 { return true; }
  var p1 = parts[1];
  if str_eq(p1, "x") || str_eq(p1, "X") || str_eq(p1, "*") { return true; }
  var min = 0;
  var r2 = xiom.string.str_to_int(p1);
  match r2 {
    Ok(val) => { min = val; },
    Err(_) => { return false; },
  }
  if v.minor != min { return false; }
  if parts.len() == 2 { return true; }
  var p2 = parts[2];
  if str_eq(p2, "x") || str_eq(p2, "X") || str_eq(p2, "*") { return true; }
  var pat = 0;
  var r3 = xiom.string.str_to_int(p2);
  match r3 {
    Ok(val) => { pat = val; },
    Err(_) => { return false; },
  }
  v.patch == pat
}

/// Byte-wise string equality, safe for strings that came from Vec[Str]
/// elements (BUG 17: `==` on element-loaded values lowers to pointer compare).
fn str_eq(a: Str, b: Str) -> Bool {
  var al = xiom.string.str_len(a);
  var bl = xiom.string.str_len(b);
  if al != bl { return false; }
  var i = 0;
  while i < al {
    if xiom.string.byte_at(a, i) != xiom.string.byte_at(b, i) { return false; }
    i = i + 1;
  }
  true
}

/// Parse a possibly partial version string; used for operator targets.
fn semver_parse_partial(s: Str) -> Option[SemVer] {
  var core = s;
  var prerelease = "";
  var build = "";
  // NOTE: plain `match` only -- TODO(compiler): BUG 38 (is-Some + match
  // double-check binds payload as 0).
  var dash = xiom.string.str_index_of(core, "-");
  match dash {
    Some(pos) => {
      prerelease = xiom.string.str_slice(core, pos + 1, core.len());
      core = xiom.string.str_slice(core, 0, pos);
    },
    None => {},
  }
  var plus = xiom.string.str_index_of(core, "+");
  match plus {
    Some(pos) => {
      build = xiom.string.str_slice(core, pos + 1, core.len());
      core = xiom.string.str_slice(core, 0, pos);
    },
    None => {},
  }
  var parts = xiom.string.str_split(core, ".");
  if parts.len() == 0 || parts.len() > 3 { return None; }
  var maj = 0;
  var min = 0;
  var pat = 0;
  if parts[0] == "x" || parts[0] == "X" || parts[0] == "*" {
    maj = 0;
  } else {
    var r = xiom.string.str_to_int(parts[0]);
    match r {
      Ok(val) => { maj = val; },
      Err(_) => { return None; },
    }
  }
  Some(SemVer { major: maj; minor: min; patch: pat; prerelease: prerelease; build: build; })
}

/// Whether a version falls inside a hyphen ("a - b") or comma-separated
/// range. Comma-separated parts are alternatives (OR); a hyphen range is
/// inclusive on both ends. A bare range delegates to semver_matches.
pub fn semver_satisfies(version: Str, range: Str) -> Bool {
  var parsed_v = semver_parse(version);
  match parsed_v {
    None => { return false; },
    Some(v) => {
      var hyphen = xiom.string.str_index_of(range, " - ");
      var lo = "";
      var hi = "";
      match hyphen {
        Some(pos) => {
          lo = xiom.string.str_slice(range, 0, pos);
          hi = xiom.string.str_slice(range, pos + 3, range.len());
        },
        None => {},
      }
      var vl = semver_parse(lo);
      var vh = semver_parse(hi);
      var lok = false;
      var hok = false;
      match vl {
        Some(_) => { lok = true; },
        None => {},
      }
      match vh {
        Some(_) => { hok = true; },
        None => {},
      }
      if !lok || !hok { return false; }
      match vl {
        Some(lv) => {
          match vh {
            Some(hv) => {
              var c1 = semver_compare(v, lv);
              var c2 = semver_compare(v, hv);
              return c1 >= 0 && c2 <= 0;
            },
            None => { return false; },
          }
        },
        None => { return false; },
      }
      var alts = xiom.string.str_split(range, ",");
      var i = 0;
      while i < alts.len() {
        var alt = alts[i];
        if xiom.string.str_len(alt) > 0 {
          if semver_matches(version, alt) {
            return true;
          }
        }
        i = i + 1;
      }
      return false;
    },
  }
}

/// Bump a version part ("major", "minor", "patch", "prerelease", "build").
/// Returns the new version string, or None if s is not a valid version.
/// prerelease bumps the trailing numeric identifier (appending ".0" when the
/// prerelease is not numeric); build does the same for build metadata.
pub fn semver_inc(s: Str, part: Str) -> Option[Str] {
  var parsed = semver_parse(s);
  match parsed {
    None => { return None; },
    Some(vv) => {
      if part == "major" {
        vv.major = vv.major + 1;
        vv.minor = 0;
        vv.patch = 0;
        vv.prerelease = "";
        vv.build = "";
      } elif part == "minor" {
        vv.minor = vv.minor + 1;
        vv.patch = 0;
        vv.prerelease = "";
        vv.build = "";
      } elif part == "patch" {
        vv.patch = vv.patch + 1;
        vv.prerelease = "";
        vv.build = "";
      } elif part == "prerelease" {
        if xiom.string.str_len(vv.prerelease) == 0 {
          vv.prerelease = "0";
        } else {
          vv.prerelease = bump_last_identifier(vv.prerelease);
        }
        vv.build = "";
      } elif part == "build" {
        if xiom.string.str_len(vv.build) == 0 {
          vv.build = "0";
        } else {
          vv.build = bump_last_identifier(vv.build);
        }
      } else {
        return None;
      }
      return Some(semver_to_string(vv));
    },
  }
}

/// Serialize a SemVer back to text. O(n).
pub fn semver_to_string(v: SemVer) -> Str {
  var s = xiom.string.str_concat(convert.int_to_string(v.major), ".");
  s = xiom.string.str_concat(s, convert.int_to_string(v.minor));
  s = xiom.string.str_concat(s, ".");
  s = xiom.string.str_concat(s, convert.int_to_string(v.patch));
  if v.prerelease.len() > 0 {
    s = xiom.string.str_concat(s, "-");
    s = xiom.string.str_concat(s, v.prerelease);
  }
  if v.build.len() > 0 {
    s = xiom.string.str_concat(s, "+");
    s = xiom.string.str_concat(s, v.build);
  }
  s
}

/// The prerelease identifier, if any.
pub fn semver_prerelease(v: SemVer) -> Option[Str] {
  if v.prerelease.len() == 0 {
    None
  } else {
    Some(v.prerelease)
  }
}

/// The build metadata, if any.
pub fn semver_build(v: SemVer) -> Option[Str] {
  if v.build.len() == 0 {
    None
  } else {
    Some(v.build)
  }
}

/// Caret compatibility: whether b falls in the caret range anchored at a.
pub fn semver_caret(a: SemVer, b: SemVer) -> Bool {
  if a.major > 0 {
    if b.major != a.major { return false; }
    if b.minor > a.minor { return true; }
    if b.minor == a.minor && b.patch >= a.patch { return true; }
    return false;
  }
  if a.minor > 0 {
    if b.major != 0 || b.minor != a.minor { return false; }
    return b.patch >= a.patch;
  }
  b.major == 0 && b.minor == 0 && b.patch == a.patch
}

/// Tilde compatibility: whether b falls in the tilde range anchored at a.
pub fn semver_tilde(a: SemVer, b: SemVer) -> Bool {
  if b.major != a.major { return false; }
  if b.minor != a.minor { return false; }
  b.patch >= a.patch
}

/// Strict greater-than comparison of two SemVer values.
pub fn semver_gt(a: SemVer, b: SemVer) -> Bool {
  semver_compare(a, b) > 0
}

/// Strict less-than comparison of two SemVer values.
pub fn semver_lt(a: SemVer, b: SemVer) -> Bool {
  semver_compare(a, b) < 0
}

/// Bump the trailing numeric identifier of a dot-separated list, appending
/// ".0" when the tail is not numeric. Internal helper.
fn bump_last_identifier(s: Str) -> Str {
  var parts = xiom.string.str_split(s, ".");
  var last = parts[parts.len() - 1];
  if is_number(last) {
    var n = 0;
    var r = xiom.string.str_to_int(last);
    match r {
      Ok(val) => { n = val; },
      Err(_) => {},
    }
    parts[parts.len() - 1] = convert.int_to_string(n + 1);
  } else {
    var app = xiom.string.str_concat(last, ".0");
    parts[parts.len() - 1] = app;
  }
  var out = parts[0];
  var i = 1;
  while i < parts.len() {
    out = xiom.string.str_concat(out, ".");
    out = xiom.string.str_concat(out, parts[i]);
    i = i + 1;
  }
  out
}
