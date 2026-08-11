// XIOM - Collections: Optimized Keyed Maps
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.intmap

// ============================================================================
// Optimized keyed maps. int_map uses a flat open-addressing table sized for the
// expected capacity (Int keys -> Int values); string_map uses a string-keyed
// variant. Both reject duplicate keys and iterate over stored keys in
// insertion order via int_map_iter.
// ============================================================================

// fn int_map_new(capacity: Int) - create an Int-keyed map with capacity slots. TODO(compiler): implement.
// fn int_map_put(m, key: Int, value: Int) - insert or overwrite key/value. TODO(compiler): implement.
// fn int_map_get(m, key) -> Option[Int] - value for key, or None. TODO(compiler): implement.
// fn int_map_contains(m, key) -> Bool - true if key is present. TODO(compiler): implement.
// fn int_map_remove(m, key) -> Bool - remove key; true if it was present. TODO(compiler): implement.
// fn int_map_size(m) -> Int - number of key/value pairs. TODO(compiler): implement.
// fn int_map_iter(m) -> Vec[Int] - all keys in insertion order. TODO(compiler): implement.
// fn string_map_new() - create a Str-keyed map. TODO(compiler): implement.
// fn string_map_put(m, key: Str, value: Int) - insert or overwrite key/value. TODO(compiler): implement.
// fn string_map_get(m, key) -> Option[Int] - value for key, or None. TODO(compiler): implement.
// fn string_map_contains(m, key) -> Bool - true if key is present. TODO(compiler): implement.
// fn string_map_remove(m, key) -> Bool - remove key; true if it was present. TODO(compiler): implement.
// fn string_map_size(m) -> Int - number of key/value pairs. TODO(compiler): implement.
