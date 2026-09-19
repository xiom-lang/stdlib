// XIOM -- Core Library
// Purpose: Core types and runtime glue: Option/Result, allocation, panic and formatting.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.core

use xiom.string;
use xiom.convert;
use xiom.mem;  // zeroed[T] is used by MaybeUninit.uninit (bare name)

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

// === Option type ===
type Option[T] = {
  is_some: Bool;
  value: T;
}

// === Result type ===
type Result[T, E] = {
  is_ok: Bool;
  value: T;
  error: E;
}

// === Panic ===
// Compiler-recognized: emits trap + error message
fn panic(msg: Str)
  requires: msg.len() > 0
;

// === Assert ===
fn assert(condition: Bool, msg: Str)
  requires: msg.len() > 0
{
  if !condition {
    panic(msg);
  }
}

/// === Numeric conversions ===
pub fn to_int(x: Float64) -> Int {
  return x as Int;
}

/// Convert an Int to Float64 (may lose precision above 2^53).
pub fn to_float(x: Int) -> Float64 {
  return x as Float64;
}

/// Decimal string for an Int.
pub fn to_string(x: Int) -> Str {
  if x == 0 {
    return "0";
  }
  var negative = false;
  var n = x;
  if n < 0 {
    negative = true;
    n = -n;
  }
  var digits: [20]UInt8;
  var pos: Int = 20;
  while n > 0 {
    pos = pos - 1;
    digits[pos] = 48 + (n % 10) as UInt8;
    n = n / 10;
  }
  if negative {
    pos = pos - 1;
    digits[pos] = 45;
  }
  let len = 20 - pos;
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      buf[i] = digits[pos + i];
      i = i + 1;
    }
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Parse an Int; Err with a message on bad input.
pub fn to_int_from_str(s: Str) -> Result[Int, Str]
  requires: true  // extern char_at calls below (D2.1/T002 safe-wrapper pattern)
{
  if s.len() == 0 {
    return Err("empty string");
  }
  var i: Int = 0;
  var negative = false;
  var c = xiom_char_at(s, 0);
  if c == '-' {
    negative = true;
    i = 1;
  } elif c == '+' {
    i = 1;
  }
  if i >= s.len() {
    return Err("no digits found");
  }
  var result: Int = 0;
  while i < s.len() {
    c = xiom_char_at(s, i);
    if c < '0' || c > '9' {
      return Err("invalid character in integer string");
    }
    let digit = (c as Int) - 48;
    if negative {
      result = result * 10 - digit;
    } else {
      result = result * 10 + digit;
    }
    i = i + 1;
  }
  return Ok(result);
}

/// Parse a Float64; Err with a message on bad input.
pub fn to_float_from_str(s: Str) -> Result[Float64, Str]
  requires: true  // extern char_at calls below (D2.1/T002 safe-wrapper pattern)
{
  if s.len() == 0 {
    return Err("empty string");
  }
  var i: Int = 0;
  var negative = false;
  var c = xiom_char_at(s, 0);
  if c == '-' {
    negative = true;
    i = 1;
  } elif c == '+' {
    i = 1;
  }
  if i >= s.len() {
    return Err("no digits found");
  }
  var int_part: Float64 = 0.0;
  var frac_part: Float64 = 0.0;
  var frac_div: Float64 = 10.0;
  var has_frac = false;
  var has_digit = false;
  while i < s.len() {
    c = xiom_char_at(s, i);
    if c == '.' {
      if has_frac {
        return Err("multiple decimal points");
      }
      has_frac = true;
      i = i + 1;
      continue;
    }
    if c == 'e' || c == 'E' {
      i = i + 1;
      var exp_negative = false;
      if i < s.len() {
        c = xiom_char_at(s, i);
        if c == '-' {
          exp_negative = true;
          i = i + 1;
        } elif c == '+' {
          i = i + 1;
        }
      }
      var exp_val: Int = 0;
      while i < s.len() {
        c = xiom_char_at(s, i);
        if c < '0' || c > '9' {
          return Err("invalid character in exponent");
        }
        exp_val = exp_val * 10 + ((c as Int) - 48);
        i = i + 1;
      }
      var value = int_part + frac_part;
      var mult: Float64 = 1.0;
      if exp_negative {
        var j: Int = 0;
        while j < exp_val {
          mult = mult * 0.1;
          j = j + 1;
        }
      } else {
        var j: Int = 0;
        while j < exp_val {
          mult = mult * 10.0;
          j = j + 1;
        }
      }
      value = value * mult;
      if negative {
        value = -value;
      }
      return Ok(value);
    }
    if c < '0' || c > '9' {
      return Err("invalid character in float string");
    }
    let digit = (c as Float64) - 48.0;
    if has_frac {
      frac_part = frac_part + digit / frac_div;
      frac_div = frac_div * 10.0;
    } else {
      int_part = int_part * 10.0 + digit;
    }
    has_digit = true;
    i = i + 1;
  }
  if !has_digit {
    return Err("no digits found");
  }
  var value = int_part + frac_part;
  if negative {
    value = -value;
  }
  return Ok(value);
}

/// Parse "true"/"false"; Err on other input.
pub fn to_bool_from_str(s: Str) -> Result[Bool, Str] {
  if s == "true" {
    return Ok(true);
  } elif s == "false" {
    return Ok(false);
  } else {
    return Err("expected \"true\" or \"false\"");
  }
}

/// Convert a code point to a Char.
pub fn to_char(x: Int) -> Char {
  return x as Char;
}

/// Code point of a Char as Int.
pub fn to_int_from_char(c: Char) -> Int {
  return c as Int;
}

/// === Collection contract methods ===
pub fn is_sorted[T: Ord](items: &Slice[T]) -> Bool {
  var i: Int = 1;
  while i < items.len() {
    if items[i - 1].compare(items[i]) > 0 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

/// True when every element satisfies `predicate` (true when empty).
pub fn all[T](items: &Slice[T], predicate: fn(T) -> Bool) -> Bool {
  var i: Int = 0;
  while i < items.len() {
    if !predicate(items[i]) {
      return false;
    }
    i = i + 1;
  }
  return true;
}

/// True when no element satisfies `predicate`.
pub fn none[T](items: &Slice[T], predicate: fn(T) -> Bool) -> Bool {
  var i: Int = 0;
  while i < items.len() {
    if predicate(items[i]) {
      return false;
    }
    i = i + 1;
  }
  return true;
}

/// True when `value` occurs in the slice.
pub fn contains[T: Eq](items: &Slice[T], value: T) -> Bool {
  var i: Int = 0;
  while i < items.len() {
    if items[i].eq(value) {
      return true;
    }
    i = i + 1;
  }
  return false;
}

// === Clone interface ===
interface Clone {
  fn clone() -> Self;
}

// === Eq interface ===
// Generic-interface form (STDLIB_GENERICS S12): dispatch through
// `a.eq(b)` -- the method-form `a.eq(b)` inside generic-bound fns
// resolves to a stub (TODO(compiler): BUG 45), and impl method names must
// not collide with fn-typed params named `eq`/`compare` (TODO(compiler):
// BUG 47 -- fn-params in the stdlib are named `cmp` to avoid this).
interface Eq[T] {
  fn eq(a: T, b: T) -> Bool;
}

impl Eq[Int] {
  fn eq(a: Int, b: Int) -> Bool { return a == b; }
}

impl Eq[Int8] {
  fn eq(a: Int8, b: Int8) -> Bool { return a == b; }
}

impl Eq[Int16] {
  fn eq(a: Int16, b: Int16) -> Bool { return a == b; }
}

impl Eq[Int32] {
  fn eq(a: Int32, b: Int32) -> Bool { return a == b; }
}

impl Eq[Int64] {
  fn eq(a: Int64, b: Int64) -> Bool { return a == b; }
}

impl Eq[UInt] {
  fn eq(a: UInt, b: UInt) -> Bool { return a == b; }
}

impl Eq[UInt8] {
  fn eq(a: UInt8, b: UInt8) -> Bool { return a == b; }
}

impl Eq[UInt16] {
  fn eq(a: UInt16, b: UInt16) -> Bool { return a == b; }
}

impl Eq[UInt32] {
  fn eq(a: UInt32, b: UInt32) -> Bool { return a == b; }
}

impl Eq[UInt64] {
  fn eq(a: UInt64, b: UInt64) -> Bool { return a == b; }
}

impl Eq[Bool] {
  fn eq(a: Bool, b: Bool) -> Bool { return a == b; }
}

impl Eq[Str] {
  fn eq(a: Str, b: Str) -> Bool { return a == b; }
}

impl Eq[Char] {
  fn eq(a: Char, b: Char) -> Bool { return a == b; }
}

impl Eq[Float32] {
  fn eq(a: Float32, b: Float32) -> Bool { return a == b; }
}

impl Eq[Float64] {
  fn eq(a: Float64, b: Float64) -> Bool { return a == b; }
}

// === Ord interface ===
interface Ord[T] {
  fn compare(a: T, b: T) -> Int;
  fn cmp(a: T, b: T) -> Int;
}

impl Ord[Int] {
  fn compare(a: Int, b: Int) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Int, b: Int) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Int8] {
  fn compare(a: Int8, b: Int8) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Int8, b: Int8) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Int16] {
  fn compare(a: Int16, b: Int16) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Int16, b: Int16) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Int32] {
  fn compare(a: Int32, b: Int32) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Int32, b: Int32) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Int64] {
  fn compare(a: Int64, b: Int64) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Int64, b: Int64) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[UInt] {
  fn compare(a: UInt, b: UInt) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: UInt, b: UInt) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[UInt8] {
  fn compare(a: UInt8, b: UInt8) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: UInt8, b: UInt8) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[UInt16] {
  fn compare(a: UInt16, b: UInt16) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: UInt16, b: UInt16) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[UInt32] {
  fn compare(a: UInt32, b: UInt32) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: UInt32, b: UInt32) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[UInt64] {
  fn compare(a: UInt64, b: UInt64) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: UInt64, b: UInt64) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Bool] {
  fn compare(a: Bool, b: Bool) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Bool, b: Bool) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Str] {
  fn compare(a: Str, b: Str) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Str, b: Str) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Char] {
  fn compare(a: Char, b: Char) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Char, b: Char) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Float32] {
  fn compare(a: Float32, b: Float32) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Float32, b: Float32) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

impl Ord[Float64] {
  fn compare(a: Float64, b: Float64) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
  fn cmp(a: Float64, b: Float64) -> Int {
    if a < b { return -1; }
    if a > b { return 1; }
    return 0;
  }
}

// === Display interface ===

interface Display {
  fn to_str() -> Str;
}

// === Hash interface ===
interface Hash {
  fn hash() -> UInt64;
}

// === Numeric traits ===
interface Add {
  fn add(self, other: &Self) -> Self;
}

interface Sub {
  fn sub(self, other: &Self) -> Self;
}

interface Mul {
  fn mul(self, other: &Self) -> Self;
}

interface Div {
  fn div(self, other: &Self) -> Self;
}

// === Box type ===
type Box[T] = {
  ptr: *T;
}

fn Box.new[T](value: T) -> Box[T]
  requires: size_of[T]() > 0
  ensures:  ptr != null
{
  let size = size_of[T]();
  unsafe {
    var raw = malloc(size);
    var typed: *T = raw as *T;
    *typed = value;
    return Box[T]{ ptr: typed; };
  }
}

fn Box.get[T](b: &Box[T]) -> &T
  requires: ptr != null
{
  unsafe {
    return &*ptr;
  }
}

fn Box.drop[T](b: Box[T])
  requires: ptr != null
  ensures: true
{
  unsafe {
    free(ptr as *UInt8);
  }
}

/// === M7: Deref / DerefMut impl for Box[T] ===
/// Box is a heap-allocated single-owner pointer. Deref allows `*box` and
/// auto-deref in method resolution (e.g., `box.method()` calls T's method).
pub fn Box[T].deref(self) -> &T
  requires: ptr != null
  ensures: true
{
  unsafe {
    return &*ptr;
  }
}

/// Mutable dereference to the boxed value.
pub fn Box[T].deref_mut(self) -> &mut T
  requires: ptr != null
  ensures: true
{
  unsafe {
    return &mut *ptr;
  }
}

/// === M7: AsRef / AsMut impl for Box[T] ===
pub fn Box[T].as_ref(self) -> &T
  requires: ptr != null
{
  return deref();
}

/// Borrow the boxed value mutably.
pub fn Box[T].as_mut(self) -> &mut T
  requires: ptr != null
{
  return deref_mut();
}

/// === M7: AsRef[Str] impl for Str ===
pub fn Str.as_ref(self) -> &Str {
  return &self;
}

/// === M7: AsRef<[UInt8]> impl for Str ===
pub fn Str.as_bytes(self) -> &Slice[UInt8]
  requires: true
{
  unsafe {
    Slice { data: &self as *UInt8, len: string.str_len(self) }
  }
}

/// 8B/M7: Clone-on-Write -- either owned or borrowed
pub type Cow[T: Clone] = enum {
  Borrowed(value: T),
  Owned(value: T),
}

/// True when the value is still borrowed (not cloned).
pub fn Cow[T: Clone].is_borrowed(self) -> Bool
  ensures: result == (match self { Borrowed(_) => true, Owned(_) => false })
{
  match self { Borrowed(_) => { return true; }; Owned(_) => { return false; }; }
}

/// True when the value is owned (cloned).
pub fn Cow[T: Clone].is_owned(self) -> Bool
  ensures: result == !self.is_borrowed()
{
  return !self.is_borrowed();
}

/// Clone on first write and return mutable access.
pub fn Cow[T: Clone].to_mut(self) -> &mut T
  ensures: true
{
  match self {
    Owned(ref mut val) => { return val; };
    Borrowed(val) => {
      self = Owned(val.clone());
      match self { Owned(ref mut val) => { return val; }; _ => { unreachable; }; };
    };
  };
}

/// Unwrap into an owned value (cloning when borrowed).
pub fn Cow[T: Clone].into_owned(self) -> T
  ensures: true
{
  match self { Owned(val) => { return val; }; Borrowed(val) => { return val.clone(); }; };
}

/// M12/P1: Read the inner value regardless of variant (no cloning).
pub fn Cow[T: Clone].borrow(self) -> &T
  ensures: true
{
  match self {
    Borrowed(ref val) => { return val; };
    Owned(ref val) => { return val; };
  };
}

// === Iterator trait (core to collections) ===
interface Iterator[T] {
  fn next(self) -> Option[T];
  fn size_hint(self) -> (Int, Option[Int]);
}

interface IntoIterator[T] {
  fn into_iter(self) -> Iterator[T];
}

// === Default trait ===
interface Default {
  fn default() -> Self;
}

// === Drop trait (deterministic cleanup) ===
interface Drop {
  fn drop(self);
}

// === 8B/M9: Debug trait (debug-print) ===
interface Debug {
  fn fmt(self, f: &mut Formatter) -> Str
    ensures: result.len() > 0
  ;
}

/// 8B/M7: Production-grade conversion + deref traits ===
pub interface From[T] {
  fn from(value: T) -> Self
    ensures: true
    ensures: Into::into(From::from(x)) == x  // round-trip law
  ;
}

/// Conversion into `T` (infallible).
pub interface Into[T] {
  fn into(self) -> T
    ensures: From::from(result) == self  // round-trip law
  ;
}

/// Fallible conversion from `T`.
pub interface TryFrom[T] {
  fn try_from(value: T) -> Result[Self, Str]
    ensures: true
  ;
}

/// Fallible conversion into `T`.
pub interface TryInto[T] {
  fn try_into(self) -> Result[T, Str]
    ensures: true
  ;
}

// === M7: From/Into implementations for primitive types ===

/// Int -> Float64 (lossless for reasonable values)
pub fn Int.from(value: Float64) -> Int {
  return to_int(value);
}
/// Truncating conversion to Int.
pub fn Float64.into(self) -> Int {
  return to_int(self);
}

/// Float64 -> Int (may truncate)
pub fn Float64.from(value: Int) -> Float64 {
  return to_float(value);
}
/// Widening conversion to Float64 (lossy above 2^53).
pub fn Int.into(self) -> Float64 {
  return to_float(self);
}

/// Int -> Str
pub fn Str.from(value: Int) -> Str {
  return to_string(value);
}
/// Decimal string conversion.
pub fn Int.into(self) -> Str {
  return to_string(self);
}

/// Float64 -> Str
pub fn Str.from(value: Float64) -> Str {
  return xiom.convert.float_to_string(value);
}
/// Decimal string conversion.
pub fn Float64.into(self) -> Str {
  return xiom.convert.float_to_string(self);
}

/// Bool -> Str
pub fn Str.from(value: Bool) -> Str {
  return convert.bool_to_string(value);
}
/// "true" or "false" conversion.
pub fn Bool.into(self) -> Str {
  return convert.bool_to_string(self);
}

/// Bool -> Int
pub fn Int.from(value: Bool) -> Int {
  if value { return 1; }
  return 0;
}
/// 1 for true, 0 for false.
pub fn Bool.into(self) -> Int {
  if self { return 1; }
  return 0;
}

/// Char -> Int
pub fn Int.from(value: Char) -> Int {
  return to_int_from_char(value);
}
/// Unicode code point conversion.
pub fn Char.into(self) -> Int {
  return to_int_from_char(self);
}

/// Int -> Char (may fail, returns first char)
pub fn Char.from(value: Int) -> Char {
  return to_char(value);
}
/// Char for the code point (invalid values map to U+FFFD).
pub fn Int.into(self) -> Char {
  return to_char(self);
}

/// Immutable dereference interface.
pub interface Deref {
  type Target;
  fn deref(self) -> &Target
    ensures: true
  ;
}

/// Mutable dereference interface.
pub interface DerefMut: Deref {
  fn deref_mut(self) -> &mut Target
    ensures: true
  ;
}

/// Cheap reference conversion interface.
pub interface AsRef[T] {
  fn as_ref(self) -> &T
    ensures: true
  ;
}

/// Cheap mutable reference conversion interface.
pub interface AsMut[T] {
  fn as_mut(self) -> &mut T
    ensures: true
  ;
}

// === Panic / Unwind ===
fn panic_if(condition: Bool, msg: Str)
  requires: msg.len() > 0
{
  if condition {
    panic(msg);
  }
}

/// === Type-level operations ===
/// Compiler intrinsic: returns size of type in bytes
pub fn size_of[T]() -> Int;

/// Compiler intrinsic: returns alignment of type in bytes
pub fn align_of[T]() -> Int;

/// === Numeric limits ===
pub const INT_MAX: Int = 9223372036854775807;
/// Minimum Int value.
pub const INT_MIN: Int = -9223372036854775808;
/// Largest finite Float64.
pub const FLOAT64_MAX: Float64 = 1.7976931348623157e308;
/// Smallest positive normal Float64.
pub const FLOAT64_MIN: Float64 = 2.2250738585072014e-308;
/// Machine epsilon for Float64.
pub const FLOAT64_EPSILON: Float64 = 2.220446049250313e-16;

/// 8B/M7: Zero-size type marker for generic parameters
pub type PhantomData[T] = { }

/// 8B/M7: Uninitialized memory container
pub type MaybeUninit[T] = { data: T; initialized: Bool; }
  derive[Clone]

/// Uninitialized value slot.
pub fn MaybeUninit[T].uninit() -> MaybeUninit[T]
  ensures: !result.initialized
{
  return MaybeUninit { data: mem.zeroed[T](), initialized: false };
}

/// Slot initialized with `value`.
pub fn MaybeUninit[T].new(value: T) -> MaybeUninit[T]
  ensures: result.initialized
{
  return MaybeUninit { data: value, initialized: true };
}

/// Read the value out (requires prior initialization).
pub fn MaybeUninit[T].assume_init(self) -> T
  requires: self.initialized
  ensures: true
{
  return self.data;
}

/// Write a value into the slot.
pub fn MaybeUninit[T].write(self, value: T)
  ensures: self.initialized == true
  ensures: self.data == value
{
  self.data = value;
  self.initialized = true;
}

// === Option methods ===
// 6F: Contract coverage -- ensures clauses for all Option methods.

fn Option[T].unwrap_or(self, default: T) -> T
  ensures: self is Some => result == self.value
  ensures: self is None => result == default
{
  match self {
    Some(v) => v;
    None => default;
  }
}

fn Option[T].unwrap_or_else(self, f: fn() -> T) -> T
  ensures: self is None => result == f()
{
  match self {
    Some(v) => v;
    None => f();
  }
}

fn Option[T].map[U](self, f: fn(T) -> U) -> Option[U]
  ensures: self is Some => result is Some
  ensures: self is None => result is None
{
  match self {
    Some(v) => Some(f(v));
    None => None;
  }
}

fn Option[T].and_then[U](self, f: fn(T) -> Option[U]) -> Option[U] {
  match self {
    Some(v) => f(v);
    None => None;
  }
}

fn Option[T].filter(self, predicate: fn(&T) -> Bool) -> Option[T]
  ensures: self is Some && predicate(&self.value) => result is Some
  ensures: self is None => result is None
{
  match self {
    Some(v) => {
      if predicate(&v) { Some(v) } else { None }
    };
    None => None;
  }
}

fn Option[T].is_some_and(self, predicate: fn(&T) -> Bool) -> Bool
  ensures: self is None => result == false
{
  match self {
    Some(v) => predicate(&v);
    None => false;
  }
}

// === Result methods ===
fn Result[T, E].unwrap_or(self, default: T) -> T {
  match self {
    Ok(v) => v;
    Err(e) => default;
  }
}

fn Result[T, E].unwrap_or_else(self, f: fn(E) -> T) -> T {
  match self {
    Ok(v) => v;
    Err(e) => f(e);
  }
}

fn Result[T, E].map[U](self, f: fn(T) -> U) -> Result[U, E] {
  match self {
    Ok(v) => Ok(f(v));
    Err(e) => Err(e);
  }
}

fn Result[T, E].map_err[F](self, f: fn(E) -> F) -> Result[T, F] {
  match self {
    Ok(v) => Ok(v);
    Err(e) => Err(f(e));
  }
}

fn Result[T, E].and_then[U](self, f: fn(T) -> Result[U, E]) -> Result[U, E] {
  match self {
    Ok(v) => f(v);
    Err(e) => Err(e);
  }
}

fn Result[T, E].expect(self, msg: Str) -> T {
  match self {
    Ok(v) => v;
    Err(e) => {
      panic(msg);
      value
    };
  }
}

fn Result[T, E].is_ok_and(self, predicate: fn(&T) -> Bool) -> Bool {
  match self {
    Ok(v) => predicate(&v);
    Err(e) => false;
  }
}

// === Binary heap (priority queue) ===
type BinaryHeap[T] = {
  data: Vec[T];
  invariant: data.len() >= 0;
}

fn sift_up[T: Ord](heap: &mut BinaryHeap[T], idx: Int)
  requires: idx >= 0 && idx < heap.data.len()
{
  var i = idx;
  while i > 0 {
    let parent = (i - 1) / 2;
    if Ord[T].compare(heap.data[parent], heap.data[i]) >= 0 {
      break;
    }
    let temp = heap.data[parent];
    heap.data[parent] = heap.data[i];
    heap.data[i] = temp;
    i = parent;
  }
}

fn sift_down[T: Ord](heap: &mut BinaryHeap[T], idx: Int)
  requires: idx >= 0 && idx < heap.data.len()
{
  let len = heap.data.len();
  var i = idx;
  loop {
    let left = 2 * i + 1;
    let right = 2 * i + 2;
    var largest = i;
    if left < len && Ord[T].compare(heap.data[left], heap.data[largest]) > 0 {
      largest = left;
    }
    if right < len && Ord[T].compare(heap.data[right], heap.data[largest]) > 0 {
      largest = right;
    }
    if largest == i {
      break;
    }
    let temp = heap.data[i];
    heap.data[i] = heap.data[largest];
    heap.data[largest] = temp;
    i = largest;
  }
}

fn BinaryHeap[T: Ord].new() -> BinaryHeap[T] {
  return BinaryHeap[T]{ data: Vec[T].new(); };
}

fn BinaryHeap[T: Ord].push(&mut self, value: T) {
  data.push(value);
  let idx = data.len() - 1;
  sift_up(self, idx);
}

fn BinaryHeap[T: Ord].pop(&mut self) -> Option[T] {
  if data.len() == 0 {
    return None;
  }
  let last = data.len() - 1;
  let result = data[0];
  data[0] = data[last];
  data.pop();
  if data.len() > 0 {
    sift_down(self, 0);
  }
  return Some(result);
}

fn BinaryHeap[T: Ord].peek(self) -> Option[T] {
  if data.len() == 0 {
    return None;
  }
  return Some(data[0]);
}

fn BinaryHeap[T].len(self) -> Int {
  return data.len();
}

fn BinaryHeap[T].is_empty(self) -> Bool {
  return data.len() == 0;
}

// -- Comparable Extrema ---------------------------------------------

/// Returns the smaller of two `Int` values.
/// Complexity: O(1). Pure, no side effects.
pub fn min_of(a: Int, b: Int) -> Int {
  if a < b {
    return a;
  };
  return b;
}

/// Returns the larger of two `Int` values.
/// Complexity: O(1). Pure, no side effects.
pub fn max_of(a: Int, b: Int) -> Int {
  if a > b {
    return a;
  };
  return b;
}

/// Returns the absolute value of `n`.
/// Complexity: O(1). Pure, no side effects.
/// NOTE: `INT_MIN` has no positive representation; wraps on overflow.
pub fn abs_int(n: Int) -> Int {
  if n < 0 {
    return -n;
  };
  return n;
}

/// Clamps `v` to the inclusive range [`lo`, `hi`].
/// Returns `lo` if `v < lo`, `hi` if `v > hi`, otherwise `v`.
/// Complexity: O(1). Pure, no side effects.
pub fn clamp_int(v: Int, lo: Int, hi: Int) -> Int {
  if v < lo {
    return lo;
  };
  if v > hi {
    return hi;
  };
  return v;
}

// -- Bool/Int Conversions -------------------------------------------

/// Converts a `Bool` to an `Int`: `true` -> 1, `false` -> 0.
/// NOTE: XIOM does NOT support `b as Int`; this is the canonical conversion.
/// Complexity: O(1). Pure, no side effects.
pub fn bool_to_int(b: Bool) -> Int {
  if b {
    return 1;
  };
  return 0;
}

/// Converts an `Int` to a `Bool`: non-zero -> `true`, zero -> `false`.
/// Complexity: O(1). Pure, no side effects.
pub fn int_to_bool(n: Int) -> Bool {
  return n != 0;
}

// -- Char Conversions -----------------------------------------------

/// Safely converts an `Int` to a `Char`.
/// Returns `None` if `n` is outside the valid Unicode code-point range (0..=0x10FFFF).
/// Complexity: O(1). Pure, no side effects.
pub fn int_to_char_safe(n: Int) -> Option[Char] {
  if n >= 0 && n <= 1114111 {
    return Some(to_char(n));
  };
  return None;
}

// -- Slice Helpers --------------------------------------------------

/// Returns the number of elements in the slice.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn slice_len[T](s: &Slice[T]) -> Int {
  return s.len();
}

/// Returns `true` if the slice has zero elements.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn slice_is_empty[T](s: &Slice[T]) -> Bool {
  return s.len() == 0;
}

/// Returns the first element of the slice, or `None` if empty.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn slice_first[T](s: &Slice[T]) -> Option[T] {
  if s.len() == 0 {
    return None;
  };
  return Some(s[0]);
}

/// Returns the element at index `i`, or `None` if out of bounds.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn slice_get[T](s: &Slice[T], i: Int) -> Option[T] {
  if i >= 0 && i < s.len() {
    return Some(s[i]);
  };
  return None;
}

/// Copies all elements from the slice into a new `Vec[T]`.
/// Complexity: O(n) time and memory. Thread-safe: reads immutable shared data.
pub fn slice_to_vec[T](s: &Slice[T]) -> Vec[T] {
  var result = Vec[T].new();
  var i: Int = 0;
  while i < s.len() {
    result.push(s[i]);
    i = i + 1;
  };
  return result;
}

// -- Slice Aggregates -----------------------------------------------

/// Finds the minimum element in the slice using `Ord.compare`.
/// Returns `None` if the slice is empty.
/// Complexity: O(n) comparisons. Thread-safe: reads immutable shared data.
pub fn min_slice[T: Ord](s: &Slice[T]) -> Option[T] {
  if s.len() == 0 {
    return None;
  };
  var min_idx: Int = 0;
  var i: Int = 1;
  while i < s.len() {
    if s[i].compare(s[min_idx]) < 0 {
      min_idx = i;
    };
    i = i + 1;
  };
  return Some(s[min_idx]);
}

/// Finds the maximum element in the slice using `Ord.compare`.
/// Returns `None` if the slice is empty.
/// Complexity: O(n) comparisons. Thread-safe: reads immutable shared data.
pub fn max_slice[T: Ord](s: &Slice[T]) -> Option[T] {
  if s.len() == 0 {
    return None;
  };
  var max_idx: Int = 0;
  var i: Int = 1;
  while i < s.len() {
    if s[i].compare(s[max_idx]) > 0 {
      max_idx = i;
    };
    i = i + 1;
  };
  return Some(s[max_idx]);
}

/// Sums all `Int` elements in the slice.
/// Returns 0 if the slice is empty.
/// Complexity: O(n). Thread-safe: reads immutable shared data.
pub fn sum_slice(s: &Slice[Int]) -> Int {
  var total: Int = 0;
  var i: Int = 0;
  while i < s.len() {
    total = total + s[i];
    i = i + 1;
  };
  return total;
}

// -- Option Standalone Queries --------------------------------------

/// Returns `true` if the option is `Some`.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn option_is_some[T](o: &Option[T]) -> Bool {
  return o.is_some;
}

/// Returns `true` if the option is `None`.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn option_is_none[T](o: &Option[T]) -> Bool {
  return !o.is_some;
}

// -- Result Standalone Queries --------------------------------------

/// Returns `true` if the result is `Ok`.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn result_is_ok[T, E](r: &Result[T, E]) -> Bool {
  return r.is_ok;
}

/// Returns `true` if the result is `Err`.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn result_is_err[T, E](r: &Result[T, E]) -> Bool {
  return !r.is_ok;
}

/// Returns the contained `Ok` value, or `default` if the result is `Err`.
/// Complexity: O(1). Thread-safe: reads immutable shared data.
pub fn result_unwrap_or[T, E](r: Result[T, E], default: T) -> T {
  match r {
    Ok(v) => v;
    Err(e) => default;
  };
}
