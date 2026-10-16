// p_wave157_shapes.xi -- wave 157 lock: TLS wave-B session layer, stage 1
// (plan item 9 wave-B; refs REL-20261015-2202-pulse item 1,
// REL-20261016-1128-orbitdb ask 2, REL-20261016-1129-xvector item 3).
// Pure parts, fail-clean paths, taxonomy, ALPN policy and the readiness
// pump for the eight-symbol session driver in xiom.net.tls.
//
// Rows (0 = all hold):
//  1 -- ALPN server policy: server preference order wins ([h2,http/1.1] x
//       [http/1.1,h2] -> "h2")
//  2 -- ALPN server policy: no overlap -> Err "no_application_protocol"
//  3 -- ALPN server policy: empty server pref -> Err (misconfiguration);
//       empty client offer -> Err "no_application_protocol"
//  4 -- taxonomy: kind names for every constant + unknown; want/fatal
//       classification
//  5 -- material sniff: "pem" / "der" / "unknown" / empty -> "unknown"
//  6 -- cert material check: fixture pair Ok; missing file Err; empty
//       file Err; empty path Err
//  7 -- driver fail-clean: zero backend refuses with typed Err; fake
//       backend (non-zero addresses) validates BEFORE any call (bad fd,
//       closed session); close of a closed session is idempotent
//  8 -- readiness pump: bad fd/timeout Err; live loopback pair
//       wait_writable(true) + wait_readable(false on timeout, true after
//       a byte)
// Setup failures use 21+ (21 stage-1 loopback pair).

module p_wave157_shapes

use xiom.net.socket;
use xiom.net.tls;
use xiom.net.tls.TlsBackend;
use xiom.net.tls.TlsSession;
use xiom.net.tls.TLS_ALPN_NO_APPLICATION_PROTOCOL;
use xiom.net.tls.TLS_ERR_LOAD;
use xiom.net.tls.TLS_ERR_ARG;

const CERT_PEM: Str = "tools/fixtures/tls/server-cert.pem";
const KEY_PEM: Str = "tools/fixtures/tls/server-key.pem";
const EMPTY_PEM: Str = "tools/fixtures/tls/empty.pem";

// =========================================================================
// Local helpers
// =========================================================================

fn bytes_of(s: Str) -> Vec[UInt8] {
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    out.push(s.byte_at(i));
    i = i + 1;
  }
  out
}

fn one_str(s: Str) -> Vec[Str] {
  var out: Vec[Str] = Vec[Str].new();
  out.push(s);
  out
}

fn two_str(a: Str, b: Str) -> Vec[Str] {
  var out: Vec[Str] = Vec[Str].new();
  out.push(a);
  out.push(b);
  out
}

fn zero_backend() -> TlsBackend {
  TlsBackend{
    handle: 0;
    tls_init: 0;
    tls_server_new: 0;
    tls_client_new: 0;
    tls_handshake: 0;
    tls_read: 0;
    tls_write: 0;
    tls_close: 0;
    tls_alpn_selected: 0;
  }
}

fn fake_backend() -> TlsBackend {
  TlsBackend{
    handle: 1;
    tls_init: 1;
    tls_server_new: 1;
    tls_client_new: 1;
    tls_handshake: 1;
    tls_read: 1;
    tls_write: 1;
    tls_close: 1;
    tls_alpn_selected: 1;
  }
}

type FdPair = {
  ok: Bool;
  lfd: Int;
  afd: Int;
  cfd: Int;
  port: Int;
}

// open_pair scans a small port range for a working loopback listener +
// connected client/server fd pair (the binding suite's pattern).
fn open_pair() -> FdPair {
  var out = FdPair{ ok: false; lfd: -1; afd: -1; cfd: -1; port: 0 };
  var attempt = 46400;
  while attempt < 46480 {
    let t = socket.socket_tcp();
    if !t.is_ok { return out; }
    let lfd0: Int = t.value;
    let b = socket.socket_bind(lfd0, "127.0.0.1", attempt);
    if b.is_ok {
      let l = socket.socket_listen(lfd0, 4);
      if l.is_ok {
        let c = socket.socket_tcp();
        if !c.is_ok {
          socket.socket_close(lfd0);
          return out;
        }
        let cfd0: Int = c.value;
        let cn = socket.socket_connect(cfd0, "127.0.0.1", attempt);
        if cn.is_ok {
          let a = socket.socket_accept(lfd0);
          if a.is_ok {
            out.ok = true;
            out.lfd = lfd0;
            out.cfd = cfd0;
            out.afd = a.value;
            out.port = attempt;
            return out;
          }
        }
        socket.socket_close(cfd0);
      }
      socket.socket_close(lfd0);
    }
    attempt = attempt + 1;
  }
  out
}

// =========================================================================
// Stage-1 rows (pure + fail-clean; no library needed)
// =========================================================================

// row_alpn_policy locks the server-side selection policy rows.
fn row_alpn_policy() -> Int {
  let pref = two_str("h2", "http/1.1");
  let offer = two_str("http/1.1", "h2");
  match tls.tls_alpn_select_server(&pref, &offer) {
    Ok(sel) => {
      if sel != "h2" { return 1; }
    },
    Err(_) => { return 1; },
  }
  let only1 = one_str("h2");
  let other = one_str("http/1.1");
  match tls.tls_alpn_select_server(&only1, &other) {
    Ok(_) => { return 2; },
    Err(e) => {
      if e != TLS_ALPN_NO_APPLICATION_PROTOCOL { return 2; }
    },
  }
  var none = Vec[Str].new();
  match tls.tls_alpn_select_server(&none, &offer) {
    Ok(_) => { return 3; },
    Err(_) => {},
  }
  match tls.tls_alpn_select_server(&pref, &none) {
    Ok(_) => { return 3; },
    Err(e) => {
      if e != TLS_ALPN_NO_APPLICATION_PROTOCOL { return 3; }
    },
  }
  0
}

// row_taxonomy locks kind names and the want/fatal classification.
fn row_taxonomy() -> Int {
  if tls.tls_err_kind_name(tls.TLS_ERR_NONE) != "none" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_LOAD) != "load" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_ARG) != "arg" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_ALLOC) != "alloc" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_CERT) != "cert" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_ALPN) != "alpn" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_HANDSHAKE) != "handshake" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_VERIFY) != "verify" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_IO) != "io" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_EOF) != "eof" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_WANT_READ) != "want-read" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_WANT_WRITE) != "want-write" { return 4; }
  if tls.tls_err_kind_name(tls.TLS_ERR_ABI) != "abi" { return 4; }
  if tls.tls_err_kind_name(999) != "unknown" { return 4; }
  if !tls.tls_err_kind_is_want(tls.TLS_ERR_WANT_READ) { return 4; }
  if !tls.tls_err_kind_is_want(tls.TLS_ERR_WANT_WRITE) { return 4; }
  if tls.tls_err_kind_is_want(tls.TLS_ERR_NONE) { return 4; }
  if !tls.tls_err_kind_is_fatal(tls.TLS_ERR_HANDSHAKE) { return 4; }
  if !tls.tls_err_kind_is_fatal(tls.TLS_ERR_VERIFY) { return 4; }
  if !tls.tls_err_kind_is_fatal(tls.TLS_ERR_IO) { return 4; }
  if tls.tls_err_kind_is_fatal(tls.TLS_ERR_EOF) { return 4; }
  if tls.tls_err_kind_is_fatal(tls.TLS_ERR_WANT_READ) { return 4; }
  if tls.tls_err_kind_is_fatal(tls.TLS_ERR_NONE) { return 4; }
  0
}

// row_sniff locks the PEM/DER leading-byte classification.
fn row_sniff() -> Int {
  let pem = bytes_of("-----BEGIN CERTIFICATE-----");
  if tls.tls_material_sniff(&pem) != "pem" { return 5; }
  var der: Vec[UInt8] = Vec[UInt8].new();
  der.push(48 as UInt8);
  der.push(130 as UInt8);
  der.push(3 as UInt8);
  if tls.tls_material_sniff(&der) != "der" { return 5; }
  var junk: Vec[UInt8] = Vec[UInt8].new();
  junk.push(0 as UInt8);
  junk.push(66 as UInt8);
  if tls.tls_material_sniff(&junk) != "unknown" { return 5; }
  var none: Vec[UInt8] = Vec[UInt8].new();
  if tls.tls_material_sniff(&none) != "unknown" { return 5; }
  if tls.tls_material_sniff(&one_str_bytes()) != "unknown" { return 5; }
  0
}

fn one_str_bytes() -> Vec[UInt8] {
  bytes_of("-")
}

// row_cert_material locks the pre-validation helper.
fn row_cert_material() -> Int {
  match tls.tls_cert_material_check(CERT_PEM, KEY_PEM) {
    Ok(_) => {},
    Err(_) => { return 6; },
  }
  match tls.tls_cert_material_check("tools/fixtures/tls/absent-cert.pem", KEY_PEM) {
    Ok(_) => { return 6; },
    Err(_) => {},
  }
  match tls.tls_cert_material_check(CERT_PEM, "tools/fixtures/tls/absent-key.pem") {
    Ok(_) => { return 6; },
    Err(_) => {},
  }
  match tls.tls_cert_material_check(EMPTY_PEM, KEY_PEM) {
    Ok(_) => { return 6; },
    Err(_) => {},
  }
  match tls.tls_cert_material_check("", KEY_PEM) {
    Ok(_) => { return 6; },
    Err(_) => {},
  }
  0
}

// row_driver_fail_clean locks the driver's validation order: zero/absent
// backends and closed sessions fail with typed errors BEFORE any call
// into a backend address (the fake backend's addresses are 1, so a
// missing validation would crash instead of returning).
fn row_driver_fail_clean() -> Int {
  let zb = zero_backend();
  let fb = fake_backend();
  var sess0 = TlsSession{ id: 0; server: false; fd: -1 };

  // Zero backend: open refuses with LOAD before anything else.
  match tls.tls_session_open(&zb, true, 3, CERT_PEM, KEY_PEM, "") {
    Ok(_) => { return 7; },
    Err(e) => {
      if e.kind != TLS_ERR_LOAD { return 7; }
    },
  }
  // Zero backend + a live-looking session: every operation refuses.
  match tls.tls_session_step(&zb, &sess0) {
    Ok(_) => { return 7; },
    Err(e) => {
      if e.kind != TLS_ERR_LOAD { return 7; }
    },
  }
  let r1 = tls.tls_session_read(&zb, &sess0, 16);
  if r1.is_ok { return 7; }
  let w1 = tls.tls_session_write(&zb, &sess0, &bytes_of("x"));
  if w1.is_ok { return 7; }
  let a1 = tls.tls_session_alpn_selected(&zb, &sess0);
  if a1.is_ok { return 7; }

  // Fake backend (addresses are 1): bad fd / closed session must be
  // rejected by validation alone.
  match tls.tls_session_open(&fb, true, -1, CERT_PEM, KEY_PEM, "") {
    Ok(_) => { return 7; },
    Err(e) => {
      if e.kind != TLS_ERR_ARG { return 7; }
    },
  }
  match tls.tls_session_open(&fb, false, -1, "", "", "127.0.0.1") {
    Ok(_) => { return 7; },
    Err(e) => {
      if e.kind != TLS_ERR_ARG { return 7; }
    },
  }
  match tls.tls_session_step(&fb, &sess0) {
    Ok(_) => { return 7; },
    Err(e) => {
      if e.kind != TLS_ERR_ARG { return 7; }
    },
  }
  let r2 = tls.tls_session_read(&fb, &sess0, 16);
  if r2.is_ok { return 7; }
  let w2 = tls.tls_session_write(&fb, &sess0, &bytes_of("x"));
  if w2.is_ok { return 7; }
  let a2 = tls.tls_session_alpn_selected(&fb, &sess0);
  if a2.is_ok { return 7; }

  // Close is idempotent for an id of 0 and refuses a negative id; the
  // zero id path returns before any backend call.
  match tls.tls_session_close(&fb, &mut sess0) {
    Ok(_) => {},
    Err(_) => { return 7; },
  }
  var sessneg = TlsSession{ id: 0 - 5; server: false; fd: -1 };
  match tls.tls_session_close(&fb, &mut sessneg) {
    Ok(_) => { return 7; },
    Err(e) => {
      if e.kind != TLS_ERR_ARG { return 7; }
    },
  }
  0
}

// row_pump locks the readiness helpers: argument errors clean, live
// loopback writable/readable transitions.
fn row_pump() -> Int {
  let bad1 = tls.tls_wait_readable(-1, 10);
  if bad1.is_ok { return 8; }
  let bad2 = tls.tls_wait_writable(-1, 10);
  if bad2.is_ok { return 8; }
  let bad3 = tls.tls_wait_readable(0, -1);
  if bad3.is_ok { return 8; }
  let bad4 = tls.tls_wait_writable(0, -1);
  if bad4.is_ok { return 8; }

  let pair = open_pair();
  if !pair.ok { return 21; }
  var rc = 0;

  match tls.tls_wait_writable(pair.cfd, 1000) {
    Ok(ready) => {
      if !ready { rc = 8; }
    },
    Err(_) => { rc = 8; },
  }
  if rc == 0 {
    match tls.tls_wait_readable(pair.afd, 30) {
      Ok(ready) => {
        if ready { rc = 8; }
      },
      Err(_) => { rc = 8; },
    }
  }
  if rc == 0 {
    let one = bytes_of("x");
    match socket.socket_send(pair.cfd, &one) {
      Ok(n) => {
        if n != 1 { rc = 8; }
      },
      Err(_) => { rc = 8; },
    }
  }
  if rc == 0 {
    match tls.tls_wait_readable(pair.afd, 1000) {
      Ok(ready) => {
        if !ready { rc = 8; }
      },
      Err(_) => { rc = 8; },
    }
  }
  if rc == 0 {
    match socket.socket_recv(pair.afd, 16) {
      Ok(got) => {
        if got.len() != 1 { rc = 8; }
        if got[0] != 120 as UInt8 { rc = 8; }
      },
      Err(_) => { rc = 8; },
    }
  }

  socket.socket_close(pair.afd);
  socket.socket_close(pair.cfd);
  socket.socket_close(pair.lfd);
  rc
}

// =========================================================================
// Driver
// =========================================================================

fn main() -> Int {
  let r1 = row_alpn_policy();
  if r1 != 0 { return r1; }
  let r4 = row_taxonomy();
  if r4 != 0 { return r4; }
  let r5 = row_sniff();
  if r5 != 0 { return r5; }
  let r6 = row_cert_material();
  if r6 != 0 { return r6; }
  let r7 = row_driver_fail_clean();
  if r7 != 0 { return r7; }
  let r8 = row_pump();
  if r8 != 0 { return r8; }
  return 0;
}
