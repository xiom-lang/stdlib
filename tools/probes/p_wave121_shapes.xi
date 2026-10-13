// p_wave121_shapes.xi -- wave 121 lock: websocket I/O fix + server-side
// helpers + chunked-transfer stream helpers (REL-20261012-1946-pulse
// stdlib-side rows).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure locks: RFC 6455 accept vector, handshake response builder, request-key
// extraction (case-insensitive), header split at CRLFCRLF (leftover
// preserved byte-exact), frame take with consumed count (masked, 16-bit
// extended length, concatenated frames, every truncated prefix), close-code
// parse, chunked encode ("<hex>\r\n" + data + "\r\n", empty -> "", end =
// "0\r\n\r\n").
//
// Wire locks on a loopback TCP pair (127.0.0.1:39531, single thread, the
// wave-119 sequencing pattern): handshake request/response roundtrip with
// ws_handshake_verify; unmasked server frame and masked client frame both
// decoded; chunked stream bytes ("200 OK" head + 2 chunks + end) delivered
// byte-exact via socket_stream_chunk/socket_stream_end; Err rows (bad fd,
// missing terminator, missing key). Every returned value is bound before
// comparing. Returns 0 when all cases hold. Red pre-fix (the helpers do not
// exist and the old client I/O is broken), green post.

module p_wave121_shapes

use xiom.net.socket;
use xiom.net.websocket;
use xiom.io;

fn main() -> Int {
  // --- RFC 6455 accept vector through the response builder ---
  let key = "dGhlIHNhbXBsZSBub25jZQ==";
  let acc = websocket.ws_accept_key(key);
  if acc != "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" {
    return 1;
  }
  let resp = websocket.ws_handshake_response(key);
  if !resp.starts_with("HTTP/1.1 101 Switching Protocols\r\n") {
    return 2;
  }
  if !websocket.ws_handshake_verify(resp, key) {
    return 3;
  }
  if resp.len() != 129 {
    return 4;
  }

  // --- request-key extraction (case + spacing variants) ---
  let req1 = "GET /chat HTTP/1.1\r\nHost: x\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n";
  let k1 = websocket.ws_request_key(req1);
  match k1 {
    Ok(v) => {
      if v != key {
        return 5;
      }
    },
    Err(_) => {
      return 5;
    },
  };
  let req2 = "GET / HTTP/1.1\r\nsec-websocket-key:   abc123\r\n\r\n";
  let k2 = websocket.ws_request_key(req2);
  match k2 {
    Ok(v) => {
      if v != "abc123" {
        return 6;
      }
    },
    Err(_) => {
      return 6;
    },
  };
  let k3 = websocket.ws_request_key("GET / HTTP/1.1\r\nHost: x\r\n\r\n");
  match k3 {
    Ok(_) => {
      return 7;
    },
    Err(_) => {},
  };

  // --- header split ---
  var raw1 = to_bytes("HTTP/1.1 101 OK\r\nA: b\r\n\r\nREST");
  let s1 = websocket.ws_split_headers(&raw1);
  match s1 {
    Ok(t) => {
      let head = t.0;
      let rest = t.1;
      if head != "HTTP/1.1 101 OK\r\nA: b" {
        return 8;
      }
      if rest.len() != 4 {
        return 9;
      }
      let r0 = rest[0];
      if r0 != 82 {
        return 9;
      }
    },
    Err(_) => {
      return 8;
    },
  };
  var raw2 = to_bytes("HTTP/1.1 101 OK\r\nA: b\r\n");
  let s2 = websocket.ws_split_headers(&raw2);
  match s2 {
    Ok(_) => {
      return 10;
    },
    Err(_) => {},
  };

  // --- frame take: masked roundtrip ---
  var p3 = to_bytes("hi!");
  let f_masked = websocket.ws_frame_encode(1, &p3, true);
  let t1 = websocket.ws_frame_take(&f_masked);
  match t1 {
    Ok(t) => {
      let fr = t.0;
      let used = t.1;
      if used != f_masked.len() {
        return 11;
      }
      if fr.opcode != 1 {
        return 12;
      }
      if fr.masked != true {
        return 12;
      }
      if fr.payload.len() != 3 {
        return 12;
      }
      let b0 = fr.payload[0];
      if b0 != 104 {
        return 12;
      }
    },
    Err(_) => {
      return 11;
    },
  };

  // --- frame take: every truncated prefix must be incomplete ---
  var cut = 0;
  while cut < f_masked.len() {
    var prefix = Vec[UInt8].new();
    var ci = 0;
    while ci < cut {
      prefix.push(f_masked[ci]);
      ci = ci + 1;
    }
    let tr = websocket.ws_frame_take(&prefix);
    match tr {
      Ok(_) => {
        return 13;
      },
      Err(_) => {},
    };
    cut = cut + 1;
  }

  // --- frame take: two concatenated frames consume exactly the first ---
  var p3b = to_bytes("zip");
  let f_a = websocket.ws_frame_encode(1, &p3b, false);
  let f_b = websocket.ws_frame_encode(2, &p3b, true);
  var both = Vec[UInt8].new();
  var bi = 0;
  while bi < f_a.len() {
    both.push(f_a[bi]);
    bi = bi + 1;
  }
  var bj = 0;
  while bj < f_b.len() {
    both.push(f_b[bj]);
    bj = bj + 1;
  }
  let t2 = websocket.ws_frame_take(&both);
  match t2 {
    Ok(t) => {
      let used2 = t.1;
      if used2 != f_a.len() {
        return 14;
      }
      let fr2 = t.0;
      if fr2.payload.len() != 3 {
        return 14;
      }
    },
    Err(_) => {
      return 14;
    },
  };

  // --- frame take: 16-bit extended length + fin flag ---
  var big = Vec[UInt8].new();
  var bli = 0;
  while bli < 300 {
    big.push((bli % 256) as UInt8);
    bli = bli + 1;
  }
  let f_big = websocket.ws_frame_encode_fin(2, true, &big, false);
  if f_big.len() != 304 {
    return 15;
  }
  let t3 = websocket.ws_frame_take(&f_big);
  match t3 {
    Ok(t) => {
      let used3 = t.1;
      if used3 != 304 {
        return 15;
      }
      let fr3 = t.0;
      if fr3.payload.len() != 300 {
        return 15;
      }
      if fr3.fin != true {
        return 15;
      }
      let b299 = fr3.payload[299];
      if b299 != 43 {
        return 15;
      }
    },
    Err(_) => {
      return 15;
    },
  };

  // --- close codes ---
  var cbytes = Vec[UInt8].new();
  cbytes.push(3);
  cbytes.push(232); // 1000
  let f_close = websocket.ws_frame_encode(8, &cbytes, false);
  let tc = websocket.ws_frame_decode(&f_close);
  match tc {
    Ok(fr) => {
      let cc = websocket.ws_close_code(&fr);
      match cc {
        Some(code) => {
          if code != 1000 {
            return 16;
          }
        },
        None => {
          return 16;
        },
      };
    },
    Err(_) => {
      return 16;
    },
  };
  let tplain = websocket.ws_frame_decode(&f_a);
  match tplain {
    Ok(fr) => {
      let cc2 = websocket.ws_close_code(&fr);
      match cc2 {
        Some(_) => {
          return 17;
        },
        None => {},
      };
    },
    Err(_) => {
      return 17;
    },
  };

  // --- chunked encode (pure) ---
  var hello = to_bytes("hello");
  let c1 = socket.socket_chunk_encode(&hello);
  if c1 != "5\r\nhello\r\n" {
    return 18;
  }
  var empty: Vec[UInt8] = Vec[UInt8].new();
  let c2 = socket.socket_chunk_encode(&empty);
  if c2.len() != 0 {
    return 19;
  }
  var bigc = Vec[UInt8].new();
  var bg = 0;
  while bg < 4096 {
    bigc.push(65);
    bg = bg + 1;
  }
  let c3 = socket.socket_chunk_encode(&bigc);
  if c3.len() != 4104 {
    return 20;
  }
  if !c3.starts_with("1000\r\n") {
    return 20;
  }
  let cend = socket.socket_chunked_end();
  if cend != "0\r\n\r\n" {
    return 21;
  }

  // --- invalid-fd rows (early Err, no syscall) ---
  let sa = socket.socket_send_all(-1, &hello);
  match sa {
    Ok(_) => {
      return 22;
    },
    Err(_) => {},
  };
  let sc = socket.socket_stream_chunk(-1, &hello);
  match sc {
    Ok(_) => {
      return 22;
    },
    Err(_) => {},
  };
  let se = socket.socket_stream_end(-1);
  match se {
    Ok(_) => {
      return 22;
    },
    Err(_) => {},
  };

  // --- wire: loopback handshake + frames + chunked bytes ---
  let srv = socket.socket_tcp();
  let sfd0: Int;
  match srv {
    Ok(f) => { sfd0 = f; },
    Err(_) => { return 23; },
  };
  let bd = socket.socket_bind(sfd0, "127.0.0.1", 39531);
  match bd {
    Ok(_) => {},
    Err(_) => { return 23; },
  };
  let ls = socket.socket_listen(sfd0, 4);
  match ls {
    Ok(_) => {},
    Err(_) => { return 23; },
  };
  let cli = socket.socket_tcp();
  let cfd0: Int;
  match cli {
    Ok(f) => { cfd0 = f; },
    Err(_) => { return 23; },
  };
  let cn = socket.socket_connect(cfd0, "127.0.0.1", 39531);
  match cn {
    Ok(_) => {},
    Err(_) => { return 24; },
  };
  let ap = socket.socket_accept(sfd0);
  let sfd: Int;
  match ap {
    Ok(f) => { sfd = f; },
    Err(_) => { return 24; },
  };

  // handshake: client request -> server key -> response -> client verify
  let request = websocket.ws_handshake_request("127.0.0.1", "/w121", key);
  var reqb = to_bytes(request);
  let snd1 = socket.socket_send_all(cfd0, &reqb);
  match snd1 {
    Ok(_) => {},
    Err(_) => { return 25; },
  };
  let got1 = recv_headers(sfd);
  match got1 {
    Ok(t) => {
      let head = t.0;
      let rk = websocket.ws_request_key(head);
      match rk {
        Ok(kv) => {
          if kv != key {
            return 26;
          }
          let rsp = websocket.ws_handshake_response(kv);
          var rspb = to_bytes(rsp);
          let snd2 = socket.socket_send_all(sfd, &rspb);
          match snd2 {
            Ok(_) => {},
            Err(_) => { return 26; },
          };
        },
        Err(_) => {
          return 26;
        },
      };
    },
    Err(_) => {
      return 26;
    },
  };
  let got2 = recv_headers(cfd0);
  match got2 {
    Ok(t) => {
      let head2 = t.0;
      if !websocket.ws_handshake_verify(head2, key) {
        return 27;
      }
    },
    Err(_) => {
      return 27;
    },
  };

  // server sends an unmasked text frame; client takes it
  var msg = to_bytes("wave121");
  let sframe = websocket.ws_frame_encode(1, &msg, false);
  let snd3 = socket.socket_send_all(sfd, &sframe);
  match snd3 {
    Ok(_) => {},
    Err(_) => { return 28; },
  };
  let rbuf1 = recv_len(cfd0, sframe.len());
  match rbuf1 {
    Ok(buf) => {
      let tk = websocket.ws_frame_take(&buf);
      match tk {
        Ok(t) => {
          let fr = t.0;
          if fr.payload.len() != 7 {
            return 29;
          }
          let fb = fr.payload[0];
          if fb != 119 {
            return 29;
          }
        },
        Err(_) => {
          return 29;
        },
      };
    },
    Err(_) => {
      return 29;
    },
  };

  // client sends a masked frame; server takes it
  let cframe = websocket.ws_frame_encode(1, &msg, true);
  let snd4 = socket.socket_send_all(cfd0, &cframe);
  match snd4 {
    Ok(_) => {},
    Err(_) => { return 30; },
  };
  let rbuf2 = recv_len(sfd, cframe.len());
  match rbuf2 {
    Ok(buf) => {
      let tk2 = websocket.ws_frame_take(&buf);
      match tk2 {
        Ok(t) => {
          let fr = t.0;
          if fr.masked != true {
            return 31;
          }
          if fr.payload.len() != 7 {
            return 31;
          }
          let fb2 = fr.payload[1];
          if fb2 != 97 {
            return 31;
          }
        },
        Err(_) => {
          return 31;
        },
      };
    },
    Err(_) => {
      return 31;
    },
  };

  // chunked stream: head + two chunks + end, byte-exact on the wire
  var ca = to_bytes("alpha");
  var cb = to_bytes("beta");
  let head = "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n";
  let expected_str = head + socket.socket_chunk_encode(&ca) + socket.socket_chunk_encode(&cb) + socket.socket_chunked_end();
  let hb = to_bytes(head);
  let snd5 = socket.socket_send_all(sfd, &hb);
  match snd5 {
    Ok(_) => {},
    Err(_) => { return 32; },
  };
  let ch1 = socket.socket_stream_chunk(sfd, &ca);
  match ch1 {
    Ok(_) => {},
    Err(_) => { return 32; },
  };
  let ch2 = socket.socket_stream_chunk(sfd, &cb);
  match ch2 {
    Ok(_) => {},
    Err(_) => { return 32; },
  };
  let ch3 = socket.socket_stream_end(sfd);
  match ch3 {
    Ok(_) => {},
    Err(_) => { return 32; },
  };
  var expect = to_bytes(expected_str);
  let rbuf3 = recv_len(cfd0, expect.len());
  match rbuf3 {
    Ok(buf) => {
      if buf.len() != expect.len() {
        return 33;
      }
      var q = 0;
      var same = true;
      while q < expect.len() {
        if buf[q] != expect[q] {
          same = false;
        }
        q = q + 1;
      }
      if !same {
        return 33;
      }
    },
    Err(_) => {
      return 33;
    },
  };

  socket.socket_close(cfd0);
  socket.socket_close(sfd);
  socket.socket_close(sfd0);
  return 0;
}

// to_bytes copies a string's bytes into a Vec.
fn to_bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i = i + 1;
  }
  v
}

// recv_len reads until at least want bytes accumulated (or EOF -> Err).
fn recv_len(fd: Int, want: Int) -> Result[Vec[UInt8], Str] {
  var acc = Vec[UInt8].new();
  var guard = 0;
  while acc.len() < want && guard < 64 {
    guard = guard + 1;
    let remain = want - acc.len();
    let r = socket.socket_recv(fd, remain);
    match r {
      Ok(v) => {
        if v.len() == 0 {
          return Err("eof");
        }
        var i = 0;
        while i < v.len() {
          acc.push(v[i]);
          i = i + 1;
        }
      },
      Err(_) => {
        return Err("recv failed");
      },
    };
  }
  if acc.len() < want {
    return Err("short read");
  }
  Ok(acc)
}

// recv_headers reads until a full CRLFCRLF-terminated head is present.
fn recv_headers(fd: Int) -> Result[(Str, Vec[UInt8]), Str] {
  var acc = Vec[UInt8].new();
  var guard = 0;
  while guard < 64 {
    guard = guard + 1;
    let sp = websocket.ws_split_headers(&acc);
    match sp {
      Ok(t) => {
        return Ok((t.0, t.1));
      },
      Err(_) => {
        let r = socket.socket_recv(fd, 4096);
        match r {
          Ok(v) => {
            if v.len() == 0 {
              return Err("eof");
            }
            var i = 0;
            while i < v.len() {
              acc.push(v[i]);
              i = i + 1;
            }
          },
          Err(_) => {
            return Err("recv failed");
          },
        };
      },
    };
  }
  Err("headers too large")
}
