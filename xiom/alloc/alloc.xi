// XIOM -- Memory Allocation
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.alloc

extern "C" {
  fn malloc(size: UInt) -> *mut UInt8;
  fn free(ptr: *mut UInt8);
  fn realloc(ptr: *mut UInt8, size: UInt) -> *mut UInt8;
  fn memset(ptr: *mut UInt8, value: Int, size: UInt) -> *mut UInt8;
}

pub type Layout = { size: Int; align: Int; } derive[Eq, Clone]

pub fn Layout.new(size: Int) -> Layout {
  Layout{ size: size, align: 8 }
}

pub fn Layout.with_align(self, align: Int) -> Layout {
  Layout{ size: self.size, align: align }
}

pub fn Layout.padded_size(self) -> Int {
  (self.size + self.align - 1) / self.align * self.align
}

pub interface Allocator {
  fn allocate(self, layout: Layout) -> Result<*mut UInt8, AllocError>;
  fn deallocate(self, ptr: *mut UInt8, layout: Layout);
  fn allocate_zeroed(self, layout: Layout) -> Result<*mut UInt8, AllocError>;
  fn grow(self, ptr: *mut UInt8, old: Layout, new: Layout) -> Result<*mut UInt8, AllocError>;
  fn shrink(self, ptr: *mut UInt8, old: Layout, new: Layout) -> Result<*mut UInt8, AllocError>;
}

pub type AllocError = { message: Str; } derive[Clone]

pub type GlobalAlloc = { }

// Returns the concrete GlobalAlloc (the Allocator interface is a bound for
// generic code, not a value type the checker can return).
pub fn global_alloc() -> GlobalAlloc {
  GlobalAlloc{ }
}

pub fn GlobalAlloc.allocate(self, layout: Layout) -> Result<*mut UInt8, AllocError>
  requires: layout.size > 0
  ensures:  result is Ok => result != null
{
  unsafe {
    let ptr = malloc(layout.size as UInt);
    if ptr == null {
      return Result{ is_ok: false, value: null, error: AllocError{ message: "allocation failed" } };
    };
    return Result{ is_ok: true, value: ptr, error: AllocError{ message: "" } };
  }
}

pub fn GlobalAlloc.deallocate(self, ptr: *mut UInt8, layout: Layout)
  requires: ptr != null
{
  unsafe {
    free(ptr);
  }
}

pub fn GlobalAlloc.allocate_zeroed(self, layout: Layout) -> Result<*mut UInt8, AllocError>
  requires: layout.size > 0
  ensures:  result is Ok => result != null
{
  unsafe {
    let ptr = malloc(layout.size as UInt);
    if ptr == null {
      return Result{ is_ok: false, value: null, error: AllocError{ message: "allocation failed" } };
    };
    memset(ptr, 0, layout.size as UInt);
    return Result{ is_ok: true, value: ptr, error: AllocError{ message: "" } };
  }
}

pub fn GlobalAlloc.grow(self, ptr: *mut UInt8, old: Layout, new: Layout) -> Result<*mut UInt8, AllocError>
  requires: ptr != null
  requires: new.size > old.size
{
  unsafe {
    let new_ptr = realloc(ptr, new.size as UInt);
    if new_ptr == null {
      return Result{ is_ok: false, value: null, error: AllocError{ message: "reallocation failed" } };
    };
    return Result{ is_ok: true, value: new_ptr, error: AllocError{ message: "" } };
  }
}

pub fn GlobalAlloc.shrink(self, ptr: *mut UInt8, old: Layout, new: Layout) -> Result<*mut UInt8, AllocError>
  requires: ptr != null
  requires: new.size < old.size
  requires: new.size > 0
{
  unsafe {
    let new_ptr = realloc(ptr, new.size as UInt);
    if new_ptr == null {
      return Result{ is_ok: false, value: null, error: AllocError{ message: "reallocation failed" } };
    };
    return Result{ is_ok: true, value: new_ptr, error: AllocError{ message: "" } };
  }
}

// Global allocator (wraps malloc/free)
pub fn alloc(size: Int) -> *mut UInt8
  requires: size > 0
  ensures:  result != null
{
  unsafe {
    return malloc(size as UInt);
  }
}

pub fn alloc_zeroed(size: Int) -> *mut UInt8
  requires: size > 0
  ensures:  result != null
{
  unsafe {
    let ptr = malloc(size as UInt);
    memset(ptr, 0, size as UInt);
    return ptr;
  }
}

// Resize an allocation. Named realloc_sized to avoid shadowing the C ABI
// symbol `realloc` -- a same-named wrapper would collide with the extern
// declaration and be silently dropped from codegen.
pub fn realloc_sized(ptr: *mut UInt8, old_size: Int, new_size: Int) -> *mut UInt8
  requires: ptr != null
  requires: new_size > 0
  ensures:  result != null
{
  unsafe {
    return realloc(ptr, new_size as UInt);
  }
}

pub fn dealloc(ptr: *mut UInt8, size: Int)
  requires: ptr != null
{
  unsafe {
    free(ptr);
  }
}

// Sized allocation
pub fn alloc_layout(layout: Layout) -> *mut UInt8
  requires: layout.size > 0
  ensures:  result != null
{
  unsafe {
    return malloc(layout.size as UInt);
  }
}

pub fn dealloc_layout(ptr: *mut UInt8, layout: Layout)
  requires: ptr != null
{
  unsafe {
    free(ptr);
  }
}
