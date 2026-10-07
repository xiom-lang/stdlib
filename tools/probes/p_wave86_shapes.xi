// p_wave86_shapes.xi -- wave 86 shape validation: convert locals + shims
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-86 clause guards: date/datetime field and length pins,
// duration normalization pins and accessor mirrors, the time_of_day band and
// timestamp pins, the wstring null-pointer identities, the from/into zero
// pins, the roundtrip empty/invalid/zero pins, uuid/mac length + parse
// guards and the iri empty-Err / nonempty-Ok presences. Values returned from
// the module surface are bound before comparing/reading. Returns 0 when
// every case holds.

module p_wave86_shapes

use xiom.convert.date as cdate;
use xiom.convert.datetime as cdt;
use xiom.convert.duration as cdur;
use xiom.convert.time as ctime;
use xiom.convert.wstring as cws;
use xiom.convert.from as cfrom;
use xiom.convert.into as cinto;
use xiom.convert.roundtrip as crt;
use xiom.convert.uuid as cuuid;
use xiom.convert.mac as cmac;
use xiom.convert.iri as ciri;

fn main() -> Int {
  // ---- date
  let d = cdate.date_new(2026, 8, 12);
  if d.year != 2026 || d.month != 8 || d.day != 12 { return 1; }
  let iso = cdate.date_iso8601(&d);
  if iso.len() != 10 { return 2; }
  if iso != "2026-08-12" { return 3; }
  if cdate.date_from_iso8601("2026-8-12").is_some { return 4; }
  if cdate.date_from_iso8601("1970-01-01").is_none { return 5; }
  let wd = cdate.date_weekday(&d);
  if wd < 0 || wd > 6 { return 6; }
  let epoch_date = cdate.date_new(1970, 1, 1);
  if cdate.date_weekday(&epoch_date) != 4 { return 7; }
  let doy = cdate.date_day_of_year(&d);
  if doy < 1 || doy > 366 { return 8; }
  if doy != 224 { return 9; }
  if cdate.date_day_of_year(&cdate.date_new(2026, 1, 1)) != 1 { return 10; }
  let iso0 = cdate.date_iso8601(&cdate.date_new(0, 1, 1));
  if iso0.len() != 10 { return 11; }

  // ---- datetime
  let dt = cdt.datetime_new(2026, 8, 12, 14, 30, 45);
  if dt.year != 2026 || dt.month != 8 || dt.day != 12 { return 12; }
  if dt.hour != 14 || dt.minute != 30 || dt.second != 45 { return 13; }
  let dtiso = cdt.datetime_iso8601(&dt);
  if dtiso != "2026-08-12T14:30:45" { return 14; }
  if dtiso.len() < 19 { return 15; }
  if cdt.datetime_from_iso8601("2026-08-12T14:30").is_some { return 16; }
  if cdt.datetime_from_iso8601("1970-01-01T00:00:00").is_none { return 17; }

  // ---- duration
  let dz = cdur.duration_seconds(0);
  if dz.secs != 0 || dz.nanos != 0 { return 18; }
  let dneg = cdur.duration_seconds(0 - 5);
  if dneg.secs != 0 - 5 || dneg.nanos != 0 { return 19; }
  let dmz = cdur.duration_millis(0);
  if dmz.secs != 0 || dmz.nanos != 0 { return 20; }
  let dm1 = cdur.duration_millis(0 - 1);
  if dm1.secs != 0 - 1 || dm1.nanos != 999000000 { return 21; }
  let dmuz = cdur.duration_micros(0);
  if dmuz.secs != 0 || dmuz.nanos != 0 { return 22; }
  let dmu = cdur.duration_micros(1500000);
  if dmu.secs != 1 || dmu.nanos != 500000000 { return 23; }
  let dnz = cdur.duration_nanos(0);
  if dnz.secs != 0 || dnz.nanos != 0 { return 24; }
  let dnm = cdur.duration_nanos(0 - 1);
  if dnm.secs != 0 - 1 || dnm.nanos != 999999999 { return 25; }
  let d5 = cdur.duration_seconds(5);
  if cdur.duration_as_secs(d5) != 5 { return 26; }
  if cdur.duration_as_ms(d5) != 5000 { return 27; }
  let d1500 = cdur.duration_millis(1500);
  if cdur.duration_as_ms(d1500) != 1500 { return 28; }
  if cdur.duration_as_secs(d1500) != 1 { return 29; }

  // ---- time (convert)
  let now = ctime.time_now();
  if now < 0 || now > 86399 { return 30; }
  let td0 = ctime.timestamp_to_date(0);
  if td0.year != 1970 || td0.month != 1 || td0.day != 1 { return 31; }
  let td1 = ctime.timestamp_to_date(86400);
  if td1.year != 1970 || td1.month != 1 || td1.day != 2 { return 32; }
  let tdn = ctime.timestamp_to_date(0 - 1);
  if tdn.year != 1969 || tdn.month != 12 || tdn.day != 31 { return 33; }
  if ctime.date_to_timestamp(&epoch_date) != 0 { return 34; }

  // ---- wstring
  if cws.from_wstring(0) != "" { return 35; }
  if cws.wstring_len(0) != 0 { return 36; }

  // ---- from / into
  if cfrom.from_int(0) != 0.0 { return 37; }
  if cfrom.from_float(0.0) != 0 { return 38; }
  if cfrom.from_bool(true) != 1 { return 39; }
  if cfrom.from_bool(false) != 0 { return 40; }
  if cinto.into_int(0.0) != 0 { return 41; }
  if cinto.into_float(0) != 0.0 { return 42; }

  // ---- roundtrip
  if crt.roundtrip_int("") { return 43; }
  if crt.roundtrip_int("0") == false { return 44; }
  if crt.roundtrip_int("007") { return 45; }
  if crt.roundtrip_float("") { return 46; }
  if crt.roundtrip_fixed(0.0, 0) == false { return 47; }
  if crt.roundtrip_fixed(1.5, 1) == false { return 48; }
  if crt.roundtrip_base(0, 10) == false { return 49; }
  if crt.roundtrip_base(42, 0) { return 50; }
  if crt.roundtrip_base(42, 37) { return 51; }
  if crt.roundtrip_base(42, 10) == false { return 52; }

  // ---- uuid
  let u = cuuid.uuid_v4();
  if u.len() != 36 { return 53; }
  if cuuid.uuid_parse("abc").is_some { return 54; }
  if cuuid.uuid_parse("123e4567-e89b-12d3-a456-426614174000").is_none { return 55; }
  if cuuid.uuid_is_valid("abc") { return 56; }
  if cuuid.uuid_is_valid("123e4567-e89b-12d3-a456-426614174000") == false { return 57; }
  let ub = cuuid.uuid_v4_bytes();
  if ub.len() != 16 { return 58; }

  // ---- mac
  if cmac.mac_parse("aa:bb").is_some { return 59; }
  if cmac.mac_parse("aa:bb:cc:dd:ee:ff").is_none { return 60; }
  let me = Vec[UInt8].new();
  if cmac.mac_to_string(&me) != "" { return 61; }
  let mb = Vec[UInt8].new();
  mb.push(1);
  mb.push(2);
  mb.push(3);
  mb.push(4);
  mb.push(5);
  mb.push(6);
  let ms = cmac.mac_to_string(&mb);
  if ms.len() != 17 { return 62; }
  if ms != "01:02:03:04:05:06" { return 63; }
  if cmac.mac_is_valid("aa:bb") { return 64; }
  let mr = cmac.mac_random();
  if mr.len() != 17 { return 65; }

  // ---- iri
  if ciri.iri_parse("").is_err == false { return 66; }
  if ciri.iri_parse("http://a/b").is_ok == false { return 67; }
  if ciri.iri_to_uri("").is_err == false { return 68; }
  if ciri.iri_to_uri("http://a/b").is_ok == false { return 69; }
  if ciri.iri_normalize("").is_err == false { return 70; }
  if ciri.iri_normalize("HTTP://A/b").is_ok == false { return 71; }
  let norm = ciri.iri_normalize("HTTP://A/b");
  match norm {
    Ok(n) => { if n != "http://a/b" { return 72; } },
    Err(_) => { return 73; },
  }

  return 0;
}
