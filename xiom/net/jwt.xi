// XIOM - Network: JSON Web Tokens
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.jwt

// Depends on: xiom.string, xiom.crypto, xiom.serialize

// ============================================================================
// JSON Web Token composition and verification per RFC 7519.
// Pure XIOM: base64url and HMAC-SHA256 sign/verify delegate to xiom.encoding
// and xiom.crypto (different names — safe). Claim extraction is a light JSON
// field scanner (no full JSON parser required for alg/exp).
// ============================================================================

use xiom.string;
use xiom.encoding;
use xiom.encoding.base64;
use xiom.crypto;

// struct Jwt { header: Str; payload: Str; signature: Str }
pub type Jwt = {
  header: Str;
  payload: Str;
  signature: Str;
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

// is_ws_byte returns true for space, tab and newline.
fn is_ws_byte(b: UInt8) -> Bool {
  b == 32 || b == 9 || b == 10 || b == 13
}

// utf8_bytes converts a string to its UTF-8 bytes, returning a fresh local
// vector (a module-returned Vec may not re-enter &Vec parameters, BUG 26 #1).
fn utf8_bytes(s: Str) -> Vec[UInt8] {
  let b = encoding.utf8_encode(s);
  var fresh = Vec[UInt8].new();
  var i = 0;
  while i < b.len() {
    fresh.push(b[i]);
    i = i + 1;
  }
  fresh
}

// copy_by_value builds a fresh byte vector from a Vec taken by value, so a
// module-returned Vec never re-enters a &Vec parameter (BUG 26 #1).
fn copy_by_value(src: Vec[UInt8]) -> Vec[UInt8] {
  var fresh = Vec[UInt8].new();
  var i = 0;
  while i < src.len() {
    fresh.push(src[i]);
    i = i + 1;
  }
  fresh
}

// bytes_to_str converts bytes back to a string (best effort). Copies into a
// fresh local Vec first so module-returned vectors never reach the builtin
// converter directly (compiler BUG 26 family).
fn bytes_to_str(data: Vec[UInt8]) -> Str {
  var fresh = Vec[UInt8].new();
  var i = 0;
  while i < data.len() {
    fresh.push(data[i]);
    i = i + 1;
  }
  let s = Str::from_utf8(fresh);
  s
}

// json_string_field returns the string value of a JSON string field.
fn json_string_field(json: Str, key: Str) -> Option[Str] {
  let needle = "\"" + key + "\"";
  let pos = index_of(json, needle);
  if pos < 0 {
    return None;
  }
  let len = json.len();
  var i = pos + needle.len();
  while i < len && is_ws_byte(json.byte_at(i)) {
    i = i + 1;
  }
  if i >= len || json.byte_at(i) != 58 {
    return None;
  }
  i = i + 1;
  while i < len && is_ws_byte(json.byte_at(i)) {
    i = i + 1;
  }
  if i >= len || json.byte_at(i) != 34 {
    return None;
  }
  i = i + 1;
  var buf = Vec[UInt8].new();
  while i < len {
    let b = json.byte_at(i);
    if b == 34 {
      let s = Str::from_utf8(buf);
      return Some(s);
    }
    if b == 92 {
      i = i + 1;
      if i >= len {
        return None;
      }
      let e = json.byte_at(i);
      if e == 110 {
        buf.push(10 as UInt8);
      } elif e == 116 {
        buf.push(9 as UInt8);
      } elif e == 114 {
        buf.push(13 as UInt8);
      } elif e == 92 {
        buf.push(92 as UInt8);
      } elif e == 47 {
        buf.push(47 as UInt8);
      } elif e == 34 {
        buf.push(34 as UInt8);
      } else {
        buf.push(e);
      }
    } else {
      buf.push(b);
    }
    i = i + 1;
  }
  None
}

// json_number_field returns the integer value of a JSON number field.
fn json_number_field(json: Str, key: Str) -> Option[Int] {
  let needle = "\"" + key + "\"";
  let pos = index_of(json, needle);
  if pos < 0 {
    return None;
  }
  let len = json.len();
  var i = pos + needle.len();
  while i < len && is_ws_byte(json.byte_at(i)) {
    i = i + 1;
  }
  if i >= len || json.byte_at(i) != 58 {
    return None;
  }
  i = i + 1;
  while i < len && is_ws_byte(json.byte_at(i)) {
    i = i + 1;
  }
  var neg = false;
  if i < len && json.byte_at(i) == 45 {
    neg = true;
    i = i + 1;
  }
  if i >= len {
    return None;
  }
  var value: Int = 0;
  var digits = 0;
  while i < len {
    let b = json.byte_at(i);
    if b < 48 || b > 57 {
      break;
    }
    value = value * 10 + (b as Int - 48);
    digits = digits + 1;
    i = i + 1;
  }
  if digits == 0 {
    return None;
  }
  if neg {
    value = 0 - value;
  }
  Some(value)
}

/// Base64url encode bytes without padding.
/// Parameters: data — the bytes to encode.
/// Returns: the unpadded URL-safe base64 string.
/// Complexity: O(n). Pure.
pub fn jwt_base64url_encode(data: &Vec[UInt8]) -> Str {
  let e = base64.base64url_encode(data);
  e
}

/// Decode an unpadded base64url string back to bytes.
/// Parameters: s — the encoded string (padding optional).
/// Returns: Ok(bytes) on success, Err for an invalid character.
/// Complexity: O(n). Pure.
pub fn jwt_base64url_decode(s: Str) -> Result[Vec[UInt8], Str] {
  let d = base64.base64url_decode(s);
  d
}

/// Test if an algorithm is supported.
/// Parameters: alg — the algorithm name.
/// Returns: true for "HS256" and "none".
/// Complexity: O(1). Pure.
pub fn jwt_alg_supported(alg: Str) -> Bool {
  alg == "HS256" || alg == "none"
}

// sign_input builds the canonical signing input for the two base64url parts.
fn sign_input(header_b64: Str, payload_b64: Str) -> Vec[UInt8] {
  let joined = header_b64 + "." + payload_b64;
  utf8_bytes(joined)
}

// hmac_sign computes the base64url HMAC-SHA256 signature for a signing input.
fn hmac_sign(secret: Str, input: &Vec[UInt8]) -> Result[Str, Str] {
  let key = utf8_bytes(secret);
  let mac_raw = crypto.hmac_sha256(&key, input);
  let mac = copy_by_value(mac_raw);
  let sig = base64.base64url_encode(&mac);
  Ok(sig)
}

/// Build a signed JWT string.
/// Parameters: header — the JSON header (e.g.
///          "{\"alg\":\"HS256\",\"typ\":\"JWT\"}"); payload — the JSON
///          claims; secret — the HMAC secret; alg — "HS256" or "none".
/// Returns: Ok("header.payload.signature") on success, Err for an unsupported
///          algorithm.
/// Complexity: O(n). Pure.
pub fn jwt_encode(header: Str, payload: Str, secret: Str, alg: Str) -> Result[Str, Str] {
  if !jwt_alg_supported(alg) {
    return Err("unsupported JWT algorithm: " + alg);
  }
  let hb_raw = utf8_bytes(header);
  let hb = encoding.base64url_encode(&hb_raw);
  let pb_raw = utf8_bytes(payload);
  let pb = encoding.base64url_encode(&pb_raw);
  let sig = jwt_sign_b64(hb, pb, secret, alg)?;
  Ok(sig)
}

/// Sign base64url parts and append the signature.
/// Parameters: header_b64 — the encoded header; payload_b64 — the encoded
///          payload; secret — the HMAC secret; alg — "HS256" or "none".
/// Returns: Ok("header.payload.signature") on success, Err for an unsupported
///          algorithm.
/// Complexity: O(n). Pure.
pub fn jwt_sign_b64(header_b64: Str, payload_b64: Str, secret: Str, alg: Str) -> Result[Str, Str] {
  if !jwt_alg_supported(alg) {
    return Err("unsupported JWT algorithm: " + alg);
  }
  let input = sign_input(header_b64, payload_b64);
  if alg == "none" {
    let token = join_token(header_b64, payload_b64, "");
    return Ok(token);
  }
  let sig = hmac_sign(secret, &input)?;
  let token = join_token(header_b64, payload_b64, sig);
  Ok(token)
}

// join_token assembles "header.payload.signature".
fn join_token(a: Str, b: Str, c: Str) -> Str {
  var result = a + ".";
  result = result + b;
  result = result + ".";
  result = result + c;
  result
}

/// Split a JWT into header, payload, and signature.
/// Parameters: token — the full JWT string.
/// Returns: Ok(Jwt) with exactly three dot-separated parts, Err otherwise.
/// Complexity: O(n). Pure.
pub fn jwt_decode(token: Str) -> Result[Jwt, Str] {
  let parts = string.str_split(token, ".");
  if parts.len() != 3 {
    return Err("invalid JWT: expected three parts");
  }
  let h = parts[0];
  let p = parts[1];
  let s = parts[2];
  if h.len() == 0 || p.len() == 0 {
    return Err("invalid JWT: empty header or payload");
  }
  Ok(Jwt{ header: h; payload: p; signature: s; })
}

/// Verify a JWT signature with the given secret.
/// Parameters: token — the JWT string; secret — the HMAC secret.
/// Returns: true when the structure is valid and (for HS256) the signature
///          matches; "none" tokens verify only when the signature part is
///          empty.
/// Complexity: O(n). Pure.
pub fn jwt_verify(token: Str, secret: Str) -> Bool {
  let decoded = jwt_decode(token);
  match decoded {
    Err(_) => return false;
    Ok(parts) => {
      let hb = parts.header;
      let pb = parts.payload;
      let sig = parts.signature;
      let hjson = jwt_base64url_decode(hb);
      match hjson {
        Err(_) => return false;
        Ok(hbytes) => {
          let hj = bytes_to_str(hbytes);
          let alg = json_string_field(hj, "alg");
          match alg {
            None => return false;
            Some(a) => {
              if a == "none" {
                return sig.len() == 0;
              }
              if a != "HS256" {
                return false;
              }
              let input = sign_input(hb, pb);
              let expected = hmac_sign(secret, &input);
              match expected {
                Err(_) => return false;
                Ok(exp) => {
                  if exp.len() != sig.len() {
                    return false;
                  }
                  var i = 0;
                  var diff = false;
                  while i < exp.len() {
                    if exp.byte_at(i) != sig.byte_at(i) {
                      diff = true;
                    }
                    i = i + 1;
                  }
                  return !diff;
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Test if the exp claim is before the given time.
/// Parameters: token — the JWT string; now — the reference unix timestamp.
/// Returns: true when the token has an exp claim at or before now, false when
///          there is no exp claim or the token is malformed.
/// Complexity: O(n). Pure.
pub fn jwt_expired(token: Str, now: Int) -> Bool {
  let decoded = jwt_decode(token);
  match decoded {
    Err(_) => return false;
    Ok(j) => {
      let pb = j.payload;
      let bytes = jwt_base64url_decode(pb);
      match bytes {
        Err(_) => return false;
        Ok(b) => {
          let pjson = bytes_to_str(b);
          let exp = json_number_field(pjson, "exp");
          match exp {
            None => false;
            Some(e) => e <= now;
          }
        }
      }
    }
  }
}

/// Extract the payload claims as JSON.
/// Parameters: token — the JWT string.
/// Returns: Ok(decoded payload) on success, Err for a malformed token or an
///          invalid base64url payload.
/// Complexity: O(n). Pure.
pub fn jwt_claims(token: Str) -> Result[Str, Str] {
  let decoded = jwt_decode(token);
  match decoded {
    Err(e) => Err(e);
    Ok(j) => {
      let pb = j.payload;
      let bytes = jwt_base64url_decode(pb);
      match bytes {
        Err(e) => Err(e);
        Ok(b) => Ok(bytes_to_str(b));
      }
    }
  }
}
