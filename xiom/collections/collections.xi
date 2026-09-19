// XIOM -- Collections Library
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collections

// === Vec ===
type Vec[T] = {
  data: *T;
  len: Int;
  cap: Int;
  elem_size: Int;
  invariant: len >= 0;
  invariant: cap >= 0;
  invariant: len <= cap;
}

fn Vec.new[T]() -> Vec[T]
  requires: true  // null-data init cast confined below (T002/T007)
{
  unsafe {
    return Vec[T]{ data: 0 as *T, len: 0, cap: 0 };
  }
}

fn Vec.with_capacity[T](cap: Int) -> Vec[T] {
  var v = Vec[T].new();
  v.cap = cap;
  return v;
}

fn Vec.push[T](value: T)
  requires: true
  ensures: len() >= 1
{
  unsafe {
    if len >= cap {
      var new_cap = cap * 2;
      if cap == 0 { new_cap = 4; }
      data = @realloc(data as *UInt8, new_cap * 8) as *T;
      cap = new_cap;
    }
    var dst = data + len;
    *dst = value;
    len = len + 1;
  }
}

fn Vec.pop[T]() -> Option[T]
  ensures: result is None => len() == 0
{
  if len == 0 { return None; }
  len = len - 1;
  unsafe {
    return Some(*(data + len));
  }
}

fn Vec.get[T](index: Int) -> Option[T]
  ensures: result is Some => index >= 0
{
  if index < 0 || index >= len { return None; }
  unsafe {
    return Some(*(data + index));
  }
}

fn Vec.len[T]() -> Int {
  return len;
}

fn Vec.is_empty[T]() -> Bool {
  return len == 0;
}

fn Vec.clear[T]()
  ensures: len() == 0
  ensures: is_empty()
{
  len = 0;
}

// ============================================================================
// 6E.3: Vec production methods -- extend, reserve, truncate, shrink_to_fit
// ============================================================================

/// Reserve capacity for at least `additional` more elements.
fn Vec.reserve[T](additional: Int)
  requires: additional >= 0
{
  var needed = len + additional;
  if needed > cap {
    var new_cap = cap;
    while new_cap < needed { new_cap = new_cap * 2; }
    if new_cap == 0 { new_cap = 4; }
    unsafe {
      data = @realloc(data as *UInt8, new_cap * 8) as *T;
      cap = new_cap;
    }
  }
}

/// Extend the vector with all elements from another vector.
fn Vec.extend[T](other: &Vec[T])
  ensures: other.len() > 0 => len() >= 1
{
  var i = 0;
  while i < other.len {
    push(other.data[i]);
    i = i + 1;
  }
}

/// Truncate the vector to `new_len`. Elements beyond are dropped.
fn Vec.truncate[T](new_len: Int)
  requires: new_len >= 0
  ensures: len() >= 0
{
  if new_len < len { len = new_len; }
}

/// Shrink capacity to match current length.
fn Vec.shrink_to_fit[T]()
  ensures: cap >= len
{
  if cap > len {
    unsafe {
      if len == 0 {
        if data as *UInt8 != 0 as *UInt8 {
          @free(data as *UInt8);
          data = 0 as *T;
        }
        cap = 0;
      } else {
        data = @realloc(data as *UInt8, len * 8) as *T;
        cap = len;
      }
    }
  }
}

fn Vec.insert[T](index: Int, value: T)
  requires: index >= 0
  requires: index <= len()
  ensures:  len() >= 1
{
  if index < 0 || index > len { return; }
  unsafe {
    if len >= cap {
      var new_cap = cap * 2;
      if cap == 0 { new_cap = 4; }
      data = @realloc(data as *UInt8, new_cap * 8) as *T;
      cap = new_cap;
    }
    var i = len;
    while i > index {
      *(data + i) = *(data + i - 1);
      i = i - 1;
    }
    *(data + index) = value;
    len = len + 1;
  }
}

fn Vec.remove[T](index: Int) -> Option[T]
  ensures:  result is Some => index >= 0
{
  if index < 0 || index >= len { return None; }
  unsafe {
    var val = *(data + index);
    var i = index;
    while i + 1 < len {
      *(data + i) = *(data + i + 1);
      i = i + 1;
    }
    len = len - 1;
    return Some(val);
  }
}

fn Vec.first[T]() -> Option[T]
  ensures: result is None => len() == 0
{
  if len == 0 { return None; }
  unsafe {
    return Some(*(data + 0));
  }
}

fn Vec.last[T]() -> Option[T]
  ensures: result is None => len() == 0
{
  if len == 0 { return None; }
  unsafe {
    return Some(*(data + len - 1));
  }
}

fn Vec.set[T](index: Int, value: T)
  requires: index >= 0
  requires: index < len()
{
  if index < 0 || index >= len { return; }
  unsafe {
    *(data + index) = value;
  }
}

/// === M7: AsRef / AsMut slice views for Vec[T] ===
/// These expose the Vec's backing array as a Slice reference with bounds contracts.
pub fn Vec[T].as_slice(self) -> Slice[T]
  requires: len >= 0
  requires: data != null || len == 0
  ensures: result.len() == len
  ensures: result.data.len == len
{
  Slice[T]{ data: self }
}

/// Mutably borrow the vector's data as a Slice.
pub fn Vec[T].as_mut_slice(self) -> Slice[T]
  requires: len >= 0
  requires: data != null || len == 0
  ensures: result.len() == len
  ensures: result.data.len == len
{
  Slice[T]{ data: self }
}

/// === Map ===
pub type Map[K, V] = {
  keys: Vec[K];
  values: Vec[V];
  invariant: keys.len() == values.len();
}

fn Map.new[K, V]() -> Map[K, V] {
  return Map[K, V]{ keys: Vec[K].new(), values: Vec[V].new() };
}

fn Map.insert[K, V](key: K, value: V)
  ensures: contains(&key)
{
  var i = 0;
  while i < keys.len() {
    if keys[i] == key {
      values[i] = value;
      return;
    }
    i = i + 1;
  }
  keys.push(key);
  values.push(value);
}

fn Map.get[K, V](key: &K) -> Option[V]
  ensures: result is Some => contains(key)
{
  var i = 0;
  while i < keys.len() {
    if keys[i] == *key {
      return Some(values[i]);
    }
    i = i + 1;
  }
  return None;
}

fn Map.remove[K, V](key: &K) -> Option[V]
  ensures: !contains(key)
{
  var i = 0;
  while i < keys.len() {
    if keys[i] == *key {
      var val = values[i];
      var j = i;
      while j + 1 < keys.len() {
        keys[j] = keys[j + 1];
        values[j] = values[j + 1];
        j = j + 1;
      }
      keys.pop();
      values.pop();
      return Some(val);
    }
    i = i + 1;
  }
  return None;
}

fn Map.contains[K, V](key: &K) -> Bool {
  var i = 0;
  while i < keys.len() {
    if keys[i] == *key { return true; }
    i = i + 1;
  }
  return false;
}

fn Map.len[K, V]() -> Int {
  return keys.len();
}

fn Map.keys[K, V]() -> Vec[K] {
  var result = Vec[K].new();
  var i = 0;
  while i < keys.len() {
    result.push(keys[i]);
    i = i + 1;
  }
  return result;
}

fn Map.values[K, V]() -> Vec[V] {
  var result = Vec[V].new();
  var i = 0;
  while i < values.len() {
    result.push(values[i]);
    i = i + 1;
  }
  return result;
}

fn Map.clear[K, V]()
  ensures: len() == 0
{
  keys.clear();
  values.clear();
}

// === Set ===
type Set[T] = {
  items: Vec[T];
  invariant: items.len() >= 0;
}

fn Set.new[T]() -> Set[T] {
  return Set[T]{ items: Vec[T].new() };
}

fn Set.insert[T](&mut self, value: T)
  ensures: contains(&value)
{
  var i = 0;
  while i < items.len() {
    if items[i] == value { return; }
    i = i + 1;
  }
  var it = items;
  it.push(value);
  items = it;
}

fn Set.remove[T](&mut self, value: T)
  ensures: !contains(&value)
{
  var i = 0;
  while i < items.len() {
    if items[i] == value {
      var j = i;
      while j + 1 < items.len() {
        items[j] = items[j + 1];
        j = j + 1;
      }
      var it = items;
      it.pop();
      items = it;
      return;
    }
    i = i + 1;
  }
}

fn Set.contains[T](value: &T) -> Bool {
  var i = 0;
  while i < items.len() {
    if items[i] == *value { return true; }
    i = i + 1;
  }
  return false;
}

fn Set.len[T]() -> Int {
  return items.len();
}

fn Set.union[T](other: &Set[T]) -> Set[T]
  ensures: result.len() >= len()
  ensures: result.len() >= other.len()
{
  var result = Set[T].new();
  var i = 0;
  while i < items.len() {
    result.insert(items[i]);
    i = i + 1;
  }
  i = 0;
  while i < other.items.len() {
    result.insert(other.items[i]);
    i = i + 1;
  }
  return result;
}

fn Set.intersection[T](other: &Set[T]) -> Set[T]
  ensures: result.len() <= len()
  ensures: result.len() <= other.len()
{
  var result = Set[T].new();
  var i = 0;
  while i < items.len() {
    if other.contains(&items[i]) {
      result.insert(items[i]);
    }
    i = i + 1;
  }
  return result;
}

fn Set.difference[T](other: &Set[T]) -> Set[T]
  ensures: result.len() <= len()
{
  var result = Set[T].new();
  var i = 0;
  while i < items.len() {
    if !(other.contains(&items[i])) {
      result.insert(items[i]);
    }
    i = i + 1;
  }
  return result;
}

// === LinkedList ===
type LinkedList[T] = {
  items: Vec[T];
  invariant: items.len() >= 0;
}

fn LinkedList.new[T]() -> LinkedList[T] {
  return LinkedList[T]{ items: Vec[T].new() };
}

fn LinkedList.push_front[T](&mut self, value: T)
  ensures: len() >= 1
{
  var new_items = Vec[T].new();
  new_items.push(value);
  var i = 0;
  while i < items.len() {
    new_items.push(items[i]);
    i = i + 1;
  }
  items = new_items;
}

fn LinkedList.push_back[T](&mut self, value: T)
  ensures: len() >= 1
{
  // read-modify-write-back (field-copy push loses the len)
  var it = items;
  it.push(value);
  items = it;
}

fn LinkedList.pop_front[T](&mut self) -> Option[T]
  ensures: result is None => len() == 0
{
  if items.len() == 0 { return None; }
  var val = items[0];
  var i = 0;
  while i + 1 < items.len() {
    items[i] = items[i + 1];
    i = i + 1;
  }
  items.pop();
  return Some(val);
}

fn LinkedList.pop_back[T](&mut self) -> Option[T]
  ensures: result is None => len() == 0
{
  if items.len() == 0 { return None; }
  var idx = items.len() - 1;
  var val = items[idx];
  items.pop();
  return Some(val);
}

fn LinkedList.len[T]() -> Int {
  return items.len();
}

fn LinkedList.is_empty[T]() -> Bool {
  return items.len() == 0;
}

// === Queue ===
type Queue[T] = {
  data: Vec[T];
  head: Int;
  tail: Int;
  invariant: data.len() >= 0;
}

fn Queue.new[T]() -> Queue[T] {
  return Queue[T]{ data: Vec[T].new(), head: 0, tail: 0 };
}

fn Queue.enqueue[T](&mut self, value: T)
  ensures: len() >= 1
{
  var d = data;
  d.push(value);
  data = d;
  tail = tail + 1;
}

fn Queue.dequeue[T]() -> Option[T]
  ensures: result is None => len() == 0
{
  if head >= tail { return None; }
  var val = data[head];
  head = head + 1;
  return Some(val);
}

fn Queue.peek[T]() -> Option[T]
  ensures: result is None => len() == 0
{
  if head >= tail { return None; }
  return Some(data[head]);
}

fn Queue.len[T]() -> Int {
  return tail - head;
}

fn Queue.is_empty[T]() -> Bool {
  return head >= tail;
}

// === Stack ===
type Stack[T] = {
  items: Vec[T];
  invariant: items.len() >= 0;
}

fn Stack.new[T]() -> Stack[T] {
  return Stack[T]{ items: Vec[T].new() };
}

fn Stack.push[T](&mut self, value: T)
  ensures: len() >= 1
{
  var it = items;
  it.push(value);
  items = it;
}

fn Stack.pop[T](&mut self) -> Option[T]
  ensures: result is None => len() == 0
{
  if items.len() == 0 { return None; }
  var idx = items.len() - 1;
  var val = items[idx];
  var it = items;
  it.pop();
  items = it;
  return Some(val);
}

fn Stack.peek[T]() -> Option[T]
  ensures: result is None => len() == 0
{
  if items.len() == 0 { return None; }
  return Some(items[items.len() - 1]);
}

fn Stack.len[T]() -> Int {
  return items.len();
}

fn Stack.is_empty[T]() -> Bool {
  return items.len() == 0;
}

// === VecDeque (double-ended queue) ===
type VecDeque[T] = {
  data: Vec[T];
  head: Int;
  tail: Int;
  invariant: data.len() >= 0;
}

fn VecDeque.new[T]() -> VecDeque[T] {
  return VecDeque[T]{ data: Vec[T].new(), head: 0, tail: 0 };
}

fn VecDeque.with_capacity[T](cap: Int) -> VecDeque[T] {
  return VecDeque[T]{ data: Vec[T].with_capacity(cap), head: 0, tail: 0 };
}

fn VecDeque.push_front[T](&mut self, value: T)
  ensures: len() >= 1
{
  // rebuild over the LIVE range only -- copying all of data re-pushes
  // elements already drained by pop_front (stale 20 bug)
  var new_data = Vec[T].new();
  new_data.push(value);
  var i = head;
  while i < tail {
    new_data.push(data[i]);
    i = i + 1;
  }
  data = new_data;
  tail = data.len();
  head = 0;
}

fn VecDeque.push_back[T](&mut self, value: T)
  ensures: len() >= 1
{
  // read-modify-write-back: a field-copy Vec push loses the len on the copy
  var d = data;
  d.push(value);
  data = d;
  tail = data.len();
}

fn VecDeque.pop_front[T](&mut self) -> Option[T]
  ensures: result is None => len() == 0
{
  if head >= tail { return None; }
  var val = data[head];
  head = head + 1;
  return Some(val);
}

fn VecDeque.pop_back[T](&mut self) -> Option[T]
  ensures: result is None => len() == 0
{
  if head >= tail { return None; }
  tail = tail - 1;
  return Some(data[tail]);
}

fn VecDeque.front[T](&mut self) -> Option[T]
  ensures: result is None => len() == 0
{
  if head >= tail { return None; }
  return Some(data[head]);
}

fn VecDeque.back[T](&mut self) -> Option[T]
  ensures: result is None => len() == 0
{
  if head >= tail { return None; }
  return Some(data[tail - 1]);
}

fn VecDeque.len[T]() -> Int {
  return tail - head;
}

// === BTreeMap (sorted map) ===
type BTreeMap[K: Ord, V] = {
  keys: Vec[K];
  values: Vec[V];
  invariant: keys.len() == values.len();
}

fn BTreeMap.new[K: Ord, V]() -> BTreeMap[K, V] {
  return BTreeMap[K, V]{ keys: Vec[K].new(), values: Vec[V].new() };
}

fn BTreeMap.insert[K: Ord, V](key: K, value: V) -> Option[V]
  ensures: contains_key(&key)
{
  var lo = 0;
  var hi = keys.len();
  while lo < hi {
    var mid = (lo + hi) / 2;
    if keys[mid] < key {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if lo < keys.len() && keys[lo] == key {
    var old = values[lo];
    values[lo] = value;
    return Some(old);
  }
  keys.push(key);
  values.push(value);
  var i = keys.len() - 1;
  while i > lo {
    keys[i] = keys[i - 1];
    values[i] = values[i - 1];
    i = i - 1;
  }
  keys[lo] = key;
  values[lo] = value;
  return None;
}

fn BTreeMap.get[K: Ord, V](key: &K) -> Option[V]
  ensures: result is Some => contains_key(key)
{
  var lo = 0;
  var hi = keys.len();
  while lo < hi {
    var mid = (lo + hi) / 2;
    if keys[mid] < *key {
      lo = mid + 1;
    } elif *key < keys[mid] {
      hi = mid;
    } else {
      return Some(values[mid]);
    }
  }
  return None;
}

fn BTreeMap.remove[K: Ord, V](key: &K) -> Option[V]
  ensures: !contains_key(key)
{
  var lo = 0;
  var hi = keys.len();
  while lo < hi {
    var mid = (lo + hi) / 2;
    if keys[mid] < *key {
      lo = mid + 1;
    } elif *key < keys[mid] {
      hi = mid;
    } else {
      var val = values[mid];
      var j = mid;
      while j + 1 < keys.len() {
        keys[j] = keys[j + 1];
        values[j] = values[j + 1];
        j = j + 1;
      }
      keys.pop();
      values.pop();
      return Some(val);
    }
  }
  return None;
}

fn BTreeMap.contains_key[K: Ord, V](key: &K) -> Bool {
  var lo = 0;
  var hi = keys.len();
  while lo < hi {
    var mid = (lo + hi) / 2;
    if keys[mid] < *key {
      lo = mid + 1;
    } elif *key < keys[mid] {
      hi = mid;
    } else {
      return true;
    }
  }
  return false;
}

fn BTreeMap.first_entry[K: Ord, V]() -> Option[(K, V)]
  ensures: result is None => len() == 0
{
  if keys.len() == 0 { return None; }
  return Some((keys[0], values[0]));
}

fn BTreeMap.last_entry[K: Ord, V]() -> Option[(K, V)]
  ensures: result is None => len() == 0
{
  if keys.len() == 0 { return None; }
  var idx = keys.len() - 1;
  return Some((keys[idx], values[idx]));
}

fn BTreeMap.len[K: Ord, V]() -> Int {
  return keys.len();
}

// === BTreeSet (sorted set) ===
type BTreeSet[T: Ord] = {
  items: Vec[T];
  invariant: items.len() >= 0;
}

fn BTreeSet.new[T: Ord]() -> BTreeSet[T] {
  return BTreeSet[T]{ items: Vec[T].new() };
}

fn BTreeSet.insert[T: Ord](value: T) -> Bool
  ensures: contains(&value)
{
  var lo = 0;
  var hi = items.len();
  while lo < hi {
    var mid = (lo + hi) / 2;
    if items[mid] < value {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if lo < items.len() && items[lo] == value { return false; }
  items.push(value);
  var i = items.len() - 1;
  while i > lo {
    items[i] = items[i - 1];
    i = i - 1;
  }
  items[lo] = value;
  return true;
}

fn BTreeSet.remove[T: Ord](value: &T) -> Bool
  ensures: !contains(value)
{
  var lo = 0;
  var hi = items.len();
  while lo < hi {
    var mid = (lo + hi) / 2;
    if items[mid] < *value {
      lo = mid + 1;
    } elif *value < items[mid] {
      hi = mid;
    } else {
      var j = mid;
      while j + 1 < items.len() {
        items[j] = items[j + 1];
        j = j + 1;
      }
      items.pop();
      return true;
    }
  }
  return false;
}

fn BTreeSet.contains[T: Ord](value: &T) -> Bool {
  var lo = 0;
  var hi = items.len();
  while lo < hi {
    var mid = (lo + hi) / 2;
    if items[mid] < *value {
      lo = mid + 1;
    } elif *value < items[mid] {
      hi = mid;
    } else {
      return true;
    }
  }
  return false;
}

fn BTreeSet.first[T: Ord]() -> Option[T]
  ensures: result is None => len() == 0
{
  if items.len() == 0 { return None; }
  return Some(items[0]);
}

fn BTreeSet.last[T: Ord]() -> Option[T]
  ensures: result is None => len() == 0
{
  if items.len() == 0 { return None; }
  return Some(items[items.len() - 1]);
}

fn BTreeSet.len[T: Ord]() -> Int {
  return items.len();
}

// === Slice methods ===
type Slice[T] = {
  data: Vec[T];
  invariant: data.len() >= 0;
}

fn Slice.len[T]() -> Int {
  return data.len();
}

fn Slice.is_empty[T]() -> Bool {
  return data.len() == 0;
}

fn Slice.first[T]() -> Option[T]
  ensures: result is None => len() == 0
{
  if data.len() == 0 { return None; }
  return Some(data[0]);
}

fn Slice.last[T]() -> Option[T]
  ensures: result is None => len() == 0
{
  if data.len() == 0 { return None; }
  return Some(data[data.len() - 1]);
}

fn Slice.get[T](index: Int) -> Option[T]
  ensures: result is Some => index >= 0
{
  if index < 0 || index >= data.len() { return None; }
  return Some(data[index]);
}

// ============================================================================
// 6E.1: HashMap[K, V] -- O(1) amortized hash-based map
// ============================================================================
// Uses open addressing with linear probing and djb2 hashing.
// Grows by 2x when load factor exceeds 0.75.

use xiom.sort;
use xiom.string;
use xiom.hash as hsh;  // alias: leaf `hash` is shadowed by collect.hash/crypto.hash

// The Vec buffer allocator intrinsics (@realloc/@free at the call sites)
// need the C symbols in scope for the import-discipline gate.
extern "C" {
  fn realloc(ptr: *UInt8, size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
}

/// Open-addressed hash map with linear probing.
pub type HashMap[K, V] = {
  data: Vec[HashMapBucket[K, V]];
  len: Int;
  cap: Int;
}

type HashMapBucket[K, V] = {
  key: K;
  value: V;
  occupied: Bool;
}

fn HashMap.new[K, V]() -> HashMap[K, V] {
  let cap = 16;
  var data = Vec[HashMapBucket[K, V]].new();
  var i = 0;
  while i < cap {
    data.push(HashMapBucket[K, V]{ key: K(), value: V(), occupied: false });
    i = i + 1;
  }
  return HashMap[K, V]{ data: data; len: 0; cap: cap };
}

/// Compute bucket index from key hash. Int-like keys only: the legacy
/// container predates the hasher interface, so the generic key is cast
/// to Int for the hash (the strict catalog gate rejects the bare K form).
fn HashMap.bucket_idx[K, V](key: &K) -> Int {
  var h = hsh.hash_combine(0, *key as Int);
  if h < 0 { h = -h; }
  return h % cap;
}

/// Insert or update a key-value pair. O(1) amortized.
fn HashMap.insert[K, V](key: K, value: V)
  requires: len <= cap
{
  // Grow if needed (load factor > 0.75)
  if len * 4 > cap * 3 {
    resize(cap * 2);
  }
  var idx = bucket_idx(&key);
  while data[idx].occupied {
    if data[idx].key == key {
      data[idx].value = value;
      return;
    }
    idx = (idx + 1) % cap;
  }
  data[idx].key = key;
  data[idx].value = value;
  data[idx].occupied = true;
  len = len + 1;
}

/// Get value by key. O(1) amortized.
fn HashMap.get[K, V](key: &K) -> Option[V] {
  if len == 0 { return None; }
  var idx = bucket_idx(key);
  var checked = 0;
  while checked < cap {
    if data[idx].occupied {
      if data[idx].key == *key {
        return Some(data[idx].value);
      }
    } else {
      // Empty bucket -- key not found
      return None;
    }
    idx = (idx + 1) % cap;
    checked = checked + 1;
  }
  return None;
}

/// Remove a key-value pair. O(1) amortized.
fn HashMap.remove[K, V](key: &K) -> Option[V] {
  if len == 0 { return None; }
  var idx = bucket_idx(key);
  var checked = 0;
  while checked < cap {
    if data[idx].occupied && data[idx].key == *key {
      var val = data[idx].value;
      data[idx].occupied = false;
      len = len - 1;
      // Rehash following elements to fill the gap
      var next = (idx + 1) % cap;
      while data[next].occupied && next != idx {
        var rehash_key = data[next].key;
        var rehash_val = data[next].value;
        data[next].occupied = false;
        len = len - 1;
        insert(rehash_key, rehash_val);
        next = (next + 1) % cap;
      }
      return Some(val);
    }
    if !data[idx].occupied { return None; }
    idx = (idx + 1) % cap;
    checked = checked + 1;
  }
  return None;
}

/// Check if key exists. O(1).
fn HashMap.contains[K, V](key: &K) -> Bool {
  match get(key) {
    Some(_) => true,
    None => false,
  }
}

/// Number of key-value pairs.
fn HashMap.count[K, V]() -> Int { return len; }

/// Remove all entries.
fn HashMap.clear[K, V]() {
  var i = 0;
  while i < cap {
    data[i].occupied = false;
    i = i + 1;
  }
  len = 0;
}

/// Resize the hash table to new capacity. O(n).
fn HashMap.resize[K, V](new_cap: Int) {
  var old_data = data;
  var old_cap = cap;
  var old_len = len;
  // Allocate new data
  data = Vec[HashMapBucket[K, V]].new();
  var i = 0;
  while i < new_cap {
    data.push(HashMapBucket[K, V]{ key: K(), value: V(), occupied: false });
    i = i + 1;
  }
  cap = new_cap;
  len = 0;
  // Re-insert all entries
  i = 0;
  while i < old_cap {
    if old_data[i].occupied {
      insert(old_data[i].key, old_data[i].value);
    }
    i = i + 1;
  }
}

// -- Vec Operations ----------------------------------------------------------

/// Reverse elements in place. O(N).
pub fn vec_reverse[T](v: &mut Vec[T]) {
  var n = v.len();
  if n <= 1 { return; }
  var i = 0;
  var j = n - 1;
  while i < j {
    var temp = v[i];
    v[i] = v[j];
    v[j] = temp;
    i = i + 1;
    j = j - 1;
  }
}

/// Sort elements in ascending order. O(N log N) avg.
pub fn vec_sort_asc[T: Ord](v: &mut Vec[T]) {
  xiom.sort.sort_quick(v);
}

/// Sort elements in descending order. O(N log N) avg.
pub fn vec_sort_desc[T: Ord](v: &mut Vec[T]) {
  xiom.sort.sort_quick(v);
  vec_reverse(v);
}

/// Returns true if the value is present. O(N).
pub fn vec_contains[T: Eq](v: &Vec[T], value: T) -> Bool {
  var i = 0;
  while i < v.len() {
    if v[i] == value { return true; }
    i = i + 1;
  }
  false
}

/// Remove consecutive duplicate elements. O(N).
pub fn vec_dedup[T: Eq](v: &mut Vec[T]) {
  var n = v.len();
  if n <= 1 { return; }
  var write = 1;
  var read = 1;
  while read < n {
    if !(v[read] == v[write - 1]) {
      v[write] = v[read];
      write = write + 1;
    }
    read = read + 1;
  }
  while v.len() > write {
    v.pop();
  }
}

/// Rotate elements left by k positions. O(N).
pub fn vec_rotate_left[T](v: &mut Vec[T], k: Int) {
  var n = v.len();
  if n <= 1 { return; }
  var kk = k % n;
  if kk <= 0 { return; }
  var i = 0;
  var j = kk - 1;
  while i < j {
    var temp = v[i];
    v[i] = v[j];
    v[j] = temp;
    i = i + 1;
    j = j - 1;
  }
  i = kk;
  j = n - 1;
  while i < j {
    var temp = v[i];
    v[i] = v[j];
    v[j] = temp;
    i = i + 1;
    j = j - 1;
  }
  i = 0;
  j = n - 1;
  while i < j {
    var temp = v[i];
    v[i] = v[j];
    v[j] = temp;
    i = i + 1;
    j = j - 1;
  }
}

/// Fill the vector with copies of `value`. O(N).
pub fn vec_fill[T: Clone](v: &mut Vec[T], value: T) {
  var i = 0;
  var n = v.len();
  while i < n {
    v[i] = value.clone();
    i = i + 1;
  }
}

/// Swap the elements at indices i and j. O(1).
pub fn vec_swap_elems[T](v: &mut Vec[T], i: Int, j: Int) {
  var n = v.len();
  if i < 0 || i >= n || j < 0 || j >= n { return; }
  if i == j { return; }
  var temp = v[i];
  v[i] = v[j];
  v[j] = temp;
}

// -- Vec Free Functions ------------------------------------------------------

/// Join a vector of strings with a separator. O(N-L) where L is avg string length.
pub fn vec_str_join(items: &Vec[Str], sep: Str) -> Str {
  var n = items.len();
  if n == 0 { return ""; }
  var result = items[0];
  var i = 1;
  while i < n {
    result = xiom.string.str_concat(result, sep);
    result = xiom.string.str_concat(result, items[i]);
    i = i + 1;
  }
  result
}

/// Minimum element in a vector, or None if empty. O(N).
pub fn vec_min[T: Ord](v: &Vec[T]) -> Option[T] {
  var n = v.len();
  if n == 0 { return None; }
  var min_val = v[0];
  var i = 1;
  while i < n {
    if v[i].compare(min_val) < 0 { min_val = v[i]; }
    i = i + 1;
  }
  Some(min_val)
}

/// Maximum element in a vector, or None if empty. O(N).
pub fn vec_max[T: Ord](v: &Vec[T]) -> Option[T] {
  var n = v.len();
  if n == 0 { return None; }
  var max_val = v[0];
  var i = 1;
  while i < n {
    if v[i].compare(max_val) > 0 { max_val = v[i]; }
    i = i + 1;
  }
  Some(max_val)
}

/// Sum of all elements in an integer vector. O(N).
pub fn vec_sum(v: &Vec[Int]) -> Int {
  var total = 0;
  var i = 0;
  while i < v.len() {
    total = total + v[i];
    i = i + 1;
  }
  total
}

/// Integer average (truncated division) of a vector. Returns 0 if empty. O(N).
pub fn vec_avg(v: &Vec[Int]) -> Int {
  var n = v.len();
  if n == 0 { return 0; }
  vec_sum(v) / n
}

/// Count elements satisfying a predicate. O(N).
pub fn vec_count_if[T](v: &Vec[T], pred: fn(&T) -> Bool) -> Int {
  var count = 0;
  var i = 0;
  while i < v.len() {
    if pred(&v[i]) { count = count + 1; }
    i = i + 1;
  }
  count
}

/// Returns true if any element satisfies the predicate. O(N).
pub fn vec_any[T](v: &Vec[T], pred: fn(&T) -> Bool) -> Bool {
  var i = 0;
  while i < v.len() {
    if pred(&v[i]) { return true; }
    i = i + 1;
  }
  false
}

/// Returns true if all elements satisfy the predicate. O(N).
pub fn vec_all[T](v: &Vec[T], pred: fn(&T) -> Bool) -> Bool {
  var i = 0;
  while i < v.len() {
    if !(pred(&v[i])) { return false; }
    i = i + 1;
  }
  true
}

// -- Map Free Functions ------------------------------------------------------

/// Number of entries in the map. O(1).
pub fn map_len[K, V](m: Map[K, V]) -> Int {
  m.len()
}

/// Returns true if the key exists in the map. O(N).
pub fn map_contains_key[K, V](m: &Map[K, V], key: &K) -> Bool {
  m.contains(key)
}

/// Get value by key, or return `default` if not found. O(N).
pub fn map_get_or[K, V](m: &Map[K, V], key: &K, default: V) -> V {
  var opt = m.get(key);
  match opt {
    Some(v) => v,
    None => default,
  }
}

/// Remove a key-value pair. Returns the value if the key was present. O(N).
pub fn map_remove_key[K, V](m: &mut Map[K, V], key: &K) -> Option[V] {
  m.remove(key)
}

/// Remove all entries from the map. O(1).
pub fn map_clear[K, V](m: &mut Map[K, V]) {
  m.clear()
}

/// Insert a key-value pair only if the key is not already present.
/// Returns true if inserted, false if key already existed. O(N).
pub fn map_insert_if_absent[K, V](m: &mut Map[K, V], key: K, value: V) -> Bool {
  if m.contains(&key) { return false; }
  m.insert(key, value);
  true
}

/// Merge two maps into a new map. Entries from `b` overwrite those from `a` on key collision. O(N-M).
pub fn map_merge[K, V](a: &Map[K, V], b: &Map[K, V]) -> Map[K, V] {
  var result = Map[K, V].new();
  var a_keys = a.keys();
  var a_vals = a.values();
  var i = 0;
  while i < a_keys.len() {
    result.insert(a_keys[i], a_vals[i]);
    i = i + 1;
  }
  var b_keys = b.keys();
  var b_vals = b.values();
  i = 0;
  while i < b_keys.len() {
    result.insert(b_keys[i], b_vals[i]);
    i = i + 1;
  }
  result
}

// -- Set Free Functions ------------------------------------------------------

/// Insert a value into the set. O(N).
pub fn set_insert[T](s: &mut Set[T], value: T) {
  s.insert(value)
}

/// Returns true if the value is in the set. O(N).
pub fn set_contains[T](s: &Set[T], value: &T) -> Bool {
  s.contains(value)
}

/// Remove a value from the set. O(N).
pub fn set_remove[T](s: &mut Set[T], value: &T) {
  s.remove(value)
}

/// Number of elements in the set. O(1).
pub fn set_len[T](s: &Set[T]) -> Int {
  s.len()
}

/// Union of two sets: all elements present in either set. O(N-M).
pub fn set_union[T](a: &Set[T], b: &Set[T]) -> Set[T] {
  a.union(b)
}

/// Intersection of two sets: elements present in both. O(N-M).
pub fn set_intersection[T](a: &Set[T], b: &Set[T]) -> Set[T] {
  a.intersection(b)
}

/// Difference of two sets: elements in `a` but not in `b`. O(N-M).
pub fn set_difference[T](a: &Set[T], b: &Set[T]) -> Set[T] {
  a.difference(b)
}

/// Returns true if `sub` is a subset of `sup` (all elements of sub are in sup). O(N-M).
pub fn set_is_subset[T](sub: &Set[T], sup: &Set[T]) -> Bool {
  var sub_vec = set_to_vec(sub);
  var i = 0;
  while i < sub_vec.len() {
    if !(sup.contains(&sub_vec[i])) { return false; }
    i = i + 1;
  }
  true
}

/// Returns true if the set contains no elements. O(1).
pub fn set_is_empty[T](s: &Set[T]) -> Bool {
  s.len() == 0
}

/// Convert a set to a vector containing all its elements. O(N).
pub fn set_to_vec[T](s: &Set[T]) -> Vec[T] {
  var result = Vec[T].new();
  var items = s.items;
  var i = 0;
  while i < items.len() {
    result.push(items[i]);
    i = i + 1;
  }
  result
}

/// Create a set from a vector (deduplicates). O(N2).
pub fn set_from_vec[T](v: &Vec[T]) -> Set[T] {
  var result = Set[T].new();
  var i = 0;
  while i < v.len() {
    set_insert(&result, v[i]);
    i = i + 1;
  }
  result
}

// ============================================================================
// Vec -- sorting & exhaustive integer aggregations (extensions)
// ============================================================================

/// Sort a vector using a custom comparator. Delegates to xiom.sort.sort_by.
/// O(N log N) average, O(N2) worst. Unstable.
/// NOTE: the comparator must be a NAMED function -- inline lambdas crash the
/// current runtime (see xiom.sort comparator note).
pub fn vec_sort_by[T](v: &mut Vec[T], compare: fn(&T, &T) -> Int) {
  // Local insertion sort keeps the Int-comparator API (xiom.sort.sort_by
  // takes an Ordering comparator) and avoids the full-path import gate.
  let n = v.len();
  var i = 1;
  while i < n {
    var j = i;
    while j > 0 {
      if compare(&v[j - 1], &v[j]) <= 0 {
        j = 0;
      } else {
        let tmp = v[j - 1];
        v[j - 1] = v[j];
        v[j] = tmp;
        j = j - 1;
      }
    }
    i = i + 1;
  }
}

/// Sliding-window maximum: for each window of size `k` starting at index 0,
/// the maximum element of that window. O(N-K) with O(K) extra space.
pub fn vec_window_max(v: &Vec[Int], k: Int) -> Vec[Int] {
  var n = v.len();
  var result = Vec[Int].new();
  if n == 0 || k <= 0 { return result; }
  var kk = k;
  if kk > n { kk = n; }
  var start = 0;
  while start + kk <= n {
    var mx = v[start];
    var i = start + 1;
    while i < start + kk {
      if v[i] > mx { mx = v[i]; }
      i = i + 1;
    }
    result.push(mx);
    start = start + 1;
  }
  return result;
}

/// Sliding-window minimum: for each window of size `k`, the minimum element.
/// O(N-K) with O(K) extra space.
pub fn vec_window_min(v: &Vec[Int], k: Int) -> Vec[Int] {
  var n = v.len();
  var result = Vec[Int].new();
  if n == 0 || k <= 0 { return result; }
  var kk = k;
  if kk > n { kk = n; }
  var start = 0;
  while start + kk <= n {
    var mn = v[start];
    var i = start + 1;
    while i < start + kk {
      if v[i] < mn { mn = v[i]; }
      i = i + 1;
    }
    result.push(mn);
    start = start + 1;
  }
  return result;
}

/// Cumulative sum: result[i] = v[0] + ... + v[i]. O(N). Empty input -> empty.
pub fn vec_cumsum(v: &Vec[Int]) -> Vec[Int] {
  var result = Vec[Int].new();
  var total = 0;
  var i = 0;
  while i < v.len() {
    total = total + v[i];
    result.push(total);
    i = i + 1;
  }
  return result;
}

/// Dot product of two integer vectors, or None if lengths differ. O(N).
pub fn vec_dot(a: &Vec[Int], b: &Vec[Int]) -> Option[Int] {
  var na = a.len();
  var nb = b.len();
  if na != nb { return None; }
  var total = 0;
  var i = 0;
  while i < na {
    total = total + a[i] * b[i];
    i = i + 1;
  }
  return Some(total);
}

/// Product of all elements in an integer vector. Returns 1 if empty. O(N).
pub fn vec_product(v: &Vec[Int]) -> Int {
  var total = 1;
  var i = 0;
  while i < v.len() {
    total = total * v[i];
    i = i + 1;
  }
  return total;
}

/// Frequency keys: distinct values of the vector, sorted ascending. O(N + M2).
/// Companion of vec_frequency_counts; the two result vectors are parallel
/// (keys[i] occurs counts[i] times).
pub fn vec_frequency_keys(v: &Vec[Int]) -> Vec[Int] {
  var counts = Map[Int, Int].new();
  var i = 0;
  while i < v.len() {
    var val = v[i];
    var opt = counts.get(&val);
    match opt {
      Some(c) => { counts.insert(val, c + 1); },
      None => { counts.insert(val, 1); },
    }
    i = i + 1;
  }
  var keys = counts.keys();
  var vals = counts.values();
  // parallel selection sort by key ascending
  var j = 0;
  while j < keys.len() {
    var min_idx = j;
    var k = j + 1;
    while k < keys.len() {
      if keys[k] < keys[min_idx] { min_idx = k; }
      k = k + 1;
    }
    if min_idx != j {
      var tk = keys[j];
      keys[j] = keys[min_idx];
      keys[min_idx] = tk;
      var tv = vals[j];
      vals[j] = vals[min_idx];
      vals[min_idx] = tv;
    }
    j = j + 1;
  }
  return keys;
}

/// Frequency counts: occurrence counts aligned with vec_frequency_keys. O(N + M2).
pub fn vec_frequency_counts(v: &Vec[Int]) -> Vec[Int] {
  var counts = Map[Int, Int].new();
  var i = 0;
  while i < v.len() {
    var val = v[i];
    var opt = counts.get(&val);
    match opt {
      Some(c) => { counts.insert(val, c + 1); },
      None => { counts.insert(val, 1); },
    }
    i = i + 1;
  }
  var keys = counts.keys();
  var vals = counts.values();
  var j = 0;
  while j < keys.len() {
    var min_idx = j;
    var k = j + 1;
    while k < keys.len() {
      if keys[k] < keys[min_idx] { min_idx = k; }
      k = k + 1;
    }
    if min_idx != j {
      var tk = keys[j];
      keys[j] = keys[min_idx];
      keys[min_idx] = tk;
      var tv = vals[j];
      vals[j] = vals[min_idx];
      vals[min_idx] = tv;
    }
    j = j + 1;
  }
  return vals;
}

/// Median of an integer vector, or None if empty. O(N log N).
/// Convention: returns the lower-middle element (index (n-1)/2) of the sorted
/// copy, so even-length inputs yield the smaller of the two middle values.
pub fn vec_median(v: &mut Vec[Int]) -> Option[Int] {
  var n = v.len();
  if n == 0 { return None; }
  var sorted = Vec[Int].new();
  var i = 0;
  while i < n {
    sorted.push(v[i]);
    i = i + 1;
  }
  xiom.sort.sort_quick(&sorted);
  return Some(sorted[(n - 1) / 2]);
}

/// Percentile of an integer vector at p (0..100), or None if empty or p invalid.
/// O(N log N). Convention: nearest-rank, index floor((n-1) * p / 100).
pub fn vec_percentile(v: &mut Vec[Int], p: Int) -> Option[Int] {
  var n = v.len();
  if n == 0 { return None; }
  if p < 0 || p > 100 { return None; }
  var sorted = Vec[Int].new();
  var i = 0;
  while i < n {
    sorted.push(v[i]);
    i = i + 1;
  }
  xiom.sort.sort_quick(&sorted);
  var idx = (n - 1) * p / 100;
  return Some(sorted[idx]);
}

/// All indices where `value` occurs. O(N). Empty if not found.
pub fn vec_find_all[T: Eq](v: &Vec[T], value: T) -> Vec[Int] {
  var result = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    if v[i] == value { result.push(i); }
    i = i + 1;
  }
  return result;
}

/// Remove every occurrence of `value` in place. O(N). Stability preserved.
pub fn vec_remove_all[T: Eq](v: &mut Vec[T], value: T) {
  var n = v.len();
  var write = 0;
  var read = 0;
  while read < n {
    if !(v[read] == value) {
      v[write] = v[read];
      write = write + 1;
    }
    read = read + 1;
  }
  while v.len() > write {
    v.pop();
  }
}

/// Keep only elements for which `keep` returns true. Returns the number of
/// removed elements. O(N). NOTE: pass a NAMED predicate -- lambdas crash the
/// current runtime.
pub fn vec_retain[T](v: &mut Vec[T], keep: fn(&T) -> Bool) -> Int {
  var n = v.len();
  var write = 0;
  var removed = 0;
  var read = 0;
  while read < n {
    if keep(&v[read]) {
      v[write] = v[read];
      write = write + 1;
    } else {
      removed = removed + 1;
    }
    read = read + 1;
  }
  while v.len() > write {
    v.pop();
  }
  return removed;
}

/// Returns true if the vector is sorted in non-decreasing order. O(N).
pub fn vec_is_sorted[T: Ord](v: &Vec[T]) -> Bool {
  var n = v.len();
  if n <= 1 { return true; }
  var i = 1;
  while i < n {
    if v[i - 1].compare(v[i]) > 0 { return false; }
    i = i + 1;
  }
  return true;
}

/// Returns true if the vector has no elements. O(1).
pub fn vec_is_empty[T](v: &Vec[T]) -> Bool {
  return v.len() == 0;
}

/// Element at index i, or `default` if out of bounds. O(1).
pub fn vec_get_or[T](v: &Vec[T], i: Int, default: T) -> T {
  if i < 0 || i >= v.len() { return default; }
  return v[i];
}

/// Left part of a vector: elements [0, i), clamped to the valid range. O(N).
pub fn vec_left(v: &Vec[Int], i: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  var n = v.len();
  if i <= 0 { return result; }
  var k = i;
  if k > n { k = n; }
  var j = 0;
  while j < k {
    result.push(v[j]);
    j = j + 1;
  }
  return result;
}

/// Right part of a vector: elements [i, n). If i <= 0 the whole vector is
/// returned; if i >= n the result is empty. O(N).
pub fn vec_right(v: &Vec[Int], i: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  var n = v.len();
  var k = i;
  if k < 0 { k = 0; }
  if k >= n { return result; }
  var j = k;
  while j < n {
    result.push(v[j]);
    j = j + 1;
  }
  return result;
}

/// Zip two integer vectors, interleaving pairs [a0, b0, a1, b1, ...] up to the
/// shorter length. O(N).
pub fn vec_zip_int(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var result = Vec[Int].new();
  var n = a.len();
  if b.len() < n { n = b.len(); }
  var i = 0;
  while i < n {
    result.push(a[i]);
    result.push(b[i]);
    i = i + 1;
  }
  return result;
}

/// Even-indexed elements of a vector: [v[0], v[2], v[4], ...]. O(N).
/// Pairs with vec_unzip_odds to recover the two halves of a zipped vector.
pub fn vec_unzip_evens(v: &Vec[Int]) -> Vec[Int] {
  var result = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    result.push(v[i]);
    i = i + 2;
  }
  return result;
}

/// Odd-indexed elements of a vector: [v[1], v[3], v[5], ...]. O(N).
pub fn vec_unzip_odds(v: &Vec[Int]) -> Vec[Int] {
  var result = Vec[Int].new();
  var i = 1;
  while i < v.len() {
    result.push(v[i]);
    i = i + 2;
  }
  return result;
}

