// XIOM stdlib smoke test -- xiom.net.{dns,ftp,smtp,tcp,udp,socket,tls,server}
// Protocol format helpers per stub.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net_proto

use xiom.net.dns;
use xiom.net.ftp;
use xiom.net.smtp;
use xiom.net.tcp;
use xiom.net.udp;
use xiom.net.socket;
use xiom.net.tls;
use xiom.net.server;
use xiom.io;

fn main() -> Int {
  // --- dns ---
  let v4 = dns.dns_parse_ipv4("192.168.1.1");
  match v4 {
    Some(b) => {
      if b.len() != 4 {
        io.println("dns-v4");
        return 1;
      }
    }
    None => {
      io.println("dns-v4");
      return 1;
    }
  }
  if dns.dns_is_valid_hostname("example.com") != true {
    io.println("dns-host");
    return 2;
  }
  if dns.dns_is_valid_hostname("-bad.com") != false {
    io.println("dns-host-bad");
    return 3;
  }
  let wp = dns.dns_well_known_port("https");
  match wp {
    Some(p) => {
      if p != 443 {
        io.println("dns-port");
        return 4;
      }
    }
    None => {
      io.println("dns-port");
      return 4;
    }
  }

  // --- ftp ---
  let u = ftp.ftp_command_user("alice");
  if u != "USER alice\r\n" {
    io.println("ftp-user");
    return 5;
  }
  let p = ftp.ftp_command_pass("secret");
  if p != "PASS secret\r\n" {
    io.println("ftp-pass");
    return 6;
  }
  let r = ftp.ftp_parse_reply("220 Welcome");
  match r {
    Some(t) => {
      if t.0 != 220 {
        io.println("ftp-reply");
        return 7;
      }
      if t.1 != "Welcome" {
        io.println("ftp-reply-text");
        return 7;
      }
    }
    None => {
      io.println("ftp-reply");
      return 7;
    }
  }
  if ftp.ftp_reply_is_success(250) != true {
    io.println("ftp-ok");
    return 8;
  }
  if ftp.ftp_default_port() != 21 {
    io.println("ftp-port");
    return 9;
  }

  // --- smtp ---
  let eh = smtp.smtp_command_ehlo("client.example.com");
  if eh != "EHLO client.example.com\r\n" {
    io.println("smtp-ehlo");
    return 10;
  }
  let mf = smtp.smtp_command_mail_from("a@example.com");
  if mf != "MAIL FROM:<a@example.com>\r\n" {
    io.println("smtp-mail");
    return 11;
  }
  let sr = smtp.smtp_parse_reply("250 OK");
  match sr {
    Some(t) => {
      if t.0 != 250 {
        io.println("smtp-reply");
        return 12;
      }
    }
    None => {
      io.println("smtp-reply");
      return 12;
    }
  }
  if smtp.smtp_reply_is_success(250) != true {
    io.println("smtp-ok");
    return 13;
  }
  if smtp.smtp_default_port() != 25 {
    io.println("smtp-port");
    return 14;
  }

  // --- tcp ---
  if tcp.tcp_validate_port(8080) != true {
    io.println("tcp-port");
    return 15;
  }
  if tcp.tcp_validate_port(70000) != false {
    io.println("tcp-port-bad");
    return 16;
  }
  let te = tcp.tcp_parse_endpoint("host.example.com:8080");
  match te {
    Some(t) => {
      if t.0 != "host.example.com" {
        io.println("tcp-host");
        return 17;
      }
      if t.1 != 8080 {
        io.println("tcp-port2");
        return 17;
      }
    }
    None => {
      io.println("tcp-parse");
      return 17;
    }
  }
  let fe = tcp.tcp_format_endpoint("h", 80);
  if fe != "h:80" {
    io.println("tcp-fmt");
    return 18;
  }

  // --- udp ---
  if udp.udp_validate_port(53) != true {
    io.println("udp-port");
    return 19;
  }
  let ue = udp.udp_parse_endpoint("ns.example.com:53");
  match ue {
    Some(t) => {
      if t.1 != 53 {
        io.println("udp-parse");
        return 20;
      }
    }
    None => {
      io.println("udp-parse");
      return 20;
    }
  }

  // --- socket ---
  let sd = socket.socket_tcp();
  match sd {
    Ok(fd) => {
      if fd < 0 {
        io.println("socket-fd");
        return 21;
      }
      socket.socket_close(fd);
    }
    Err(_) => {
      io.println("socket-create");
      return 22;
    }
  }
  let st = socket.socket_set_timeout(0, 100);
  if st.is_ok {
    io.println("socket-timeout");
    return 23;
  }

  // --- tls ---
  if tls.tls_default_port() != 443 {
    io.println("tls-port");
    return 24;
  }
  if tls.tls_version_name(0x0303) != "TLSv1.2" {
    io.println("tls-ver");
    return 25;
  }
  if tls.tls_alert_name(40) != "handshake_failure" {
    io.println("tls-alert");
    return 26;
  }
  if tls.tls_cipher_suite_name(0xC02F) != "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256" {
    io.println("tls-cipher");
    return 27;
  }

  // --- server ---
  let rl = server.server_parse_request_line("GET /index.html HTTP/1.1");
  match rl {
    Some(t) => {
      if t.0 != "GET" {
        io.println("srv-method");
        return 28;
      }
      if t.1 != "/index.html" {
        io.println("srv-target");
        return 28;
      }
      if t.2 != "HTTP/1.1" {
        io.println("srv-ver");
        return 28;
      }
    }
    None => {
      io.println("srv-request-line");
      return 28;
    }
  }
  let resp = server.server_build_response(200, "hi");
  if resp.starts_with("HTTP/1.1 200 OK") != true {
    io.println("srv-resp");
    return 29;
  }
  if server.server_status_text(404) != "Not Found" {
    io.println("srv-status");
    return 30;
  }
  if server.server_default_port() != 80 {
    io.println("srv-port");
    return 31;
  }

  io.println("OK");
  return 0;
}
