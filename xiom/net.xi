// XIOM — Networking Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net

// === TCP ===
pub type TcpStream = { fd: Int; } derive[Clone]

pub type TcpListener = { fd: Int; } derive[Clone]

pub type NetError = { message: Str; code: Int; }

pub fn tcp_connect(host: Str, port: Int) -> Result[TcpStream, NetError] {
  Err(NetError{ message: "TCP requires OS socket FFI — implement tcp_connect via platform socket API (socket/connect)"; code: -1; })
}

pub fn tcp_listen(host: Str, port: Int) -> Result[TcpListener, NetError] {
  Err(NetError{ message: "TCP requires OS socket FFI — implement tcp_listen via platform socket API (socket/bind/listen)"; code: -2; })
}

pub fn TcpStream.read(self, buf: &mut Vec[UInt8]) -> Result[Int, NetError] {
  Err(NetError{ message: "TCP requires OS socket FFI — implement TcpStream.read via platform socket API (recv)"; code: -3; })
}

pub fn TcpStream.write(self, data: &Vec[UInt8]) -> Result[Int, NetError] {
  Err(NetError{ message: "TCP requires OS socket FFI — implement TcpStream.write via platform socket API (send)"; code: -4; })
}

pub fn TcpStream.close(self) -> Result[Unit, NetError] {
  Ok(Unit)
}

pub fn TcpListener.accept(self) -> Result[(TcpStream, Str), NetError] {
  Err(NetError{ message: "TCP requires OS socket FFI — implement TcpListener.accept via platform socket API (accept)"; code: -5; })
}

// === HTTP ===
pub type HttpResponse = {
  status: Int;
  body: Str;
} derive[Clone]

pub fn http_get(url: Str) -> Result[HttpResponse, NetError] {
  let parsed = parse_url(url)?;
  var request: Str = "GET " + parsed.path;
  if parsed.query.len() > 0 {
    request = request + "?" + parsed.query;
  }
  request = request + " HTTP/1.1\r\n";
  request = request + "Host: " + parsed.host + "\r\n";
  request = request + "Connection: close\r\n";
  request = request + "User-Agent: XIOM/0.1\r\n";
  request = request + "\r\n";
  var port: Int = 0;
  if parsed.port > 0 {
    port = parsed.port;
  } else {
    if parsed.scheme == "https" {
      port = 443;
    } else {
      port = 80;
    }
  }
  let stream = tcp_connect(parsed.host, port)?;
  var req_bytes: Vec[UInt8] = Vec[UInt8]::with_capacity(request.len() as UInt);
  var j = 0;
  while j < request.len() {
    req_bytes.push(request.byte_at(j));
    j = j + 1;
  }
  stream.write(&req_bytes)?;
  var resp_buf: Vec[UInt8] = Vec[UInt8]::with_capacity(65536);
  let total = stream.read(&mut resp_buf)?;
  stream.close()?;
  var resp_bytes: Vec[UInt8] = Vec[UInt8]::with_capacity(total as UInt);
  var k = 0;
  while k < total {
    if k < resp_buf.len() {
      resp_bytes.push(resp_buf[k]);
    }
    k = k + 1;
  }
  let raw = Str::from_utf8(resp_bytes);
  parse_http_response(raw)
}

pub fn http_post(url: Str, body: Str) -> Result[HttpResponse, NetError] {
  let parsed = parse_url(url)?;
  var request: Str = "POST " + parsed.path;
  if parsed.query.len() > 0 {
    request = request + "?" + parsed.query;
  }
  request = request + " HTTP/1.1\r\n";
  request = request + "Host: " + parsed.host + "\r\n";
  request = request + "Connection: close\r\n";
  request = request + "Content-Type: application/x-www-form-urlencoded\r\n";
  request = request + "Content-Length: " + body.len().to_str() + "\r\n";
  request = request + "User-Agent: XIOM/0.1\r\n";
  request = request + "\r\n";
  request = request + body;
  var port: Int = 0;
  if parsed.port > 0 {
    port = parsed.port;
  } else {
    if parsed.scheme == "https" {
      port = 443;
    } else {
      port = 80;
    }
  }
  let stream = tcp_connect(parsed.host, port)?;
  var req_bytes: Vec[UInt8] = Vec[UInt8]::with_capacity(request.len() as UInt);
  var j = 0;
  while j < request.len() {
    req_bytes.push(request.byte_at(j));
    j = j + 1;
  }
  stream.write(&req_bytes)?;
  var resp_buf: Vec[UInt8] = Vec[UInt8]::with_capacity(65536);
  let total = stream.read(&mut resp_buf)?;
  stream.close()?;
  var resp_bytes: Vec[UInt8] = Vec[UInt8]::with_capacity(total as UInt);
  var k = 0;
  while k < total {
    if k < resp_buf.len() {
      resp_bytes.push(resp_buf[k]);
    }
    k = k + 1;
  }
  let raw = Str::from_utf8(resp_bytes);
  parse_http_response(raw)
}

fn parse_http_response(raw: Str) -> Result[HttpResponse, NetError] {
  let sp = string.index_of(raw, " ");
  if sp.is_none {
    return Err(NetError{ message: "invalid HTTP response: no status line"; code: -10; });
  }
  let sp_idx = sp.value;
  let after_sp = str_slice(raw, sp_idx + 1, raw.len());
  let sp2 = string.index_of(after_sp, " ");
  var status_str: Str = "";
  if sp2.is_some {
    status_str = str_slice(after_sp, 0, sp2.value);
  } else {
    let nl = string.index_of(after_sp, "\r");
    if nl.is_some {
      status_str = str_slice(after_sp, 0, nl.value);
    } else {
      status_str = after_sp;
    }
  }
  let status = str_to_int(status_str);
  let body_sep = string.index_of(raw, "\r\n\r\n");
  var body: Str = "";
  if body_sep.is_some {
    body = str_slice(raw, body_sep.value + 4, raw.len());
  } else {
    let body_sep2 = string.index_of(raw, "\n\n");
    if body_sep2.is_some {
      body = str_slice(raw, body_sep2.value + 2, raw.len());
    } else {
      body = "";
    }
  }
  Ok(HttpResponse{ status: status; body: body; })
}

// === UDP ===
pub type UdpSocket = { fd: Int; }

fn udp_bind(host: Str, port: Int) -> Result[UdpSocket, NetError] {
  Err(NetError{ message: "UDP requires OS socket FFI — implement udp_bind via platform socket API (socket/bind)"; code: -6; })
}

pub fn UdpSocket.send_to(self, data: &Vec[UInt8], addr: Str, port: Int) -> Result[Int, NetError] {
  Err(NetError{ message: "UDP requires OS socket FFI — implement UdpSocket.send_to via platform socket API (sendto)"; code: -7; })
}

pub fn UdpSocket.recv_from(self, buf: &mut Vec[UInt8]) -> Result[(Int, Str, Int), NetError] {
  Err(NetError{ message: "UDP requires OS socket FFI — implement UdpSocket.recv_from via platform socket API (recvfrom)"; code: -8; })
}

pub fn UdpSocket.close(self) -> Result[Unit, NetError] {
  Ok(Unit)
}

// === DNS ===
fn resolve_host(hostname: Str) -> Result[Vec[Str], NetError] {
  var dot_count: Int = 0;
  var i: Int = 0;
  var all_digits = true;
  var len = hostname.len();
  while i < len {
    let b = hostname.byte_at(i);
    if b == 46 {
      dot_count = dot_count + 1;
    } elif b < 48 or b > 57 {
      all_digits = false;
    }
    i = i + 1;
  }
  if all_digits and dot_count == 3 {
    var result: Vec[Str] = Vec[Str]::new();
    result.push(hostname);
    return Ok(result);
  }
  Err(NetError{ message: "DNS resolution requires OS resolver FFI — implement resolve_host via getaddrinfo"; code: -9; })
}

fn local_addr(port: Int) -> Result[Str, NetError] {
  Err(NetError{ message: "local address requires OS socket FFI — implement local_addr via gethostname/getsockname"; code: -10; })
}

// === URL parsing ===
pub type UrlParts = {
  scheme: Str;
  host: Str;
  port: Int;
  path: Str;
  query: Str;
  fragment: Str;
}

fn parse_url(url: Str) -> Result[UrlParts, NetError] {
  let len = url.len();
  if len == 0 {
    return Err(NetError{ message: "empty URL"; code: -30; });
  }
  var scheme: Str = "";
  var rest: Str = url;
  let scheme_pos = string.index_of(url, "://");
  if scheme_pos.is_some {
    let sp = scheme_pos.value;
    scheme = str_slice(url, 0, sp);
    rest = str_slice(url, sp + 3, len);
  }
  var host: Str = "";
  var port: Int = 0;
  var path: Str = "/";
  var query: Str = "";
  var fragment: Str = "";
  let path_start = string.index_of(rest, "/");
  let query_start = string.index_of(rest, "?");
  let frag_start = string.index_of(rest, "#");
  var authority_end: Int = rest.len();
  if path_start.is_some and path_start.value < authority_end {
    authority_end = path_start.value;
  }
  if query_start.is_some and query_start.value < authority_end {
    authority_end = query_start.value;
  }
  if frag_start.is_some and frag_start.value < authority_end {
    authority_end = frag_start.value;
  }
  var authority = str_slice(rest, 0, authority_end);
  let colon_pos = string.index_of(authority, ":");
  if colon_pos.is_some {
    host = str_slice(authority, 0, colon_pos.value);
    let port_str = str_slice(authority, colon_pos.value + 1, authority.len());
    port = str_to_int(port_str);
  } else {
    host = authority;
  }
  if host.len() == 0 {
    return Err(NetError{ message: "URL has no host"; code: -31; });
  }
  let after_authority = str_slice(rest, authority_end, rest.len());
  if after_authority.len() > 0 {
    let after_auth_len = after_authority.len();
    var frag_in_after: Option[Int] = None;
    var query_in_after: Option[Int] = None;
    var j = 0;
    while j < after_auth_len {
      if after_authority[j] == '?' and query_in_after.is_none {
        query_in_after = Some(j);
      }
      if after_authority[j] == '#' and frag_in_after.is_none {
        frag_in_after = Some(j);
      }
      j = j + 1;
    }
    var path_end: Int = after_auth_len;
    if query_in_after.is_some and query_in_after.value < path_end {
      path_end = query_in_after.value;
    }
    if frag_in_after.is_some and frag_in_after.value < path_end {
      path_end = frag_in_after.value;
    }
    path = str_slice(after_authority, 0, path_end);
    if path.len() == 0 {
      path = "/";
    }
    if query_in_after.is_some {
      var query_end: Int = after_auth_len;
      if frag_in_after.is_some and frag_in_after.value > query_in_after.value {
        query_end = frag_in_after.value;
      }
      query = str_slice(after_authority, query_in_after.value + 1, query_end);
    }
    if frag_in_after.is_some {
      fragment = str_slice(after_authority, frag_in_after.value + 1, after_auth_len);
    }
  }
  Ok(UrlParts{
    scheme: scheme;
    host: host;
    port: port;
    path: path;
    query: query;
    fragment: fragment;
  })
}

// === HTTP methods ===
pub type HttpMethod = enum { GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS }

// === Helpers: string utilities ===

fn str_slice(s: Str, start: Int, end: Int) -> Str {
  let len = s.len();
  var s_start = start;
  var s_end = end;
  if s_start < 0 { s_start = 0; }
  if s_end > len { s_end = len; }
  if s_start >= s_end { return ""; }
  let len_result = s_end - s_start;
  var buf: Vec[UInt8] = Vec[UInt8]::with_capacity(len_result as UInt);
  var i = s_start;
  while i < s_end {
    buf.push(s.byte_at(i));
    i = i + 1;
  }
  match Str::from_utf8(buf) {
    Ok(s) => { return s; }
    Err(_) => { return ""; }
  }
}

fn str_to_int(s: Str) -> Int {
  var result: Int = 0;
  var sign: Int = 1;
  var start: Int = 0;
  let len = s.len();
  if len > 0 and s.byte_at(0) == 45 {
    sign = -1;
    start = 1;
  } elif len > 0 and s.byte_at(0) == 43 {
    start = 1;
  }
  var i = start;
  while i < len {
    let b = s.byte_at(i);
    if b < 48 or b > 57 { break; }
    result = result * 10 + (b as Int - 48);
    i = i + 1;
  }
  result * sign
}
