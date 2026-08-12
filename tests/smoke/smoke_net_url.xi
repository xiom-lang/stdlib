// XIOM stdlib smoke test — xiom.net.url + xiom.net.ws + xiom.net.websocket
// URL parsing, ws URL parsing/building, websocket handshake and framing.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net_url

use xiom.net.url;
use xiom.net.ws;
use xiom.net.websocket;
use xiom.io;

fn main() -> Int {
  // --- url_parse ---
  let up = url.url_parse("https://example.com/path?q=1");
  match up {
    Ok(p) => {
      if p.scheme != "https" {
        io.println("url-scheme");
        return 1;
      }
      if p.host != "example.com" {
        io.println("url-host");
        return 2;
      }
      if p.path != "/path" {
        io.println("url-path");
        return 3;
      }
      if p.query != "q=1" {
        io.println("url-query");
        return 4;
      }
    }
    Err(_) => {
      io.println("url-parse");
      return 5;
    }
  }

  // --- url encode/decode ---
  let enc = url.url_encode_component("a b&c=d");
  match enc {
    Ok(s) => {
      if s != "a%20b%26c%3Dd" {
        io.println("url-enc");
        return 6;
      }
    }
    Err(_) => {
      io.println("url-enc");
      return 6;
    }
  }
  let dec = url.url_decode_component("a%20b%26c%3Dd");
  match dec {
    Ok(s) => {
      if s != "a b&c=d" {
        io.println("url-dec");
        return 7;
      }
    }
    Err(_) => {
      io.println("url-dec");
      return 7;
    }
  }

  // --- ws_parse_url ---
  let wp = ws.ws_parse_url("wss://echo.example.com:8443/chat");
  match wp {
    Ok(t) => {
      var host = t.0;
      var port = t.1;
      var path = t.2;
      if host != "echo.example.com" {
        io.println("ws-host");
        return 8;
      }
      if port != 8443 {
        io.println("ws-port");
        return 9;
      }
      if path != "/chat" {
        io.println("ws-path");
        return 10;
      }
    }
    Err(_) => {
      io.println("ws-parse");
      return 11;
    }
  }
  let wp2 = ws.ws_parse_url("ws://default.example.com/socket");
  match wp2 {
    Ok(t) => {
      if t.1 != 80 {
        io.println("ws-defport");
        return 12;
      }
    }
    Err(_) => {
      io.println("ws-parse2");
        return 13;
    }
  }
  if ws.ws_is_ws_url("ws://x/") != true {
    io.println("ws-is-ws");
    return 14;
  }
  if ws.ws_is_wss_url("wss://x/") != true {
    io.println("ws-is-wss");
    return 15;
  }

  // --- websocket accept key (RFC 6455 test vector) ---
  let acc = websocket.ws_accept_key("dGhlIHNhbXBsZSBub25jZQ==");
  if acc != "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" {
    io.println("ws-accept");
    return 16;
  }

  // --- websocket handshake request ---
  let req = websocket.ws_handshake_request("example.com", "/chat", "dGhlIHNhbXBsZSBub25jZQ==");
  if req.starts_with("GET /chat HTTP/1.1") != true {
    io.println("ws-req-line");
    return 17;
  }
  if req.starts_with("Sec-WebSocket-Version") == true {
    io.println("ws-req-version");
    return 17;
  }

  // --- websocket frame encode/decode round-trip ---
  var payload: Vec[UInt8] = Vec[UInt8]::new();
  payload.push(72);
  payload.push(105);
  payload.push(33);
  let frame = websocket.ws_frame_encode(1, &payload, false);
  let decoded = websocket.ws_frame_decode(&frame);
  match decoded {
    Ok(f) => {
      if f.opcode != 1 {
        io.println("ws-frame-op");
        return 18;
      }
      if f.fin != true {
        io.println("ws-frame-fin");
        return 18;
      }
      if f.payload.len() != 3 {
        io.println("ws-frame-len");
        return 18;
      }
      if f.payload[0] != 72 || f.payload[2] != 33 {
        io.println("ws-frame-data");
        return 18;
      }
    }
    Err(_) => {
      io.println("ws-frame-decode");
      return 19;
    }
  }

  // --- ws_parse_url (websocket module) ---
  let wp3 = websocket.ws_parse_url("ws://h.example.com:9000/path");
  match wp3 {
    Ok(t) => {
      if t.0 != "h.example.com" || t.1 != 9000 || t.2 != "/path" {
        io.println("ws-parse3");
        return 20;
      }
    }
    Err(_) => {
      io.println("ws-parse3");
      return 20;
    }
  }

  io.println("OK");
  return 0;
}
