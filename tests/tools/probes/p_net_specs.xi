// p_net_specs.xi -- wave 6 part 2 validation for net contract clauses.
module p_net_specs
use xiom.net;
use xiom.net.address;
use xiom.net.cookie;
use xiom.net.ftp;
use xiom.io;

fn main() -> Int {
  if ftp.ftp_default_port() != 21 { io.println("ftp port"); return 1; };
  if ftp.ftp_reply_is_success(199) { return 2; };
  if !ftp.ftp_reply_is_success(200) { return 3; };
  if !ftp.ftp_reply_is_success(299) { return 4; };
  if ftp.ftp_reply_is_success(300) { return 5; };
  if ftp.ftp_reply_is_positive_preliminary(99) { return 6; };
  if !ftp.ftp_reply_is_positive_preliminary(100) { return 7; };
  if !ftp.ftp_reply_is_positive_preliminary(199) { return 8; };
  if ftp.ftp_reply_is_positive_preliminary(200) { return 9; };

  var jar = cookie.cookie_jar_new();
  if cookie.cookie_jar_size(&jar) != 0 { io.println("jar 0"); return 10; };

  if address.address_port("host:8080") != 8080 { io.println("addr 8080"); return 11; };
  if address.address_port("nonsense") != 0 { io.println("addr none"); return 12; };
  if address.address_port("host:-1") != 0 { io.println("addr neg"); return 13; };
  if address.address_port("host:0") != 0 { io.println("addr zero"); return 14; };

  if net.is_valid_port(0) { return 15; };
  if !net.is_valid_port(1) { return 16; };
  if !net.is_valid_port(65535) { return 17; };
  if net.is_valid_port(65536) { return 18; };
  if net.is_valid_port(-5) { return 19; };

  io.println("P_NET_SPECS OK");
  io.flush_stdout();
  0
}
