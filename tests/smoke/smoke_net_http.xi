// XIOM stdlib smoke test -- xiom.net.http + xiom.net.https
// HTTP/HTTPS request line, request building, response parsing helpers.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net_http

use xiom.net.http;
use xiom.net.https;
use xiom.io;

fn main() -> Int {
  // --- http request line build ---
  let line = http.http_request_line("GET", "/");
  if line != "GET / HTTP/1.1" {
    io.println("http-line=[" + line + "]");
    return 1;
  }
  let line2 = http.http_request_line("POST", "/api");
  if line2 != "POST /api HTTP/1.1" {
    io.println("http-line2");
    return 2;
  }

  // --- https request line ---
  let hline = https.https_request_line("GET", "/");
  if hline != "GET / HTTP/1.1" {
    io.println("https-line");
    return 3;
  }

  // --- status text ---
  if http.http_status_text(200) != "OK" {
    io.println("http-st200");
    return 4;
  }
  if http.http_status_text(404) != "Not Found" {
    io.println("http-st404");
    return 5;
  }
  if http.http_status_text(500) != "Internal Server Error" {
    io.println("http-st500");
    return 6;
  }
  if https.https_status_text(503) != "Service Unavailable" {
    io.println("https-st503");
    return 7;
  }

  // --- url encode/decode ---
  let enc = http.http_url_encode("a b&c=d");
  if enc != "a%20b%26c%3Dd" {
    io.println("http-enc=[" + enc + "]");
    return 8;
  }
  let dec = http.http_url_decode("a%20b%26c%3Dd");
  match dec {
    Ok(s) => {
      if s != "a b&c=d" {
        io.println("http-dec");
        return 9;
      }
    }
    Err(_) => {
      io.println("http-dec");
      return 9;
    }
  }

  // --- response status extraction ---
  let st = http.http_response_status("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nhello");
  match st {
    Some(c) => {
      if c != 200 {
        io.println("http-resp-status");
        return 10;
      }
    }
    None => {
      io.println("http-resp-status");
      return 10;
    }
  }
  let st2 = https.https_response_status("HTTP/1.1 404 Not Found\r\n\r\nx");
  match st2 {
    Some(c) => {
      if c != 404 {
        io.println("https-resp-status");
        return 11;
      }
    }
    None => {
      io.println("https-resp-status");
      return 11;
    }
  }

  // --- response header parsing ---
  let hdrs = http.http_parse_response_headers("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nX-A: 1\r\n\r\nbody");
  if hdrs.len() != 2 {
    io.println("http-hdrs-len");
    return 12;
  }

  // --- request building ---
  var h: Vec[(Str, Str)] = Vec[(Str, Str)]::new();
  h.push(("User-Agent", "xiom"));
  var b: Vec[UInt8] = Vec[UInt8]::new();
  let req = http.http_build_request("POST", "http://example.com/api?x=1", &h, &b);
  match req {
    Ok(r) => {
      if r.starts_with("POST /api?x=1 HTTP/1.1") != true {
        io.println("http-build-line");
        return 13;
      }
      if r.starts_with("Host: example.com") == true {
        io.println("http-build-host");
        return 13;
      }
    }
    Err(_) => {
      io.println("http-build");
      return 13;
    }
  }
  let req2 = https.https_build_request("GET", "https://example.com/", &h, &b);
  match req2 {
    Ok(r) => {
      if r.starts_with("GET / HTTP/1.1") != true {
        io.println("https-build-line");
        return 14;
      }
    }
    Err(_) => {
      io.println("https-build");
      return 14;
    }
  }

  // --- default ports ---
  if https.https_default_port() != 443 {
    io.println("https-port");
    return 15;
  }

  io.println("OK");
  return 0;
}
