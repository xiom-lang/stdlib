// XIOM — Collections Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

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

fn Vec.new[T]() -> Vec[T] {
  return Vec[T]{ data: 0 as *T, len: 0, cap: 0 };
}

fn Vec.with_capacity[T](cap: Int) -> Vec[T] {
  var v = Vec[T].new();
  v.cap = cap;
  return v;
}

fn Vec.push[T](value: T)
  ensures: len() == len()@pre + 1
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
  ensures: len() == len()@pre - 1 || len() == 0
{
  if len == 0 { return None; }
  len = len - 1;
  unsafe {
    return Some(*(data + len));
  }
}

fn Vec.get[T](index: Int) -> Option[T]
  ensures: result is Some => index >= 0 && index < len()@pre
  ensures: result is None => index < 0 || index >= len()@pre
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
// 6E.3: Vec production methods — extend, reserve, truncate, shrink_to_fit
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
  ensures: len() == len()@pre + other.len()
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
  ensures: len() <= len()@pre
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
  ensures:  len() == len()@pre + 1
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
  requires: index >= 0
  ensures:  result is Some => len() == len()@pre - 1
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
  ensures: result is Some => len()@pre > 0
  ensures: result is None => len()@pre == 0
{
  if len == 0 { return None; }
  unsafe {
    return Some(*(data + 0));
  }
}

fn Vec.last[T]() -> Option[T]
  ensures: result is Some => len()@pre > 0
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

// === Map ===
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

fn Set.insert[T](value: T)
  ensures: contains(&value)
{
  var i = 0;
  while i < items.len() {
    if items[i] == value { return; }
    i = i + 1;
  }
  items.push(value);
}

fn Set.remove[T](value: &T)
  ensures: !contains(value)
{
  var i = 0;
  while i < items.len() {
    if items[i] == *value {
      var j = i;
      while j + 1 < items.len() {
        items[j] = items[j + 1];
        j = j + 1;
      }
      items.pop();
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

fn LinkedList.push_front[T](value: T)
  ensures: len() == len()@pre + 1
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

fn LinkedList.push_back[T](value: T)
  ensures: len() == len()@pre + 1
{
  items.push(value);
}

fn LinkedList.pop_front[T]() -> Option[T]
  ensures: result is Some => len() == len()@pre - 1
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

fn LinkedList.pop_back[T]() -> Option[T]
  ensures: result is Some => len() == len()@pre - 1
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

fn Queue.enqueue[T](value: T)
  ensures: len() == len()@pre + 1
{
  data.push(value);
  tail = tail + 1;
}

fn Queue.dequeue[T]() -> Option[T]
  ensures: result is Some => len() == len()@pre - 1
{
  if head >= tail { return None; }
  var val = data[head];
  head = head + 1;
  return Some(val);
}

fn Queue.peek[T]() -> Option[T]
  ensures: len() == len()@pre
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

fn Stack.push[T](value: T)
  ensures: len() == len()@pre + 1
{
  items.push(value);
}

fn Stack.pop[T]() -> Option[T]
  ensures: result is Some => len() == len()@pre - 1
{
  if items.len() == 0 { return None; }
  var idx = items.len() - 1;
  var val = items[idx];
  items.pop();
  return Some(val);
}

fn Stack.peek[T]() -> Option[T]
  ensures: len() == len()@pre
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

fn VecDeque.push_front[T](value: T)
  ensures: len() == len()@pre + 1
{
  var new_data = Vec[T].new();
  new_data.push(value);
  var i = 0;
  while i < data.len() {
    new_data.push(data[i]);
    i = i + 1;
  }
  data = new_data;
  tail = data.len();
  head = 0;
}

fn VecDeque.push_back[T](value: T)
  ensures: len() == len()@pre + 1
{
  data.push(value);
  tail = data.len();
}

fn VecDeque.pop_front[T]() -> Option[T]
  ensures: result is Some => len() == len()@pre - 1
{
  if head >= tail { return None; }
  var val = data[head];
  head = head + 1;
  return Some(val);
}

fn VecDeque.pop_back[T]() -> Option[T]
  ensures: result is Some => len() == len()@pre - 1
{
  if head >= tail { return None; }
  tail = tail - 1;
  return Some(data[tail]);
}

fn VecDeque.front[T]() -> Option[T]
  ensures: len() == len()@pre
{
  if head >= tail { return None; }
  return Some(data[head]);
}

fn VecDeque.back[T]() -> Option[T]
  ensures: len() == len()@pre
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
  ensures: result is Some => len()@pre > 0
{
  if keys.len() == 0 { return None; }
  return Some((keys[0], values[0]));
}

fn BTreeMap.last_entry[K: Ord, V]() -> Option[(K, V)]
  ensures: result is Some => len()@pre > 0
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
  ensures: result is Some => len()@pre > 0
{
  if items.len() == 0 { return None; }
  return Some(items[0]);
}

fn BTreeSet.last[T: Ord]() -> Option[T]
  ensures: result is Some => len()@pre > 0
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
  ensures: result is Some => len()@pre > 0
{
  if data.len() == 0 { return None; }
  return Some(data[0]);
}

fn Slice.last[T]() -> Option[T]
  ensures: result is Some => len()@pre > 0
{
  if data.len() == 0 { return None; }
  return Some(data[data.len() - 1]);
}

fn Slice.get[T](index: Int) -> Option[T]
  ensures: result is Some => index >= 0 && index < len()@pre
{
  if index < 0 || index >= data.len() { return None; }
  return Some(data[index]);
}

// ============================================================================
// 6E.1: HashMap[K, V] — O(1) amortized hash-based map
// ============================================================================
// Uses open addressing with linear probing and djb2 hashing.
// Grows by 2x when load factor exceeds 0.75.

use xiom.hash;

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

/// Compute bucket index from key hash.
fn HashMap.bucket_idx[K, V](key: &K) -> Int {
  var h = hash.hash_combine(0, *key);
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
      // Empty bucket — key not found
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
