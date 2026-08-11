// XIOM - Cryptography: Key Exchange
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto.keyx

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Key exchange: X25519, ECDH, classic Diffie-Hellman. NOTE: current
// implementation lives in crypto.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn x25519_keypair() -> (Vec[UInt8], Vec[UInt8]) - generate a new X25519 keypair; tuple is (sk, pk). TODO(compiler): implement.
// fn x25519_public_key(sk) -> Vec[UInt8] - derive the public key from a secret key. TODO(compiler): implement.
// fn x25519_shared_secret(sk, pk) -> Vec[UInt8] - compute the X25519 shared secret. TODO(compiler): implement.
// fn x25519_base(sk) -> Vec[UInt8] - multiply the base point by sk (public key). TODO(compiler): implement.
// fn ecdh_p256(sk, pk) -> Vec[UInt8] - ECDH shared secret on P-256. TODO(compiler): implement.
// fn ecdh_secp256k1(sk, pk) -> Vec[UInt8] - ECDH shared secret on secp256k1. TODO(compiler): implement.
// fn dh_generate_key(prime: &Vec[UInt8], generator: &Vec[UInt8]) -> Vec[UInt8] - generate a classic DH private key. TODO(compiler): implement.
// fn dh_shared_secret(prime, own_sk, peer_pk) -> Vec[UInt8] - compute the classic DH shared secret. TODO(compiler): implement.
// fn key_agreement_derive(shared, info, len) -> Vec[UInt8] - derive symmetric key bytes from a shared secret. TODO(compiler): implement.
// fn key_agreement_validate(pk) -> Bool - sanity-check a peer public key. TODO(compiler): implement.
