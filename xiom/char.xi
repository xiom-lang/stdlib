// XIOM — Character Operations
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.char

pub fn is_alphabetic(c: Char) -> Bool;
pub fn is_alphanumeric(c: Char) -> Bool;
pub fn is_ascii(c: Char) -> Bool;
pub fn is_control(c: Char) -> Bool;
pub fn is_digit(c: Char) -> Bool;
pub fn is_lowercase(c: Char) -> Bool;
pub fn is_uppercase(c: Char) -> Bool;
pub fn is_numeric(c: Char) -> Bool;
pub fn is_punctuation(c: Char) -> Bool;
pub fn is_whitespace(c: Char) -> Bool;

pub fn to_lowercase(c: Char) -> Char;
pub fn to_uppercase(c: Char) -> Char;
pub fn to_digit(c: Char, radix: Int) -> Option[Int];
pub fn from_digit(n: Int, radix: Int) -> Option[Char];

pub fn len_utf8(c: Char) -> Int;
pub fn encode_utf8(c: Char, buf: &mut Vec[UInt8]);
