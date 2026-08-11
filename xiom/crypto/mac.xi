// XIOM - Cryptography: MAC
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto.mac

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Message authentication codes: HMAC, Poly1305, CBC-MAC, CMAC. NOTE: current
// implementation lives in crypto.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn hmac_new(key: &Vec[UInt8], hash: Int) -> Hmac - create an incremental HMAC; Hmac holds the keyed inner/outer state. TODO(compiler): implement.
// fn hmac_update(h, data: &Vec[UInt8]) - feed data into an in-progress HMAC. TODO(compiler): implement.
// fn hmac_final(h) -> Vec[UInt8] - finish an HMAC and return the tag. TODO(compiler): implement.
// fn hmac_sha256(key, data) -> Vec[UInt8] - one-shot HMAC-SHA256. TODO(compiler): implement.
// fn hmac_sha512(key, data) -> Vec[UInt8] - one-shot HMAC-SHA512. TODO(compiler): implement.
// fn hmac_verify(key, data, tag: &Vec[UInt8]) -> Bool - constant-time tag comparison. TODO(compiler): implement.
// fn poly1305_mac(key: &Vec[UInt8], data) -> Vec[UInt8] - Poly1305 one-shot MAC (16 bytes). TODO(compiler): implement.
// fn poly1305_verify(key, data, tag) -> Bool - constant-time Poly1305 verification. TODO(compiler): implement.
// fn cbc_mac(key, iv, data) -> Vec[UInt8] - CBC-MAC over the message. TODO(compiler): implement.
// fn cmac_aes128(key, data) -> Vec[UInt8] - AES-CMAC-128 (NIST SP 800-38B). TODO(compiler): implement.
// fn constant_time_eq(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool - timing-safe byte comparison. TODO(compiler): implement.
// fn constant_time_select(a: Int, b: Int, bit: Bool) -> Int - return a when bit is true, else b. TODO(compiler): implement.
