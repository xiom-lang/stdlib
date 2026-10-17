// XIOM - Compression: ZIP container (row 22)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress.zip

// Depends on: xiom.compress.crc32, xiom.compress.deflate, xiom.string.builder

use xiom.compress.crc32;
use xiom.compress.deflate;
use xiom.string.builder;

// ============================================================================
// ZIP container read/write (APPNOTE.TXT shape, zip32 subset):
//   - reader: EOCD scan (comment-tolerant), central-directory walk, local
//     header parse, methods 0 (stored) and 8 (deflate), CRC-32 verification
//     against the neutral xiom.compress.crc32, decompression through the
//     wave-158 RFC 1951 decoder (dynamic blocks included).
//   - writer: minimal valid archive -- local headers (no data descriptors),
//     central directory, EOCD; methods 0/8 with correct CRC-32 and sizes.
//
// Out of scope (honest errors): zip64, encryption, multi-disk, methods other
// than stored/deflate. Entry names are the raw UTF-8 bytes of the `Str`
// given / read back; `/` separators are the caller's choice.
//
// The wave-158 note on module-level arrays applies: no module-level tables
// live here, all state is in locals/results. Complexity: O(n) per entry.
// ============================================================================

const _ZIP_LOCAL_SIG: Int = 0x04034B50;
const _ZIP_CENTRAL_SIG: Int = 0x02014B50;
const _ZIP_EOCD_SIG: Int = 0x06054B50;
const _ZIP_DEFAULT_CAP: Int = 1073741824;

/// Method 0: stored (no compression).
pub const ZIP_METHOD_STORED: Int = 0;
/// Method 8: deflate (RFC 1951 raw stream, as produced by
/// xiom.compress.deflate).
pub const ZIP_METHOD_DEFLATE: Int = 8;

/// One extracted archive member (reader side). `crc`, `compressed_size` and
/// `uncompressed_size` come from the central directory; `data` is the
/// verified content.
pub type ZipEntry = {
  name: Str;
  method: Int;
  crc: Int;
  compressed_size: Int;
  uncompressed_size: Int;
  data: Vec[UInt8];
}

/// Incremental archive builder (writer side). `out` holds local headers +
/// payloads, `central` holds central-directory records as they are added.
pub type ZipWriter = {
  out: Vec[UInt8];
  central: Vec[UInt8];
  count: Int;
}

// ---------------------------------------------------------------------------
// Byte helpers (locals only)
// ---------------------------------------------------------------------------

fn _raw_u8(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

fn _rd_u16(data: &Vec[UInt8], pos: Int) -> Int {
  return (data[pos] as Int) | ((data[pos + 1] as Int) << 8);
}

fn _rd_u32(data: &Vec[UInt8], pos: Int) -> Int {
  var v: Int = data[pos] as Int;
  v = v | ((data[pos + 1] as Int) << 8);
  v = v | ((data[pos + 2] as Int) << 16);
  v = v | ((data[pos + 3] as Int) << 24);
  return v;
}

fn _wr_u16(out: &mut Vec[UInt8], v: Int) {
  out.push((v & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
}

fn _wr_u32(out: &mut Vec[UInt8], v: Int) {
  out.push((v & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push(((v >> 16) & 0xFF) as UInt8);
  out.push(((v >> 24) & 0xFF) as UInt8);
}

/// Copy the raw UTF-8 bytes of `s` into `out`.
fn _push_str_bytes(out: &mut Vec[UInt8], s: Str) {
  var i = 0;
  let len = s.len();
  let base = s.c_str();
  while i < len {
    out.push(_raw_u8(base, i));
    i = i + 1;
  }
}

/// Build a Str from `len` raw bytes at `pos` (single allocation via the
/// string builder; bytes are copied verbatim).
fn _bytes_to_str(data: &Vec[UInt8], pos: Int, len: Int) -> Str {
  var sb = Vec[UInt8].new();
  var i = 0;
  while i < len {
    sb.push(data[pos + i]);
    i = i + 1;
  }
  return builder.sb_to_str(&sb);
}

// ---------------------------------------------------------------------------
// Reader
// ---------------------------------------------------------------------------

/// Scan backwards for the end-of-central-directory signature (comment
/// tolerated, up to 64 KiB as the format allows). Returns -1 when absent.
fn _zip_find_eocd(data: &Vec[UInt8]) -> Int
  ensures: (data.len() < 22) => (result == 0 - 1)
{
  var len = data.len();
  if len < 22 {
    return -1;
  };
  var i = len - 22;
  var lowest = 0;
  if len > 65557 {
    lowest = len - 65557;
  };
  while i >= lowest {
    var b0 = data[i] as Int;
    if b0 == 0x50 {
      if (data[i + 1] as Int) == 0x4B && (data[i + 2] as Int) == 0x05 && (data[i + 3] as Int) == 0x06 {
        return i;
      };
    };
    i = i - 1;
  };
  return -1;
}

/// Parse and validate the EOCD; returns [central_offset, central_size,
/// total_entries].
fn _zip_cd_layout(data: &Vec[UInt8]) -> Result[Vec[Int], Str] {
  if data.len() < 22 {
    return Err("zip: data too short for end of central directory");
  };
  var eocd = _zip_find_eocd(data);
  if eocd < 0 {
    return Err("zip: end of central directory not found");
  };
  var disk = _rd_u16(data, eocd + 4);
  var cd_disk = _rd_u16(data, eocd + 6);
  if disk != 0 || cd_disk != 0 {
    return Err("zip: multi-disk archives are not supported");
  };
  var entries = _rd_u16(data, eocd + 10);
  var cd_size = _rd_u32(data, eocd + 12);
  var cd_off = _rd_u32(data, eocd + 16);
  if cd_off + cd_size > data.len() {
    return Err("zip: central directory exceeds archive");
  };
  var layout = Vec[Int].new();
  layout.push(cd_off);
  layout.push(cd_size);
  layout.push(entries);
  return Ok(layout);
}

/// Extract one central-directory record at `pos` into a verified ZipEntry.
/// The caller guarantees the signature and the 46-byte fixed header.
fn _zip_record_extract(data: &Vec[UInt8], pos: Int, max_out: Int) -> Result[ZipEntry, Str] {
  var flags = _rd_u16(data, pos + 8);
  var method = _rd_u16(data, pos + 10);
  var crc = _rd_u32(data, pos + 16);
  var csize = _rd_u32(data, pos + 20);
  var usz = _rd_u32(data, pos + 24);
  var name_len = _rd_u16(data, pos + 28);
  var extra_len = _rd_u16(data, pos + 30);
  var comment_len = _rd_u16(data, pos + 32);
  var lho = _rd_u32(data, pos + 42);
  if pos + 46 + name_len + extra_len + comment_len > data.len() {
    return Err("zip: truncated central directory record");
  };
  if (flags & 0x1) != 0 {
    return Err("zip: encrypted entries are not supported");
  };
  if csize == 0xFFFFFFFF || usz == 0xFFFFFFFF || lho == 0xFFFFFFFF {
    return Err("zip: zip64 archives are not supported");
  };
  if method != ZIP_METHOD_STORED && method != ZIP_METHOD_DEFLATE {
    return Err("zip: unsupported compression method");
  };
  if usz > max_out {
    return Err("zip: declared output exceeds cap");
  };
  var name = _bytes_to_str(data, pos + 46, name_len);
  if lho + 30 > data.len() {
    return Err("zip: local header out of range");
  };
  if _rd_u32(data, lho) != _ZIP_LOCAL_SIG {
    return Err("zip: bad local header signature");
  };
  var lname_len = _rd_u16(data, lho + 26);
  var lextra_len = _rd_u16(data, lho + 28);
  var data_start = lho + 30 + lname_len + lextra_len;
  if data_start + csize > data.len() {
    return Err("zip: compressed data out of range");
  };
  var comp = Vec[UInt8].new();
  var i = 0;
  while i < csize {
    comp.push(data[data_start + i]);
    i = i + 1;
  };
  var out = Vec[UInt8].new();
  if method == ZIP_METHOD_STORED {
    if csize != usz {
      return Err("zip: stored size mismatch");
    };
    out = comp;
  } else {
    var decoded = deflate.deflate_decompress_capped(&comp, max_out);
    match decoded {
      Ok(v) => { out = v; },
      Err(e) => { return Err(e); },
    }
  };
  if out.len() != usz {
    return Err("zip: size mismatch");
  };
  var actual_crc = crc32.crc32(&out) & 0xFFFFFFFF;
  if actual_crc != crc {
    return Err("zip: CRC32 mismatch");
  };
  return Ok(ZipEntry{
    name: name,
    method: method,
    crc: crc,
    compressed_size: csize,
    uncompressed_size: usz,
    data: out,
  });
}

/// Parse the central directory and return the member names in archive order.
/// Err on any malformed structure (truncation, bad signatures, zip64,
/// multi-disk).
pub fn zip_list(data: &Vec[UInt8]) -> Result[Vec[Str], Str]
  ensures: (data.len() < 22) => (result.is_err)
{
  var layout = _zip_cd_layout(data);
  var names = Vec[Str].new();
  match layout {
    Ok(fields) => {
      var cd_off = fields[0];
      var cd_size = fields[1];
      var entries = fields[2];
      var pos = cd_off;
      var end = cd_off + cd_size;
      var i = 0;
      while i < entries {
        if pos + 46 > end {
          return Err("zip: truncated central directory");
        };
        if _rd_u32(data, pos) != _ZIP_CENTRAL_SIG {
          return Err("zip: bad central directory signature");
        };
        var name_len = _rd_u16(data, pos + 28);
        var extra_len = _rd_u16(data, pos + 30);
        var comment_len = _rd_u16(data, pos + 32);
        if pos + 46 + name_len > end {
          return Err("zip: truncated central directory record");
        };
        names.push(_bytes_to_str(data, pos + 46, name_len));
        pos = pos + 46 + name_len + extra_len + comment_len;
        i = i + 1;
      };
      return Ok(names);
    },
    Err(e) => { return Err(e); },
  }
}

/// Extract every member with a per-entry output ceiling (decompression-bomb
/// guard). Verifies each entry's CRC-32 and uncompressed size against the
/// central directory; Err on the first mismatch.
pub fn zip_extract_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[ZipEntry], Str]
  ensures: (data.len() < 22) => (result.is_err)
  ensures: (max_out < 0) => (result.is_err)
{
  var entries_out = Vec[ZipEntry].new();
  if max_out < 0 {
    return Err("zip: negative output cap");
  };
  var layout = _zip_cd_layout(data);
  match layout {
    Ok(fields) => {
      var cd_off = fields[0];
      var cd_size = fields[1];
      var entries = fields[2];
      var pos = cd_off;
      var end = cd_off + cd_size;
      var i = 0;
      while i < entries {
        if pos + 46 > end {
          return Err("zip: truncated central directory");
        };
        if _rd_u32(data, pos) != _ZIP_CENTRAL_SIG {
          return Err("zip: bad central directory signature");
        };
        var name_len = _rd_u16(data, pos + 28);
        var extra_len = _rd_u16(data, pos + 30);
        var comment_len = _rd_u16(data, pos + 32);
        if pos + 46 + name_len + extra_len + comment_len > end {
          return Err("zip: truncated central directory record");
        };
        var one = _zip_record_extract(data, pos, max_out);
        match one {
          Ok(entry) => { entries_out.push(entry); },
          Err(e) => { return Err(e); },
        };
        pos = pos + 46 + name_len + extra_len + comment_len;
        i = i + 1;
      };
      return Ok(entries_out);
    },
    Err(e) => { return Err(e); },
  }
}

/// Extract every member with the default 1 GiB per-entry ceiling.
pub fn zip_extract(data: &Vec[UInt8]) -> Result[Vec[ZipEntry], Str]
  ensures: (data.len() < 22) => (result.is_err)
{
  return zip_extract_capped(data, _ZIP_DEFAULT_CAP);
}

/// Extract a single member by exact name (raw UTF-8 byte equality). Scanning
/// stops at the first match; Err when the name is absent or the entry is
/// malformed.
pub fn zip_read(data: &Vec[UInt8], name: Str) -> Result[Vec[UInt8], Str]
  ensures: (data.len() < 22) => (result.is_err)
{
  var layout = _zip_cd_layout(data);
  match layout {
    Ok(fields) => {
      var cd_off = fields[0];
      var cd_size = fields[1];
      var entries = fields[2];
      var pos = cd_off;
      var end = cd_off + cd_size;
      var i = 0;
      while i < entries {
        if pos + 46 > end {
          return Err("zip: truncated central directory");
        };
        if _rd_u32(data, pos) != _ZIP_CENTRAL_SIG {
          return Err("zip: bad central directory signature");
        };
        var name_len = _rd_u16(data, pos + 28);
        var extra_len = _rd_u16(data, pos + 30);
        var comment_len = _rd_u16(data, pos + 32);
        if pos + 46 + name_len > end {
          return Err("zip: truncated central directory record");
        };
        var entry_name = _bytes_to_str(data, pos + 46, name_len);
        if entry_name == name {
          var one = _zip_record_extract(data, pos, _ZIP_DEFAULT_CAP);
          match one {
            Ok(entry) => {
              var copy = Vec[UInt8].new();
              var j = 0;
              while j < entry.data.len() {
                copy.push(entry.data[j]);
                j = j + 1;
              };
              return Ok(copy);
            },
            Err(e) => { return Err(e); },
          }
        };
        pos = pos + 46 + name_len + extra_len + comment_len;
        i = i + 1;
      };
      return Err("zip: entry not found");
    },
    Err(e) => { return Err(e); },
  }
}

// ---------------------------------------------------------------------------
// Writer
// ---------------------------------------------------------------------------
/// New empty archive builder. `finish` on a fresh writer emits a valid
/// 22-byte empty archive.
pub fn zip_writer_new() -> ZipWriter
  ensures: result.count == 0
  ensures: result.out.len() == 0
  ensures: result.central.len() == 0
{
  return ZipWriter{
    out: Vec[UInt8].new(),
    central: Vec[UInt8].new(),
    count: 0,
  };
}

/// Append one member: local header + payload, then its central-directory
/// record. `method` is ZIP_METHOD_STORED or ZIP_METHOD_DEFLATE; deflate uses
/// the default level 6. Err on ids the zip32 format cannot express.
pub fn zip_writer_add(w: &mut ZipWriter, name: Str, data: &Vec[UInt8], method: Int) -> Result[Unit, Str]
  ensures: (name.len() == 0) => (result.is_err)
  ensures: (name.len() > 65535) => (result.is_err)
{
  return zip_writer_add_level(w, name, data, method, 6);
}

/// `zip_writer_add` with an explicit deflate level (0..9; ignored for
/// stored).
pub fn zip_writer_add_level(w: &mut ZipWriter, name: Str, data: &Vec[UInt8], method: Int, level: Int) -> Result[Unit, Str]
  ensures: (name.len() == 0) => (result.is_err)
  ensures: (name.len() > 65535) => (result.is_err)
{
  var name_len = name.len();
  if name_len <= 0 {
    return Err("zip: entry name must not be empty");
  };
  if name_len > 65535 {
    return Err("zip: entry name too long for zip32");
  };
  if w.count >= 65535 {
    return Err("zip: too many entries for zip32");
  };
  if method != ZIP_METHOD_STORED && method != ZIP_METHOD_DEFLATE {
    return Err("zip: unsupported compression method");
  };
  var uncomp_size = data.len();
  if uncomp_size > 0xFFFFFFFE {
    return Err("zip: entry too large for zip32");
  };
  // Compress first: the local header carries sizes/CRC and this writer emits
  // no data descriptors.
  var comp = Vec[UInt8].new();
  if method == ZIP_METHOD_STORED {
    var i = 0;
    while i < uncomp_size {
      comp.push(data[i]);
      i = i + 1;
    }
  } else {
    comp = deflate.deflate_compress_level(data, level);
  };
  var comp_size = comp.len();
  if comp_size > 0xFFFFFFFE {
    return Err("zip: compressed data too large for zip32");
  };
  var crc = crc32.crc32(data) & 0xFFFFFFFF;
  var offset = w.out.len();
  // Local file header (30 bytes + name, no extra field).
  _wr_u32(&mut w.out, _ZIP_LOCAL_SIG);
  _wr_u16(&mut w.out, 20);
  _wr_u16(&mut w.out, 0);
  _wr_u16(&mut w.out, method);
  _wr_u16(&mut w.out, 0);
  _wr_u16(&mut w.out, 0x21);
  _wr_u32(&mut w.out, crc);
  _wr_u32(&mut w.out, comp_size);
  _wr_u32(&mut w.out, uncomp_size);
  _wr_u16(&mut w.out, name_len);
  _wr_u16(&mut w.out, 0);
  _push_str_bytes(&mut w.out, name);
  var i2 = 0;
  while i2 < comp_size {
    w.out.push(comp[i2]);
    i2 = i2 + 1;
  };
  // Central directory record (46 bytes + name, no extra/comment).
  _wr_u32(&mut w.central, _ZIP_CENTRAL_SIG);
  _wr_u16(&mut w.central, 20);
  _wr_u16(&mut w.central, 20);
  _wr_u16(&mut w.central, 0);
  _wr_u16(&mut w.central, method);
  _wr_u16(&mut w.central, 0);
  _wr_u16(&mut w.central, 0x21);
  _wr_u32(&mut w.central, crc);
  _wr_u32(&mut w.central, comp_size);
  _wr_u32(&mut w.central, uncomp_size);
  _wr_u16(&mut w.central, name_len);
  _wr_u16(&mut w.central, 0);
  _wr_u16(&mut w.central, 0);
  _wr_u16(&mut w.central, 0);
  _wr_u16(&mut w.central, 0);
  _wr_u32(&mut w.central, 0);
  _wr_u32(&mut w.central, offset);
  _push_str_bytes(&mut w.central, name);
  w.count = w.count + 1;
  return Ok(());
}

/// Close the archive: append the central directory and the EOCD and return
/// the full byte stream. The writer stays usable for a new archive.
pub fn zip_writer_finish(w: &mut ZipWriter) -> Result[Vec[UInt8], Str]
  ensures: (result.is_ok) => (w.out.len() == w.out.len()@pre + w.central.len() + 22)
{
  var count = w.count;
  var cd_size = w.central.len();
  var cd_off = w.out.len();
  if cd_off + cd_size + 22 > 0xFFFFFFFE {
    return Err("zip: archive too large for zip32");
  };
  var i = 0;
  while i < cd_size {
    var b = w.central[i];
    w.out.push(b);
    i = i + 1;
  };
  _wr_u32(&mut w.out, _ZIP_EOCD_SIG);
  _wr_u16(&mut w.out, 0);
  _wr_u16(&mut w.out, 0);
  _wr_u16(&mut w.out, count);
  _wr_u16(&mut w.out, count);
  _wr_u32(&mut w.out, cd_size);
  _wr_u32(&mut w.out, cd_off);
  _wr_u16(&mut w.out, 0);
  var result = Vec[UInt8].new();
  var j = 0;
  while j < w.out.len() {
    result.push(w.out[j]);
    j = j + 1;
  };
  return Ok(result);
}
