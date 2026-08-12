// XIOM stdlib smoke test — xiom.serialize submodules
// Tests: endian (LE/BE reads+writes, i64, f64), varint (LEB128 encode/decode
// round-trip, zigzag, uvarint), json (construct + stringify + get), yaml_lite
// (scalar/sequence/mapping emission).
// Returns 0 on success, unique error code on failure.

module smoke_serialize
use xiom.serialize.endian;
use xiom.serialize.varint;
use xiom.serialize.json;
use xiom.serialize.yaml_lite;

fn main() -> Int {
  // ---- endian ----
  var out = Vec[UInt8].new();
  endian.write_u32_le(&mut out, 0x12345678 as UInt32);
  if out.len() != 4 { return 1; }
  if out[0] != 0x78u8 || out[1] != 0x56u8 || out[2] != 0x34u8 || out[3] != 0x12u8 { return 2; }
  var rbe = endian.read_u32_be(&out, 0);
  if rbe != 0x78563412 as UInt32 { return 3; }
  var rle = endian.read_u32_le(&out, 0);
  if rle != 0x12345678 as UInt32 { return 4; }

  var out16 = Vec[UInt8].new();
  endian.write_u16_le(&mut out16, 0xABCD as UInt16);
  if out16[0] != 0xCDu8 || out16[1] != 0xABu8 { return 5; }
  var r16le = endian.read_u16_le(&out16, 0);
  if r16le != 0xABCD as UInt16 { return 6; }
  var out16b = Vec[UInt8].new();
  endian.write_u16_be(&mut out16b, 0xABCD as UInt16);
  var r16be = endian.read_u16_be(&out16b, 0);
  if r16be != 0xABCD as UInt16 { return 6; }

  var out64 = Vec[UInt8].new();
  endian.write_u64_be(&mut out64, 0x0102030405060708 as UInt64);
  var r64be = endian.read_u64_be(&out64, 0);
  if r64be != 0x0102030405060708 as UInt64 { return 7; }
  var out64le = Vec[UInt8].new();
  endian.write_u64_le(&mut out64le, 0x0102030405060708 as UInt64);
  var r64le = endian.read_u64_le(&out64le, 0);
  if r64le != 0x0102030405060708 as UInt64 { return 8; }

  var outi = Vec[UInt8].new();
  endian.write_i64_le(&mut outi, -42);
  var ri64 = endian.read_i64_le(&outi, 0);
  if ri64 != -42 { return 9; }

  var outf = Vec[UInt8].new();
  endian.write_f64_le(&mut outf, 1.5);
  var rf64 = endian.read_f64_le(&outf, 0);
  if rf64 != 1.5 { return 10; }

  // ---- varint ----
  var enc = varint.varint_encode(300);
  if enc.len() != 2 { return 11; }
  if enc[0] != 0xACu8 || enc[1] != 0x02u8 { return 12; }

  var vals = Vec[Int].new();
  vals.push(300);
  vals.push(-7);
  vals.push(0);
  var enc_slice = varint.varint_encode_slice(&vals);
  var dec_slice = varint.varint_decode_slice(&enc_slice);
  match dec_slice {
    Ok(dv) => {
      if dv.len() != 3 { return 13; }
      if dv[0] != 300 { return 14; }
      if dv[1] != -7 { return 15; }
      if dv[2] != 0 { return 16; }
    }
    Err(_) => { return 17; }
  }

  var size = varint.varint_size(300);
  if size != 2 { return 18; }
  var zz = varint.zigzag_encode(-2);
  if zz != 3 { return 19; }
  var zzd = varint.zigzag_decode(zz);
  if zzd != -2 { return 20; }

  var uenc = varint.uvarint_encode(300 as UInt64);
  var udec = varint.uvarint_decode(&uenc);
  match udec {
    Ok(pair) => {
      if pair.0 != 300 as UInt64 { return 21; }
      if pair.1 != 2 { return 22; }
    }
    Err(_) => { return 23; }
  }

  // ---- json (construct + stringify; parse/objects blocked by compiler bugs) ----
  var arr = json.json_array_new();
  arr = json.json_array_push(arr, json.json_number(1.0));
  arr = json.json_array_push(arr, json.json_bool(true));
  arr = json.json_array_push(arr, json.json_null());
  var s = json.json_stringify(arr);
  if s.len() == 0 { return 24; }
  var got = json.json_get(arr, "x");
  match got {
    Some(_) => { return 25; }
    None => {}
  }
  var t = json.json_type(json.json_bool(true));
  if t != "bool" { return 26; }

  // ---- yaml_lite (emission) ----
  var y1 = yaml_lite.yaml_emit_scalar("hello world");
  if y1 != "hello world" { return 27; }
  var y2 = yaml_lite.yaml_emit_scalar("a:b");
  if y2 != "\"a:b\"" { return 28; }
  var items = Vec[Str].new();
  items.push("one");
  items.push("two");
  var seq = yaml_lite.yaml_emit_sequence(&items);
  if seq != "- one\n- two" { return 29; }
  var keys = Vec[Str].new();
  var vals2 = Vec[Str].new();
  keys.push("name");
  vals2.push("Alice");
  var mp = yaml_lite.yaml_emit_mapping(&keys, &vals2);
  if mp != "name: Alice" { return 30; }

  return 0;
}
