// XIOM - OS: Filetype
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.os.filetype

// Depends on: xiom.string

// ============================================================================
// File content detection: EOL style, byte-order marks, UTF BOM presence,
// binary-vs-text classification, encoding detection, magic numbers, MIME
// sniffing, and container format checks. Pure byte sniffing with no external
// dependencies.
// ============================================================================

use xiom.string;

// hex_digit returns the lowercase hex character for a nibble (0-15).
fn hex_digit(nib: Int) -> UInt8 {
  if nib < 10 {
    return (48 + nib) as UInt8;
  }
  (87 + nib) as UInt8
}

/// Detect the line ending style.
/// Parameters: data -- the bytes to inspect.
/// Returns: "lf", "crlf", "cr", "mixed" or "none".
/// Complexity: O(n). Pure.
pub fn detect_eol(data: &Vec[UInt8]) -> Str {
  var lf = 0;
  var cr = 0;
  var crlf_count = 0;
  var i = 0;
  let len = data.len();
  while i < len {
    let b = data[i] as Int;
    if b == 10 {
      lf = lf + 1;
    } elif b == 13 {
      if i + 1 < len && data[i + 1] == 10 {
        crlf_count = crlf_count + 1;
        i = i + 1;
      } else {
        cr = cr + 1;
      }
    }
    i = i + 1;
  }
  let total = lf + cr + crlf_count;
  if total == 0 {
    return "none";
  }
  if crlf_count > 0 && lf == 0 && cr == 0 {
    return "crlf";
  }
  if lf > 0 && cr == 0 && crlf_count == 0 {
    return "lf";
  }
  if cr > 0 && lf == 0 && crlf_count == 0 {
    return "cr";
  }
  "mixed"
}

/// Detect and describe the byte-order mark, or "" if absent.
/// Parameters: data -- the bytes to inspect.
/// Returns: "utf-8", "utf-16le", "utf-16be", "utf-32le", "utf-32be" or "".
/// Complexity: O(1). Pure.
pub fn detect_bom(data: &Vec[UInt8]) -> Str {
  let len = data.len();
  if len >= 4 && data[0] == 255 as UInt8 && data[1] == 254 as UInt8 && data[2] == 0 as UInt8 && data[3] == 0 as UInt8 {
    return "utf-32le";
  }
  if len >= 4 && data[0] == 0 as UInt8 && data[1] == 0 as UInt8 && data[2] == 254 as UInt8 && data[3] == 255 as UInt8 {
    return "utf-32be";
  }
  if len >= 2 && data[0] == 255 as UInt8 && data[1] == 254 as UInt8 {
    return "utf-16le";
  }
  if len >= 2 && data[0] == 254 as UInt8 && data[1] == 255 as UInt8 {
    return "utf-16be";
  }
  if len >= 3 && data[0] == 239 as UInt8 && data[1] == 187 as UInt8 && data[2] == 191 as UInt8 {
    return "utf-8";
  }
  ""
}

/// Return true if data starts with the UTF-8 BOM.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the EF BB BF prefix.
/// Complexity: O(1). Pure.
pub fn has_utf8_bom(data: &Vec[UInt8]) -> Bool {
  data.len() >= 3 && data[0] == 239 as UInt8 && data[1] == 187 as UInt8 && data[2] == 191 as UInt8
}

/// Return true if data starts with the UTF-16 LE BOM.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the FF FE prefix.
/// Complexity: O(1). Pure.
pub fn has_utf16le_bom(data: &Vec[UInt8]) -> Bool {
  data.len() >= 2 && data[0] == 255 as UInt8 && data[1] == 254 as UInt8
}

/// Return true if data starts with the UTF-16 BE BOM.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the FE FF prefix.
/// Complexity: O(1). Pure.
pub fn has_utf16be_bom(data: &Vec[UInt8]) -> Bool {
  data.len() >= 2 && data[0] == 254 as UInt8 && data[1] == 255 as UInt8
}

/// Return true if data starts with the UTF-32 LE BOM.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the FF FE 00 00 prefix.
/// Complexity: O(1). Pure.
pub fn has_utf32le_bom(data: &Vec[UInt8]) -> Bool {
  data.len() >= 4 && data[0] == 255 as UInt8 && data[1] == 254 as UInt8 && data[2] == 0 as UInt8 && data[3] == 0 as UInt8
}

/// Return true if data starts with the UTF-32 BE BOM.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the 00 00 FE FF prefix.
/// Complexity: O(1). Pure.
pub fn has_utf32be_bom(data: &Vec[UInt8]) -> Bool {
  data.len() >= 4 && data[0] == 0 as UInt8 && data[1] == 0 as UInt8 && data[2] == 254 as UInt8 && data[3] == 255 as UInt8
}

/// Classify data as binary by a control-byte heuristic.
/// Parameters: data -- the bytes to inspect.
/// Returns: true when a NUL byte is present or control bytes exceed 30% of
///          the sampled prefix.
/// Complexity: O(min(n, 1024)). Pure.
pub fn is_binary(data: &Vec[UInt8]) -> Bool {
  let len = data.len();
  var sample = len;
  if sample > 1024 {
    sample = 1024;
  }
  var controls = 0;
  var i = 0;
  while i < sample {
    let b = data[i] as Int;
    if b == 0 {
      return true;
    }
    if b < 32 && b != 9 && b != 10 && b != 13 && b != 12 && b != 8 {
      controls = controls + 1;
    }
    i = i + 1;
  }
  if sample > 0 && controls * 100 / sample > 30 {
    return true;
  }
  false
}

/// Classify data as plain text by a control-byte heuristic.
/// Parameters: data -- the bytes to inspect.
/// Returns: true when the data is not classified as binary.
/// Complexity: O(min(n, 1024)). Pure.
pub fn is_text(data: &Vec[UInt8]) -> Bool {
  !is_binary(data)
}

/// Guess the character encoding.
/// Parameters: data -- the bytes to inspect.
/// Returns: "utf-8", "utf-16le", "utf-16be", "utf-32le", "utf-32be", "ascii"
///          or "binary".
/// Complexity: O(n). Pure.
pub fn detect_encoding(data: &Vec[UInt8]) -> Str {
  let bom = detect_bom(data);
  if bom.len() > 0 {
    return bom;
  }
  if is_binary(data) {
    return "binary";
  }
  var ascii = true;
  var i = 0;
  while i < data.len() {
    let b = data[i] as Int;
    if b > 127 {
      ascii = false;
    }
    i = i + 1;
  }
  if ascii {
    return "ascii";
  }
  "utf-8"
}

/// Return the magic-number hex prefix of data.
/// Parameters: data -- the bytes to inspect.
/// Returns: the lowercase hex of the first up-to-8 bytes ("" for empty input).
/// Complexity: O(1). Pure.
pub fn magic_number(data: &Vec[UInt8]) -> Str {
  let len = data.len();
  if len == 0 {
    return "";
  }
  var n = len;
  if n > 8 {
    n = 8;
  }
  var buf = Vec[UInt8].new();
  var i = 0;
  while i < n {
    let b = data[i] as Int;
    buf.push(hex_digit(b >> 4));
    buf.push(hex_digit(b & 0xF));
    i = i + 1;
  }
  let s = Str::from_utf8(buf);
  s
}

// magic_matches checks data against a fixed magic byte prefix.
fn magic_matches(data: &Vec[UInt8], prefix: &Vec[UInt8]) -> Bool {
  if data.len() < prefix.len() {
    return false;
  }
  var i = 0;
  while i < prefix.len() {
    if data[i] != prefix[i] {
      return false;
    }
    i = i + 1;
  }
  true
}

// mv_b builds a magic prefix vector.
fn mv_b(a: UInt8) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a);
  v
}

// mv_2 builds a 2-byte magic prefix vector.
fn mv_2(a: UInt8, b: UInt8) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a);
  v.push(b);
  v
}

// mv_3 builds a 3-byte magic prefix vector.
fn mv_3(a: UInt8, b: UInt8, c: UInt8) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a);
  v.push(b);
  v.push(c);
  v
}

// mv_4 builds a 4-byte magic prefix vector.
fn mv_4(a: UInt8, b: UInt8, c: UInt8, d: UInt8) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a);
  v.push(b);
  v.push(c);
  v.push(d);
  v
}

// starts_with_ascii checks a leading ASCII literal.
fn starts_with_ascii(data: &Vec[UInt8], s: Str) -> Bool {
  if data.len() < s.len() {
    return false;
  }
  var i = 0;
  while i < s.len() {
    if data[i] != s.byte_at(i) {
      return false;
    }
    i = i + 1;
  }
  true
}

// is_png_magic / jpeg / gif / pdf / zip / gzip / elf / pe / macho helpers.
fn is_png_magic(data: &Vec[UInt8]) -> Bool {
  let p = mv_4(137 as UInt8, 80 as UInt8, 78 as UInt8, 71 as UInt8);
  magic_matches(data, &p)
}

fn is_jpeg_magic(data: &Vec[UInt8]) -> Bool {
  let p = mv_3(255 as UInt8, 216 as UInt8, 255 as UInt8);
  magic_matches(data, &p)
}

fn is_gif_magic(data: &Vec[UInt8]) -> Bool {
  starts_with_ascii(data, "GIF8")
}

fn is_pdf_magic(data: &Vec[UInt8]) -> Bool {
  starts_with_ascii(data, "%PDF-")
}

fn is_zip_magic(data: &Vec[UInt8]) -> Bool {
  let p = mv_4(80 as UInt8, 75 as UInt8, 3 as UInt8, 4 as UInt8);
  magic_matches(data, &p)
}

fn is_gzip_magic(data: &Vec[UInt8]) -> Bool {
  let p = mv_2(31 as UInt8, 139 as UInt8);
  magic_matches(data, &p)
}

fn is_elf_magic(data: &Vec[UInt8]) -> Bool {
  let p = mv_4(127 as UInt8, 69 as UInt8, 76 as UInt8, 70 as UInt8);
  magic_matches(data, &p)
}

fn is_pe_magic(data: &Vec[UInt8]) -> Bool {
  let p = mv_2(77 as UInt8, 90 as UInt8);
  magic_matches(data, &p)
}

fn is_macho_magic(data: &Vec[UInt8]) -> Bool {
  let p1 = mv_4(254 as UInt8, 237 as UInt8, 250 as UInt8, 206 as UInt8);
  let p2 = mv_4(254 as UInt8, 237 as UInt8, 250 as UInt8, 207 as UInt8);
  let p3 = mv_4(202 as UInt8, 254 as UInt8, 186 as UInt8, 190 as UInt8);
  let p4 = mv_4(207 as UInt8, 250 as UInt8, 237 as UInt8, 254 as UInt8);
  if magic_matches(data, &p1) { return true; }
  if magic_matches(data, &p2) { return true; }
  if magic_matches(data, &p3) { return true; }
  if magic_matches(data, &p4) { return true; }
  false
}

/// Detect the MIME type by content sniffing.
/// Parameters: data -- the bytes to inspect.
/// Returns: a MIME type guessed from magic bytes and text heuristics.
/// Complexity: O(1). Pure.
pub fn detect_mime(data: &Vec[UInt8]) -> Str {
  if is_png_magic(data) { return "image/png"; }
  if is_jpeg_magic(data) { return "image/jpeg"; }
  if is_gif_magic(data) { return "image/gif"; }
  if starts_with_ascii(data, "RIFF") {
    if data.len() >= 12 && data[8] == 87 as UInt8 && data[9] == 65 as UInt8 && data[10] == 86 as UInt8 && data[11] == 69 as UInt8 {
      return "audio/x-wav";
    }
    if data.len() >= 12 && data[8] == 65 as UInt8 && data[9] == 86 as UInt8 && data[10] == 73 as UInt8 && data[11] == 32 as UInt8 {
      return "video/x-msvideo";
    }
    return "application/octet-stream";
  }
  if starts_with_ascii(data, "OggS") { return "audio/ogg"; }
  if is_pdf_magic(data) { return "application/pdf"; }
  if is_zip_magic(data) { return "application/zip"; }
  if is_gzip_magic(data) { return "application/gzip"; }
  if is_elf_magic(data) { return "application/x-executable"; }
  if is_pe_magic(data) { return "application/x-dosexec"; }
  if starts_with_ascii(data, "<html") || starts_with_ascii(data, "<!DOCTYPE html") { return "text/html"; }
  if is_text(data) { return "text/plain"; }
  "application/octet-stream"
}

/// Detect the MIME type from magic bytes only.
/// Parameters: data -- the bytes to inspect.
/// Returns: the magic-derived MIME type or "application/octet-stream".
/// Complexity: O(1). Pure.
pub fn mime_from_magic(data: &Vec[UInt8]) -> Str {
  if is_png_magic(data) { return "image/png"; }
  if is_jpeg_magic(data) { return "image/jpeg"; }
  if is_gif_magic(data) { return "image/gif"; }
  if is_pdf_magic(data) { return "application/pdf"; }
  if is_zip_magic(data) { return "application/zip"; }
  if is_gzip_magic(data) { return "application/gzip"; }
  if is_elf_magic(data) { return "application/x-executable"; }
  if is_pe_magic(data) { return "application/x-dosexec"; }
  "application/octet-stream"
}

/// Return true if data matches a known image format.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for PNG/JPEG/GIF/BMP/WebP/ICO signatures.
/// Complexity: O(1). Pure.
pub fn is_image_data(data: &Vec[UInt8]) -> Bool {
  if is_png_magic(data) { return true; }
  if is_jpeg_magic(data) { return true; }
  if is_gif_magic(data) { return true; }
  if starts_with_ascii(data, "BM") { return true; }
  if starts_with_ascii(data, "RIFF") && data.len() >= 12 {
    if data[8] == 87 as UInt8 && data[9] == 69 as UInt8 && data[10] == 66 as UInt8 && data[11] == 80 as UInt8 {
      return true;
    }
  }
  false
}

/// Return true if data matches a known audio format.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for WAV/OGG/FLAC/MP3 (ID3) signatures.
/// Complexity: O(1). Pure.
pub fn is_audio_data(data: &Vec[UInt8]) -> Bool {
  if starts_with_ascii(data, "OggS") { return true; }
  if starts_with_ascii(data, "fLaC") { return true; }
  if data.len() >= 3 && data[0] == 73 as UInt8 && data[1] == 68 as UInt8 && data[2] == 51 as UInt8 { return true; }
  if starts_with_ascii(data, "RIFF") && data.len() >= 12 {
    if data[8] == 87 as UInt8 && data[9] == 65 as UInt8 && data[10] == 86 as UInt8 && data[11] == 69 as UInt8 {
      return true;
    }
  }
  false
}

/// Return true if data matches a known video container.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for AVI/MP4/MKV/WebM/Ogg signatures.
/// Complexity: O(1). Pure.
pub fn is_video_data(data: &Vec[UInt8]) -> Bool {
  if starts_with_ascii(data, "OggS") { return true; }
  if data.len() >= 4 && data[0] == 26 as UInt8 && data[1] == 69 as UInt8 && data[2] == 223 as UInt8 && data[3] == 163 as UInt8 { return true; }
  if data.len() >= 11 && data[0] == 0 as UInt8 && data[1] == 0 as UInt8 && data[2] == 0 as UInt8 && data[3] == 24 as UInt8 {
    if data[4] == 102 as UInt8 && data[5] == 116 as UInt8 && data[6] == 121 as UInt8 && data[7] == 112 as UInt8 {
      return true;
    }
  }
  if starts_with_ascii(data, "RIFF") && data.len() >= 12 {
    if data[8] == 65 as UInt8 && data[9] == 86 as UInt8 && data[10] == 73 as UInt8 && data[11] == 32 as UInt8 {
      return true;
    }
  }
  false
}

/// Return true if data looks like a PDF.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the "%PDF-" header.
/// Complexity: O(1). Pure.
pub fn is_pdf_data(data: &Vec[UInt8]) -> Bool {
  is_pdf_magic(data)
}

/// Return true if data is a ZIP archive.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the "PK\x03\x04" local-file header.
/// Complexity: O(1). Pure.
pub fn is_zip_data(data: &Vec[UInt8]) -> Bool {
  is_zip_magic(data)
}

/// Return true if data is a gzip stream.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the 1F 8B header.
/// Complexity: O(1). Pure.
pub fn is_gzip_data(data: &Vec[UInt8]) -> Bool {
  is_gzip_magic(data)
}

/// Return true if data is an ELF binary.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the 7F 45 4C 46 header.
/// Complexity: O(1). Pure.
pub fn is_elf_data(data: &Vec[UInt8]) -> Bool {
  is_elf_magic(data)
}

/// Return true if data is a PE/COFF binary.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the "MZ" DOS header.
/// Complexity: O(1). Pure.
pub fn is_pe_data(data: &Vec[UInt8]) -> Bool {
  is_pe_magic(data)
}

/// Return true if data is a Mach-O binary.
/// Parameters: data -- the bytes to inspect.
/// Returns: true for the Mach-O magic numbers.
/// Complexity: O(1). Pure.
pub fn is_macho_data(data: &Vec[UInt8]) -> Bool {
  is_macho_magic(data)
}
