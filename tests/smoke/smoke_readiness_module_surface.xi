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
  return 0;
}
