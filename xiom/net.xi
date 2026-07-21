// XIOM — Networking Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net

// === FFI: C Runtime Socket Functions ===
extern "C" {
  fn xiom_socket_create(family: Int, typ: Int, proto: Int) -> Int;
  fn xiom_socket_connect(sock: Int, host: *UInt8, port: Int) -> Int;
  fn xiom_socket_bind(sock: Int, port: Int) -> Int;
  fn xiom_socket_listen(sock: Int, backlog: Int) -> Int;
  fn xiom_socket_accept(sock: Int, client_ip: *UInt8, client_port: *Int) -> Int;
  fn xiom_socket_send(sock: Int, buf: *UInt8, len: Int) -> Int;
  fn xiom_socket_recv(sock: Int, buf: *UInt8, len: Int) -> Int;
  fn xiom_socket_close(sock: Int) -> Int;
  fn xiom_dns_resolve(hostname: *UInt8, ip_buf: *UInt8, buf_size: Int) -> Int;
  fn xiom_socket_sendto(sock: Int, buf: *UInt8, len: Int, host: *UInt8, port: Int) -> Int;
  fn xiom_socket_recvfrom(sock: Int, buf: *UInt8, len: Int, out_ip: *UInt8, out_port: *Int) -> Int;
  fn xiom_gethostname(buf: *UInt8, len: Int) -> Int;
  // Memory helpers (from xiom_runtime)
  fn xiom_alloc(size: UInt) -> *UInt8;
  fn xiom_free(ptr: *UInt8);
}

// === Constants ===
const AF_INET: Int = 2;
const SOCK_STREAM: Int = 1;
const SOCK_DGRAM: Int = 2;

// === TCP ===
pub type TcpStream = { fd: Int; } derive[Clone]

pub type TcpListener = { fd: Int; } derive[Clone]

pub type NetError = { message: Str; code: Int; }

pub fn tcp_connect(host: Str, port: Int) -> Result[TcpStream, NetError]
  requires: host.len() > 0
  requires: port > 0 && port <= 65535 {
  if host.len() <= 0 {
    return Err(NetError{ message: "host must not be empty"; code: -100; });
  }
  if port <= 0 || port >= 65536 {
    return Err(NetError{ message: "port out of range (1-65535)"; code: -101; });
  }
  unsafe {
    let fd = xiom_socket_create(AF_INET, SOCK_STREAM, 0);
    if fd < 0 {
      return Err(NetError{ message: "failed to create socket"; code: fd; });
    }
    var c_host_buf: [256]UInt8;
    var i = 0;
    let hlen = host.len();
    while i < hlen && i < 255 {
      c_host_buf[i] = host.byte_at(i);
      i = i + 1;
    }
    c_host_buf[i] = 0 as UInt8;
    let result = xiom_socket_connect(fd, &c_host_buf as *UInt8, port);
    if result < 0 {
      xiom_socket_close(fd);
      return Err(NetError{ message: "connection failed"; code: result; });
    }
    return Ok(TcpStream{ fd: fd; });
  }
}

pub fn tcp_listen(host: Str, port: Int) -> Result[TcpListener, NetError]
  requires: host.len() > 0
  requires: port > 0 && port <= 65535 {
  if port <= 0 || port >= 65536 {
    return Err(NetError{ message: "port out of range (1-65535)"; code: -101; });
  }
  unsafe {
    let fd = xiom_socket_create(AF_INET, SOCK_STREAM, 0);
    if fd < 0 {
      return Err(NetError{ message: "failed to create socket"; code: fd; });
    }
    if xiom_socket_bind(fd, port) < 0 {
      xiom_socket_close(fd);
      return Err(NetError{ message: "bind failed"; code: -1; });
    }
    if xiom_socket_listen(fd, 128) < 0 {
      xiom_socket_close(fd);
      return Err(NetError{ message: "listen failed"; code: -1; });
    }
    return Ok(TcpListener{ fd: fd; });
  }
}

pub fn TcpStream.read(self, buf: &mut Vec[UInt8]) -> Result[Int, NetError] {
  unsafe {
    var recv_buf: [4096]UInt8;
    let n = xiom_socket_recv(self.fd, &recv_buf as *UInt8, 4096);
    if n < 0 {
      return Err(NetError{ message: "read failed"; code: n; });
    }
    var i = 0;
    while i < n {
      buf.push(recv_buf[i]);
      i = i + 1;
    }
    return Ok(n);
  }
}

pub fn TcpStream.write(self, data: &Vec[UInt8]) -> Result[Int, NetError] {
  unsafe {
    var raw_buf: [65536]UInt8;
    var i = 0;
    let dlen = data.len();
    if dlen > 65536 {
      return Err(NetError{ message: "data too large for stack buffer"; code: -200; });
    }
    while i < dlen {
      raw_buf[i] = data[i];
      i = i + 1;
    }
    let n = xiom_socket_send(self.fd, &raw_buf as *UInt8, dlen);
    if n < 0 {
      return Err(NetError{ message: "write failed"; code: n; });
    }
    return Ok(n);
  }
}

pub fn TcpStream.close(self) -> Result[Unit, NetError] {
  unsafe {
    xiom_socket_close(self.fd);
  }
  Ok(Unit)
}

pub fn TcpListener.accept(self) -> Result[(TcpStream, Str), NetError] {
  unsafe {
    var ip_buf: [64]UInt8;
    var port_val: Int = 0;
    let client = xiom_socket_accept(self.fd, &ip_buf as *UInt8, &port_val);
    if client < 0 {
      return Err(NetError{ message: "accept failed"; code: client; });
    }
    var ip_len: Int = 0;
    while ip_len < 64 && ip_buf[ip_len] != 0 as UInt8 {
      ip_len = ip_len + 1;
    }
    var ip_chars: Vec[UInt8] = Vec[UInt8]::new();
    var j = 0;
    while j < ip_len {
      ip_chars.push(ip_buf[j]);
      j = j + 1;
    }
    let client_ip = Str::from_utf8(ip_chars);
    return Ok((TcpStream{ fd: client; }, client_ip));
  }
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

pub fn udp_bind(host: Str, port: Int) -> Result[UdpSocket, NetError] {
  if port <= 0 || port >= 65536 {
    return Err(NetError{ message: "port out of range (1-65535)"; code: -101; });
  }
  unsafe {
    let fd = xiom_socket_create(AF_INET, SOCK_DGRAM, 0);
    if fd < 0 {
      return Err(NetError{ message: "failed to create UDP socket"; code: fd; });
    }
    if xiom_socket_bind(fd, port) < 0 {
      xiom_socket_close(fd);
      return Err(NetError{ message: "UDP bind failed"; code: -1; });
    }
    return Ok(UdpSocket{ fd: fd; });
  }
}

pub fn UdpSocket.send_to(self, data: &Vec[UInt8], addr: Str, port: Int) -> Result[Int, NetError] {
  unsafe {
    var raw_buf: [65536]UInt8;
    var i = 0;
    let dlen = data.len();
    if dlen > 65536 {
      return Err(NetError{ message: "data too large for stack buffer"; code: -200; });
    }
    while i < dlen {
      raw_buf[i] = data[i];
      i = i + 1;
    }
    var c_host_buf: [256]UInt8;
    var h = 0;
    let alen = addr.len();
    while h < alen && h < 255 {
      c_host_buf[h] = addr.byte_at(h);
      h = h + 1;
    }
    c_host_buf[h] = 0 as UInt8;
    let n = xiom_socket_sendto(self.fd, &raw_buf as *UInt8, dlen, &c_host_buf as *UInt8, port);
    if n < 0 {
      return Err(NetError{ message: "UDP send_to failed"; code: n; });
    }
    return Ok(n);
  }
}

pub fn UdpSocket.recv_from(self, buf: &mut Vec[UInt8]) -> Result[(Int, Str, Int), NetError] {
  unsafe {
    var recv_buf: [4096]UInt8;
    var ip_buf: [64]UInt8;
    var port_val: Int = 0;
    let n = xiom_socket_recvfrom(self.fd, &recv_buf as *UInt8, 4096, &ip_buf as *UInt8, &port_val);
    if n < 0 {
      return Err(NetError{ message: "UDP recv_from failed"; code: n; });
    }
    var i = 0;
    while i < n {
      buf.push(recv_buf[i]);
      i = i + 1;
    }
    var ip_len: Int = 0;
    while ip_len < 64 && ip_buf[ip_len] != 0 as UInt8 {
      ip_len = ip_len + 1;
    }
    var ip_chars: Vec[UInt8] = Vec[UInt8]::new();
    var j = 0;
    while j < ip_len {
      ip_chars.push(ip_buf[j]);
      j = j + 1;
    }
    let sender_ip = Str::from_utf8(ip_chars);
    return Ok((n, sender_ip, port_val));
  }
}

pub fn UdpSocket.close(self) -> Result[Unit, NetError] {
  unsafe {
    xiom_socket_close(self.fd);
  }
  Ok(Unit)
}

// === DNS ===
pub fn resolve_host(hostname: Str) -> Result[Vec[Str], NetError] {
  unsafe {
    var c_host: [256]UInt8;
    var i = 0;
    let hlen = hostname.len();
    while i < hlen && i < 255 {
      c_host[i] = hostname.byte_at(i);
      i = i + 1;
    }
    c_host[i] = 0 as UInt8;
    var ip_buf: [256]UInt8;
    let rc = xiom_dns_resolve(&c_host as *UInt8, &ip_buf as *UInt8, 256);
    if rc < 0 {
      return Err(NetError{ message: "DNS resolution failed"; code: rc; });
    }
    var ip_len: Int = 0;
    while ip_len < 256 && ip_buf[ip_len] != 0 as UInt8 {
      ip_len = ip_len + 1;
    }
    var ip_chars: Vec[UInt8] = Vec[UInt8]::with_capacity(ip_len as UInt);
    var j = 0;
    while j < ip_len {
      ip_chars.push(ip_buf[j]);
      j = j + 1;
    }
    let ip_str = Str::from_utf8(ip_chars);
    var result: Vec[Str] = Vec[Str]::new();
    result.push(ip_str);
    return Ok(result);
  }
}

pub fn local_addr(port: Int) -> Result[Str, NetError] {
  // Get local machine hostname, then resolve it
  unsafe {
    var host_buf: [256]UInt8;
    let hrc = xiom_gethostname(&host_buf as *UInt8, 256);
    if hrc < 0 {
      return Err(NetError{ message: "gethostname failed"; code: hrc; });
    }
    var host_len: Int = 0;
    while host_len < 256 && host_buf[host_len] != 0 as UInt8 {
      host_len = host_len + 1;
    }
    var host_chars: Vec[UInt8] = Vec[UInt8]::with_capacity(host_len as UInt);
    var i = 0;
    while i < host_len {
      host_chars.push(host_buf[i]);
      i = i + 1;
    }
    let hostname = Str::from_utf8(host_chars);
    var c_host: [256]UInt8;
    var h = 0;
    let hn_len = hostname.len();
    while h < hn_len && h < 255 {
      c_host[h] = hostname.byte_at(h);
      h = h + 1;
    }
    c_host[h] = 0 as UInt8;
    var ip_buf: [256]UInt8;
    let rc = xiom_dns_resolve(&c_host as *UInt8, &ip_buf as *UInt8, 256);
    if rc < 0 {
      return Err(NetError{ message: "local_addr DNS resolution failed"; code: rc; });
    }
    var ip_len: Int = 0;
    while ip_len < 256 && ip_buf[ip_len] != 0 as UInt8 {
      ip_len = ip_len + 1;
    }
    var ip_chars: Vec[UInt8] = Vec[UInt8]::with_capacity(ip_len as UInt);
    var j = 0;
    while j < ip_len {
      ip_chars.push(ip_buf[j]);
      j = j + 1;
    }
    let ip_str = Str::from_utf8(ip_chars);
    return Ok(ip_str + ":" + port.to_str());
  }
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

pub fn parse_url(url: Str) -> Result[UrlParts, NetError] {
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
  if path_start.is_some && path_start.value < authority_end {
    authority_end = path_start.value;
  }
  if query_start.is_some && query_start.value < authority_end {
    authority_end = query_start.value;
  }
  if frag_start.is_some && frag_start.value < authority_end {
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
      if after_authority[j] == '?' && query_in_after.is_none {
        query_in_after = Some(j);
      }
      if after_authority[j] == '#' && frag_in_after.is_none {
        frag_in_after = Some(j);
      }
      j = j + 1;
    }
    var path_end: Int = after_auth_len;
    if query_in_after.is_some && query_in_after.value < path_end {
      path_end = query_in_after.value;
    }
    if frag_in_after.is_some && frag_in_after.value < path_end {
      path_end = frag_in_after.value;
    }
    path = str_slice(after_authority, 0, path_end);
    if path.len() == 0 {
      path = "/";
    }
    if query_in_after.is_some {
      var query_end: Int = after_auth_len;
      if frag_in_after.is_some && frag_in_after.value > query_in_after.value {
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
  if len > 0 && s.byte_at(0) == 45 {
    sign = -1;
    start = 1;
  } elif len > 0 && s.byte_at(0) == 43 {
    start = 1;
  }
  var i = start;
  while i < len {
    let b = s.byte_at(i);
    if b < 48 || b > 57 { break; }
    result = result * 10 + (b as Int - 48);
    i = i + 1;
  }
  result * sign
}
