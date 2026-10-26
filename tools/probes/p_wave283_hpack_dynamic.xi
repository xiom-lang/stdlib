// p_wave283_hpack_dynamic.xi -- HPACK dynamic table (RFC 7541 section 2.3).
// Locks insert, newest-first indexing, size accounting, eviction, max-size
// changes, clear, and the oversized-entry rule. Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave283_hpack_dynamic

use xiom.net.h2;

fn main() -> Int {
  var t = h2.h2_hpack_dynamic_new(4096);
  if h2.h2_hpack_dynamic_len(&t) != 0 { return 1; }
  if h2.h2_hpack_dynamic_size(&t) != 0 { return 2; }

  h2.h2_hpack_dynamic_add(&mut t, ":method", "GET");
  if h2.h2_hpack_dynamic_len(&t) != 1 { return 3; }
  if h2.h2_hpack_dynamic_size(&t) != 42 { return 4; }   // 7+3+32

  h2.h2_hpack_dynamic_add(&mut t, "cache-control", "no-cache");
  if h2.h2_hpack_dynamic_len(&t) != 2 { return 5; }
  if h2.h2_hpack_dynamic_size(&t) != 95 { return 6; }   // +13+8+32

  let g1 = h2.h2_hpack_dynamic_get(&t, 1);
  if g1.is_none { return 7; }
  if g1.value.0 != "cache-control" { return 8; }
  if g1.value.1 != "no-cache" { return 9; }
  let g2 = h2.h2_hpack_dynamic_get(&t, 2);
  if g2.is_none { return 10; }
  if g2.value.0 != ":method" { return 11; }
  if h2.h2_hpack_dynamic_get(&t, 0).is_some { return 12; }
  if h2.h2_hpack_dynamic_get(&t, 3).is_some { return 13; }

  // A max below the current size evicts every entry.
  h2.h2_hpack_dynamic_set_max(&mut t, 50);
  if h2.h2_hpack_dynamic_len(&t) != 0 { return 14; }
  if h2.h2_hpack_dynamic_size(&t) != 0 { return 15; }

  h2.h2_hpack_dynamic_add(&mut t, "a", "b");
  if h2.h2_hpack_dynamic_len(&t) != 1 { return 16; }
  h2.h2_hpack_dynamic_set_max(&mut t, 100);
  h2.h2_hpack_dynamic_add(&mut t, "c", "d");
  h2.h2_hpack_dynamic_add(&mut t, "e", "f");
  // Three 34-byte entries would be 102 > 100, so the oldest evicts.
  if h2.h2_hpack_dynamic_len(&t) != 2 { return 17; }
  if h2.h2_hpack_dynamic_size(&t) != 68 { return 18; }
  let n1 = h2.h2_hpack_dynamic_get(&t, 1);
  if n1.is_none { return 19; }
  if n1.value.0 != "e" { return 20; }
  let n2 = h2.h2_hpack_dynamic_get(&t, 2);
  if n2.is_none { return 21; }
  if n2.value.0 != "c" { return 22; }
  if h2.h2_hpack_dynamic_get(&t, 3).is_some { return 23; }

  h2.h2_hpack_dynamic_clear(&mut t);
  if h2.h2_hpack_dynamic_len(&t) != 0 { return 24; }
  if h2.h2_hpack_dynamic_size(&t) != 0 { return 25; }

  // Entry bigger than max_size clears the table and is not inserted.
  h2.h2_hpack_dynamic_set_max(&mut t, 50);
  h2.h2_hpack_dynamic_add(&mut t, "0123456789", "0123456789");
  if h2.h2_hpack_dynamic_len(&t) != 0 { return 26; }

  // max_size 0 accepts nothing.
  var z = h2.h2_hpack_dynamic_new(0);
  h2.h2_hpack_dynamic_add(&mut z, "a", "b");
  if h2.h2_hpack_dynamic_len(&z) != 0 { return 27; }

  return 0;
}
