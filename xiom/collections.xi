// XIOM — Collections Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collections

// === Vec ===
type Vec[T] = {
  data: *T;
  len: Int;
  cap: Int;
}

fn Vec.new[T]() -> Vec[T] {
  return Vec[T]{ data: 0 as *T, len: 0, cap: 0 };
}

fn Vec.with_capacity[T](cap: Int) -> Vec[T] {
  var v = Vec[T].new();
  v.cap = cap;
  return v;
}

fn Vec.push[T](value: T) {
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

fn Vec.pop[T]() -> Option[T] {
  if len == 0 { return None; }
  len = len - 1;
  unsafe {
    return Some(*(data + len));
  }
}

fn Vec.get[T](index: Int) -> Option[T] {
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

fn Vec.clear[T]() {
  len = 0;
}

fn Vec.insert[T](index: Int, value: T) {
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

fn Vec.remove[T](index: Int) -> Option[T] {
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

fn Vec.first[T]() -> Option[T] {
  if len == 0 { return None; }
  unsafe {
    return Some(*(data + 0));
  }
}

fn Vec.last[T]() -> Option[T] {
  if len == 0 { return None; }
  unsafe {
    return Some(*(data + len - 1));
  }
}

fn Vec.set[T](index: Int, value: T) {
  if index < 0 || index >= len { return; }
  unsafe {
    *(data + index) = value;
  }
}

// === Map ===
type Map[K, V] = {
  keys: Vec[K];
  values: Vec[V];
}

fn Map.new[K, V]() -> Map[K, V] {
  return Map[K, V]{ keys: Vec[K].new(), values: Vec[V].new() };
}

fn Map.insert[K, V](key: K, value: V) {
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

fn Map.get[K, V](key: &K) -> Option[V] {
  var i = 0;
  while i < keys.len() {
    if keys[i] == *key {
      return Some(values[i]);
    }
    i = i + 1;
  }
  return None;
}

fn Map.remove[K, V](key: &K) -> Option[V] {
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

fn Map.clear[K, V]() {
  keys.clear();
  values.clear();
}

// === Set ===
type Set[T] = {
  items: Vec[T];
}

fn Set.new[T]() -> Set[T] {
  return Set[T]{ items: Vec[T].new() };
}

fn Set.insert[T](value: T) {
  var i = 0;
  while i < items.len() {
    if items[i] == value { return; }
    i = i + 1;
  }
  items.push(value);
}

fn Set.remove[T](value: &T) {
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

fn Set.union[T](other: &Set[T]) -> Set[T] {
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

fn Set.intersection[T](other: &Set[T]) -> Set[T] {
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

fn Set.difference[T](other: &Set[T]) -> Set[T] {
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
}

fn LinkedList.new[T]() -> LinkedList[T] {
  return LinkedList[T]{ items: Vec[T].new() };
}

fn LinkedList.push_front[T](value: T) {
  var new_items = Vec[T].new();
  new_items.push(value);
  var i = 0;
  while i < items.len() {
    new_items.push(items[i]);
    i = i + 1;
  }
  items = new_items;
}

fn LinkedList.push_back[T](value: T) {
  items.push(value);
}

fn LinkedList.pop_front[T]() -> Option[T] {
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

fn LinkedList.pop_back[T]() -> Option[T] {
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
}

fn Queue.new[T]() -> Queue[T] {
  return Queue[T]{ data: Vec[T].new(), head: 0, tail: 0 };
}

fn Queue.enqueue[T](value: T) {
  data.push(value);
  tail = tail + 1;
}

fn Queue.dequeue[T]() -> Option[T] {
  if head >= tail { return None; }
  var val = data[head];
  head = head + 1;
  return Some(val);
}

fn Queue.peek[T]() -> Option[T] {
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
}

fn Stack.new[T]() -> Stack[T] {
  return Stack[T]{ items: Vec[T].new() };
}

fn Stack.push[T](value: T) {
  items.push(value);
}

fn Stack.pop[T]() -> Option[T] {
  if items.len() == 0 { return None; }
  var idx = items.len() - 1;
  var val = items[idx];
  items.pop();
  return Some(val);
}

fn Stack.peek[T]() -> Option[T] {
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
}

fn VecDeque.new[T]() -> VecDeque[T] {
  return VecDeque[T]{ data: Vec[T].new(), head: 0, tail: 0 };
}

fn VecDeque.with_capacity[T](cap: Int) -> VecDeque[T] {
  return VecDeque[T]{ data: Vec[T].with_capacity(cap), head: 0, tail: 0 };
}

fn VecDeque.push_front[T](value: T) {
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

fn VecDeque.push_back[T](value: T) {
  data.push(value);
  tail = data.len();
}

fn VecDeque.pop_front[T]() -> Option[T] {
  if head >= tail { return None; }
  var val = data[head];
  head = head + 1;
  return Some(val);
}

fn VecDeque.pop_back[T]() -> Option[T] {
  if head >= tail { return None; }
  tail = tail - 1;
  return Some(data[tail]);
}

fn VecDeque.front[T]() -> Option[T] {
  if head >= tail { return None; }
  return Some(data[head]);
}

fn VecDeque.back[T]() -> Option[T] {
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
}

fn BTreeMap.new[K: Ord, V]() -> BTreeMap[K, V] {
  return BTreeMap[K, V]{ keys: Vec[K].new(), values: Vec[V].new() };
}

fn BTreeMap.insert[K: Ord, V](key: K, value: V) -> Option[V] {
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

fn BTreeMap.get[K: Ord, V](key: &K) -> Option[V] {
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

fn BTreeMap.remove[K: Ord, V](key: &K) -> Option[V] {
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

fn BTreeMap.first_entry[K: Ord, V]() -> Option[(K, V)] {
  if keys.len() == 0 { return None; }
  return Some((keys[0], values[0]));
}

fn BTreeMap.last_entry[K: Ord, V]() -> Option[(K, V)] {
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
}

fn BTreeSet.new[T: Ord]() -> BTreeSet[T] {
  return BTreeSet[T]{ items: Vec[T].new() };
}

fn BTreeSet.insert[T: Ord](value: T) -> Bool {
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

fn BTreeSet.remove[T: Ord](value: &T) -> Bool {
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

fn BTreeSet.first[T: Ord]() -> Option[T] {
  if items.len() == 0 { return None; }
  return Some(items[0]);
}

fn BTreeSet.last[T: Ord]() -> Option[T] {
  if items.len() == 0 { return None; }
  return Some(items[items.len() - 1]);
}

fn BTreeSet.len[T: Ord]() -> Int {
  return items.len();
}

// === Slice methods ===
type Slice[T] = {
  data: Vec[T];
}

fn Slice.len[T]() -> Int {
  return data.len();
}

fn Slice.is_empty[T]() -> Bool {
  return data.len() == 0;
}

fn Slice.first[T]() -> Option[T] {
  if data.len() == 0 { return None; }
  return Some(data[0]);
}

fn Slice.last[T]() -> Option[T] {
  if data.len() == 0 { return None; }
  return Some(data[data.len() - 1]);
}

fn Slice.get[T](index: Int) -> Option[T] {
  if index < 0 || index >= data.len() { return None; }
  return Some(data[index]);
}
