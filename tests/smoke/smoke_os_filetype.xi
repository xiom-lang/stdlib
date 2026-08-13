// XIOM stdlib smoke test — xiom.os.filetype + xiom.os.err + xiom.os.event
// Byte sniffing, errno tables, and event-loop stubs.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_os_filetype

use xiom.os.filetype;
use xiom.os.err;
use xiom.os.event;
use xiom.io;

fn main() -> Int {
  // --- filetype: PNG / PDF / text detection ---
  let png = mkbytes([137, 80, 78, 71, 13, 10, 26, 10]);
  if !filetype.is_image_data(&png) {
    io.println("ft-img");
    return 1;
  }
  if filetype.is_pdf_data(&png) {
    io.println("ft-img2");
    return 2;
  }
  let pdf = mkbytes([37, 80, 68, 70, 45, 49, 46, 52]);
  if !filetype.is_pdf_data(&pdf) {
    io.println("ft-pdf");
    return 3;
  }
  if filetype.detect_mime(&pdf) != "application/pdf" {
    io.println("ft-mime");
    return 4;
  }
  if filetype.mime_from_magic(&pdf) != "application/pdf" {
    io.println("ft-magic-mime");
    return 5;
  }

  // --- filetype: EOL detection ---
  let lf = mkbytes([104, 105, 10, 116, 104, 101, 114, 101]);
  if filetype.detect_eol(&lf) != "lf" {
    io.println("ft-eol-lf");
    return 6;
  }
  let crlf = mkbytes([97, 13, 10, 98, 13, 10, 99]);
  if filetype.detect_eol(&crlf) != "crlf" {
    io.println("ft-eol-crlf");
    return 7;
  }
  let none = mkbytes([97, 98, 99]);
  if filetype.detect_eol(&none) != "none" {
    io.println("ft-eol-none");
    return 8;
  }

  // --- filetype: BOMs ---
  let utf8bom = mkbytes([239, 187, 191, 104, 105]);
  if !filetype.has_utf8_bom(&utf8bom) {
    io.println("ft-bom8");
    return 9;
  }
  if filetype.detect_bom(&utf8bom) != "utf-8" {
    io.println("ft-bom8b");
    return 10;
  }
  let le16 = mkbytes([255, 254, 104, 0]);
  if !filetype.has_utf16le_bom(&le16) {
    io.println("ft-bom16le");
    return 11;
  }
  let be16 = mkbytes([254, 255, 0, 104]);
  if !filetype.has_utf16be_bom(&be16) {
    io.println("ft-bom16be");
    return 12;
  }
  let le32 = mkbytes([255, 254, 0, 0, 104, 0, 0, 0]);
  if !filetype.has_utf32le_bom(&le32) {
    io.println("ft-bom32le");
    return 13;
  }
  let be32 = mkbytes([0, 0, 254, 255, 0, 0, 0, 104]);
  if !filetype.has_utf32be_bom(&be32) {
    io.println("ft-bom32be");
    return 14;
  }

  // --- filetype: binary vs text, encoding ---
  let bin = mkbytes([1, 0, 2, 3, 4, 0, 5, 6]);
  if !filetype.is_binary(&bin) {
    io.println("ft-binary");
    return 15;
  }
  if filetype.is_text(&bin) {
    io.println("ft-text2");
    return 16;
  }
  let text = mkbytes([104, 101, 108, 108, 111]);
  if !filetype.is_text(&text) {
    io.println("ft-text");
    return 17;
  }
  if filetype.detect_encoding(&bin) != "binary" {
    io.println("ft-enc-binary");
    return 18;
  }
  if filetype.detect_encoding(&text) != "ascii" {
    io.println("ft-enc-ascii");
    return 19;
  }
  if filetype.detect_encoding(&utf8bom) != "utf-8" {
    io.println("ft-enc-bom");
    return 20;
  }

  // --- filetype: magic numbers + containers ---
  if filetype.magic_number(&png) != "89504e470d0a1a0a" {
    io.println("ft-magic");
    return 21;
  }
  let zip = mkbytes([80, 75, 3, 4, 20, 0]);
  if !filetype.is_zip_data(&zip) {
    io.println("ft-zip");
    return 22;
  }
  let gz = mkbytes([31, 139, 8, 0]);
  if !filetype.is_gzip_data(&gz) {
    io.println("ft-gzip");
    return 23;
  }
  let elf = mkbytes([127, 69, 76, 70, 2, 1, 1]);
  if !filetype.is_elf_data(&elf) {
    io.println("ft-elf");
    return 24;
  }
  let pe = mkbytes([77, 90, 144, 0]);
  if !filetype.is_pe_data(&pe) {
    io.println("ft-pe");
    return 25;
  }
  let macho = mkbytes([207, 250, 237, 254, 7, 0]);
  if !filetype.is_macho_data(&macho) {
    io.println("ft-macho");
    return 26;
  }
  let wav = mkbytes([82, 73, 70, 70, 36, 0, 0, 0, 87, 65, 86, 69]);
  if !filetype.is_audio_data(&wav) {
    io.println("ft-audio");
    return 27;
  }
  let avi = mkbytes([82, 73, 70, 70, 36, 0, 0, 0, 65, 86, 73, 32]);
  if !filetype.is_video_data(&avi) {
    io.println("ft-video");
    return 28;
  }

  // --- err: names and messages ---
  if err.errno_name(2) != "ENOENT" {
    io.println("err-name");
    return 29;
  }
  if err.errno_name(13) != "EACCES" {
    io.println("err-name2");
    return 30;
  }
  if err.errno_name(999) != "EUNKNOWN" {
    io.println("err-name3");
    return 31;
  }
  if err.strerror(2) != "no such file or directory" {
    io.println("err-msg");
    return 32;
  }
  if err.strerror(13) != "permission denied" {
    io.println("err-msg2");
    return 33;
  }
  {
    let s = err.errno_to_string(2);
    if s != "ENOENT (2): no such file or directory" {
      io.println("err-fmt");
      return 34;
    }
  }
  if err.last_error() != "" {
    io.println("err-last");
    return 35;
  }
  if err.errno() != 0 {
    io.println("err-errno");
    return 36;
  }
  if err.errno_message() != "unknown error" {
    io.println("err-msg3");
    return 37;
  }
  if err.demangle("_Z3foov") != "_Z3foov" {
    io.println("err-demangle");
    return 38;
  }
  if err.backtrace().len() != 0 {
    io.println("err-backtrace");
    return 39;
  }

  // --- event: documented stubs ---
  {
    let r = event.epoll_create();
    if r.is_ok {
      io.println("ev-epoll");
      return 40;
    }
  }
  {
    let r = event.kqueue_create();
    if r.is_ok {
      io.println("ev-kqueue");
      return 41;
    }
  }
  {
    let r = event.eventfd_new(0);
    if r.is_ok {
      io.println("ev-eventfd");
      return 42;
    }
  }
  {
    let r = event.timerfd_new();
    if r.is_ok {
      io.println("ev-timerfd");
      return 43;
    }
  }

  io.println("OK");
  return 0;
}

fn mkbytes(arr: Vec[Int]) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < arr.len() {
    v.push(arr[i] as UInt8);
    i = i + 1;
  }
  v
}
