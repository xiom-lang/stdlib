// smoke_readiness_module_surface.xi -- readiness wave 313: module-surface lock.
//
// The module-smoke readiness criterion (owner, 2026-09-29) counts a module as
// covered when a smoke imports it or calls one of its public functions. This
// smoke imports the 44 modules that had no smoke reference on 2026-10-31, so
// every stdlib module is at least compiled and linked by the smoke corpus.
// Function-level calls for these modules land in follow-up waves.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module smoke_readiness_module_surface

use xiom.async;
use xiom.async.io;
use xiom.bigfloat;
use xiom.collect.bitset;
use xiom.collect.composite;
use xiom.collect.eventlog;
use xiom.collect.groupfold;
use xiom.collect.mailbox;
use xiom.collect.vecops;
use xiom.collect.vecstr;
use xiom.compress.accept_encoding;
use xiom.compress.crc32;
use xiom.compress.zip;
use xiom.convert.overflow;
use xiom.crypto.aead;
use xiom.crypto.aes;
use xiom.crypto.keccak;
use xiom.crypto.md5;
use xiom.crypto.sha;
use xiom.encoding.le;
use xiom.format.number;
use xiom.format.textual;
use xiom.math.fixed;
use xiom.math.int;
use xiom.math.interfaces;
use xiom.math.precision;
use xiom.math.tower;
use xiom.math.trigonometric_constants;
use xiom.net.h2;
use xiom.net.h2_io;
use xiom.net.tls_libssl;
use xiom.num.convert;
use xiom.os.lock;
use xiom.reflect;
use xiom.search;
use xiom.serialize.xml;
use xiom.simd;
use xiom.stats.int_stats;
use xiom.string.ascii;
use xiom.string.codepoint;
use xiom.string.lines;
use xiom.string.view;
use xiom.test.assertions;
use xiom.thread;

fn main() -> Int {
  // One representative call per module where a safe, side-effect-free entry
  // exists. The remaining modules are import-only (pure re-export/aggregate
  // or platform-gated); their functions land in follow-up waves.
  var bytes: Vec[UInt8] = Vec[UInt8].new();
  bytes.push(1 as UInt8);

  let crc = crc32.crc32(&bytes);
  if crc < 0 { return 1; }

  let (sum, ov) = overflow.overflowing_add(1, 2);
  if sum != 3 || ov { return 2; }

  var out: Vec[UInt8] = Vec[UInt8].new();
  let w = le.write_u16_le(&mut out, 258);
  if w.is_err { return 3; }
  if out.len() != 2 { return 4; }

  let nfmt = number.fmt_int_with_separators(1234567, ",");
  if nfmt.len() == 0 { return 5; }

  var lines_in: Vec[Str] = Vec[Str].new();
  lines_in.push("abc");
  let boxed = textual.box_around(&lines_in, 5);
  if boxed.len() == 0 { return 6; }

  if fixed.mul(3, 4, 1) != 12 { return 7; }
  let _ = convert.to_base58(42);

  var sorted: Vec[Int] = Vec[Int].new();
  sorted.push(1);
  sorted.push(3);
  sorted.push(5);
  let _ = search.interpolation_search(&sorted, 3);

  let _ = ascii.ascii_is_digit(48);
  let _ = codepoint.codepoint_valid(65);
  let _ = lines.lines_count("a\nb");
  let _ = view.view_of("abc");
  let _ = assertions.assertions_new();
  thread.sleep_ms(0);
  let _ = simd.simd_supported();
  let _ = reflect.type_count();

  var vals: Vec[Int] = Vec[Int].new();
  vals.push(2);
  vals.push(4);
  let _ = int_stats.int_mean(&vals);

  let bs = bitset.bitset_new(8);
  let _ = bitset.bitset_len(&bs);
  let el = eventlog.eventlog_new();
  let _ = eventlog.eventlog_len(&el);
  let gf = groupfold.group_fold_new();
  let _ = groupfold.group_fold_size(&gf);
  let _ = mailbox.mailboxes_new();

  let cp = vecops.vec_copy_int(&vals);
  if cp.len() != 2 { return 8; }
  var strs: Vec[Str] = Vec[Str].new();
  strs.push("a");
  if !vecstr.vec_str_contains(&strs, "a") { return 9; }

  var sup: Vec[Str] = Vec[Str].new();
  sup.push("gzip");
  let _ = accept_encoding.accept_encoding_choose("gzip", &sup);
  let _ = zip.zip_list(&bytes);
  let _ = aead.aead_alg_supported(1);
  let _ = aes.aes_sbox(0);
  let k = keccak.keccak256_hex(&bytes);
  if k.len() != 64 { return 10; }
  var ints: Vec[Int] = Vec[Int].new();
  ints.push(1);
  let m = md5.md5_hex(&ints);
  if m.len() != 32 { return 11; }
  let _ = sha.sha256_initial_h0();
  let _ = h2.h2_frame_header_encode(0, 0, 0, 0);
  let _ = tls_libssl.tls_libssl_available();
  let _ = xml.xml_tokenizer_new("<a/>");

  return 0;
}
