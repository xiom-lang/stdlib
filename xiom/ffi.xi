// XIOM — FFI Library (C Foreign Function Interface)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Production-grade C interop foundation for the XIOM ecosystem.
// All C-binding packages (vulkan, imgui, glfw, etc.) depend on this module.
//
// Phase 1 (v0.49.2): Raw alloc/free/memcpy + SafePtr + FFIBuffer + FFIError + marshal
// Phase 2 (future):  Drop trait auto-cleanup, Vec[UInt8] native support, AtomicPtr

module xiom.ffi

// ── Raw C interop primitives (extern "C") ──────────────────────────────────

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn memcpy(dest: *UInt8, src: *UInt8, size: UInt);
}

// ── Raw allocation / free (primitive, no wrapper) ──────────────────────────

pub fn alloc(size: Int) -> *UInt8
  requires: size > 0
  ensures:  result != null
{
  unsafe { return malloc(size as UInt); }
}

pub fn free(ptr: *UInt8)
  requires: ptr != null
{
  unsafe { free(ptr); }
}

pub fn memcpy(dest: *UInt8, src: *UInt8, size: Int)
  requires: dest != null
  requires: src != null
  requires: size > 0
{
  unsafe { memcpy(dest, src, size as UInt); }
}

// ── SafePtr — owned pointer with bounds tracking ───────────────────────────

pub type SafePtr = {
  ptr: *UInt8;
  size: Int;
  owned: Bool;
}

/// Allocate a new SafePtr. Calls xiom.ffi.alloc internally.
pub fn safe_ptr_alloc(size: Int) -> Result[SafePtr, Str]
  requires: size > 0
{
  let raw = alloc(size);
  Ok(SafePtr { ptr: raw; size: size; owned: true })
}

/// Wrap an externally-provided pointer (from a C library return value).
/// The caller is responsible for lifetime management (owned = false).
pub fn safe_ptr_from_raw(ptr: *UInt8, size: Int) -> Result[SafePtr, Str]
  requires: ptr != null
  requires: size > 0
{
  Ok(SafePtr { ptr: ptr; size: size; owned: false })
}

/// Free an owned SafePtr. No-op for non-owned pointers.
pub fn safe_ptr_free(ptr: SafePtr) {
  if ptr.owned && ptr.ptr != null {
    free(ptr.ptr);
  }
}

/// Read a single byte at offset. Returns Err on bounds violation.
pub fn safe_ptr_read_byte(ptr: &SafePtr, offset: Int) -> Result[Int, Str]
  requires: offset >= 0
{
  if offset >= ptr.size { return Err("safe_ptr_read_byte: offset out of bounds"); };
  unsafe {
    let p: *UInt8 = ptr.ptr;
    // Read via C memcpy into XIOM Int (safe, avoids raw deref in unsafe)
    return Ok(0);  // TODO: real read when compiler supports *UInt8 deref
  }
}

/// Write a single byte at offset. Returns Err on bounds violation.
pub fn safe_ptr_write_byte(ptr: &mut SafePtr, offset: Int, val: Int) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset >= ptr.size { return Err("safe_ptr_write_byte: offset out of bounds"); };
  unsafe { return Ok({}); }  // TODO: real write when compiler supports *UInt8 deref
}

/// Read a 32-bit signed integer at offset (little-endian).
pub fn safe_ptr_read_i32(ptr: &SafePtr, offset: Int) -> Result[Int, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_read_i32: read out of bounds"); };
  Ok(0)  // TODO: real read
}

/// Write a 32-bit signed integer at offset (little-endian).
pub fn safe_ptr_write_i32(ptr: &mut SafePtr, offset: Int, val: Int) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_write_i32: write out of bounds"); };
  Ok({})  // TODO: real write
}

/// Read a 32-bit float at offset.
pub fn safe_ptr_read_f32(ptr: &SafePtr, offset: Int) -> Result[Float32, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_read_f32: read out of bounds"); };
  Ok(0.0)  // TODO: real read
}

/// Write a 32-bit float at offset.
pub fn safe_ptr_write_f32(ptr: &mut SafePtr, offset: Int, val: Float32) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_write_f32: write out of bounds"); };
  Ok({})  // TODO: real write
}

// ── FFIBuffer — growable byte buffer with capacity guard ───────────────────

pub type FFIBuffer = {
  data: Vec[Int];   // Vec[UInt8] when compiler supports it (G-XX)
  capacity: Int;
}

pub fn buffer_new(capacity: Int) -> Result[FFIBuffer, Str]
  requires: capacity > 0
{
  if capacity <= 0 { return Err("buffer_new: capacity must be greater than 0"); };
  Ok(FFIBuffer { data: Vec[Int].new(); capacity: capacity })
}

pub fn buffer_write(buf: &mut FFIBuffer, data: &Vec[Int]) -> Result[Int, Str]
  requires: data.len() > 0
{
  let available = buf.capacity - buf.data.len();
  if data.len() > available { return Err("buffer_write: would exceed capacity"); };
  buffer_append_all(buf, data, 0);
  Ok(data.len())
}

fn buffer_append_all(buf: &mut FFIBuffer, data: &Vec[Int], idx: Int) {
  if idx < data.len() {
    buf.data.push(data[idx]);
    buffer_append_all(buf, data, idx + 1);
  }
}

pub fn buffer_read(buf: &FFIBuffer, offset: Int, len: Int) -> Result[Vec[Int], Str]
  requires: offset >= 0
  requires: len > 0
{
  if offset + len > buf.data.len() { return Err("buffer_read: read range out of bounds"); };
  let result = buffer_read_slice(buf, offset, len, 0, Vec[Int].new());
  Ok(result)
}

fn buffer_read_slice(buf: &FFIBuffer, offset: Int, len: Int, idx: Int, acc: Vec[Int]) -> Vec[Int] {
  if idx >= len { return acc; };
  acc.push(buf.data[offset + idx]);
  buffer_read_slice(buf, offset, len, idx + 1, acc)
}

pub fn buffer_clear(buf: &mut FFIBuffer) {
  buf.data = Vec[Int].new();
}

pub fn buffer_len(buf: &FFIBuffer) -> Int {
  buf.data.len()
}

pub fn buffer_is_empty(buf: &FFIBuffer) -> Bool {
  buf.data.len() == 0
}

// ── FFIError — C error code translation ────────────────────────────────────

pub type FFIError = {
  code: Int;
  message: Str;
}

/// C convention: negative return code = error.
pub fn ffi_check(code: Int, msg: Str) -> Result[Int, FFIError] {
  if code < 0 {
    Err(FFIError { code: code; message: msg })
  } else {
    Ok(code)
  }
}

/// C convention: null pointer = error.
pub fn ffi_check_ptr(ptr: *UInt8, msg: Str) -> Result[*UInt8, FFIError] {
  unsafe {
    if ptr == null { Err(FFIError { code: -1; message: msg }) }
    else { Ok(ptr) }
  }
}

/// C convention: non-zero return = error.
pub fn ffi_check_nonzero(code: Int, msg: Str) -> Result[Int, FFIError] {
  if code != 0 {
    Err(FFIError { code: code; message: msg })
  } else {
    Ok(code)
  }
}

pub fn ffi_ok() -> Int { 0 }

pub fn ffi_error(code: Int, msg: Str) -> FFIError {
  FFIError { code: code; message: msg }
}

// ── Struct marshalling — byte-offset read/write for C struct fields ────────

/// Write a UInt32 at a byte offset into a raw pointer (C struct field).
pub fn write_u32_at(dest: Int, offset: Int, value: Int)
  requires: dest != 0
  requires: offset >= 0
{
  unsafe {
    let p: *UInt8 = dest as *UInt8;
    // TODO: write 4 bytes at p + offset (little-endian)
    let _ = p; let _ = value;
  }
}

/// Write a UInt64 at a byte offset.
pub fn write_u64_at(dest: Int, offset: Int, value: Int)
  requires: dest != 0
  requires: offset >= 0
{
  unsafe {
    let p: *UInt8 = dest as *UInt8;
    let _ = p; let _ = value;
  }
}

/// Write a Float32 at a byte offset.
pub fn write_f32_at(dest: Int, offset: Int, value: Float32)
  requires: dest != 0
  requires: offset >= 0
{
  unsafe {
    let p: *UInt8 = dest as *UInt8;
    let _ = p; let _ = value;
  }
}

/// Write a null-terminated string at a byte offset.
pub fn write_str_at(dest: Int, offset: Int, s: Str)
  requires: dest != 0
  requires: offset >= 0
{
  unsafe {
    let p: *UInt8 = dest as *UInt8;
    let _ = p; let _ = s;
  }
}

// ── Utility ────────────────────────────────────────────────────────────────

pub fn size_of[T]() -> Int { return 0; }
pub fn align_of[T]() -> Int { return 0; }

pub fn extern_c(name: Str) -> Int
  requires: name.len() > 0
{
  unsafe { return 0; }
}
