// XIOM stdlib smoke test — xiom.net.jwt + xiom.net.tls_helper
// JWT encode/decode/verify and TLS PEM/DER certificate helpers.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net_jwt

use xiom.net.jwt;
use xiom.net.tls_helper;
use xiom.io;

fn main() -> Int {
  // --- jwt: base64url ---
  let bytes = mkbytes("hello");
  let enc = jwt.jwt_base64url_encode(&bytes);
  if enc != "aGVsbG8" {
    io.println("jwt-b64-enc");
    return 1;
  }
  {
    let dec = jwt.jwt_base64url_decode(enc);
    match dec {
      Err(e) => {
        io.println("jwt-b64-dec");
        return 2;
      }
      Ok(b) => {
        if b.len() != 5 {
          io.println("jwt-b64-len");
          return 3;
        }
        if b[0] != 104 || b[4] != 111 {
          io.println("jwt-b64-bytes");
          return 4;
        }
      }
    }
  }
  if jwt.jwt_base64url_decode("!!!not-base64!!!").is_ok {
    io.println("jwt-b64-invalid");
    return 5;
  }

  // --- jwt: alg support ---
  if !jwt.jwt_alg_supported("HS256") {
    io.println("jwt-alg-hs256");
    return 6;
  }
  if !jwt.jwt_alg_supported("none") {
    io.println("jwt-alg-none");
    return 7;
  }
  if jwt.jwt_alg_supported("RS256") {
    io.println("jwt-alg-rs");
    return 8;
  }

  // --- jwt: encode + verify ---
  let header = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
  let payload = "{\"sub\":\"123\",\"name\":\"test\"}";
  let token = jwt.jwt_encode(header, payload, "secret-key", "HS256");
  match token {
    Err(e) => {
      io.println("jwt-encode");
      return 9;
    }
    Ok(t) => {
      if !jwt.jwt_verify(t, "secret-key") {
        io.println("jwt-verify");
        return 10;
      }
      if jwt.jwt_verify(t, "wrong-key") {
        io.println("jwt-verify-wrong");
        return 11;
      }
      {
        let dec = jwt.jwt_decode(t);
        match dec {
          Err(e) => {
            io.println("jwt-decode");
            return 12;
          }
          Ok(j) => {
            if j.header.len() == 0 || j.payload.len() == 0 || j.signature.len() == 0 {
              io.println("jwt-parts");
              return 13;
            }
          }
        }
      }
      {
        let claims = jwt.jwt_claims(t);
        match claims {
          Err(e) => {
            io.println("jwt-claims");
            return 14;
          }
          Ok(c) => {
            if c != payload {
              io.println("jwt-claims-value");
              return 15;
            }
          }
        }
      }
    }
  }

  // --- jwt: alg=none ---
  let header_none = "{\"alg\":\"none\",\"typ\":\"JWT\"}";
  let token2 = jwt.jwt_encode(header_none, payload, "", "none");
  match token2 {
    Err(e) => {
      io.println("jwt-none-encode");
      return 16;
    }
    Ok(t) => {
      if !jwt.jwt_verify(t, "") {
        io.println("jwt-none-verify");
        return 17;
      }
    }
  }

  // --- jwt: expiring claims ---
  let payload_exp = "{\"exp\":1000}";
  let token3 = jwt.jwt_encode(header, payload_exp, "secret", "HS256");
  match token3 {
    Err(e) => {
      io.println("jwt-exp-encode");
      return 18;
    }
    Ok(t) => {
      if !jwt.jwt_expired(t, 2000) {
        io.println("jwt-expired");
        return 19;
      }
      if jwt.jwt_expired(t, 500) {
        io.println("jwt-not-expired");
        return 20;
      }
    }
  }

  // --- tls_helper: SHA-256 fingerprint ---
  let der = mkbytes("der-bytes-for-test");
  let fp = tls_helper.cert_fingerprint_sha256(&der);
  if fp.len() != 32 {
    io.println("tls-fp-len");
    return 21;
  }
  let fp2 = tls_helper.cert_fingerprint_sha256(&der);
  if fp2.len() != 32 {
    io.println("tls-fp2");
    return 22;
  }
  if tls_helper.cert_fingerprint_sha1(&der).len() != 0 {
    io.println("tls-fp1");
    return 23;
  }

  // --- tls_helper: PEM round-trip ---
  let pem = tls_helper.pem_encode(&der, "CERTIFICATE");
  if pem.len() == 0 {
    io.println("tls-pem-enc");
    return 24;
  }
  {
    let der2 = tls_helper.pem_decode(pem);
    match der2 {
      Err(e) => {
        io.println("tls-pem-dec");
        return 25;
      }
      Ok(b) => {
        if b.len() != der.len() {
          io.println("tls-pem-len");
          return 26;
        }
      }
    }
  }
  {
    let certs = tls_helper.pem_parse_certificates(pem);
    match certs {
      Err(e) => {
        io.println("tls-pem-certs");
        return 27;
      }
      Ok(cs) => {
        if cs.len() != 1 {
          io.println("tls-pem-certs-len");
          return 28;
        }
      }
    }
  }

  // --- tls_helper: DER length decode ---
  let lenvec = mklen();
  {
    let dl = tls_helper.der_length_decode(&lenvec, 1);
    match dl {
      Err(e) => {
        io.println("tls-derlen");
        return 29;
      }
      Ok(t) => {
        if t.0 != 256 {
          io.println("tls-derlen-value");
          return 30;
        }
        if t.1 != 3 {
          io.println("tls-derlen-consumed");
          return 31;
        }
      }
    }
  }
  {
    let dl2 = tls_helper.der_length_decode(&lenvec, 0);
    match dl2 {
      Err(e) => {
        io.println("tls-derlen2");
        return 32;
      }
      Ok(t) => {
        if t.0 != 0x30 {
          io.println("tls-derlen-short");
          return 33;
        }
      }
    }
  }

  io.println("OK");
  return 0;
}

fn mkbytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i = i + 1;
  }
  v
}

fn mklen() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(0x30 as UInt8);
  v.push(0x82 as UInt8);
  v.push(0x01 as UInt8);
  v.push(0x00 as UInt8);
  v.push(0xFF as UInt8);
  v
}

// DER: SEQUENCE { OID 2.5.4.3 }
fn mkoid() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(0x30 as UInt8);
  v.push(0x05 as UInt8);
  v.push(0x06 as UInt8);
  v.push(0x03 as UInt8);
  v.push(0x55 as UInt8);
  v.push(0x04 as UInt8);
  v.push(0x03 as UInt8);
  v
}
