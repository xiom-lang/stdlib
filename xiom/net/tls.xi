// XIOM -- TLS Protocol Helpers (xiom.net.tls)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure TLS version/cipher/alert/handshake name helpers per RFC 5246
// and related RFCs. No network I/O or cryptography is performed here.

module xiom.net.tls

// tls_default_port returns the default TLS port (443).
// Complexity: O(1). Pure.
pub fn tls_default_port() -> Int {
  443
}

// tls_version_name maps a TLS version code point to its name.
// Recognised values: 0x0301 TLSv1.0, 0x0302 TLSv1.1, 0x0303 TLSv1.2,
// 0x0304 TLSv1.3. Unknown values return "unknown". Complexity: O(1).
pub fn tls_version_name(version: Int) -> Str {
  if version == 0x0301 { return "TLSv1.0"; }
  if version == 0x0302 { return "TLSv1.1"; }
  if version == 0x0303 { return "TLSv1.2"; }
  if version == 0x0304 { return "TLSv1.3"; }
  if version == 0x0300 { return "SSLv3"; }
  "unknown"
}

// tls_handshake_type_name maps a TLS handshake message type to its
// name. Complexity: O(1).
pub fn tls_handshake_type_name(t: Int) -> Str {
  if t == 0 { return "hello_request"; }
  if t == 1 { return "client_hello"; }
  if t == 2 { return "server_hello"; }
  if t == 4 { return "new_session_ticket"; }
  if t == 8 { return "encrypted_extensions"; }
  if t == 11 { return "certificate"; }
  if t == 12 { return "server_key_exchange"; }
  if t == 13 { return "certificate_request"; }
  if t == 14 { return "server_hello_done"; }
  if t == 15 { return "certificate_verify"; }
  if t == 16 { return "client_key_exchange"; }
  if t == 20 { return "finished"; }
  if t == 22 { return "certificate_status"; }
  if t == 23 { return "key_update"; }
  "unknown"
}

// tls_alert_name maps a TLS alert description to its name per RFC 5246
// and RFC 8446. Complexity: O(1).
pub fn tls_alert_name(code: Int) -> Str {
  if code == 0 { return "close_notify"; }
  if code == 10 { return "unexpected_message"; }
  if code == 20 { return "bad_record_mac"; }
  if code == 21 { return "decryption_failed"; }
  if code == 22 { return "record_overflow"; }
  if code == 40 { return "handshake_failure"; }
  if code == 42 { return "bad_certificate"; }
  if code == 43 { return "unsupported_certificate"; }
  if code == 44 { return "certificate_revoked"; }
  if code == 45 { return "certificate_expired"; }
  if code == 46 { return "certificate_unknown"; }
  if code == 47 { return "illegal_parameter"; }
  if code == 48 { return "unknown_ca"; }
  if code == 49 { return "access_denied"; }
  if code == 50 { return "decode_error"; }
  if code == 51 { return "decrypt_error"; }
  if code == 70 { return "protocol_version"; }
  if code == 71 { return "insufficient_security"; }
  if code == 80 { return "internal_error"; }
  if code == 86 { return "inappropriate_fallback"; }
  if code == 90 { return "user_canceled"; }
  if code == 100 { return "no_renegotiation"; }
  if code == 110 { return "unsupported_extension"; }
  if code == 112 { return "unrecognized_name"; }
  if code == 113 { return "bad_certificate_status_response"; }
  if code == 116 { return "unknown_psk_identity"; }
  if code == 120 { return "no_application_protocol"; }
  "unknown"
}

// tls_cipher_suite_name maps a TLS cipher suite code to a
// human-readable name for the most common suites, or "unknown" (0x0000-
// 0xFFFF, two-byte IANA code). Complexity: O(1).
pub fn tls_cipher_suite_name(code: Int) -> Str {
  if code == 0x002F { return "TLS_RSA_WITH_AES_128_CBC_SHA"; }
  if code == 0x0035 { return "TLS_RSA_WITH_AES_256_CBC_SHA"; }
  if code == 0x003C { return "TLS_RSA_WITH_AES_128_CBC_SHA256"; }
  if code == 0x009C { return "TLS_RSA_WITH_AES_128_GCM_SHA256"; }
  if code == 0x009D { return "TLS_RSA_WITH_AES_256_GCM_SHA384"; }
  if code == 0xC02F { return "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"; }
  if code == 0xC030 { return "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"; }
  if code == 0xC02B { return "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"; }
  if code == 0xC02C { return "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"; }
  if code == 0xC013 { return "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"; }
  if code == 0xC014 { return "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA"; }
  if code == 0xC027 { return "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"; }
  if code == 0x1301 { return "TLS_AES_128_GCM_SHA256"; }
  if code == 0x1302 { return "TLS_AES_256_GCM_SHA384"; }
  if code == 0x1303 { return "TLS_CHACHA20_POLY1305_SHA256"; }
  "unknown"
}
