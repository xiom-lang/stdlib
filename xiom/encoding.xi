// XIOM — Encoding Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.encoding

// === Base64 ===
pub fn base64_encode(data: &Vec[UInt8]) -> Str;
pub fn base64_decode(encoded: Str) -> Result<Vec[UInt8], Str>;
pub fn base64url_encode(data: &Vec[UInt8]) -> Str;
pub fn base64url_decode(encoded: Str) -> Result<Vec[UInt8], Str>;

// === Hex ===
pub fn hex_encode(data: &Vec[UInt8]) -> Str;
pub fn hex_decode(encoded: Str) -> Result<Vec[UInt8], Str>;
pub fn hex_encode_upper(data: &Vec[UInt8]) -> Str;

// === URL encoding ===
pub fn url_encode(data: Str) -> Str;
pub fn url_decode(encoded: Str) -> Result<Str, Str>;

// === Percent encoding ===
pub fn percent_encode(data: Str) -> Str;
pub fn percent_decode(encoded: Str) -> Result<Str, Str>;

// === UTF-8 ===
pub fn utf8_encode(s: Str) -> Vec[UInt8];
pub fn utf8_decode(data: &Vec[UInt8]) -> Result<Str, Str>;
pub fn utf8_valid(data: &Vec[UInt8]) -> Bool;
pub fn utf8_char_len(first_byte: UInt8) -> Int;

// === Binary to text ===
pub fn binary_to_text(data: &Vec[UInt8], format: Int) -> Str; // 0=base64, 1=hex, 2=base64url
pub fn text_to_binary(text: Str, format: Int) -> Result<Vec[UInt8], Str>;
