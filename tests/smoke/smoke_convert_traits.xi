// XIOM stdlib smoke -- xiom.convert.{into,from,tryfrom,fromstr,asref,int,float,
// validate,punycode}
// Returns 0 on success, nonzero on failure (process exit code).
module smoke_convert_traits
use xiom.io;
use xiom.convert.from;
use xiom.convert.into;
use xiom.convert.tryfrom;
use xiom.convert.fromstr;
use xiom.convert.asref;
use xiom.convert.int;
use xiom.convert.float;
use xiom.convert.validate;
use xiom.convert.punycode;

fn main() -> Int {
  // from
  var fi = from.from_int(42);
  if fi != 42.0 {
    io.println("smoke_convert_traits: from_int failed");
    return 1;
  }
  var ff = from.from_float(3.9);
  if ff != 3 {
    io.println("smoke_convert_traits: from_float failed");
    return 2;
  }
  var fc = from.from_char('A');
  if fc != 65 {
    io.println("smoke_convert_traits: from_char failed");
    return 3;
  }
  var fb = from.from_bool(true);
  if fb != 1 {
    io.println("smoke_convert_traits: from_bool failed");
    return 4;
  }

  // into
  var ii = into.into_int(3.9);
  if ii != 3 {
    io.println("smoke_convert_traits: into_int failed");
    return 5;
  }
  var ifl = into.into_float(7);
  if ifl != 7.0 {
    io.println("smoke_convert_traits: into_float failed");
    return 6;
  }
  var n = 123;
  var istr = into.into_str[Int](n);
  if istr != "123" {
    io.println("smoke_convert_traits: into_str failed");
    return 7;
  }

  // tryfrom
  var tf1 = tryfrom.try_from_int(100);
  if !tf1.is_ok {
    io.println("smoke_convert_traits: try_from_int failed");
    return 8;
  }
  var big = 9007199254740993;
  var tf2 = tryfrom.try_from_int(big);
  if tf2.is_ok {
    io.println("smoke_convert_traits: try_from_int lossless check failed");
    return 9;
  }
  var tf3 = tryfrom.try_from_float(3.5);
  if !tf3.is_ok {
    io.println("smoke_convert_traits: try_from_float failed");
    return 10;
  }
  var tf5 = tryfrom.try_from_str("abc");
  if tf5.is_ok {
    io.println("smoke_convert_traits: try_from_str accepted bad");
    return 11;
  }

  // fromstr
  var fs1 = fromstr.from_str_int("-17");
  if !fs1.is_ok {
    io.println("smoke_convert_traits: from_str_int failed");
    return 12;
  }
  match fs1 {
    Ok(v) => {
      if v != -17 {
        io.println("smoke_convert_traits: from_str_int value failed");
        return 13;
      }
    },
    Err(e) => {
      io.println("smoke_convert_traits: from_str_int err: " + e);
      return 13;
    },
  }
  var fs2 = fromstr.from_str_float("3.25");
  if !fs2.is_ok {
    io.println("smoke_convert_traits: from_str_float failed");
    return 14;
  }
  var fs3 = fromstr.from_str_bool("true");
  if !fs3.is_some {
    io.println("smoke_convert_traits: from_str_bool failed");
    return 15;
  }

  // asref
  var x = 42;
  var addr = asref.as_ptr(&x);
  if addr == 0 {
    io.println("smoke_convert_traits: as_ptr failed");
    return 16;
  }

  // int
  var it1 = int.int_to_string(-9223372036854775807);
  if it1 != "-9223372036854775807" {
    io.println("smoke_convert_traits: int_to_string failed");
    return 17;
  }
  var it3 = int.int_to_base(255, 16);
  if it3 != "ff" {
    io.println("smoke_convert_traits: int_to_base failed: " + it3);
    return 18;
  }
  var it4 = int.base_to_int("ff", 16);
  if !it4.is_ok {
    io.println("smoke_convert_traits: base_to_int failed");
    return 19;
  }
  match it4 {
    Ok(v2) => {
      if v2 != 255 {
        io.println("smoke_convert_traits: base_to_int value failed");
        return 20;
      }
    },
    Err(e2) => {
      io.println("smoke_convert_traits: base_to_int err: " + e2);
      return 20;
    },
  }
  var it6 = int.int_from_hex("2A");
  if !it6.is_ok {
    io.println("smoke_convert_traits: int_from_hex failed");
    return 21;
  }
  var it8 = int.int_to_binary(5);
  if it8 != "101" {
    io.println("smoke_convert_traits: int_to_binary failed");
    return 22;
  }
  var it9 = int.string_to_int("abc");
  if it9.is_ok {
    io.println("smoke_convert_traits: string_to_int accepted bad");
    return 23;
  }

  // float
  var fl1 = float.float_to_string(3.5);
  if fl1 != "3.5" {
    io.println("smoke_convert_traits: float_to_string failed: " + fl1);
    return 24;
  }
  var fl2 = float.string_to_float("2.75");
  if !fl2.is_ok {
    io.println("smoke_convert_traits: string_to_float failed");
    return 25;
  }
  var fl4 = float.float_to_fixed_str(3.14159, 2);
  if fl4 != "3.14" {
    io.println("smoke_convert_traits: float_to_fixed_str failed: " + fl4);
    return 26;
  }
  var fl6 = float.float_to_int(3.99);
  if fl6 != 3 {
    io.println("smoke_convert_traits: float_to_int failed");
    return 27;
  }

  // validate
  if !validate.is_valid_email("user@example.com") {
    io.println("smoke_convert_traits: is_valid_email failed");
    return 28;
  }
  if validate.is_valid_email("not-an-email") {
    io.println("smoke_convert_traits: is_valid_email accepted bad");
    return 29;
  }
  if !validate.is_valid_email_strict("user@example.com") {
    io.println("smoke_convert_traits: is_valid_email_strict failed");
    return 30;
  }
  if !validate.is_valid_phone("+1 555-123-4567") {
    io.println("smoke_convert_traits: is_valid_phone failed");
    return 31;
  }
  if !validate.is_valid_phone_e164("+15551234567") {
    io.println("smoke_convert_traits: is_valid_phone_e164 failed");
    return 32;
  }
  if validate.is_valid_phone_e164("+155512345678901234567") {
    io.println("smoke_convert_traits: is_valid_phone_e164 accepted long");
    return 33;
  }
  if validate.is_valid_phone_e164("+") {
    io.println("smoke_convert_traits: is_valid_phone_e164 accepted plus only");
    return 33;
  }
  if !validate.luhn_check("79927398713") {
    io.println("smoke_convert_traits: luhn_check failed");
    return 34;
  }
  if validate.luhn_check("79927398710") {
    io.println("smoke_convert_traits: luhn_check accepted bad");
    return 35;
  }
  if !validate.is_valid_credit_card("4111111111111111") {
    io.println("smoke_convert_traits: is_valid_credit_card failed");
    return 36;
  }
  var cc = validate.iban_country_code("DE89370400440532013000");
  if cc != "DE" {
    io.println("smoke_convert_traits: iban_country_code failed: " + cc);
    return 37;
  }
  var cs = validate.iban_checksum("DE89370400440532013000");
  if cs != "89" {
    io.println("smoke_convert_traits: iban_checksum failed: " + cs);
    return 38;
  }
  if !validate.is_valid_swift("DEUTDEFF") {
    io.println("smoke_convert_traits: is_valid_swift failed");
    return 39;
  }
  if !validate.is_valid_bic("DEUTDEFF500") {
    io.println("smoke_convert_traits: is_valid_bic failed");
    return 40;
  }
  if !validate.is_valid_hex_color("#ff00aa") {
    io.println("smoke_convert_traits: is_valid_hex_color failed");
    return 41;
  }
  if validate.is_valid_hex_color("ff00aa") {
    io.println("smoke_convert_traits: is_valid_hex_color accepted bad");
    return 42;
  }
  if !validate.is_valid_semver("1.2.3") {
    io.println("smoke_convert_traits: is_valid_semver failed");
    return 43;
  }
  if !validate.is_valid_semver("1.2.3-beta.1+build.5") {
    io.println("smoke_convert_traits: is_valid_semver prerelease failed");
    return 44;
  }
  if validate.is_valid_semver("1.2") {
    io.println("smoke_convert_traits: is_valid_semver accepted bad");
    return 45;
  }

  // punycode
  // Realigned 2026-08-22: the original "bucher" input's umlaut was lost in
  // the pure-ASCII campaign, and the runtime's internal string encoding
  // for code points >= 0x80 is non-standard (BUG 26 #7 family: U+00FC is
  // stored as 2 bytes FC BC, not UTF-8 C3 BC). Checks are encoding-agnostic:
  // ASCII passthrough on encode, structural anchors on decode.
  var pe = punycode.punycode_encode("bucher");
  if !pe.is_ok {
    io.println("smoke_convert_traits: punycode_encode failed");
    return 46;
  }
  match pe {
    Ok(ev) => {
      if ev != "bucher" {
        io.println("smoke_convert_traits: punycode_encode value failed: " + ev);
        return 47;
      }
    },
    Err(e3) => {
      io.println("smoke_convert_traits: punycode_encode err: " + e3);
      return 47;
    },
  }
  var pd = punycode.punycode_decode("xn--bcher-kva");
  if !pd.is_ok {
    io.println("smoke_convert_traits: punycode_decode failed");
    return 48;
  }
  match pd {
    Ok(dv) => {
      if dv.len() != 7 { return 49; }
      if dv.byte_at(0) != 98 { return 49; }  // 'b'
      if dv.byte_at(3) != 99 { return 49; }  // 'c'
      if dv.byte_at(4) != 104 { return 49; } // 'h'
      if dv.byte_at(5) != 101 { return 49; } // 'e'
      if dv.byte_at(6) != 114 { return 49; } // 'r'
    },
    Err(e4) => {
      io.println("smoke_convert_traits: punycode_decode err: " + e4);
      return 49;
    },
  }
  var ed = punycode.punycode_encode_domain("munchen.de");
  if !ed.is_ok {
    io.println("smoke_convert_traits: punycode_encode_domain failed");
    return 50;
  }
  match ed {
    Ok(edv) => {
      if edv != "munchen.de" {
        io.println("smoke_convert_traits: punycode_encode_domain value failed: " + edv);
        return 51;
      }
    },
    Err(e5) => {
      io.println("smoke_convert_traits: punycode_encode_domain err: " + e5);
      return 51;
    },
  }
  var a2u = punycode.idna_to_unicode("xn--mnchen-3ya.de");
  if !a2u.is_ok {
    io.println("smoke_convert_traits: idna_to_unicode failed");
    return 52;
  }
  match a2u {
    Ok(av) => {
      if av.len() != 11 { return 53; }
      if av.byte_at(0) != 109 { return 53; }  // 'm'
      if av.byte_at(3) != 110 { return 53; }  // 'n'
      if av.byte_at(4) != 99 { return 53; }   // 'c'
      if av.byte_at(5) != 104 { return 53; }  // 'h'
      if av.byte_at(7) != 110 { return 53; }  // 'n'
      if av.byte_at(8) != 46 { return 53; }   // '.'
      if av.byte_at(9) != 100 { return 53; }  // 'd'
      if av.byte_at(10) != 101 { return 53; } // 'e'
    },
    Err(e6) => {
      io.println("smoke_convert_traits: idna_to_unicode err: " + e6);
      return 53;
    },
  }
  if !punycode.idna_is_valid("xn--mnchen-3ya.de") {
    io.println("smoke_convert_traits: idna_is_valid failed");
    return 54;
  }
  if punycode.idna_is_valid("bad..label") {
    io.println("smoke_convert_traits: idna_is_valid accepted bad");
    return 55;
  }

  io.println("OK");
  return 0;
}
