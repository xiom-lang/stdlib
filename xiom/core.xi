// XIOM — Core Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.core

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
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
fn panic(msg: Str);

// === Assert ===
fn assert(condition: Bool, msg: Str) {
  if !condition {
    panic(msg);
  }
}

// === Numeric conversions ===
fn to_int(x: Float64) -> Int {
  return x as Int;
}

fn to_float(x: Int) -> Float64 {
  return x as Float64;
}

fn to_string(x: Int) -> Str {
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

fn to_int_from_str(s: Str) -> Result[Int, Str] {
  if s.len() == 0 {
    return Err("empty string");
  }
  var i: Int = 0;
  var negative = false;
  var c = s.char_at(0);
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
    c = s.char_at(i);
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

fn to_float_from_str(s: Str) -> Result[Float64, Str] {
  if s.len() == 0 {
    return Err("empty string");
  }
  var i: Int = 0;
  var negative = false;
  var c = s.char_at(0);
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
    c = s.char_at(i);
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
        c = s.char_at(i);
        if c == '-' {
          exp_negative = true;
          i = i + 1;
        } elif c == '+' {
          i = i + 1;
        }
      }
      var exp_val: Int = 0;
      while i < s.len() {
        c = s.char_at(i);
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

fn to_bool_from_str(s: Str) -> Result[Bool, Str] {
  if s == "true" {
    return Ok(true);
  } elif s == "false" {
    return Ok(false);
  } else {
    return Err("expected \"true\" or \"false\"");
  }
}

fn to_char(x: Int) -> Char {
  return x as Char;
}

fn to_int_from_char(c: Char) -> Int {
  return c as Int;
}

// === Collection contract methods ===
fn is_sorted[T: Ord](items: &Slice[T]) -> Bool {
  var i: Int = 1;
  while i < items.len() {
    if items[i - 1].compare(&items[i]) > 0 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn all[T](items: &Slice[T], predicate: fn(T) -> Bool) -> Bool {
  var i: Int = 0;
  while i < items.len() {
    if !predicate(items[i]) {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn none[T](items: &Slice[T], predicate: fn(T) -> Bool) -> Bool {
  var i: Int = 0;
  while i < items.len() {
    if predicate(items[i]) {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn contains[T: Eq](items: &Slice[T], value: T) -> Bool {
  var i: Int = 0;
  while i < items.len() {
    if items[i].eq(&value) {
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
interface Eq {
  fn eq(other: &Self) -> Bool;
}

// === Ord interface ===
interface Ord {
  fn compare(other: &Self) -> Int;
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

fn Box.new[T](value: T) -> Box[T] {
  let size = size_of[T]();
  unsafe {
    var raw = malloc(size);
    var typed: *T = raw as *T;
    *typed = value;
    return Box[T]{ ptr: typed; };
  }
}

fn Box.get[T](b: &Box[T]) -> &T {
  unsafe {
    return &*ptr;
  }
}

fn Box.drop[T](b: Box[T]) {
  unsafe {
    free(ptr as *UInt8);
  }
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

// === Panic / Unwind ===
fn panic_if(condition: Bool, msg: Str) {
  if condition {
    panic(msg);
  }
}

// === Type-level operations ===
// Compiler intrinsic: returns size of type in bytes
fn size_of[T]() -> Int;

// Compiler intrinsic: returns alignment of type in bytes
fn align_of[T]() -> Int;

// === Numeric limits ===
const INT_MAX: Int = 9223372036854775807;
const INT_MIN: Int = -9223372036854775808;
const FLOAT64_MAX: Float64 = 1.7976931348623157e308;
const FLOAT64_MIN: Float64 = 2.2250738585072014e-308;
const FLOAT64_EPSILON: Float64 = 2.220446049250313e-16;

// === Option methods ===
fn Option[T].unwrap_or(self, default: T) -> T {
  match self {
    Some(v) => v;
    None => default;
  }
}

fn Option[T].unwrap_or_else(self, f: fn() -> T) -> T {
  match self {
    Some(v) => v;
    None => f();
  }
}

fn Option[T].map[U](self, f: fn(T) -> U) -> Option[U] {
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

fn Option[T].filter(self, predicate: fn(&T) -> Bool) -> Option[T] {
  match self {
    Some(v) => {
      if predicate(&v) {
        Some(v)
      } else {
        None
      }
    };
    None => None;
  }
}

fn Option[T].is_some_and(self, predicate: fn(&T) -> Bool) -> Bool {
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
type BinaryHeap[T] = { data: Vec[T]; }

fn sift_up[T: Ord](heap: &mut BinaryHeap[T], idx: Int) {
  var i = idx;
  while i > 0 {
    let parent = (i - 1) / 2;
    if heap.data[parent].compare(&heap.data[i]) >= 0 {
      break;
    }
    let temp = heap.data[parent];
    heap.data[parent] = heap.data[i];
    heap.data[i] = temp;
    i = parent;
  }
}

fn sift_down[T: Ord](heap: &mut BinaryHeap[T], idx: Int) {
  let len = heap.data.len();
  var i = idx;
  loop {
    let left = 2 * i + 1;
    let right = 2 * i + 2;
    var largest = i;
    if left < len && heap.data[left].compare(&heap.data[largest]) > 0 {
      largest = left;
    }
    if right < len && heap.data[right].compare(&heap.data[largest]) > 0 {
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

fn BinaryHeap[T: Ord].push(self, value: T) {
  data.push(value);
  let idx = data.len() - 1;
  sift_up(self, idx);
}

fn BinaryHeap[T: Ord].pop(self) -> Option[T] {
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
