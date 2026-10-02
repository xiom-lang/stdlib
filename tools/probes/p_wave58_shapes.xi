// p_wave58_shapes.xi -- wave 58 shape validation: xiom.net HTTP family
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-58 clauses on xiom.net.{http, header, cookie, mime}
// (55 pub fns). Payloads are read through match where the shape is proven
// (Str/Vec/struct tuples); Option payloads are presence-only where the
// known compiler bugs make binds unsafe; network entry points are probed
// through their empty-URL early error only. Includes the accept_q_value
// fix-first witness (q is capped at 1000 per RFC 7231). Returns 0 when
// every case holds.

module p_wave58_shapes

use xiom.net.http;
use xiom.net.header;
use xiom.net.cookie;
use xiom.net.mime;
use xiom.net.url;
use xiom.net.cookie.Cookie;

fn main() -> Int {
  // ---- http text/status
  if !(http.http_status_text(200) == "OK") { return 1; }
  if !(http.http_status_text(404) == "Not Found") { return 2; }
  if !(http.http_status_text(500) == "Internal Server Error") { return 3; }
  if !(http.http_status_text(418) == "Unknown") { return 4; }
  if !(http.http_request_line("GET", "/") == "GET / HTTP/1.1") { return 5; }
  if !http.http_response_status("HTTP/1.1 200 OK\r\n").is_some { return 6; }
  if http.http_response_status("bad").is_some { return 7; }

  // ---- http response parse (payload through match)
  let raw = "HTTP/1.1 200 OK\r\nA: 1\r\nB:  x \r\n\r\nhi";
  let hs = http.http_parse_response_headers(raw);
  if hs.len() != 2 { return 8; }
  if !(hs[0].0 == "A" && hs[0].1 == "1") { return 9; }
  if http.http_parse_response_headers("").len() != 0 { return 10; }
  match http.http_parse_response(raw) {
    Ok(r) => {
      if r.status != 200 { return 11; }
      if r.headers.len() != 2 { return 12; }
      if r.body.len() != 2 { return 13; }
      if http.http_status_code(&r) != 200 { return 14; }
      if !http.http_header(&r, "a").is_some { return 15; }
      if http.http_header(&r, "z").is_some { return 16; }
      if !(http.http_body_text(&r) == "hi") { return 17; }
      if cookie.cookie_jar_size(cookie.cookie_jar_new()) != 0 { return 18; }
    },
    Err(_) => { return 19; },
  }
  if http.http_parse_response("bad").is_ok { return 20; }

  // ---- http encoding/build
  if !(http.http_url_encode("abcXYZ019-._~") == "abcXYZ019-._~") { return 21; }
  if !(http.http_url_encode("a b") == "a%20b") { return 22; }
  if !(http.http_url_encode("%") == "%25") { return 23; }
  match http.http_url_decode("a%20b") {
    Ok(s) => {
      if !(s == "a b") { return 24; }
    },
    Err(_) => { return 25; },
  }
  match http.http_url_decode("abc") {
    Ok(s) => {
      if !(s == "abc") { return 26; }
    },
    Err(_) => { return 27; },
  }
  if http.http_url_decode("%zz").is_ok { return 28; }
  if http.http_url_decode("abc%2").is_ok { return 29; }
  match http.http_build_request("GET", "http://h/", Vec[(Str, Str)].new(), Vec[UInt8].new()) {
    Ok(req) => {
      if !(req == "GET / HTTP/1.1\r\nHost: h\r\nContent-Length: 0\r\nConnection: close\r\n\r\n") { return 30; }
    },
    Err(_) => { return 31; },
  }
  if http.http_build_request("GET", "", Vec[(Str, Str)].new(), Vec[UInt8].new()).is_ok { return 32; }
  // ---- network entry points: empty-URL early error only
  if http.http_get("").is_ok { return 33; }
  if http.http_post("", Vec[UInt8].new()).is_ok { return 34; }
  if http.http_put("", Vec[UInt8].new()).is_ok { return 35; }
  if http.http_delete("").is_ok { return 36; }
  if http.http_head("").is_ok { return 37; }
  if http.http_patch("", Vec[UInt8].new()).is_ok { return 38; }
  if http.http_get_text("").is_ok { return 39; }
  if http.http_get_bytes("").is_ok { return 40; }
  if http.http_redirect_follow("", -1).is_ok { return 41; }
  if http.http_request("GET", "", Vec[(Str, Str)].new(), Vec[UInt8].new()).is_ok { return 42; }

  // ---- header
  var hdrs = Vec[(Str, Str)].new();
  hdrs.push(("A", "1"));
  if !header.header_get(&hdrs, "a").is_some { return 43; }
  if !header.header_get(&hdrs, "A").is_some { return 44; }
  if header.header_get(&hdrs, "z").is_some { return 45; }
  if !header.header_contains(&hdrs, "a") { return 46; }
  if !(header.header_serialize(&hdrs) == "A: 1\r\n") { return 47; }
  if !(header.header_serialize(Vec[(Str, Str)].new()) == "") { return 48; }
  match header.header_parse_line("A: 1 \r\n") {
    Some(p) => {
      if !(p.0 == "A" && p.1 == "1") { return 49; }
    },
    None => { return 50; },
  }
  if header.header_parse_line("A 1").is_some { return 51; }
  header.header_set(&mut hdrs, "a", "2");
  if hdrs.len() != 1 { return 52; }
  if !header.header_remove(&mut hdrs, "a") { return 53; }
  if hdrs.len() != 0 { return 54; }
  if header.header_remove(&mut hdrs, "x") { return 55; }

  // ---- cookie
  match cookie.cookie_parse("a=b; c=d") {
    Ok(c) => {
      if !(c.name == "a" && c.value == "b") { return 56; }
    },
    Err(_) => { return 57; },
  }
  if cookie.cookie_parse("").is_ok { return 58; }
  if cookie.cookie_parse("a").is_ok { return 59; }
  if cookie.cookie_parse("=b").is_ok { return 60; }
  match cookie.cookie_parse_set_cookie("a=b; Path=/; HttpOnly; Max-Age=3600; SameSite=Strict") {
    Ok(c) => {
      if !(c.path == "/") { return 61; }
      if !c.http_only { return 62; }
      if c.max_age != 3600 { return 63; }
      if !(c.same_site == "Strict") { return 64; }
    },
    Err(_) => { return 65; },
  }
  let ck = Cookie{ name: "a"; value: "b"; domain: ""; path: ""; expires: 0; max_age: 0; secure: false; http_only: false; same_site: ""; };
  if !(cookie.cookie_serialize(ck) == "a=b") { return 66; }
  if cookie.cookie_expires_after(ck, 100) { return 67; }
  if !cookie.cookie_jar_matches(ck, "http://h/x") { return 68; }
  var jar = cookie.cookie_jar_new();
  cookie.cookie_jar_set(&mut jar, ck);
  if !cookie.cookie_jar_get(&jar, "a", "http://h/").is_some { return 70; }
  if cookie.cookie_jar_get(&jar, "z", "http://h/").is_some { return 71; }
  if cookie.cookie_jar_size(jar) != 1 { return 69; }
  if !cookie.cookie_domain_matches("example.com", "sub.example.com") { return 72; }
  if cookie.cookie_domain_matches("", "x") { return 73; }
  if !cookie.cookie_domain_matches("a.com", "a.com") { return 74; }
  if !cookie.cookie_path_matches("/a", "/a/b") { return 75; }
  if cookie.cookie_path_matches("/a", "/ab") { return 76; }
  if !cookie.cookie_path_matches("", "/x") { return 77; }

  // ---- mime
  match mime.mime_parse("text/html; charset=utf-8") {
    Ok(m) => {
      if !(m.kind == "text") { return 78; }
      if !(m.subtype == "html") { return 79; }
      if m.params.len() != 1 { return 80; }
    },
    Err(_) => { return 81; },
  }
  if mime.mime_parse("text").is_ok { return 82; }
  if mime.mime_parse("/x").is_ok { return 83; }
  if !(mime.mime_type_of("x.HTML") == "text/html") { return 84; }
  if !(mime.mime_type_of("a.jpeg") == "image/jpeg") { return 85; }
  if !(mime.mime_type_of("noext") == "application/octet-stream") { return 86; }
  if !(mime.mime_extension_of("TEXT/HTML") == "html") { return 87; }
  if !(mime.mime_extension_of("foo/bar") == "") { return 88; }
  if !mime.mime_matches("text/*", "text/plain") { return 89; }
  if !mime.mime_matches("*/*", "image/png") { return 90; }
  if mime.mime_matches("text/html", "text/plain") { return 91; }
  if !mime.mime_is_text("text/plain") { return 92; }
  if !mime.mime_is_text("application/json") { return 93; }
  if mime.mime_is_text("image/png") { return 94; }
  if !mime.mime_is_image("image/x-icon") { return 95; }
  if !mime.mime_is_audio("audio/mpeg") { return 96; }
  if !mime.mime_is_video("video/mp4") { return 97; }
  if !mime.mime_is_application("application/pdf") { return 98; }
  if !(mime.charset_detect(Vec[UInt8].new()) == "ascii") { return 99; }
  match mime.charset_normalize("a", "UTF-8") {
    Ok(s) => {
      if !(s == "a") { return 100; }
    },
    Err(_) => { return 101; },
  }
  if mime.charset_normalize("a", "shift-jis").is_ok { return 102; }
  if mime.charset_normalize("a", "").is_ok { return 103; }
  if !(mime.etag_new(Vec[UInt8].new()) == "\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"") { return 104; }
  if !mime.etag_matches("\"x\"", "\"x\"") { return 105; }
  if !mime.etag_matches("x", "*") { return 106; }
  if mime.etag_matches("\"x\"", "\"y\"") { return 107; }
  let ap = mime.accept_parse("text/html, application/json;q=0.9");
  if ap.len() != 2 { return 108; }
  if !(ap[0].0 == "text/html" && ap[0].1 == 1000) { return 109; }
  if mime.accept_parse("").len() != 0 { return 110; }
  if mime.accept_q_value("text/html;q=0.8, */*;q=0.1", "text/plain") != 100 { return 111; }
  if mime.accept_q_value("text/html", "image/png") != 0 { return 112; }
  // fix-first: RFC 7231 caps q at 1.0 (scaled 1000); 1.999 must not win
  if mime.accept_q_value("text/html;q=1.999", "text/html") != 1000 { return 113; }
  match mime.accept_negotiate("text/html", Vec[Str].new()) {
    Some(_) => { return 114; },
    None => {},
  }
  let lp = mime.link_parse("<https://a.com>; rel=\"next\"; title=\"Next\"");
  if lp.len() != 1 { return 115; }
  if !(lp[0].href == "https://a.com") { return 116; }
  if !(lp[0].rel == "next") { return 117; }
  if mime.link_find(&lp, "prev").is_some { return 118; }
  if !mime.link_find(&lp, "next").is_some { return 119; }

  return 0;
}
