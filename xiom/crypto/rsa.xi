// XIOM -- RSA Public-Key Cryptosystem (Educational / Small-Key)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// WARNING -- EDUCATIONAL IMPLEMENTATION:
//   XIOM Int is 64-bit signed (i64, max ~= 9.22e18). This limits RSA to
//   keys where n = p*q < 2^63. In practice, keys up to ~30 bits are
//   feasible (since primes around 2^15 multiply to ~2^30).
//
//   THIS IS NOT SECURE FOR PRODUCTION USE. Real RSA requires key sizes
//   of at least 2048 bits (617 decimal digits). Use xiom.crypto for
//   actual asymmetric crypto operations.
//
//   This implementation demonstrates the mathematical structure of RSA:
//   key generation, modular exponentiation, encryption, decryption,
//   signing, and verification -- all correct modulo the small-key limit.
//
// Algorithm (RSA):
//   1. KeyGen: Pick two primes p, q. Compute n = p*q, phi = (p-1)(q-1).
//      Choose e coprime to phi (typically 65537). Compute d = e-1 mod phi.
//      Public key: (n, e). Private key: (n, d).
//   2. Encrypt: c = m^e mod n
//   3. Decrypt: m = c^d mod n
//   4. Sign: sig = m^d mod n
//   5. Verify: m' = sig^e mod n; check m == m'
//
// Security notes:
//   - RSA security relies on the hardness of factoring n = p*q.
//   - With small keys (< 64 bits), factoring is trivial (trial division).
//   - Never reuse the same key for both signing and encryption.
//   - Always use padding (OAEP for encryption, PSS for signing) in real RSA.
//     This implementation uses raw/textbook RSA (no padding).

module xiom.rsa

// ============================================================================
// Types
// ============================================================================

/// Full RSA key pair (private key).
/// n: modulus (p * q)
/// e: public exponent
/// d: private exponent (e-1 mod phi(n))
pub type RsaKeyPair = {
  n: Int;
  e: Int;
  d: Int;
}

/// RSA public key.
/// n: modulus
/// e: public exponent
pub type RsaPublicKey = {
  n: Int;
  e: Int;
}

/// Derive the public key (n, e) from a key pair.
/// The public key can be safely shared; the private exponent d stays
/// inside the RsaKeyPair.
pub fn rsa_public_key(pair: &RsaKeyPair) -> RsaPublicKey {
  return RsaPublicKey{
    n: pair.n;
    e: pair.e;
  };
}

// ============================================================================
// Modular Arithmetic Primitives
// ============================================================================

/// Compute (a mod m) with non-negative result.
fn _mod(a: Int, m: Int) -> Int {
  var r = a % m;
  if r < 0 {
    r = r + m;
  }
  return r;
}

/// Compute base^exp mod modulus using square-and-multiply.
///
/// Algorithm:
///   result = 1
///   while exp > 0:
///     if exp is odd: result = (result * base) mod modulus
///     exp = exp / 2
///     base = (base * base) mod modulus
///
/// Complexity: O(log exp) multiplications.
/// Security: Not constant-time -- fine for educational use.
fn _mod_pow(base: Int, exp: Int, modulus: Int) -> Int {
  if modulus <= 1 {
    return 0;
  }
  var result = 1;
  var b = _mod(base, modulus);
  var e = exp;
  while e > 0 {
    if e % 2 == 1 {
      result = _mod(result * b, modulus);
    }
    e = e / 2;
    b = _mod(b * b, modulus);
  }
  return result;
}

/// Extended Euclidean Algorithm.
///
/// Given integers a and b, finds x, y such that: a*x + b*y = gcd(a, b).
/// Returns a Vec[Int] of length 2: [gcd, x].
/// If gcd == 1, then x is the modular inverse of a modulo b.
///
/// Algorithm:
///   Maintain invariants:
///     a * old_s + b * old_t = old_r
///     a * s     + b * t     = r
///   When r becomes 0, old_r is the gcd.
fn _extended_gcd(a: Int, b: Int) -> Vec[Int] {
  var old_r = a;
  var r = b;
  var old_s = 1;
  var s = 0;

  while r != 0 {
    let quotient = old_r / r;
    var temp = r;
    r = old_r - quotient * temp;
    old_r = temp;

    temp = s;
    s = old_s - quotient * temp;
    old_s = temp;
  }

  var result = Vec[Int].new();
  result.push(old_r); // gcd
  result.push(old_s); // x (Bezout coefficient)
  return result;
}

/// Compute modular inverse: find x such that (a * x) == 1 mod m.
/// Returns -1 if no inverse exists (gcd(a, m) != 1).
fn _mod_inverse(a: Int, m: Int) -> Int {
  var eg = _extended_gcd(_mod(a, m), m);
  let gcd = eg[0];
  if gcd != 1 {
    return -1;
  }
  return _mod(eg[1], m);
}

// ============================================================================
// Primality Testing (Trial Division)
//
// For the small primes needed by educational RSA (< 2^15), trial division
// up to sqrt(n) is fast enough. Real RSA uses Miller-Rabin probabilistic
// test.
// ============================================================================

/// Trial division primality test.
/// Returns true if n is prime, false otherwise.
///
/// Complexity: O(sqrt(n)) -- acceptable for n < 2^31 (~46,340 iterations max).
fn _is_prime(n: Int) -> Bool {
  if n < 2 {
    return false;
  }
  if n == 2 || n == 3 {
    return true;
  }
  if n % 2 == 0 {
    return false;
  }

  // Check odd divisors up to sqrt(n)
  var i = 3;
  while i * i <= n {
    if n % i == 0 {
      return false;
    }
    i = i + 2;
  }
  return true;
}

/// Generate a random prime in the range [min, max] using trial division.
/// Uses xiom.math.random_range for random candidate selection.
///
/// Strategy:
///   1. Generate random odd numbers in [min, max].
///   2. Test each with _is_prime.
///   3. Return first prime found.
///   4. If no prime found after many attempts, fall back to a known prime.
fn _random_prime(min: Int, max: Int) -> Int {
  // Ensure min is odd
  if min % 2 == 0 {
    min = min + 1;
  }

  var attempts = 0;
  // Try up to 1000 candidates
  while attempts < 1000 {
    // Pick a random odd number in range
    let range = (max - min) / 2;
    var r = xiom.math.random_range(0, range);
    var candidate = min + 2 * r;

    if _is_prime(candidate) {
      return candidate;
    }
    attempts = attempts + 1;
  }

  // Fallback: return a known safe prime
  return 65521;
}

// ============================================================================
// Key Generation
// ============================================================================

/// Generate an RSA key pair with approximately `bits` bits of modulus.
///
/// Algorithm:
///   1. Choose two distinct primes p, q of roughly bits/2 each.
///   2. n = p * q  (must fit in i64: n < 2^63)
///   3. phi = (p-1) * (q-1)
///   4. e = 65537 (standard RSA public exponent; Fermat prime F4)
///      If 65537 >= phi or gcd(e, phi) != 1, fall back to e = 3 and search.
///   5. d = e-1 mod phi (modular inverse via extended Euclidean algorithm)
///
/// Parameters:
///   bits: desired modulus size in bits (recommended: 16-30 for this impl)
/// Returns: Result[RsaKeyPair, Str] -- the key pair or an error message
///
/// Complexity: O(2^(bits/2)) for primality testing due to trial division.
///             Keep bits <= 30 for reasonable performance.
pub fn rsa_keygen(bits: Int) -> Result[RsaKeyPair, Str] {
  if bits < 8 || bits > 30 {
    return Err("RSA key size must be between 8 and 30 bits for this implementation");
  }

  // Each prime should be roughly bits/2 wide
  let half_bits = bits / 2;
  var p = 2;
  var q = 3;
  var min_prime = 2;
  var max_prime = 32768;

  // Compute min/max for primes; keep within i64-safe ranges
  // For 30-bit n: primes around 15 bits (2^15 = 32768)
  if half_bits <= 15 {
    min_prime = 2;
    max_prime = 32768;
  } else {
    min_prime = 16384;
    max_prime = 46340; // sqrt(2^31) ~= 46340
  }

  if half_bits < 4 {
    min_prime = 2;
    max_prime = 16;
  }

  // Limit prime search to keep n within i64 range
  var safe_max = 3037000499;
  while max_prime * max_prime > safe_max {
    max_prime = max_prime / 2;
  }

  p = _random_prime(min_prime, max_prime);
  q = _random_prime(min_prime, max_prime);

  // Ensure p != q
  var retry = 0;
  while q == p && retry < 50 {
    q = _random_prime(min_prime, max_prime);
    retry = retry + 1;
  }

  // Ensure n fits in i64
  var n = p * q;
  while n < 0 || n > 9000000000000000000 {
    max_prime = max_prime / 2;
    p = _random_prime(min_prime, max_prime);
    q = _random_prime(min_prime, max_prime);
    n = p * q;
  }

  let phi = (p - 1) * (q - 1);

  // Public exponent: prefer 65537 (Fermat prime F4), widely used in practice
  var e = 65537;
  if e >= phi || _extended_gcd(e, phi)[0] != 1 {
    // Fallback: search for a small odd e coprime to phi
    e = 3;
    while e < phi {
      if _extended_gcd(e, phi)[0] == 1 {
        break;
      }
      e = e + 2;
    }
    if e >= phi {
      return Err("Could not find a public exponent coprime to phi(n)");
    }
  }

  // Private exponent: d == e-1 mod phi
  let d = _mod_inverse(e, phi);
  if d < 0 {
    return Err("Could not compute modular inverse for private exponent");
  }

  return Ok(RsaKeyPair{ n: n; e: e; d: d; });
}

// ============================================================================
// Encryption / Decryption
// ============================================================================

/// Encrypt a message using RSA.
///
/// c == m^e mod n
///
/// Parameters:
///   msg: plaintext message (Int, must be < n)
///   key: RSA public key (n, e)
/// Returns: ciphertext (Int)
///
/// Note: In real RSA, messages are padded and encoded as integers < n.
///       This raw implementation encrypts a single integer value.
pub fn rsa_encrypt(msg: Int, key: &RsaPublicKey) -> Int {
  return _mod_pow(msg, key.e, key.n);
}

/// Decrypt a ciphertext using RSA.
///
/// m == c^d mod n
///
/// Parameters:
///   ct: ciphertext (Int, must be < n)
///   key: RSA key pair (n, e, d)
/// Returns: plaintext (Int)
pub fn rsa_decrypt(ct: Int, key: &RsaKeyPair) -> Int {
  return _mod_pow(ct, key.d, key.n);
}

// ============================================================================
// Signing / Verification
// ============================================================================

/// Sign a message using RSA (textbook/Raw RSA signature).
///
/// sig == m^d mod n
///
/// Parameters:
///   msg: message to sign (Int)
///   key: RSA key pair (n, e, d)
/// Returns: signature (Int)
///
/// Security note: Real RSA signing uses PSS padding and hashes the message
///                before signing. This raw version is for education only.
pub fn rsa_sign(msg: Int, key: &RsaKeyPair) -> Int {
  return _mod_pow(msg, key.d, key.n);
}

/// Verify an RSA signature.
///
/// m' == sig^e mod n; returns (m' == msg)
///
/// Parameters:
///   msg: original message (Int)
///   sig: signature to verify (Int)
///   key: RSA public key (n, e)
/// Returns: true if signature is valid
pub fn rsa_verify(msg: Int, sig: Int, key: &RsaPublicKey) -> Bool {
  let decrypted = _mod_pow(sig, key.e, key.n);
  return decrypted == msg;
}
