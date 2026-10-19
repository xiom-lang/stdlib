// p_nested_generic_ptr_read.xi -- a generic call nested as the argument of
// ptr.read is silently mis-typed (wrong payload, no diagnostic)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0, `nested=42 local=42`.
// Observed on compiler v0.64.6 (official archive) and v0.64.7 (extract):
// compile rc 0, run rc 1, `nested=0 local=42`. `ptr.read(identity_ptr[T](p))`
// reads the erased `T` (8 bytes) instead of `Pair[T]` (16 bytes), so the
// returned struct is zeroed. Staging the generic call in a local first is
// the verified shape (`local`).
//
// Impact: the handle form of `xiom.sync.channel` stages the cell pointer in a
// local before every ptr.read/ptr.write for this reason (see the module-level
// compiler note). Found by the wave-188 mandatory probe (wishlist row 47 /
// REL-20261018-1518-xvector-2); distinct from REL-20261018-1546 (callee
// reads of &Vec[GenericStruct], still red on these pins).
// This file is excluded from tools/probes/ until the compiler fixes it.

module p_nested_generic_ptr_read

use xiom.io;
use xiom.convert;
use xiom.alloc;
use xiom.ptr;
use xiom.core.size_of;

type Pair[T] = { a: Int; b: Int; }

fn identity_ptr[T](p: *Pair[T]) -> *Pair[T]
  requires: p != null
{
  unsafe { return p; }
}

fn nested_implicit[T](p: *Pair[T]) -> Int {
  let q = ptr.read(identity_ptr[T](p));
  return q.a + q.b;
}

fn local_implicit[T](p: *Pair[T]) -> Int {
  let q0 = identity_ptr[T](p);
  let q = ptr.read(q0);
  return q.a + q.b;
}

fn main() -> Int {
  let cell = alloc.alloc(size_of[Pair[Int]]());
  let v = Pair[Int]{ a: 20; b: 22; };
  unsafe { ptr.write(cell as *Pair[Int], v); }
  var p: *Pair[Int];
  unsafe { p = cell as *Pair[Int]; }

  let nested = nested_implicit[Int](p);
  let local = local_implicit[Int](p);
  io.println("nested=" + convert.int_to_string(nested)
    + " local=" + convert.int_to_string(local));

  unsafe { alloc.dealloc(cell, size_of[Pair[Int]]()); }
  if nested != 42 { return 1; }
  if local != 42 { return 2; }
  return 0;
}
