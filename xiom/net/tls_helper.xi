// XIOM - Networking: TLS Certificate Helpers
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.tls_helper

// Depends on: xiom.net + xiom.string

// ============================================================================
// X.509 certificate and PEM/DER helper utilities. NOTE: full TLS is a separate
// package - this sublib only stubs the certificate/helper utilities. Current
// implementation lives in net.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn cert_fingerprint_sha256(der: &Vec[UInt8]) -> Vec[UInt8] - SHA-256 fingerprint of a DER certificate. TODO(compiler): implement.
// fn cert_fingerprint_sha1(der) -> Vec[UInt8] - SHA-1 fingerprint of a DER certificate. TODO(compiler): implement.
// fn cert_validity_dates(der) -> Result[(Str, Str), Str] - validity period; the tuple is (not_before, not_after). TODO(compiler): implement.
// fn cert_subject_cn(der) -> Result[Str, Str] - the common name of the certificate subject. TODO(compiler): implement.
// fn cert_issuer_cn(der) -> Result[Str, Str] - the common name of the certificate issuer. TODO(compiler): implement.
// fn cert_public_key_info(der) -> Result[(Str, Int), Str] - public key metadata; the tuple is (algorithm, bits). TODO(compiler): implement.
// fn cert_is_self_signed(der) -> Bool - true when subject equals issuer. TODO(compiler): implement.
// fn pem_encode(der: &Vec[UInt8], label: Str) -> Str - wrap DER bytes in a PEM armor with the given label. TODO(compiler): implement.
// fn pem_decode(pem: Str) -> Result[Vec[UInt8], Str] - strip PEM armor and return the DER bytes. TODO(compiler): implement.
// fn pem_parse_certificates(pem) -> Result[Vec[Vec[UInt8]], Str] - extract every certificate block from a PEM string. TODO(compiler): implement.
// fn der_length_decode(data: &Vec[UInt8], pos: Int) -> Result[(Int, Int), Str] - read a DER length at pos; the tuple is (length, bytes_consumed). TODO(compiler): implement.
// fn asn1_read_oid(data, pos) -> Result[(Vec[Int], Int), Str] - read an ASN.1 object identifier at pos; the tuple is (oid, next_pos). TODO(compiler): implement.
