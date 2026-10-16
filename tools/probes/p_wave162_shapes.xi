// p_wave162_shapes.xi -- wave 162 lock: SSE connection layer (REL-20261015-2202-pulse
// item 7): sse_connect / sse_connect_headers / sse_read_event / sse_close /
// sse_read_events against loopback fixtures served by real spawn threads.
// Rows (0 = all hold):
//  1 -- sse_connect over a loopback fixture: Ok + open flag true
//  2 -- event 1: id "1", event "message", data "hello"
//  3 -- event 2: multi-line data joins as "second\nline"
//  4 -- comment-only chunk is consumed and yields empty data (raw-chunk rule)
//  5 -- CRLF block: event "ping", data "tick", retry 1500
//  6 -- EOF after the events -> read Err; sse_close idempotent (open false)
//  7 -- a 404 response is refused with Err
//  8 -- a 200 with Content-Type: text/html is refused with Err
//  9 -- https:// is refused without touching the network
// 10 -- empty url and unparsable url are refused
// 11 -- custom headers connect and stream (header injection refused)
// 12 -- sse_read_events drains both buffered events (count 2, order stable)
// Setup failures use 20+.

module p_wave162_shapes

use xiom.net;
use xiom.net.socket;
use xiom.net.sse;
use xiom.string;
use xiom.thread;
use xiom.thread.spawn;

// --- fixtures (one accept each; fixed loopback ports) -----------------------

fn _serve_ok() -> Int {
  let l = net.tcp_listen("127.0.0.1", 46731);
  match l {
    Ok(listener) => {
      let ar = listener.accept();
      match ar {
        Ok(pair) => {
          let st = pair.0;
          var rb: Vec[UInt8] = Vec[UInt8].new();
          let _ = st.read(&mut rb);
          let resp = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream; charset=utf-8\r\nCache-Control: no-cache\r\n\r\nid: 1\nevent: message\ndata: hello\n\ndata: second\ndata: line\n\n: keep-alive\n\nevent: ping\r\ndata: tick\r\nretry: 1500\r\n\r\n";
          var b: Vec[UInt8] = Vec[UInt8].new();
          var i = 0;
          while i < resp.len() {
            b.push(resp.byte_at(i));
            i = i + 1;
          };
          let _ = st.write_all(&b);
          thread.sleep_ms(600);
          let _ = st.close();
          socket.socket_close(listener.fd);
          0
        },
        Err(_) => { socket.socket_close(listener.fd); 1 },
      }
    },
    Err(_) => { 2 },
  }
}

fn _serve_404() -> Int {
  let l = net.tcp_listen("127.0.0.1", 46732);
  match l {
    Ok(listener) => {
      let ar = listener.accept();
      match ar {
        Ok(pair) => {
          let st = pair.0;
          var rb: Vec[UInt8] = Vec[UInt8].new();
          let _ = st.read(&mut rb);
          let resp = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: 4\r\n\r\nnope";
          var b: Vec[UInt8] = Vec[UInt8].new();
          var i = 0;
          while i < resp.len() {
            b.push(resp.byte_at(i));
            i = i + 1;
          };
          let _ = st.write_all(&b);
          thread.sleep_ms(100);
          let _ = st.close();
          socket.socket_close(listener.fd);
          0
        },
        Err(_) => { socket.socket_close(listener.fd); 1 },
      }
    },
    Err(_) => { 2 },
  }
}

fn _serve_wrong_ct() -> Int {
  let l = net.tcp_listen("127.0.0.1", 46733);
  match l {
    Ok(listener) => {
      let ar = listener.accept();
      match ar {
        Ok(pair) => {
          let st = pair.0;
          var rb: Vec[UInt8] = Vec[UInt8].new();
          let _ = st.read(&mut rb);
          let resp = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<html></html>";
          var b: Vec[UInt8] = Vec[UInt8].new();
          var i = 0;
          while i < resp.len() {
            b.push(resp.byte_at(i));
            i = i + 1;
          };
          let _ = st.write_all(&b);
          thread.sleep_ms(100);
          let _ = st.close();
          socket.socket_close(listener.fd);
          0
        },
        Err(_) => { socket.socket_close(listener.fd); 1 },
      }
    },
    Err(_) => { 2 },
  }
}

fn _serve_drain() -> Int {
  let l = net.tcp_listen("127.0.0.1", 46734);
  match l {
    Ok(listener) => {
      let ar = listener.accept();
      match ar {
        Ok(pair) => {
          let st = pair.0;
          var rb: Vec[UInt8] = Vec[UInt8].new();
          let _ = st.read(&mut rb);
          let resp = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\n\r\ndata: a\n\ndata: b\n\n";
          var b: Vec[UInt8] = Vec[UInt8].new();
          var i = 0;
          while i < resp.len() {
            b.push(resp.byte_at(i));
            i = i + 1;
          };
          let _ = st.write_all(&b);
          thread.sleep_ms(400);
          let _ = st.close();
          socket.socket_close(listener.fd);
          0
        },
        Err(_) => { socket.socket_close(listener.fd); 1 },
      }
    },
    Err(_) => { 2 },
  }
}

fn _serve_headers() -> Int {
  let l = net.tcp_listen("127.0.0.1", 46735);
  match l {
    Ok(listener) => {
      let ar = listener.accept();
      match ar {
        Ok(pair) => {
          let st = pair.0;
          var rb: Vec[UInt8] = Vec[UInt8].new();
          let _ = st.read(&mut rb);
          let resp = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\n\r\ndata: hdr\n\n";
          var b: Vec[UInt8] = Vec[UInt8].new();
          var i = 0;
          while i < resp.len() {
            b.push(resp.byte_at(i));
            i = i + 1;
          };
          let _ = st.write_all(&b);
          thread.sleep_ms(300);
          let _ = st.close();
          socket.socket_close(listener.fd);
          0
        },
        Err(_) => { socket.socket_close(listener.fd); 1 },
      }
    },
    Err(_) => { 2 },
  }
}

// --- client helpers ----------------------------------------------------------

// Retry only on a refused connect (server not listening yet); every other
// error (a real protocol refusal) returns immediately.
fn _connect_retry(url: Str, tries: Int) -> Result[SseConnection, Str] {
  var i = 0;
  var last = "no attempt";
  while i < tries {
    match sse.sse_connect(url) {
      Ok(c) => { return Ok(c); },
      Err(e) => {
        last = e;
        if !string.str_contains(e, "connection failed") {
          return Err(e);
        };
      },
    };
    thread.sleep_ms(50);
    i = i + 1;
  };
  Err(last)
}

fn main() -> Int {
  // --- rows 1-6: the OK fixture --------------------------------------------
  let t1 = spawn.spawn(_serve_ok);
  let c1 = _connect_retry("http://127.0.0.1:46731/stream", 60);
  if c1.is_err { return 20; }
  var conn = c1.value;
  if !conn.open { return 1; }

  // Row 2: event 1.
  match sse.sse_read_event(&mut conn) {
    Ok(e) => {
      if e.id != "1" { return 2; }
      if e.event != "message" { return 2; }
      if e.data != "hello" { return 2; }
    },
    Err(_) => { return 2; },
  };

  // Row 3: multi-line data.
  match sse.sse_read_event(&mut conn) {
    Ok(e) => {
      if e.data != "second\nline" { return 3; }
    },
    Err(_) => { return 3; },
  };

  // Row 4: comment-only chunk.
  match sse.sse_read_event(&mut conn) {
    Ok(e) => {
      if e.data != "" { return 4; }
    },
    Err(_) => { return 4; },
  };

  // Row 5: CRLF block with retry.
  match sse.sse_read_event(&mut conn) {
    Ok(e) => {
      if e.event != "ping" { return 5; }
      if e.data != "tick" { return 5; }
      if e.retry != 1500 { return 5; }
    },
    Err(_) => { return 5; },
  };

  // Row 6: EOF then idempotent close.
  match sse.sse_read_event(&mut conn) {
    Ok(_) => { return 6; },
    Err(_) => {},
  };
  sse.sse_close(&mut conn);
  if conn.open { return 6; }
  sse.sse_close(&mut conn);
  if conn.open { return 6; }
  let _ = spawn.join(t1);

  // Row 7: 404 refusal.
  let t7 = spawn.spawn(_serve_404);
  let c7 = _connect_retry("http://127.0.0.1:46732/x", 40);
  if c7.is_ok { return 7; }
  let _ = spawn.join(t7);

  // Row 8: wrong content type refusal.
  let t8 = spawn.spawn(_serve_wrong_ct);
  let c8 = _connect_retry("http://127.0.0.1:46733/x", 40);
  if c8.is_ok { return 8; }
  let _ = spawn.join(t8);

  // Row 9: https refused before any network use.
  let c9 = sse.sse_connect("https://127.0.0.1:46731/stream");
  if c9.is_ok { return 9; }

  // Row 10: empty / unparsable urls.
  let c10a = sse.sse_connect("");
  if c10a.is_ok { return 10; }
  let c10b = sse.sse_connect("not a url");
  if c10b.is_ok { return 10; }

  // Row 11: custom headers connect + stream.
  let t11 = spawn.spawn(_serve_headers);
  var hs: Vec[(Str, Str)] = Vec[(Str, Str)].new();
  hs.push(("X-Test", "1"));
  var c11r = sse.sse_connect_headers("http://127.0.0.1:46735/s", &hs);
  var tries11 = 0;
  while c11r.is_err && tries11 < 60 {
    thread.sleep_ms(50);
    c11r = sse.sse_connect_headers("http://127.0.0.1:46735/s", &hs);
    tries11 = tries11 + 1;
  };
  if c11r.is_err { return 20; }
  var conn11 = c11r.value;
  match sse.sse_read_event(&mut conn11) {
    Ok(e) => {
      if e.data != "hdr" { return 11; }
    },
    Err(_) => { return 11; },
  };
  sse.sse_close(&mut conn11);
  let _ = spawn.join(t11);
  // Header injection is refused before any network use.
  var bad: Vec[(Str, Str)] = Vec[(Str, Str)].new();
  bad.push(("X-Bad", "a\r\nX-Inject: b"));
  let c11bad = sse.sse_connect_headers("http://127.0.0.1:46735/s", &bad);
  if c11bad.is_ok { return 11; }

  // Row 12: drain both events.
  let t12 = spawn.spawn(_serve_drain);
  let c12 = _connect_retry("http://127.0.0.1:46734/d", 60);
  if c12.is_err { return 20; }
  var conn12 = c12.value;
  var evs: Vec[SseEvent] = Vec[SseEvent].new();
  var total = 0;
  var tries12 = 0;
  while total < 2 && tries12 < 100 {
    total = total + sse.sse_read_events(&mut conn12, &mut evs);
    if total < 2 {
      thread.sleep_ms(50);
    };
    tries12 = tries12 + 1;
  };
  if total != 2 { return 12; }
  if evs.len() != 2 { return 12; }
  let e0 = evs[0];
  let e1 = evs[1];
  if e0.data != "a" { return 12; }
  if e1.data != "b" { return 12; }
  sse.sse_close(&mut conn12);
  let _ = spawn.join(t12);

  return 0;
}
