// XIOM - Networking: TLS Certificate Helpers
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.net.tls_helper

// Depends on: xiom.net + xiom.string

// ============================================================================
// X.509 certificate and PEM/DER helper utilities. Full TLS is a separate
// package; this sublib provides the certificate/helper utilities. DER is
// parsed with a local minimal ASN.1 TLV walker; fingerprints delegate to
// xiom.crypto (SHA-256) and PEM armor delegates to xiom.encoding.base64.
// SHA-1 fingerprints cannot be produced (no SHA-1 in xiom.crypto) -- that
// function is a documented empty result.
// ============================================================================

use xiom.string;
use xiom.crypto;
use xiom.encoding.base64;

// idx_of returns the byte index of needle in hay, or -1.
fn idx_of(hay: Str, needle: Str) -> Int {
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

// bytes_region copies data[from, to) into a fresh vector.
fn bytes_region(data: &Vec[UInt8], from: Int, to: Int) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i = from;
  while i < to && i < data.len() {
    out.push(data[i]);
    i = i + 1;
  }
  out
}

// copy_vec copies a module-returned Vec into a fresh local vector.
fn copy_vec(src: Vec[UInt8]) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i = 0;
  while i < src.len() {
    out.push(src[i]);
    i = i + 1;
  }
  out
}

// region_str converts a byte region to a string (best effort).
fn region_str(data: &Vec[UInt8], from: Int, to: Int) -> Str {
  let region = bytes_region(data, from, to);
  let s = Str::from_utf8(region);
  s
}

/// Read a DER length at pos.
/// Parameters: data -- the DER bytes; pos -- the position of the length octet.
/// Returns: Ok((length, bytes_consumed)) for short and long forms; Err for
///          indefinite lengths or truncated input.
/// Complexity: O(1). Pure.
pub fn der_length_decode(data: &Vec[UInt8], pos: Int) -> Result[(Int, Int), Str] {
  let dlen = data.len();
  if pos < 0 || pos >= dlen {
    return Err("DER length: position out of bounds");
  }
  let first = data[pos] as Int;
  if first < 0x80 {
    return Ok((first, 1));
  }
  if first == 0x80 {
    return Err("DER length: indefinite form not allowed");
  }
  let nbytes = first & 0x7F;
  if nbytes == 0 {
    return Err("DER length: malformed long form");
  }
  if nbytes > 8 {
    return Err("DER length: too many length octets");
  }
  if pos + 1 + nbytes > dlen {
    return Err("DER length: truncated");
  }
  var length: Int = 0;
  var i = 0;
  while i < nbytes {
    length = length * 256 + (data[pos + 1 + i] as Int);
    i = i + 1;
  }
  Ok((length, 1 + nbytes))
}

// der_read_tlv reads a single TLV at pos; returns (tag, content_start, next).
fn der_read_tlv(data: &Vec[UInt8], pos: Int) -> Result[(Int, Int, Int), Str] {
  let dlen = data.len();
  if pos < 0 || pos >= dlen {
    return Err("DER TLV: position out of bounds");
  }
  let tag = data[pos] as Int;
  let lenres = der_length_decode(data, pos + 1);
  match lenres {
    Err(e) => Err(e);
    Ok(l) => {
      let length = l.0;
      let consumed = l.1;
      let content_start = pos + 1 + consumed;
      if content_start + length > dlen {
        return Err("DER TLV: content out of bounds");
      }
      Ok((tag, content_start, content_start + length));
    }
  }
}

/// Read an ASN.1 object identifier at pos.
/// Parameters: data -- the DER bytes; pos -- the position of the OID tag.
/// Returns: Ok((oid components, next_pos)) on success, Err on malformed input.
/// Complexity: O(n). Pure.
pub fn asn1_read_oid(data: &Vec[UInt8], pos: Int) -> Result[(Vec[Int], Int), Str] {
  let tlv = der_read_tlv(data, pos);
  match tlv {
    Err(e) => Err(e);
    Ok(t) => {
      if t.0 != 0x06 {
        return Err("ASN.1 OID: expected tag 0x06");
      }
      let start = t.1;
      let end = t.2;
      if end <= start {
        return Err("ASN.1 OID: empty content");
      }
      var oid = Vec[Int].new();
      let first = data[start] as Int;
      oid.push(first / 40);
      oid.push(first % 40);
      var i = start + 1;
      while i < end {
        var value: Int = 0;
        var more = true;
        while more && i < end {
          let b = data[i] as Int;
          value = value * 128 + (b & 0x7F);
          if b & 0x80 == 0 {
            more = false;
          }
          i = i + 1;
        }
        if more {
          return Err("ASN.1 OID: truncated subidentifier");
        }
        oid.push(value);
      }
      Ok((oid, end));
    }
  }
}

// oid_is_cn returns true when oid equals the commonName OID 2.5.4.3.
fn oid_is_cn(oid: &Vec[Int]) -> Bool {
  if oid.len() != 4 {
    return false;
  }
  oid[0] == 2 && oid[1] == 5 && oid[2] == 4 && oid[3] == 3
}

// der_string reads a DER string value (PrintableString/UTF8String/IA5String/
// T61String/BMPString) at pos; returns the decoded string and next position.
fn der_string(data: &Vec[UInt8], pos: Int) -> Result<(Str, Int), Str> {
  let tlv = der_read_tlv(data, pos);
  match tlv {
    Err(e) => Err(e);
    Ok(t) => {
      let tag = t.0;
      if tag != 0x0C && tag != 0x13 && tag != 0x16 && tag != 0x14 && tag != 0x1E {
        return Err("DER string: unexpected tag");
      }
      let s = region_str(data, t.1, t.2);
      Ok((s, t.2));
    }
  }
}

// name_cn scans a DER Name (RDNSequence) for the commonName attribute.
fn name_cn(data: &Vec[UInt8], start: Int, end: Int) -> Result[Str, Str] {
  var pos = start;
  while pos < end {
    let rdn = der_read_tlv(data, pos);
    match rdn {
      Err(e) => return Err(e);
      Ok(r) => {
        if r.0 != 0x31 {
          return Err("DER name: expected SET");
        }
        var inner = r.1;
        while inner < r.2 {
          let atv = der_read_tlv(data, inner);
          match atv {
            Err(e) => return Err(e);
            Ok(a) => {
              if a.0 != 0x30 {
                return Err("DER name: expected SEQUENCE");
              }
              let oidres = asn1_read_oid(data, a.1);
              match oidres {
                Err(e) => return Err(e);
                Ok(o) => {
                  let oid = o.0;
                  let oid_next = o.1;
                  if oid_is_cn(&oid) {
                    let sres = der_string(data, oid_next);
                    match sres {
                      Err(e) => return Err(e);
                      Ok(s) => return Ok(s.0);
                    }
                  }
                }
              }
              inner = a.2;
            }
          }
        }
        pos = r.2;
      }
    }
  }
  Err("DER name: no commonName attribute")
}

/// SHA-256 fingerprint of a DER certificate.
/// Parameters: der -- the certificate DER bytes.
/// Returns: the 32-byte SHA-256 digest.
/// Complexity: O(n). Pure.
pub fn cert_fingerprint_sha256(der: &Vec[UInt8]) -> Vec[UInt8] {
  let raw = crypto.sha256(der);
  copy_vec(raw)
}

/// SHA-1 fingerprint of a DER certificate.
/// NOT AVAILABLE: xiom.crypto does not provide SHA-1. Returns an empty
/// vector.
/// Complexity: O(1). Pure.
pub fn cert_fingerprint_sha1(der: &Vec[UInt8]) -> Vec[UInt8] {
  let _ = der;
  var out = Vec[UInt8].new();
  out
}

// cert_find_tbs locates the tbsCertificate SEQUENCE and returns its content
// bounds.
fn cert_find_tbs(der: &Vec[UInt8]) -> Result<(Int, Int), Str> {
  let outer = der_read_tlv(der, 0);
  match outer {
    Err(e) => Err(e);
    Ok(o) => {
      if o.0 != 0x30 {
        return Err("DER certificate: expected SEQUENCE");
      }
      let tbs = der_read_tlv(der, o.1);
      match tbs {
        Err(e) => Err(e);
        Ok(t) => {
          if t.0 != 0x30 {
            return Err("DER certificate: expected tbsCertificate SEQUENCE");
          }
          Ok((t.1, t.2));
        }
      }
    }
  }
}

// cert_child_tags walks the tbs children and returns (validity_start,
// validity_end, subject_start, subject_end, issuer_start, issuer_end,
// spki_start, spki_end) as an 8-tuple; -1 marks "not found".
fn cert_child_ranges(der: &Vec[UInt8]) -> Result<(Int, Int, Int, Int, Int, Int, Int, Int), Str> {
  let tbs = cert_find_tbs(der);
  match tbs {
    Err(e) => return Err(e);
    Ok(t) => {
      var pos = t.0;
      let end = t.1;
      var serial_done = false;
      var sig_done = false;
      var issuer_start = -1;
      var issuer_end = -1;
      var validity_start = -1;
      var validity_end = -1;
      var subject_start = -1;
      var subject_end = -1;
      var spki_start = -1;
      var spki_end = -1;
      while pos < end {
        let tlv = der_read_tlv(der, pos);
        match tlv {
          Err(e) => return Err(e);
          Ok(v) => {
            let tag = v.0;
            if tag == 0xA0 {
              // version [0]
            } elif tag == 0x02 && !serial_done {
              serial_done = true;
            } elif tag == 0x30 && !sig_done {
              sig_done = true;
            } elif tag == 0x30 && issuer_start < 0 {
              issuer_start = v.1;
              issuer_end = v.2;
            } elif tag == 0x30 && validity_start < 0 {
              validity_start = v.1;
              validity_end = v.2;
            } elif tag == 0x30 && subject_start < 0 {
              subject_start = v.1;
              subject_end = v.2;
            } elif tag == 0x30 && spki_start < 0 {
              spki_start = v.1;
              spki_end = v.2;
            }
            pos = v.2;
          }
        }
      }
      return Ok((issuer_start, issuer_end, validity_start, validity_end, subject_start, subject_end, spki_start, spki_end));
    }
  }
}

// validity_dates extracts the not-before and not-after strings from the
// validity SEQUENCE.
fn validity_dates(der: &Vec[UInt8]) -> Result[(Str, Str), Str] {
  let ranges = cert_child_ranges(der);
  match ranges {
    Err(e) => return Err(e);
    Ok(r) => {
      let vstart = r.2;
      let vend = r.3;
      if vstart < 0 {
        return Err("certificate has no validity period");
      }
      let first = der_read_tlv(der, vstart);
      match first {
        Err(e) => return Err(e);
        Ok(f) => {
          let second = der_read_tlv(der, f.2);
          match second {
            Err(e) => return Err(e);
            Ok(s) => {
              let nb = region_str(der, f.1, f.2);
              let na = region_str(der, s.1, s.2);
              Ok((nb, na));
            }
          }
        }
      }
      let _ = vend;
    }
  }
}

/// Certificate validity period.
/// Parameters: der -- the certificate DER bytes.
/// Returns: Ok((not_before, not_after)) as ASN.1 time strings, Err when the
///          structure cannot be parsed.
/// Complexity: O(n). Pure.
pub fn cert_validity_dates(der: &Vec[UInt8]) -> Result[(Str, Str), Str] {
  validity_dates(der)
}

/// The common name of the certificate subject.
/// Parameters: der -- the certificate DER bytes.
/// Returns: Ok(CN) on success, Err when unparseable or missing.
/// Complexity: O(n). Pure.
pub fn cert_subject_cn(der: &Vec[UInt8]) -> Result[Str, Str] {
  let ranges = cert_child_ranges(der);
  match ranges {
    Err(e) => Err(e);
    Ok(r) => {
      let sstart = r.4;
      let send = r.5;
      if sstart < 0 {
        return Err("certificate has no subject");
      }
      name_cn(der, sstart, send)
    }
  }
}

/// The common name of the certificate issuer.
/// Parameters: der -- the certificate DER bytes.
/// Returns: Ok(CN) on success, Err when unparseable or missing.
/// Complexity: O(n). Pure.
pub fn cert_issuer_cn(der: &Vec[UInt8]) -> Result[Str, Str] {
  let ranges = cert_child_ranges(der);
  match ranges {
    Err(e) => Err(e);
    Ok(r) => {
      let istart = r.0;
      let iend = r.1;
      if istart < 0 {
        return Err("certificate has no issuer");
      }
      name_cn(der, istart, iend)
    }
  }
}

// oid_algorithm_name maps an algorithm OID to a human name.
fn oid_algorithm_name(oid: &Vec[Int]) -> Str {
  if oid.len() >= 2 && oid[0] == 1 && oid[1] == 2 && oid.len() >= 7 {
    if oid[2] == 840 && oid[3] == 113549 && oid[4] == 1 && oid[5] == 1 {
      if oid[6] == 1 { return "RSA"; }
      if oid[6] == 7 { return "RSA-OAEP"; }
    }
  }
  if oid.len() >= 3 && oid[0] == 1 && oid[1] == 2 && oid[2] == 840 && oid.len() >= 5 {
    if oid[3] == 10045 && oid[4] == 2 {
      return "EC";
    }
    if oid[3] == 10040 && oid[4] == 4 {
      return "DSA";
    }
  }
  if oid.len() >= 3 && oid[0] == 1 && oid[1] == 3 && oid[2] == 14 && oid.len() >= 4 && oid[3] == 3 && oid.len() >= 5 && oid[4] == 2 && oid.len() >= 6 && oid[5] == 6 {
    return "DSA";
  }
  "Unknown"
}

/// Public key metadata for a certificate.
/// Parameters: der -- the certificate DER bytes.
/// Returns: Ok((algorithm, bits)) on success, Err when unparseable.
/// Complexity: O(n). Pure.
pub fn cert_public_key_info(der: &Vec[UInt8]) -> Result[(Str, Int), Str] {
  let ranges = cert_child_ranges(der);
  match ranges {
    Err(e) => Err(e);
    Ok(r) => {
      let sstart = r.6;
      let send = r.7;
      if sstart < 0 {
        return Err("certificate has no subjectPublicKeyInfo");
      }
      let spki = der_read_tlv(der, sstart);
      match spki {
        Err(e) => Err(e);
        Ok(sp) => {
          let alg = der_read_tlv(der, sp.1);
          match alg {
            Err(e) => Err(e);
            Ok(a) => {
              let oidres = asn1_read_oid(der, a.1);
              match oidres {
                Err(e) => Err(e);
                Ok(o) => {
                  let name = oid_algorithm_name(&o.0);
                  let bitstr = der_read_tlv(der, a.2);
                  match bitstr {
                    Err(e) => Err(e);
                    Ok(bs) => {
                      if bs.0 != 0x03 {
                        return Err("public key: expected BIT STRING");
                      }
                      if bs.2 <= bs.1 {
                        return Err("public key: empty BIT STRING");
                      }
                      let unused = data_byte_at(der, bs.1) as Int;
                      let total_bits = (bs.2 - bs.1 - 1) * 8 - unused;
                      Ok((name, total_bits));
                    }
                  }
                }
              }
            }
          }
          let _ = send;
        }
      }
    }
  }
}

// data_byte_at reads a byte at pos with bounds clamping.
fn data_byte_at(data: &Vec[UInt8], pos: Int) -> UInt8 {
  if pos < 0 || pos >= data.len() {
    return 0 as UInt8;
  }
  data[pos]
}

/// True when subject equals issuer (by common name comparison).
/// Parameters: der -- the certificate DER bytes.
/// Returns: true when both subject and issuer CNs parse and match; false
///          otherwise (including unparseable input).
/// Complexity: O(n). Pure.
pub fn cert_is_self_signed(der: &Vec[UInt8]) -> Bool {
  let s = cert_subject_cn(der);
  let i = cert_issuer_cn(der);
  match s {
    Err(_) => return false;
    Ok(scn) => {
      match i {
        Err(_) => return false;
        Ok(icn) => scn == icn;
      }
    }
  }
}

/// Wrap DER bytes in a PEM armor with the given label.
/// Parameters: der -- the DER bytes; label -- the PEM label (e.g.
///          "CERTIFICATE").
/// Returns: the PEM string with 64-column base64 lines.
/// Complexity: O(n). Pure.
pub fn pem_encode(der: &Vec[UInt8], label: Str) -> Str {
  let b64 = base64.base64_encode(der);
  var result = "-----BEGIN ";
  result = result + label;
  result = result + "-----\n";
  var i = 0;
  while i < b64.len() {
    var line_end = i + 64;
    if line_end > b64.len() {
      line_end = b64.len();
    }
    let line = string.str_slice(b64, i, line_end);
    result = result + line;
    result = result + "\n";
    i = line_end;
  }
  result = result + "-----END ";
  result = result + label;
  result = result + "-----\n";
  result
}

// pem_find_block returns the base64 body of the first PEM block with the
// given label, or None.
fn pem_find_block(pem: Str, label: Str) -> Option[Str] {
  let begin_marker = "-----BEGIN " + label + "-----";
  let begin = idx_of(pem, begin_marker);
  if begin < 0 {
    return None;
  }
  let start = begin + begin_marker.len();
  let end_marker = "-----END " + label + "-----";
  let end = idx_of(pem, end_marker);
  if end < 0 {
    return None;
  }
  var body = string.str_slice(pem, start, end);
  var cleaned = "";
  var i = 0;
  while i < body.len() {
    let b = body.byte_at(i);
    if b == 10 || b == 13 || b == 32 || b == 9 {
      i = i + 1;
      continue;
    }
    let ch = string.str_slice(body, i, i + 1);
    cleaned = cleaned + ch;
    i = i + 1;
  }
  Some(cleaned)
}

/// Strip PEM armor and return the DER bytes.
/// Parameters: pem -- the PEM string.
/// Returns: Ok(DER bytes) on success, Err when no matching block is found.
/// Complexity: O(n). Pure.
pub fn pem_decode(pem: Str) -> Result[Vec[UInt8], Str] {
  let body = pem_find_block(pem, "CERTIFICATE");
  match body {
    None => {
      let body2 = pem_find_block(pem, "PRIVATE KEY");
      match body2 {
        None => Err("pem_decode: no PEM block found");
        Some(b) => base64.base64_decode(b);
      }
    }
    Some(b) => base64.base64_decode(b);
  }
}

/// Extract every certificate block from a PEM string.
/// Parameters: pem -- the PEM string.
/// Returns: Ok(the DER bytes of each CERTIFICATE block) on success, Err when
///          no certificate block is present.
/// Complexity: O(n). Pure.
pub fn pem_parse_certificates(pem: Str) -> Result[Vec[Vec[UInt8]], Str] {
  var result: Vec[Vec[UInt8]] = Vec[Vec[UInt8]].new();
  var rest = pem;
  var found = false;
  var done = false;
  while !done {
    let block = pem_find_block(rest, "CERTIFICATE");
    match block {
      None => {
        done = true;
        break;
      }
      Some(b) => {
        found = true;
        let der = base64.base64_decode(b);
        match der {
          Err(e) => return Err(e);
          Ok(bytes) => {
            result.push(bytes);
          }
        }
        let marker = "-----END CERTIFICATE-----";
        let end = idx_of(rest, marker);
        if end < 0 {
          done = true;
          break;
        }
        let after = end + marker.len();
        rest = string.str_slice(rest, after, rest.len());
      }
    }
  }
  if !found {
    return Err("pem_parse_certificates: no CERTIFICATE block found");
  }
  Ok(result)
}
