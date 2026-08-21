// XIOM stdlib smoke test -- xiom.num.convert, xiom.format.number, xiom.format.dump
// Returns 0 on success, 1 on failure (process exit code).
//
// NOTE on ASCII85 vectors: the standard Adobe ASCII85 encoding of the
// 3-byte string "Man" (77, 97, 110) is "9jqo" (a partial group of 3 bytes
// yields 4 characters). "9jqo^" is the standard encoding of the 4-byte
// string "Man " (77, 97, 110, 32), which is asserted separately below.
//
// Option[Vec[UInt8]] values are destructured with `match` (binding the
// payload as a real Vec) rather than `.value` field access.

module smoke_num_format_folder
use xiom.num.convert as numconv;
use xiom.format.number as fnum;
use xiom.format.dump as fdump;
use xiom.string;

fn main() -> Int {
  // --- base58 / base62 ---
  if numconv.to_base58(0) != "1" { return 1; }
  var b58 = numconv.to_base58(123456789);
  if numconv.from_base58(b58) != Some(123456789) { return 1; }
  if numconv.from_base58("0") != None { return 1; }
  var b62 = numconv.to_base62(987654321);
  if numconv.from_base62(b62) != Some(987654321) { return 1; }
  if numconv.to_base62(0) != "0" { return 1; }
  if numconv.from_base62("zz!") != None { return 1; }

  // --- ascii85 ---
  var man = Vec[UInt8].new();
  man.push(77); man.push(97); man.push(110);
  if numconv.to_ascii85(&man) != "9jqo" { return 1; }
  var dec85 = numconv.from_ascii85("9jqo");
  var ok85 = false;
  match dec85 {
    Some(v) => {
      if v.len() == 3 && v[0] == 77 && v[1] == 97 && v[2] == 110 { ok85 = true; }
    },
    None => {},
  }
  if !ok85 { return 1; }
  var dec85b = numconv.from_ascii85("9jqo^");
  var ok85b = false;
  match dec85b {
    Some(v) => {
      if v.len() == 4 && v[0] == 77 && v[1] == 97 && v[2] == 110 && v[3] == 32 { ok85b = true; }
    },
    None => {},
  }
  if !ok85b { return 1; }
  var rt = numconv.from_ascii85(numconv.to_ascii85(&man));
  var ok_rt = false;
  match rt {
    Some(v) => {
      if v.len() == 3 && v[0] == 77 && v[1] == 97 && v[2] == 110 { ok_rt = true; }
    },
    None => {},
  }
  if !ok_rt { return 1; }
  var empty = Vec[UInt8].new();
  if numconv.to_ascii85(&empty) != "" { return 1; }
  var de = numconv.from_ascii85("");
  var ok_de = false;
  match de {
    Some(v) => {
      if v.len() == 0 { ok_de = true; }
    },
    None => {},
  }
  if !ok_de { return 1; }

  // --- roman ---
  var r1990 = numconv.to_roman(1990);
  if !(r1990.is_some) { return 1; }
  if r1990.value != "MCMXC" { return 1; }
  var r2024 = numconv.to_roman(2024);
  if !(r2024.is_some) { return 1; }
  if r2024.value != "MMXXIV" { return 1; }
  if numconv.from_roman("MCMXC") != Some(1990) { return 1; }
  if numconv.to_roman(0).is_some { return 1; }
  if numconv.to_roman(-5).is_some { return 1; }
  if numconv.to_roman(4000).is_some { return 1; }
  if numconv.from_roman("ABC").is_some { return 1; }

  // --- number formatting ---
  if fnum.fmt_int_with_separators(0, ",") != "0" { return 1; }
  if fnum.fmt_int_with_separators(123, ",") != "123" { return 1; }
  if fnum.fmt_int_with_separators(1234567, ",") != "1,234,567" { return 1; }
  if fnum.fmt_int_with_separators(-987654, ",") != "-987,654" { return 1; }
  if fnum.fmt_float_fixed(3.14159, 2) != "3.14" { return 1; }
  if fnum.fmt_float_fixed(1.5, 2) != "1.50" { return 1; }
  if fnum.fmt_float_fixed(1.5, 0) != "2" { return 1; }
  if fnum.fmt_percent(0.125, 1) != "12.5%" { return 1; }
  if fnum.fmt_bytes(0) != "0 B" { return 1; }
  if fnum.fmt_bytes(512) != "512 B" { return 1; }
  if fnum.fmt_bytes(1024) != "1.0 KiB" { return 1; }
  if fnum.fmt_bytes(1536) != "1.5 KiB" { return 1; }
  if fnum.fmt_duration_ms(0) != "0ms" { return 1; }
  if fnum.fmt_duration_ms(65000) != "1m 5s" { return 1; }
  if fnum.fmt_duration_ms(90061000) != "1d 1h 1m 1s" { return 1; }
  if fnum.fmt_ordinal(1) != "1st" { return 1; }
  if fnum.fmt_ordinal(2) != "2nd" { return 1; }
  if fnum.fmt_ordinal(3) != "3rd" { return 1; }
  if fnum.fmt_ordinal(4) != "4th" { return 1; }
  if fnum.fmt_ordinal(11) != "11th" { return 1; }
  if fnum.fmt_ordinal(12) != "12th" { return 1; }
  if fnum.fmt_ordinal(13) != "13th" { return 1; }
  if fnum.fmt_ordinal(21) != "21st" { return 1; }
  if fnum.fmt_ordinal(22) != "22nd" { return 1; }
  if fnum.fmt_ordinal(23) != "23rd" { return 1; }
  if fnum.fmt_ordinal(101) != "101st" { return 1; }
  if fnum.fmt_ordinal(111) != "111th" { return 1; }

  // --- dumps ---
  var hello = Vec[UInt8].new();
  hello.push(104); hello.push(101); hello.push(108); hello.push(108); hello.push(111);
  var dump = fdump.hexdump(&hello);
  if !string.str_starts_with(dump, "00000000") { return 1; }
  if !string.str_contains(dump, "68 65 6c 6c 6f") { return 1; }
  if !string.str_contains(dump, "|hello|") { return 1; }
  var od = fdump.octal_dump(&hello);
  if od.len() == 0 { return 1; }
  if !string.str_contains(od, "150") { return 1; }
  var bd = fdump.binary_dump(&hello);
  if bd.len() == 0 { return 1; }
  if !string.str_contains(bd, "01101000") { return 1; }
  var ed = fdump.hexdump(&empty);
  if ed != "" { return 1; }

  return 0;
}
