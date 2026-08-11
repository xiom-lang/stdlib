// XIOM - Network: JSON Web Tokens
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.jwt

// Depends on: xiom.string, xiom.crypto, xiom.serialize

// ============================================================================
// JSON Web Token composition and verification per RFC 7519.
// Pure XIOM: base64url plus signature composition over existing modules.
// ============================================================================

// struct Jwt { header: Str; payload: Str; signature: Str }

// fn jwt_encode(header: Str, payload: Str, secret: Str, alg: Str) -> Result[Str, Str] - build a signed JWT string. TODO(compiler): implement.
// fn jwt_decode(token: Str) -> Result[Jwt, Str] - split a JWT into header, payload, and signature. TODO(compiler): implement.
// fn jwt_verify(token: Str, secret: Str) -> Bool - verify a JWT signature with the given secret. TODO(compiler): implement.
// fn jwt_sign_b64(header_b64: Str, payload_b64: Str, secret: Str, alg: Str) -> Result[Str, Str] - sign base64url parts and append the signature. TODO(compiler): implement.
// fn jwt_base64url_encode(data: &Vec[UInt8]) -> Str - base64url encode without padding. TODO(compiler): implement.
// fn jwt_base64url_decode(s: Str) -> Result[Vec[UInt8], Str] - decode unpadded base64url back to bytes. TODO(compiler): implement.
// fn jwt_alg_supported(alg: Str) -> Bool - test if an algorithm is supported. TODO(compiler): implement.
// fn jwt_expired(token: Str, now: Int) -> Bool - test if the exp claim is before the given time. TODO(compiler): implement.
// fn jwt_claims(token: Str) -> Result[Str, Str] - extract the payload claims as JSON. TODO(compiler): implement.
