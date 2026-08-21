// XIOM stdlib smoke -- xiom.convert.{escape,quotedprintable,uuencode}
// Returns 0 on success, nonzero on failure (process exit code).
module smoke_convert_escape
use xiom.io;
use xiom.convert;
use xiom.string;
use xiom.convert.escape;
use xiom.convert.quotedprintable;
use xiom.convert.uuencode;

fn main() -> Int {
  // escape: html
  var he = escape.html_escape("a\"b<");
  if he != "a&quot;b&lt;" {
    io.println("smoke_convert_escape: html_escape failed: " + he);
    return 1;
  }
  var hu = escape.html_unescape(he);
  if hu != "a\"b<" {
    io.println("smoke_convert_escape: html_unescape failed: " + hu);
    return 2;
  }
  var hu2 = escape.html_unescape("&#65;&#x42;");
  if hu2 != "AB" {
    io.println("smoke_convert_escape: html_unescape numeric failed: " + hu2);
    return 3;
  }
  // escape: xml
  var xe = escape.xml_escape("<a> & 'b'");
  var xu = escape.xml_unescape(xe);
  if xu != "<a> & 'b'" {
    io.println("smoke_convert_escape: xml round-trip failed: " + xu);
    return 4;
  }
  // escape: csv
  var csv = escape.csv_escape_field("a,b\"c");
  if csv != "\"a,b\"\"c\"" {
    io.println("smoke_convert_escape: csv_escape_field failed: " + csv);
    return 5;
  }
  var csvu = escape.csv_unescape_field(csv);
  if csvu != "a,b\"c" {
    io.println("smoke_convert_escape: csv_unescape_field failed: " + csvu);
    return 6;
  }
  // escape: tsv
  var tsv = escape.tsv_escape_field("a\tb");
  var tsvu = escape.tsv_unescape_field(tsv);
  if tsvu != "a\tb" {
    io.println("smoke_convert_escape: tsv round-trip failed");
    return 7;
  }
  // escape: regex + glob
  var re = escape.regex_escape("a.b*c");
  if re != "a\\.b\\*c" {
    io.println("smoke_convert_escape: regex_escape failed: " + re);
    return 8;
  }
  var ge = escape.glob_escape("a*b?");
  var gu = escape.glob_unescape(ge);
  if gu != "a*b?" {
    io.println("smoke_convert_escape: glob round-trip failed: " + gu);
    return 9;
  }
  // escape: shell + cmd
  var sq = escape.shell_quote("it's");
  if sq != "'it'\\''s'" {
    io.println("smoke_convert_escape: shell_quote failed: " + sq);
    return 10;
  }
  var se = escape.shell_escape("a b$c");
  if se != "a\\ b\\$c" {
    io.println("smoke_convert_escape: shell_escape failed: " + se);
    return 11;
  }
  var ce = escape.cmd_escape("a&b");
  if ce != "a^&b" {
    io.println("smoke_convert_escape: cmd_escape failed: " + ce);
    return 12;
  }
  var cq = escape.cmd_quote("x");
  if cq != "\"x\"" {
    io.println("smoke_convert_escape: cmd_quote failed: " + cq);
    return 13;
  }

  // quotedprintable
  var data = Vec[UInt8].new();
  data.push(97);
  data.push(61);
  data.push(98);
  data.push(32);
  data.push(120);
  var qpe = quotedprintable.qp_encode(&data);
  var qpd = quotedprintable.qp_decode(qpe);
  if !qpd.is_ok {
    io.println("smoke_convert_escape: qp_decode failed");
    return 20;
  }
  match qpd {
    Ok(out) => {
      if out.len() != 5 {
        io.println("smoke_convert_escape: qp round-trip len failed");
        return 21;
      }
      var i: Int = 0;
      while i < 5 {
        if out[i] != data[i] {
          io.println("smoke_convert_escape: qp round-trip byte failed");
          return 22;
        }
        i = i + 1;
      }
    },
    Err(e) => {
      io.println("smoke_convert_escape: qp err: " + e);
      return 21;
    },
  }
  var eb = quotedprintable.qp_escape_byte(61);
  if eb != "=3D" {
    io.println("smoke_convert_escape: qp_escape_byte failed: " + eb);
    return 23;
  }
  if quotedprintable.qp_is_binary("hello") {
    io.println("smoke_convert_escape: qp_is_binary false positive");
    return 24;
  }
  var longdata = Vec[UInt8].new();
  var k: Int = 0;
  while k < 80 {
    longdata.push((65 + (k % 26)) as UInt8);
    k = k + 1;
  }
  var longenc = quotedprintable.qp_encode(&longdata);
  var longdec = quotedprintable.qp_decode(longenc);
  if !longdec.is_ok {
    io.println("smoke_convert_escape: qp long decode failed");
    return 25;
  }
  match longdec {
    Ok(ld) => {
      if ld.len() != 80 {
        io.println("smoke_convert_escape: qp long len failed");
        return 26;
      }
    },
    Err(e3) => {
      io.println("smoke_convert_escape: qp long err: " + e3);
      return 26;
    },
  }

  // uuencode: known answers (avoid reading Vec payloads -- compiler bug)
  var ud = Vec[UInt8].new();
  ud.push(104);
  ud.push(101);
  ud.push(108);
  ud.push(108);
  ud.push(111);
  var ue = uuencode.uuencode(&ud);
  if ue != "%:&5L;&\\ \n" {
    io.println("smoke_convert_escape: uuencode known-answer failed: " + ue);
    return 30;
  }
  var uud = uuencode.uudecode(ue);
  if !uud.is_ok {
    io.println("smoke_convert_escape: uudecode failed");
    return 31;
  }
  var uul = uuencode.uuencode_line(&ud);
  if uul != "%:&5L;&\\ " {
    io.println("smoke_convert_escape: uuencode_line known-answer failed: " + uul);
    return 32;
  }
  var uul_dec = uuencode.uudecode_line(uul);
  if !uul_dec.is_ok {
    io.println("smoke_convert_escape: uudecode_line failed");
    return 33;
  }
  var bad_line = uuencode.uudecode_line("!!!");
  if bad_line.is_ok {
    io.println("smoke_convert_escape: uudecode_line accepted bad");
    return 34;
  }
  var xxe = uuencode.xxencode(&ud);
  if xxe != "3O4JgP4w+\n" {
    io.println("smoke_convert_escape: xxencode known-answer failed: " + xxe);
    return 35;
  }
  var xxd = uuencode.xxdecode(xxe);
  if !xxd.is_ok {
    io.println("smoke_convert_escape: xxdecode failed");
    return 36;
  }
  var el = uuencode.uu_encoded_length(5);
  if el != 61 {
    io.println("smoke_convert_escape: uu_encoded_length failed: " + convert.int_to_string(el));
    return 37;
  }

  io.println("OK");
  return 0;
}



