// XIOM stdlib smoke test — xiom.net.cookie + xiom.net.mime +
// xiom.net.multipart + xiom.net.sse
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net_http2

use xiom.net.cookie;
use xiom.net.mime;
use xiom.net.multipart;
use xiom.net.sse;
use xiom.io;

fn main() -> Int {
  // --- cookie: parse request header ---
  let c1 = cookie.cookie_parse("a=b; c=d");
  match c1 {
    Err(e) => {
      io.println("cookie-parse");
      return 1;
    }
    Ok(co) => {
      if co.name != "a" {
        io.println("cookie-name");
        return 2;
      }
      if co.value != "b" {
        io.println("cookie-value");
        return 3;
      }
    }
  }
  if cookie.cookie_parse("badsegment").is_ok {
    io.println("cookie-invalid");
    return 4;
  }

  // --- cookie: Set-Cookie attributes ---
  let sc = cookie.cookie_parse_set_cookie("sid=xyz; Path=/; HttpOnly; Max-Age=3600; SameSite=Strict; Secure");
  match sc {
    Err(e) => {
      io.println("setcookie");
      return 5;
    }
    Ok(co) => {
      if co.name != "sid" {
        io.println("setcookie-name");
        return 6;
      }
      if co.path != "/" {
        io.println("setcookie-path");
        return 7;
      }
      if co.http_only != true {
        io.println("setcookie-httponly");
        return 8;
      }
      if co.max_age != 3600 {
        io.println("setcookie-maxage");
        return 9;
      }
      if co.same_site != "Strict" {
        io.println("setcookie-samesite");
        return 10;
      }
      if co.secure != true {
        io.println("setcookie-secure");
        return 11;
      }
    }
  }
  {
    let sc2 = cookie.cookie_parse("k=v");
    match sc2 {
      Err(e) => {
        io.println("cookie-serialize");
        return 12;
      }
      Ok(co) => {
        if cookie.cookie_serialize(co) != "k=v" {
          io.println("cookie-serialize");
          return 12;
        }
      }
    }
  }

  // --- cookie: domain / path matching ---
  if !cookie.cookie_domain_matches("example.com", "www.example.com") {
    io.println("cookie-domain");
    return 13;
  }
  if cookie.cookie_domain_matches("example.com", "example.org") {
    io.println("cookie-domain2");
    return 14;
  }
  if !cookie.cookie_path_matches("/a", "/a/b") {
    io.println("cookie-path");
    return 15;
  }
  if cookie.cookie_path_matches("/a", "/ab") {
    io.println("cookie-path2");
    return 16;
  }

  // --- cookie: jar ---
  var jar = cookie.cookie_jar_new();
  let jc = cookie.cookie_parse_set_cookie("session=abc; Domain=example.com; Path=/");
  match jc {
    Err(e) => {
      io.println("jar-cookie");
      return 17;
    }
    Ok(co) => {
      cookie.cookie_jar_set(&mut jar, co);
    }
  }
  if cookie.cookie_jar_size(&jar) != 1 {
    io.println("jar-size");
    return 18;
  }
  {
    let found = cookie.cookie_jar_get(&jar, "session", "https://www.example.com/page");
    match found {
      None => {
        io.println("jar-get");
        return 19;
      }
      Some(co) => {
        if co.value != "abc" {
          io.println("jar-get-value");
          return 20;
        }
      }
    }
  }

  // --- mime: type from extension ---
  if mime.mime_type_of("index.html") != "text/html" {
    io.println("mime-html");
    return 21;
  }
  if mime.mime_type_of("photo.png") != "image/png" {
    io.println("mime-png");
    return 22;
  }
  if mime.mime_type_of("data.json") != "application/json" {
    io.println("mime-json");
    return 23;
  }
  if mime.mime_type_of("doc.pdf") != "application/pdf" {
    io.println("mime-pdf");
    return 24;
  }
  if mime.mime_type_of("unknown.xyz") != "application/octet-stream" {
    io.println("mime-default");
    return 25;
  }
  if mime.mime_extension_of("application/json") != "json" {
    io.println("mime-ext");
    return 26;
  }

  // --- mime: matching + classification ---
  if !mime.mime_matches("text/*", "text/plain") {
    io.println("mime-match");
    return 27;
  }
  if mime.mime_matches("text/*", "image/png") {
    io.println("mime-match2");
    return 28;
  }
  if !mime.mime_matches("*/*", "application/pdf") {
    io.println("mime-match3");
    return 29;
  }
  if !mime.mime_is_text("text/plain") {
    io.println("mime-istext");
    return 30;
  }
  if !mime.mime_is_image("image/png") {
    io.println("mime-isimg");
    return 31;
  }
  if !mime.mime_is_audio("audio/mpeg") {
    io.println("mime-isaudio");
    return 32;
  }
  if !mime.mime_is_video("video/mp4") {
    io.println("mime-isvideo");
    return 33;
  }
  if !mime.mime_is_application("application/json") {
    io.println("mime-isapp");
    return 34;
  }

  // --- mime: parse ---
  let mp = mime.mime_parse("text/html; charset=utf-8");
  match mp {
    Err(e) => {
      io.println("mime-parse");
      return 35;
    }
    Ok(m) => {
      if m.type != "text" {
        io.println("mime-parse-type");
        return 36;
      }
      if m.subtype != "html" {
        io.println("mime-parse-subtype");
        return 37;
      }
    }
  }
  if mime.mime_parse("notamime").is_ok {
    io.println("mime-parse-invalid");
    return 38;
  }

  // --- mime: etag ---
  let etag = mime.etag_new(&mkvec("hello"));
  if etag.len() < 4 {
    io.println("etag-len");
    return 39;
  }
  if etag.byte_at(0) != 34 {
    io.println("etag-quote");
    return 40;
  }
  if !mime.etag_matches(etag, "other, " + etag) {
    io.println("etag-match");
    return 41;
  }
  if mime.etag_matches(etag, "other") {
    io.println("etag-match2");
    return 42;
  }
  if !mime.etag_matches(etag, "*") {
    io.println("etag-star");
    return 43;
  }

  // --- mime: accept negotiation ---
  let entries = mime.accept_parse("text/html, application/json;q=0.9, */*;q=0.5");
  if entries.len() != 3 {
    io.println("accept-len");
    return 44;
  }
  if mime.accept_q_value("text/html, application/json;q=0.9", "application/json") != 900 {
    io.println("accept-q");
    return 45;
  }
  if mime.accept_q_value("text/html, application/json;q=0.9", "text/html") != 1000 {
    io.println("accept-q2");
    return 46;
  }
  if mime.accept_q_value("text/html", "image/png") != 0 {
    io.println("accept-q3");
    return 47;
  }

  // --- mime: links ---
  let links = mime.link_parse("<https://a.com/next>; rel=\"next\"; title=\"Next\"");
  if links.len() != 1 {
    io.println("link-len");
    return 48;
  }
  {
    let href = mime.link_find(&links, "next");
    match href {
      None => {
        io.println("link-find");
        return 49;
      }
      Some(h) => {
        if h != "https://a.com/next" {
          io.println("link-href");
          return 50;
        }
      }
    }
  }

  // --- multipart: boundary + content type ---
  let boundary = multipart.multipart_boundary_new();
  if boundary.len() == 0 {
    io.println("mp-boundary");
    return 51;
  }
  let ct = multipart.multipart_content_type(boundary);
  if ct.len() < 20 {
    io.println("mp-ct");
    return 52;
  }

  // --- multipart: build empty parts and parse ---
  var empty_parts: Vec[UInt8] = Vec[UInt8].new();
  var body = multipart.multipart_build(&empty_parts, "bnd");
  if body.len() != 9 {
    io.println("mp-empty-len");
    return 53;
  }

  // --- multipart: parse a handcrafted body ---
  var handcrafted = Vec[UInt8].new();
  push_bytes(&mut handcrafted, "--bnd\r\n");
  push_bytes(&mut handcrafted, "Content-Disposition: form-data; name=\"field\"\r\n");
  push_bytes(&mut handcrafted, "\r\n");
  push_bytes(&mut handcrafted, "value1\r\n");
  push_bytes(&mut handcrafted, "--bnd--\r\n");
  let parsed = multipart.multipart_parse(&handcrafted, "bnd");
  match parsed {
    Err(e) => {
      io.println("mp-parse");
      return 54;
    }
    Ok(ps) => {
      if ps.len() != 1 {
        io.println("mp-parse-len");
        return 55;
      }
    }
  }

  // --- sse: parse events ---
  let ev = sse.sse_parse_event("id: 1\ndata: hello\n\n");
  match ev {
    Err(e) => {
      io.println("sse-parse");
      return 56;
    }
    Ok(e) => {
      if e.data != "hello" {
        io.println("sse-data");
        return 57;
      }
      if e.event != "message" {
        io.println("sse-event");
        return 58;
      }
    }
  }
  let ev2 = sse.sse_parse_event("event: close\ndata: bye\n\n");
  match ev2 {
    Err(e) => {
      io.println("sse-parse2");
      return 59;
    }
    Ok(e) => {
      if e.event != "close" {
        io.println("sse-event2");
        return 60;
      }
    }
  }
  let ev3 = sse.sse_parse_event("id: 42\ndata: a\ndata: b\n\n");
  match ev3 {
    Err(e) => {
      io.println("sse-parse3");
      return 61;
    }
    Ok(e) => {
      if e.data != "a\nb" {
        io.println("sse-multiline");
        return 62;
      }
      {
        let id = sse.sse_event_id(e);
        match id {
          None => {
            io.println("sse-id");
            return 63;
          }
          Some(v) => {
            if v != "42" {
              io.println("sse-id-value");
              return 64;
            }
          }
        }
      }
    }
  }
  {
    let ev4 = sse.sse_parse_event("data: x\n\n");
    match ev4 {
      Err(e) => {
        io.println("sse-parse4");
        return 65;
      }
      Ok(e) => {
        if sse.sse_event_id(e).is_some {
          io.println("sse-noid");
          return 66;
        }
      }
    }
  }

  io.println("OK");
  return 0;
}

fn mkvec(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i = i + 1;
  }
  v
}

fn push_bytes(dst: &mut Vec[UInt8], s: Str) {
  var i = 0;
  while i < s.len() {
    dst.push(s.byte_at(i));
    i = i + 1;
}
