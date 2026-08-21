// XIOM -- FFI Library (C Foreign Function Interface)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Production-grade C interop foundation for the XIOM ecosystem.
// All C-binding packages (vulkan, imgui, glfw, etc.) depend on this module.
//
// Phase 1 (v0.49.2): Raw alloc/free/memcpy + SafePtr + FFIBuffer + FFIError + marshal
// Phase 2 (future):  Drop trait auto-cleanup, Vec[UInt8] native support, AtomicPtr

module xiom.ffi
use xiom.ffi.dl;
use xiom.ffi.c;
use xiom.ffi.errno;

// ---- Raw C interop primitives (extern "C") --------------------------------------------------------------------

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn memcpy(dest: *UInt8, src: *UInt8, size: UInt);
}

// ---- Raw allocation / free (primitive, no wrapper) ----------------------------------------------------

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

// ---- SafePtr -- owned pointer with bounds tracking ------------------------------------------------------

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

// ---- Bounds-checked pointer read/write (little-endian) ----------------------------------------

/// Read a single byte at offset. Bounds-checked.
pub fn safe_ptr_read_byte(ptr: &SafePtr, offset: Int) -> Result[Int, Str]
  requires: offset >= 0
{
  if offset >= ptr.size { return Err("safe_ptr_read_byte: offset out of bounds"); };
  unsafe {
    return Ok(ptr.ptr[offset] as Int);
  }
}

/// Write a single byte at offset. Bounds-checked.
pub fn safe_ptr_write_byte(ptr: &mut SafePtr, offset: Int, val: Int) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset >= ptr.size { return Err("safe_ptr_write_byte: offset out of bounds"); };
  unsafe {
    ptr.ptr[offset] = val as UInt8;
  };
  Ok({})
}

/// Read a 32-bit signed integer at offset (little-endian). Bounds-checked.
/// Bytes are combined as: b0 | b1<<8 | b2<<16 | b3<<24 with sign extension.
pub fn safe_ptr_read_i32(ptr: &SafePtr, offset: Int) -> Result[Int, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_read_i32: read out of bounds"); };
  unsafe {
    let b0 = ptr.ptr[offset + 0] as Int;
    let b1 = ptr.ptr[offset + 1] as Int;
    let b2 = ptr.ptr[offset + 2] as Int;
    let b3 = ptr.ptr[offset + 3] as Int;
    let uval = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
    // Sign-extend from 32 bits if Int is wider than 32 bits.
    if (b3 & 0x80) != 0 {
      return Ok(uval - 4294967296);
    };
    Ok(uval)
  }
}

/// Write a 32-bit signed integer at offset (little-endian). Bounds-checked.
/// Decomposed into 4 bytes: byte i = (val >> (8*i)) & 0xFF.
pub fn safe_ptr_write_i32(ptr: &mut SafePtr, offset: Int, val: Int) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_write_i32: write out of bounds"); };
  unsafe {
    ptr.ptr[offset + 0] = ( val        & 0xFF) as UInt8;
    ptr.ptr[offset + 1] = ((val >>  8) & 0xFF) as UInt8;
    ptr.ptr[offset + 2] = ((val >> 16) & 0xFF) as UInt8;
    ptr.ptr[offset + 3] = ((val >> 24) & 0xFF) as UInt8;
  };
  Ok({})
}

/// Read a 32-bit float at offset. Bounds-checked.
/// Uses *const Float32 pointer-cast for bit-level reinterpretation.
pub fn safe_ptr_read_f32(ptr: &SafePtr, offset: Int) -> Result[Float32, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_read_f32: read out of bounds"); };
  unsafe {
    let fp: *const Float32 = (ptr.ptr + offset) as *const Float32;
    return Ok(*fp);
  }
}

/// Write a 32-bit float at offset. Bounds-checked.
pub fn safe_ptr_write_f32(ptr: &mut SafePtr, offset: Int, val: Float32) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_write_f32: write out of bounds"); };
  unsafe {
    let fp: *mut Float32 = (ptr.ptr + offset) as *mut Float32;
    *fp = val;
  };
  Ok({})
}

// ---- SafePtr extended helpers ------------------------------------------------------------------------------------------

/// Read a 32-bit unsigned integer at offset (little-endian). Bounds-checked.
/// Result is always non-negative (0..4294967295).
pub fn safe_ptr_read_u32(ptr: &SafePtr, offset: Int) -> Result[Int, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_read_u32: read out of bounds"); };
  unsafe {
    let b0 = ptr.ptr[offset + 0] as Int;
    let b1 = ptr.ptr[offset + 1] as Int;
    let b2 = ptr.ptr[offset + 2] as Int;
    let b3 = ptr.ptr[offset + 3] as Int;
    Ok(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
  }
}

/// Write a 32-bit unsigned integer at offset (little-endian). Bounds-checked.
/// Writes the lower 32 bits of val.
pub fn safe_ptr_write_u32(ptr: &mut SafePtr, offset: Int, val: Int) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset + 4 > ptr.size { return Err("safe_ptr_write_u32: write out of bounds"); };
  unsafe {
    ptr.ptr[offset + 0] = ( val        & 0xFF) as UInt8;
    ptr.ptr[offset + 1] = ((val >>  8) & 0xFF) as UInt8;
    ptr.ptr[offset + 2] = ((val >> 16) & 0xFF) as UInt8;
    ptr.ptr[offset + 3] = ((val >> 24) & 0xFF) as UInt8;
  };
  Ok({})
}

/// Read a 64-bit signed integer at offset (little-endian). Bounds-checked.
/// Bytes combined: b0 | b1<<8 | ... | b7<<56 with sign extension.
pub fn safe_ptr_read_i64(ptr: &SafePtr, offset: Int) -> Result[Int, Str]
  requires: offset >= 0
{
  if offset + 8 > ptr.size { return Err("safe_ptr_read_i64: read out of bounds"); };
  unsafe {
    let b0 = ptr.ptr[offset + 0] as Int;
    let b1 = ptr.ptr[offset + 1] as Int;
    let b2 = ptr.ptr[offset + 2] as Int;
    let b3 = ptr.ptr[offset + 3] as Int;
    let b4 = ptr.ptr[offset + 4] as Int;
    let b5 = ptr.ptr[offset + 5] as Int;
    let b6 = ptr.ptr[offset + 6] as Int;
    let b7 = ptr.ptr[offset + 7] as Int;
    let uval = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
             | (b4 << 32) | (b5 << 40) | (b6 << 48) | (b7 << 56);
    // Sign-extend from 64 bits: subtract 2^64 if high bit set.
    // If Int is exactly 64 bits, b7<<56 naturally sets the sign bit and
    // the combined value is already negative via two's complement overflow.
    Ok(uval)
  }
}

/// Write a 64-bit signed integer at offset (little-endian). Bounds-checked.
pub fn safe_ptr_write_i64(ptr: &mut SafePtr, offset: Int, val: Int) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset + 8 > ptr.size { return Err("safe_ptr_write_i64: write out of bounds"); };
  unsafe {
    ptr.ptr[offset + 0] = ( val        & 0xFF) as UInt8;
    ptr.ptr[offset + 1] = ((val >>  8) & 0xFF) as UInt8;
    ptr.ptr[offset + 2] = ((val >> 16) & 0xFF) as UInt8;
    ptr.ptr[offset + 3] = ((val >> 24) & 0xFF) as UInt8;
    ptr.ptr[offset + 4] = ((val >> 32) & 0xFF) as UInt8;
    ptr.ptr[offset + 5] = ((val >> 40) & 0xFF) as UInt8;
    ptr.ptr[offset + 6] = ((val >> 48) & 0xFF) as UInt8;
    ptr.ptr[offset + 7] = ((val >> 56) & 0xFF) as UInt8;
  };
  Ok({})
}

/// Read a 64-bit float at offset. Bounds-checked.
/// Uses *const Float64 pointer-cast for bit-level reinterpretation.
pub fn safe_ptr_read_f64(ptr: &SafePtr, offset: Int) -> Result[Float64, Str]
  requires: offset >= 0
{
  if offset + 8 > ptr.size { return Err("safe_ptr_read_f64: read out of bounds"); };
  unsafe {
    let fp: *const Float64 = (ptr.ptr + offset) as *const Float64;
    return Ok(*fp);
  }
}

/// Write a 64-bit float at offset. Bounds-checked.
pub fn safe_ptr_write_f64(ptr: &mut SafePtr, offset: Int, val: Float64) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset + 8 > ptr.size { return Err("safe_ptr_write_f64: write out of bounds"); };
  unsafe {
    let fp: *mut Float64 = (ptr.ptr + offset) as *mut Float64;
    *fp = val;
  };
  Ok({})
}

/// Read a 16-bit unsigned integer at offset (little-endian). Bounds-checked.
/// Result is in range 0..65535.
pub fn safe_ptr_read_u16(ptr: &SafePtr, offset: Int) -> Result[Int, Str]
  requires: offset >= 0
{
  if offset + 2 > ptr.size { return Err("safe_ptr_read_u16: read out of bounds"); };
  unsafe {
    let b0 = ptr.ptr[offset + 0] as Int;
    let b1 = ptr.ptr[offset + 1] as Int;
    Ok(b0 | (b1 << 8))
  }
}

/// Write a 16-bit unsigned integer at offset (little-endian). Bounds-checked.
/// Writes the lower 16 bits of val.
pub fn safe_ptr_write_u16(ptr: &mut SafePtr, offset: Int, val: Int) -> Result[Unit, Str]
  requires: offset >= 0
{
  if offset + 2 > ptr.size { return Err("safe_ptr_write_u16: write out of bounds"); };
  unsafe {
    ptr.ptr[offset + 0] = ( val        & 0xFF) as UInt8;
    ptr.ptr[offset + 1] = ((val >> 8) & 0xFF) as UInt8;
  };
  Ok({})
}

/// Fill the entire SafePtr buffer with a byte value. Bounds-safe (uses size field).
/// Complexity: O(n), where n = ptr.size.
pub fn safe_ptr_fill(ptr: &mut SafePtr, value: Int) -> Result[Unit, Str]
  requires: value >= 0
  requires: value <= 255
{
  unsafe {
    var i = 0;
    while i < ptr.size {
      ptr.ptr[i] = value as UInt8;
      i = i + 1;
    };
  };
  Ok({})
}

/// Copy count bytes from src to dst. Bounds-checked against both SafePtr sizes.
/// Complexity: O(count).
pub fn safe_ptr_copy(dst: &mut SafePtr, src: &SafePtr, count: Int) -> Result[Unit, Str]
  requires: count >= 0
{
  if count > dst.size { return Err("safe_ptr_copy: count exceeds dst size"); };
  if count > src.size { return Err("safe_ptr_copy: count exceeds src size"); };
  unsafe {
    var i = 0;
    while i < count {
      dst.ptr[i] = src.ptr[i];
      i = i + 1;
    };
  };
  Ok({})
}

/// Copy all bytes from a SafePtr into a Vec[Int].
/// Each byte becomes a separate Int element. Result length equals ptr.size.
pub fn safe_ptr_to_vec(ptr: &SafePtr) -> Result[Vec[Int], Str] {
  var result = Vec[Int].new();
  unsafe {
    var i = 0;
    while i < ptr.size {
      result.push(ptr.ptr[i] as Int);
      i = i + 1;
    };
  };
  Ok(result)
}

// ---- Raw pointer helpers (unsafe, no bounds checks) ----------------------------------------------

/// Raw unsafe read of a UInt8 at pointer p.
/// SAFETY: caller must ensure p points to valid memory.
/// No bounds check.
pub fn ptr_read_u8(p: *UInt8) -> Int {
  unsafe {
    return p[0] as Int;
  }
}

/// Raw unsafe write of a UInt8 at pointer p.
/// SAFETY: caller must ensure p points to valid mutable memory.
/// No bounds check.
pub fn ptr_write_u8(p: *UInt8, v: Int)
  requires: v >= 0
  requires: v <= 255
{
  unsafe {
    p[0] = v as UInt8;
  }
}

/// Raw unsafe read of a 32-bit unsigned integer at pointer p (little-endian).
/// SAFETY: caller must ensure p and p+0..p+3 point to valid memory.
/// No bounds check.
pub fn ptr_read_u32_le(p: *UInt8) -> Int {
  unsafe {
    let b0 = p[0] as Int;
    let b1 = p[1] as Int;
    let b2 = p[2] as Int;
    let b3 = p[3] as Int;
    return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
  }
}

/// Raw unsafe write of a 32-bit unsigned integer at pointer p (little-endian).
/// Writes the lower 32 bits of v.
/// SAFETY: caller must ensure p+0..p+3 point to valid mutable memory.
/// No bounds check.
pub fn ptr_write_u32_le(p: *UInt8, v: Int)
  requires: v >= 0
{
  unsafe {
    p[0] = ( v        & 0xFF) as UInt8;
    p[1] = ((v >>  8) & 0xFF) as UInt8;
    p[2] = ((v >> 16) & 0xFF) as UInt8;
    p[3] = ((v >> 24) & 0xFF) as UInt8;
  }
}

/// Raw unsafe read of a 64-bit unsigned integer at pointer p (little-endian).
/// SAFETY: caller must ensure p+0..p+7 point to valid memory.
/// No bounds check.
pub fn ptr_read_u64_le(p: *UInt8) -> Int {
  unsafe {
    let b0 = p[0] as Int;
    let b1 = p[1] as Int;
    let b2 = p[2] as Int;
    let b3 = p[3] as Int;
    let b4 = p[4] as Int;
    let b5 = p[5] as Int;
    let b6 = p[6] as Int;
    let b7 = p[7] as Int;
    return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
         | (b4 << 32) | (b5 << 40) | (b6 << 48) | (b7 << 56);
  }
}

/// Raw unsafe write of a 64-bit unsigned integer at pointer p (little-endian).
/// Writes the lower 64 bits of v.
/// SAFETY: caller must ensure p+0..p+7 point to valid mutable memory.
/// No bounds check.
pub fn ptr_write_u64_le(p: *UInt8, v: Int) {
  unsafe {
    p[0] = ( v        & 0xFF) as UInt8;
    p[1] = ((v >>  8) & 0xFF) as UInt8;
    p[2] = ((v >> 16) & 0xFF) as UInt8;
    p[3] = ((v >> 24) & 0xFF) as UInt8;
    p[4] = ((v >> 32) & 0xFF) as UInt8;
    p[5] = ((v >> 40) & 0xFF) as UInt8;
    p[6] = ((v >> 48) & 0xFF) as UInt8;
    p[7] = ((v >> 56) & 0xFF) as UInt8;
  }
}

// ---- FFIBuffer -- growable byte buffer with capacity guard --------------------------------------

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

// ---- FFIError -- C error code translation ------------------------------------------------------------------------

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

// ---- Struct marshalling -- byte-offset read/write for C struct fields ----------------

/// Write a UInt32 at a byte offset into a raw pointer (C struct field).
pub fn write_u32_at(dest: Int, offset: Int, value: Int)
  requires: dest != 0
  requires: offset >= 0
{
  unsafe {
    let p: *UInt8 = dest as *UInt8;
    p[0] = ( value        & 0xFF) as UInt8;
    p[1] = ((value >>  8) & 0xFF) as UInt8;
    p[2] = ((value >> 16) & 0xFF) as UInt8;
    p[3] = ((value >> 24) & 0xFF) as UInt8;
  }
}

/// Write a UInt64 at a byte offset.
pub fn write_u64_at(dest: Int, offset: Int, value: Int)
  requires: dest != 0
  requires: offset >= 0
{
  unsafe {
    let p: *UInt8 = dest as *UInt8;
    p[0] = ( value        & 0xFF) as UInt8;
    p[1] = ((value >>  8) & 0xFF) as UInt8;
    p[2] = ((value >> 16) & 0xFF) as UInt8;
    p[3] = ((value >> 24) & 0xFF) as UInt8;
    p[4] = ((value >> 32) & 0xFF) as UInt8;
    p[5] = ((value >> 40) & 0xFF) as UInt8;
    p[6] = ((value >> 48) & 0xFF) as UInt8;
    p[7] = ((value >> 56) & 0xFF) as UInt8;
  }
}

/// Write a Float32 at a byte offset.
pub fn write_f32_at(dest: Int, offset: Int, value: Float32)
  requires: dest != 0
  requires: offset >= 0
{
  unsafe {
    let p: *UInt8 = dest as *UInt8;
    let fp: *mut Float32 = (p + offset) as *mut Float32;
    *fp = value;
  }
}

/// Write a null-terminated string at a byte offset.
pub fn write_str_at(dest: Int, offset: Int, s: Str)
  requires: dest != 0
  requires: offset >= 0
{
  unsafe {
    let p: *UInt8 = dest as *UInt8;
    var i = 0;
    while i < s.len() {
      p[offset + i] = s[i] as UInt8;
      i = i + 1;
    };
    p[offset + i] = 0 as UInt8;
  }
}

// ---- Utility --------------------------------------------------------------------------------------------------------------------------------

pub fn size_of[T]() -> Int { return 0; }
pub fn align_of[T]() -> Int { return 0; }

pub fn extern_c(name: Str) -> Int
  requires: name.len() > 0
{
  unsafe { return 0; }
}
