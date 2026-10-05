// p_wave75_shapes.xi -- wave 75 shape validation: encoding remainder + debug
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-75 clause guards on xiom.encoding.ascii85 (6),
// xiom.encoding.punycode (7), xiom.encoding.idna (8), xiom.debug.disasm (7),
// xiom.debug.heap_report (11), xiom.debug.trace (11) and xiom.debug.hexdump;
// returns 0 when every case holds. Output is console-only; no network I/O.

module p_wave75_shapes

use xiom.encoding.ascii85;
use xiom.encoding.punycode;
use xiom.encoding.idna;
use xiom.debug;
use xiom.debug.disasm;
use xiom.debug.heap_report;
use xiom.debug.trace;

fn _seq(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(i as UInt8);
    i = i + 1;
  }
  return v;
}

fn main() -> Int {
  var empty = Vec[UInt8].new();

  // ---- ascii85
  if ascii85.ascii85_encode(&empty).len() != 0 { return 1; }
  if ascii85.ascii85_encode(&_seq(4)).len() != 5 { return 2; }
  if ascii85.ascii85_encode(&_seq(1)).len() != 2 { return 3; }
  var zeros = Vec[UInt8].new();
  zeros.push(0u8); zeros.push(0u8); zeros.push(0u8); zeros.push(0u8);
  if ascii85.ascii85_encode(&zeros) != "z" { return 4; }
  match ascii85.ascii85_decode("") {
    Ok(v) => { if v.len() != 0 { return 5; } }
    Err(_) => { return 5; }
  }
  match ascii85.ascii85_decode("z") {
    Ok(v) => { if v.len() != 4 { return 6; } }
    Err(_) => { return 6; }
  }
  if ascii85.ascii85_encode_str("").len() != 0 { return 7; }
  match ascii85.ascii85_decode_str("") {
    Ok(s) => { if s.len() != 0 { return 8; } }
    Err(_) => { return 8; }
  }
  if ascii85.ascii85_encode_with_delim(&empty).len() != 4 { return 9; }
  if !ascii85.ascii85_decode_with_delim("z").is_err { return 10; }
  if !ascii85.ascii85_decode_with_delim("").is_err { return 11; }
  match ascii85.ascii85_decode_with_delim("<~z~>") {
    Ok(v) => { if v.len() != 4 { return 12; } }
    Err(_) => { return 12; }
  }

  // ---- punycode
  if punycode.punycode_adapt(0, 1, true) != 0 { return 13; }
  if punycode.punycode_adapt(100, 4, false) < 0 { return 14; }
  if punycode.punycode_encode_digit(0) != 'a' { return 15; }
  if punycode.punycode_encode_digit(25) != 'z' { return 16; }
  if punycode.punycode_encode_digit(26) != '0' { return 17; }
  if punycode.punycode_encode_digit(35) != '9' { return 18; }
  if punycode.punycode_encode_digit(36) != (0 as Char) { return 19; }
  if punycode.punycode_encode_digit(0 - 1) != (0 as Char) { return 20; }
  if punycode.punycode_decode_digit('a') != 0 { return 21; }
  if punycode.punycode_decode_digit('0') != 26 { return 22; }
  if punycode.punycode_decode_digit('!') != 0 - 1 { return 23; }
  if punycode.punycode_decode_digit('\0') != 0 - 1 { return 24; }
  match punycode.punycode_encode("") {
    Ok(s) => { if s.len() != 0 { return 25; } }
    Err(_) => { return 25; }
  }
  match punycode.punycode_encode("abc") {
    Ok(s) => { if s != "abc-" { return 26; } }
    Err(_) => { return 26; }
  }
  match punycode.punycode_decode("") {
    Ok(s) => { if s.len() != 0 { return 27; } }
    Err(_) => { return 27; }
  }
  match punycode.punycode_decode("abc-") {
    Ok(s) => { if s != "abc" { return 28; } }
    Err(_) => { return 28; }
  }
  match punycode.punycode_encode_domain("") {
    Ok(s) => { if s.len() != 0 { return 29; } }
    Err(_) => { return 29; }
  }
  match punycode.punycode_decode_domain("") {
    Ok(s) => { if s.len() != 0 { return 30; } }
    Err(_) => { return 30; }
  }
  match punycode.punycode_encode_domain("a.b") {
    Ok(s) => { if s != "a.b" { return 31; } }
    Err(_) => { return 31; }
  }

  // ---- idna
  if idna.idna_split_labels("").len() < 1 { return 32; }
  var no_labels = Vec[Str].new();
  if idna.idna_join_labels(&no_labels).len() != 0 { return 33; }
  var two = Vec[Str].new(); two.push("a"); two.push("b");
  if idna.idna_join_labels(&two) != "a.b" { return 34; }
  if !idna.idna_to_ascii("").is_err { return 35; }
  match idna.idna_to_ascii("EXAMPLE.COM") {
    Ok(s) => { if s != "example.com" { return 36; } }
    Err(_) => { return 36; }
  }
  if !idna.idna_to_ascii("-a.com").is_err { return 37; }
  match idna.idna_to_unicode("") {
    Ok(s) => { if s.len() != 0 { return 38; } }
    Err(_) => { return 38; }
  }
  match idna.idna_to_unicode("example.com") {
    Ok(s) => { if s != "example.com" { return 39; } }
    Err(_) => { return 39; }
  }
  if idna.idna_is_valid("") { return 40; }
  if !idna.idna_is_valid("example.com") { return 41; }
  if idna.idna_is_valid("-a.com") { return 42; }
  if idna.idna_is_valid("a..b") { return 43; }
  match idna.idna_uts46_normalize("") {
    Ok(s) => { if s.len() != 0 { return 44; } }
    Err(_) => { return 44; }
  }
  match idna.idna_uts46_normalize("EXAMPLE.COM") {
    Ok(s) => { if s != "example.com" { return 45; } }
    Err(_) => { return 45; }
  }
  match idna.idna_nameprep("") {
    Ok(s) => { if s.len() != 0 { return 46; } }
    Err(_) => { return 46; }
  }
  match idna.idna_nameprep("ABC") {
    Ok(s) => { if s != "abc" { return 47; } }
    Err(_) => { return 47; }
  }
  if !idna.idna_nameprep(" ").is_err { return 48; }
  if !idna.idna_is_bidi_valid("") { return 49; }
  if !idna.idna_is_bidi_valid("abc") { return 50; }

  // ---- disasm stubs
  if !disasm.disasm_bytes(&empty, "x86").is_err { return 51; }
  if !disasm.disasm_function(0, 0).is_err { return 52; }
  if !disasm.disasm_instruction_length(&empty, 0).is_err { return 53; }
  if disasm.disasm_arch_supported("x86") { return 54; }
  if !disasm.disasm_syntax("x86", true).is_err { return 55; }
  if !disasm.disasm_symbolize(0).is_none { return 56; }
  if !disasm.disasm_debug_info(0).is_none { return 57; }

  // ---- heap_report
  heap_report.heap_reset_stats();
  if heap_report.heap_allocations() != 0 { return 58; }
  if heap_report.heap_frees() != 0 { return 59; }
  if heap_report.heap_live_objects() != 0 { return 60; }
  if !heap_report.heap_is_empty() { return 61; }
  if heap_report.heap_snapshot().len() != 0 { return 62; }
  if heap_report.heap_top_allocations(5).len() != 0 { return 63; }
  if heap_report.heap_usage() < 0 { return 64; }
  if heap_report.heap_peak_usage() < 0 { return 65; }
  if heap_report.heap_report().len() < 12 { return 66; }
  if heap_report.heap_report_json().len() < 2 { return 67; }

  // ---- hexdump clause guards
  if debug.hexdump(&empty, 16).len() != 0 { return 68; }
  if debug.hexdump(&_seq(3), 16).len() == 0 { return 69; }

  // ---- trace
  trace.trace_set_enabled(false);
  if trace.trace_enabled() { return 70; }
  trace.trace_enter("x");
  if trace.trace_depth() != 0 { return 71; }
  if trace.trace_backtrace().len() != 0 { return 72; }
  trace.trace_set_enabled(true);
  trace.trace_enter("a");
  if trace.trace_depth() != 1 { return 73; }
  if trace.trace_backtrace().len() != 1 { return 74; }
  if trace.trace_current_function() != "a" { return 75; }
  if trace.trace_source_location() != "a" { return 76; }
  trace.trace_enter("b");
  if trace.trace_depth() != 2 { return 77; }
  trace.trace_exit("nope");
  if trace.trace_depth() != 2 { return 78; }
  trace.trace_exit("b");
  if trace.trace_depth() != 1 { return 79; }
  trace.trace_exit("a");
  if trace.trace_depth() != 0 { return 80; }
  trace.trace_exit("a");
  if trace.trace_depth() != 0 { return 81; }
  trace.trace_set_enabled(false);
  if trace.trace_current_file() != "unknown" { return 82; }
  if trace.trace_current_line() != 0 { return 83; }
  var frames = Vec[Int].new();
  frames.push(16);
  frames.push(0 - 3);
  if trace.trace_backtrace_symbols(&frames).len() != 2 { return 84; }

  return 0;
}
