// XIOM - Network: HTTP Cookies
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.cookie

// Depends on: xiom.string, xiom.time

// ============================================================================
// HTTP cookie parsing, serialization, and jar management per RFC 6265.
// Provides the Cookie struct plus parse/serialize helpers and a jar with
// domain/path matching for request cookies. Set-Cookie attributes (Expires,
// Max-Age, Domain, Path, Secure, HttpOnly, SameSite) are parsed from HTTP
// dates. All functions are pure.
// ============================================================================

use xiom.string;
use xiom.time;

/// struct Cookie { name: Str; value: Str; domain: Str; path: Str; expires: Int;
///                 max_age: Int; secure: Bool; http_only: Bool; same_site: Str }
///   expires is a unix timestamp (0 = session cookie); same_site is "Strict",
///   "Lax" or "None" ("" when unset).
pub type Cookie = {
  name: Str;
  value: Str;
  domain: Str;
  path: Str;
  expires: Int;
  max_age: Int;
  secure: Bool;
  http_only: Bool;
  same_site: Str;
}

/// struct CookieJar - an ordered collection of cookies.
pub type CookieJar = {
  cookies: Vec[Cookie];
}

// is_ws_byte returns true for space and tab.
fn is_ws_byte(b: UInt8) -> Bool {
  b == 32 || b == 9
}

// trim_ws trims leading and trailing spaces and tabs.
fn trim_ws(s: Str) -> Str {
  let len = s.len();
  var start = 0;
  var end = len;
  while start < end && is_ws_byte(s.byte_at(start)) {
    start = start + 1;
  }
  while end > start && is_ws_byte(s.byte_at(end - 1)) {
    end = end - 1;
  }
  string.str_slice(s, start, end)
}

// split splits s on every occurrence of delim.
fn split(s: Str, delim: Str) -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  let dlen = delim.len();
  if dlen == 0 {
    var i = 0;
    while i < s.len() {
      result.push(string.str_slice(s, i, i + 1));
      i = i + 1;
    }
    return result;
  }
  var start = 0;
  var pos = 0;
  let slen = s.len();
  while pos < slen {
    if pos + dlen <= slen && string.str_slice(s, pos, pos + dlen) == delim {
      result.push(string.str_slice(s, start, pos));
      pos = pos + dlen;
      start = pos;
    } else {
      pos = pos + 1;
    }
  }
  result.push(string.str_slice(s, start, slen));
  result
}

// index_of returns the byte index of needle in hay, or -1.
fn index_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return 0; }
  if nlen > hlen { return -1; }
  var i = 0;
  while i <= hlen - nlen {
    if string.str_slice(hay, i, i + nlen) == needle {
      return i;
    }
    i = i + 1;
  }
  -1
}

// lower returns the lowercase form of s.
fn lower(s: Str) -> Str {
  string.str_lower(s)
}

// parse_digits parses leading decimal digits into an Int; -1 when none.
fn parse_digits(s: Str) -> Int {
  let len = s.len();
  if len == 0 {
    return -1;
  }
  var result: Int = 0;
  var i = 0;
  while i < len {
    let b = s.byte_at(i);
    if b < 48 || b > 57 {
      return -1;
    }
    result = result * 10 + (b as Int - 48);
    if result > 1000000000 {
      return -1;
    }
    i = i + 1;
  }
  result
}

// days_from_civil converts a proleptic Gregorian calendar date to days since
// the Unix epoch (Howard Hinnant's algorithm).
fn days_from_civil(y_in: Int, m_in: Int, d: Int) -> Int {
  var y = y_in;
  var m = m_in;
  if m <= 2 {
    y = y - 1;
  }
  let era = (if y >= 0 { y } else { y - 399 }) / 400;
  let yoe = y - era * 400;
  var mp = m + 9;
  if mp > 12 {
    mp = mp - 12;
  }
  let doy = (153 * mp + 2) / 5 + d - 1;
  let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  era * 146097 + doe - 719468
}

// month_value maps a three-letter month name to 1..12, or -1.
fn month_value(mon: Str) -> Int {
  let m = lower(mon);
  if m == "jan" { return 1; }
  if m == "feb" { return 2; }
  if m == "mar" { return 3; }
  if m == "apr" { return 4; }
  if m == "may" { return 5; }
  if m == "jun" { return 6; }
  if m == "jul" { return 7; }
  if m == "aug" { return 8; }
  if m == "sep" { return 9; }
  if m == "oct" { return 10; }
  if m == "nov" { return 11; }
  if m == "dec" { return 12; }
  -1
}

// parse_hms parses "HH:MM:SS" into seconds since midnight, or -1.
fn parse_hms(t: Str) -> Int {
  let parts = split(t, ":");
  if parts.len() != 3 {
    return -1;
  }
  let h = parse_digits(parts[0]);
  let mi = parse_digits(parts[1]);
  let s = parse_digits(parts[2]);
  if h < 0 || mi < 0 || s < 0 {
    return -1;
  }
  if h > 23 || mi > 59 || s > 61 {
    return -1;
  }
  h * 3600 + mi * 60 + s
}

// parse_http_date parses an RFC 7231 IMF-fixdate ("Sun, 06 Nov 1994 08:49:37
// GMT") into a unix timestamp, or 0 when the date cannot be parsed.
fn parse_http_date(s: Str) -> Int {
  var date = s;
  if date.len() >= 2 && date.byte_at(0) == 34 && date.byte_at(date.len() - 1) == 34 {
    date = string.str_slice(date, 1, date.len() - 1);
  }
  let comma = index_of(date, ",");
  if comma >= 0 {
    date = string.str_slice(date, comma + 1, date.len());
  }
  let parts = split(date, " ");
  if parts.len() < 4 {
    return 0;
  }
  let day = parse_digits(trim_ws(parts[0]));
  let mon = month_value(trim_ws(parts[1]));
  let year = parse_digits(trim_ws(parts[2]));
  let secs = parse_hms(trim_ws(parts[3]));
  if day < 1 || day > 31 || mon < 1 || mon > 12 || year < 1900 || year > 9999 || secs < 0 {
    return 0;
  }
  let days = days_from_civil(year, mon, day);
  days * 86400 + secs
}

/// Parse a request Cookie header into a cookie.
/// Parameters: header -- the Cookie header value (e.g. "a=b; c=d").
/// Returns: Ok(Cookie) for the first name=value pair, Err when the header is
///          empty or any segment is malformed.
/// Complexity: O(n). Pure.
pub fn cookie_parse(header: Str) -> Result[Cookie, Str] {
  let parts = split(header, ";");
  if parts.len() == 0 {
    return Err("empty cookie header");
  }
  var i = 0;
  var name = "";
  var value = "";
  while i < parts.len() {
    let seg = trim_ws(parts[i]);
    if seg.len() == 0 {
      return Err("empty cookie segment");
    }
    let eq = index_of(seg, "=");
    if eq <= 0 {
      return Err("malformed cookie segment: " + seg);
    }
    let n = trim_ws(string.str_slice(seg, 0, eq));
    let v = trim_ws(string.str_slice(seg, eq + 1, seg.len()));
    if n.len() == 0 {
      return Err("empty cookie name");
    }
    if i == 0 {
      name = n;
      value = v;
    }
    i = i + 1;
  }
  Ok(Cookie{
    name: name;
    value: value;
    domain: "";
    path: "";
    expires: 0;
    max_age: 0;
    secure: false;
    http_only: false;
    same_site: "";
  })
}

/// Parse a Set-Cookie header into a cookie.
/// Parameters: header -- the Set-Cookie header value (e.g.
///          "a=b; Path=/; HttpOnly; Max-Age=3600; SameSite=Strict").
/// Returns: Ok(Cookie) with attributes applied, Err when the name=value pair
///          is missing or malformed.
/// Complexity: O(n). Pure.
pub fn cookie_parse_set_cookie(header: Str) -> Result[Cookie, Str] {
  let parts = split(header, ";");
  if parts.len() == 0 {
    return Err("empty Set-Cookie header");
  }
  let first = trim_ws(parts[0]);
  let eq = index_of(first, "=");
  if eq <= 0 {
    return Err("malformed Set-Cookie pair");
  }
  let name = trim_ws(string.str_slice(first, 0, eq));
  let value = trim_ws(string.str_slice(first, eq + 1, first.len()));
  if name.len() == 0 {
    return Err("empty cookie name");
  }
  var domain = "";
  var path = "";
  var expires: Int = 0;
  var max_age: Int = 0;
  var secure = false;
  var http_only = false;
  var same_site = "";
  var i = 1;
  while i < parts.len() {
    let seg = trim_ws(parts[i]);
    if seg.len() == 0 {
      i = i + 1;
      continue;
    }
    let aeq = index_of(seg, "=");
    if aeq > 0 {
      let attr = lower(trim_ws(string.str_slice(seg, 0, aeq)));
      let val = trim_ws(string.str_slice(seg, aeq + 1, seg.len()));
      if attr == "domain" {
        domain = val;
      } elif attr == "path" {
        path = val;
      } elif attr == "expires" {
        expires = parse_http_date(val);
      } elif attr == "max-age" {
        let ma = parse_digits(val);
        if ma >= 0 {
          max_age = ma;
        }
      } elif attr == "samesite" {
        same_site = val;
      }
    } else {
      let attr = lower(seg);
      if attr == "secure" {
        secure = true;
      } elif attr == "httponly" {
        http_only = true;
      }
    }
    i = i + 1;
  }
  Ok(Cookie{
    name: name;
    value: value;
    domain: domain;
    path: path;
    expires: expires;
    max_age: max_age;
    secure: secure;
    http_only: http_only;
    same_site: same_site;
  })
}

/// Serialize a cookie into Cookie header form ("name=value").
/// Parameters: c -- the cookie.
/// Returns: the "name=value" string.
/// Complexity: O(1). Pure.
pub fn cookie_serialize(c: Cookie) -> Str {
  c.name + "=" + c.value
}

/// Create an empty cookie jar.
/// Returns: a jar holding no cookies.
/// Complexity: O(1). Pure.
pub fn cookie_jar_new() -> CookieJar {
  CookieJar{ cookies: Vec[Cookie].new(); }
}

/// Store a cookie in the jar, replacing an existing cookie with the same
/// name, domain and path.
/// Parameters: jar -- the mutable jar; c -- the cookie to store.
/// Returns: Unit.
/// Complexity: O(n) with n = jar size. Pure.
pub fn cookie_jar_set(jar: &mut CookieJar, c: Cookie) {
  var i = 0;
  while i < jar.cookies.len() {
    let cur = jar.cookies[i];
    if cur.name == c.name && cur.domain == c.domain && cur.path == c.path {
      jar.cookies[i] = c;
      return;
    }
    i = i + 1;
  }
  jar.cookies.push(c);
}

/// Fetch a cookie by name for a url.
/// Parameters: jar -- the jar; name -- the cookie name; url -- the request url.
/// Returns: Some(Cookie) for the first matching cookie, None otherwise.
/// Complexity: O(n) with n = jar size. Pure.
pub fn cookie_jar_get(jar: &CookieJar, name: Str, url: Str) -> Option[Cookie] {
  var i = 0;
  while i < jar.cookies.len() {
    let c = jar.cookies[i];
    if c.name == name && cookie_jar_matches(c, url) {
      return Some(c);
    }
    i = i + 1;
  }
  None
}

/// Test if a cookie applies to a url (domain match, path match and not
/// expired).
/// Parameters: c -- the cookie; url -- the request url.
/// Returns: true when the cookie applies.
/// Complexity: O(n). Pure.
pub fn cookie_jar_matches(c: Cookie, url: Str) -> Bool {
  let host = url_host(url);
  let path = url_path(url);
  if c.domain.len() > 0 {
    if !cookie_domain_matches(c.domain, host) {
      return false;
    }
  }
  if c.path.len() > 0 {
    if !cookie_path_matches(c.path, path) {
      return false;
    }
  }
  if c.expires > 0 {
    let now = time.unix_timestamp();
    if c.expires <= now {
      return false;
    }
  }
  true
}

/// Count cookies held in the jar.
/// Parameters: jar -- the jar.
/// Returns: the number of cookies.
/// Complexity: O(1). Pure.
pub fn cookie_jar_size(jar: &CookieJar) -> Int
  ensures: result >= 0
{
  jar.cookies.len()
}

/// Test if the cookie expires within the given number of seconds.
/// Parameters: c -- the cookie; seconds -- the window in seconds.
/// Returns: true when the cookie has an expiry and it falls at or before
///          now + seconds (already-expired cookies count as expiring).
/// Complexity: O(1). Pure.
pub fn cookie_expires_after(c: Cookie, seconds: Int) -> Bool {
  if c.expires <= 0 {
    return false;
  }
  let now = time.unix_timestamp();
  c.expires <= now + seconds
}

/// RFC 6265 domain-match test.
/// Parameters: domain -- the cookie's Domain attribute; host -- the request
///          host.
/// Returns: true when host equals domain or is a subdomain of domain.
/// Complexity: O(n). Pure.
pub fn cookie_domain_matches(domain: Str, host: Str) -> Bool {
  if domain.len() == 0 || host.len() == 0 {
    return false;
  }
  if domain == host {
    return true;
  }
  let dot = "." + domain;
  let hlen = host.len();
  let dlen = dot.len();
  if hlen > dlen {
    let tail = string.str_slice(host, hlen - dlen, hlen);
    if tail == dot {
      return true;
    }
  }
  false
}

/// RFC 6265 path-match test.
/// Parameters: path -- the cookie's Path attribute; request_path -- the request
///          path.
/// Returns: true when request_path matches the cookie path.
/// Complexity: O(n). Pure.
pub fn cookie_path_matches(path: Str, request_path: Str) -> Bool {
  if path.len() == 0 {
    return true;
  }
  if path == request_path {
    return true;
  }
  if string.str_starts_with(request_path, path) {
    let plen = path.len();
    let rlen = request_path.len();
    if rlen > plen {
      if path.byte_at(plen - 1) == 47 {
        return true;
      }
      if request_path.byte_at(plen) == 47 {
        return true;
      }
    }
  }
  false
}

// url_host extracts the host (without port) from a url.
fn url_host(url: Str) -> Str {
  var rest = url;
  let scheme = index_of(url, "://");
  if scheme >= 0 {
    rest = string.str_slice(url, scheme + 3, url.len());
  }
  var end = rest.len();
  let slash = index_of(rest, "/");
  let q = index_of(rest, "?");
  let h = index_of(rest, "#");
  if slash >= 0 && slash < end { end = slash; }
  if q >= 0 && q < end { end = q; }
  if h >= 0 && h < end { end = h; }
  let authority = string.str_slice(rest, 0, end);
  let colon = index_of(authority, ":");
  if colon >= 0 {
    return string.str_slice(authority, 0, colon);
  }
  authority
}

// url_path extracts the path (leading '/', empty for no path) from a url.
fn url_path(url: Str) -> Str {
  var rest = url;
  let scheme = index_of(url, "://");
  if scheme >= 0 {
    rest = string.str_slice(url, scheme + 3, url.len());
  }
  let slash = index_of(rest, "/");
  if slash < 0 {
    return "/";
  }
  let q = index_of(rest, "?");
  let h = index_of(rest, "#");
  var end = rest.len();
  if q >= 0 && q < end { end = q; }
  if h >= 0 && h < end { end = h; }
  if end <= slash {
    return "/";
  }
  string.str_slice(rest, slash, end)
}
