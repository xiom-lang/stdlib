// XIOM — Serialization Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// derive[Serialize, Deserialize] with contract preservation.
// A deserialized struct is validated against its invariants.

module xiom.serialize

// === Serialize trait ===
pub interface Serialize {
  fn serialize(self) -> Result[Str, SerializeError];
  fn serialize_json(self) -> Result[Str, SerializeError];
  fn serialize_bytes(self) -> Result[Vec[UInt8], SerializeError];
}

// === Deserialize trait (with contract preservation) ===
pub interface Deserialize {
  fn deserialize(data: Str) -> Result[Self, SerializeError]
    ensures: result is Ok => self.invariant_check()
  fn deserialize_json(data: Str) -> Result[Self, SerializeError]
    ensures: result is Ok => self.invariant_check()
  fn deserialize_bytes(data: Vec[UInt8]) -> Result[Self, SerializeError]
    ensures: result is Ok => self.invariant_check()
}

// === Error type ===
pub type SerializeError = {
  kind: Int;
  message: Str;
  path: Str;
  line: Int;
  col: Int;
} derive[Eq, Clone, Display]

// Error kinds: 0=Unknown, 1=InvalidFormat, 2=MissingField, 3=TypeMismatch, 4=ContractViolation, 5=UnsupportedType

pub fn SerializeError.format_error() -> Str { return "TODO"; }

// === Format detection ===
pub fn detect_format(data: &Vec[UInt8]) -> Str;
pub fn is_valid_json(data: Str) -> Bool;
pub fn is_valid_bytes(data: &Vec[UInt8]) -> Bool;

// === JSON helpers ===
pub fn json_string(s: Str) -> Str;
pub fn json_number(n: Float64) -> Str;
pub fn json_bool(b: Bool) -> Str;
pub fn json_null() -> Str;
pub fn json_array(items: Vec[Str]) -> Str;
pub fn json_object(pairs: Vec[(Str, Str)]) -> Str;
pub fn json_parse(data: Str) -> Result[JsonValue, SerializeError];

pub type JsonValue = enum {
  Null,
  Bool(value: Bool),
  Number(value: Float64),
  String(value: Str),
  Array(items: Vec<JsonValue>),
  Object(entries: Map[Str, JsonValue]),
}

// === Binary helpers ===
pub fn little_endian() -> Bool;
pub fn big_endian() -> Bool;
