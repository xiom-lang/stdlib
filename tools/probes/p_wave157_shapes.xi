// p_wave157_shapes.xi -- wave 157 lock: TLS wave-B session layer (plan item 9
// wave-B; refs REL-20261015-2202-pulse item 1, REL-20261016-1128-orbitdb
// ask 2, REL-20261016-1129-xvector item 3). Pure parts, fail-clean paths,
// taxonomy and ALPN policy for the eight-symbol session driver in
// xiom.net.tls, plus the live in-tree libssl leg (xiom.net.tls_libssl).
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
//  9 -- libssl ALPN client wire golden ([h2,http/1.1] -> 12 bytes, no
//       outer 2-byte prefix) + empty list Err
// 10 -- tls_libssl_load_named(bogus) -> Err kind TLS_ERR_LOAD
// 11 -- tls_libssl_load(): Err(TLS_ERR_LOAD) -> live leg SKIPs (pass);
//       Err(TLS_ERR_ABI) or anything else -> failure
// 12 -- (live) tls_libssl_available() == true once the library loaded
// 13 -- (live) bad handles on a loaded library: step/read/write/shutdown/
//       alpn with a closed session -> typed Err; free of a zero session
//       is a clean no-op
// 14 -- (live) loopback pair + server/client sessions (client ALPN
//       set-list accepted; nonblocking fds)
// 15 -- (live) full TLS handshake, step-driven via tls_wait_readable /
//       tls_wait_writable
// 16 -- (live) encrypted app data both directions (ping + pong)
// 17 -- (live) ALPN negotiated read: both ends "" (no server-side
//       selector; the documented state)
// 18 -- (live) clean close: server close_notify -> Ok(0); client read ->
//       Err kind TLS_ERR_EOF; shutdown completes 1/1
// Setup failures use 21+ (21 stage-1 loopback pair, 22 live loopback
// pair, 23 fixture read).

module p_wave157_shapes

use xiom.io;
use xiom.net.socket;
use xiom.net.tls;
use xiom.net.tls.TlsBackend;
use xiom.net.tls.TlsSession;
use xiom.net.tls.TLS_ALPN_NO_APPLICATION_PROTOCOL;
use xiom.net.tls.TLS_ERR_LOAD;
use xiom.net.tls.TLS_ERR_ABI;
use xiom.net.tls.TLS_ERR_ARG;
use xiom.net.tls.TLS_ERR_EOF;
use xiom.net.tls.TLS_STEP_DONE;
use xiom.net.tls.TLS_STEP_WANT_READ;
use xiom.net.tls.TLS_STEP_WANT_WRITE;
use xiom.net.tls_libssl;
use xiom.net.tls_libssl.TlsLibssl;
use xiom.net.tls_libssl.TlsLibSession;

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
// Stage-2 rows (libssl)
// =========================================================================

// row_alpn_wire locks the client set-list wire format (no outer prefix).
fn row_alpn_wire() -> Int {
  let names = two_str("h2", "http/1.1");
  match tls_libssl.tls_libssl_alpn_client_wire(&names) {
    Ok(w) => {
      if w.len() != 12 { return 9; }
      if w[0] != 2 as UInt8 { return 9; }
      if w[3] != 8 as UInt8 { return 9; }
    },
    Err(_) => { return 9; },
  }
  var none = Vec[Str].new();
  match tls_libssl.tls_libssl_alpn_client_wire(&none) {
    Ok(_) => { return 9; },
    Err(_) => {},
  }
  0
}

// pump_handshake drives both step machines until both finish; returns 0
// on success, 1/2 on a fatal per side, 3 on exhaustion.
fn pump_handshake(lib: &TlsLibssl, srv: &TlsLibSession, cli: &TlsLibSession) -> Int {
  var srv_done = false;
  var cli_done = false;
  var srv_code = 0;
  var cli_code = 0;
  var i = 0;
  while i < 400 {
    if srv_done && cli_done {
      return 0;
    }
    if !srv_done {
      match tls_libssl.tls_libssl_step(lib, srv, true) {
        Ok(c) => {
          srv_code = c;
          if c == TLS_STEP_DONE { srv_done = true; }
        },
        Err(_) => { return 1; },
      }
    }
    if !cli_done {
      match tls_libssl.tls_libssl_step(lib, cli, false) {
        Ok(c) => {
          cli_code = c;
          if c == TLS_STEP_DONE { cli_done = true; }
        },
        Err(_) => { return 2; },
      }
    }
    if srv_done && cli_done {
      return 0;
    }
    if !srv_done {
      if srv_code == TLS_STEP_WANT_WRITE {
        let _ = tls.tls_wait_writable(srv.fd, 30);
      } else {
        let _ = tls.tls_wait_readable(srv.fd, 30);
      }
    }
    if !cli_done {
      if cli_code == TLS_STEP_WANT_WRITE {
        let _ = tls.tls_wait_writable(cli.fd, 30);
      } else {
        let _ = tls.tls_wait_readable(cli.fd, 30);
      }
    }
    i = i + 1;
  }
  3
}

// shutdown_progress retries one side's shutdown across WANT states until
// it completes (1) or the budget runs out (-1).
fn shutdown_progress(lib: &TlsLibssl, sess: &TlsLibSession, fd: Int) -> Int {
  var k = 0;
  while k < 400 {
    let r = tls_libssl.tls_libssl_shutdown(lib, sess);
    if r.is_ok {
      if r.value == 1 { return 1; }
    } else {
      if r.error.kind == tls.TLS_ERR_WANT_READ {
        let _ = tls.tls_wait_readable(fd, 25);
      } elif r.error.kind == tls.TLS_ERR_WANT_WRITE {
        let _ = tls.tls_wait_writable(fd, 25);
      } else {
        return -1;
      }
    }
    k = k + 1;
  }
  -1
}

// row_live runs the live libssl leg on a fresh loopback pair.
fn row_live(lib: &TlsLibssl) -> Int {
  var zero = TlsLibSession{ ssl: 0; ctx: 0; fd: -1 };

  // Bad handles on a loaded library: typed errors, no crash.
  match tls_libssl.tls_libssl_step(lib, &zero, true) {
    Ok(_) => { return 13; },
    Err(e) => {
      if e.kind != TLS_ERR_ARG { return 13; }
    },
  }
  let r0 = tls_libssl.tls_libssl_read(lib, &zero, 16);
  if r0.is_ok { return 13; }
  let w0 = tls_libssl.tls_libssl_write(lib, &zero, &bytes_of("x"));
  if w0.is_ok { return 13; }
  let sd0 = tls_libssl.tls_libssl_shutdown(lib, &zero);
  if sd0.is_ok { return 13; }
  let a0 = tls_libssl.tls_libssl_alpn_selected(lib, &zero);
  if a0.is_ok { return 13; }
  tls_libssl.tls_libssl_free(lib, &zero);

  // Fixtures must be readable before the live handshake.
  match tls.tls_cert_material_check(CERT_PEM, KEY_PEM) {
    Ok(_) => {},
    Err(_) => { return 23; },
  }

  let pair = open_pair();
  if !pair.ok { return 22; }

  let srr = tls_libssl.tls_libssl_server_session(lib, pair.afd, CERT_PEM, KEY_PEM);
  if !srr.is_ok {
    socket.socket_close(pair.afd);
    socket.socket_close(pair.cfd);
    socket.socket_close(pair.lfd);
    return 14;
  }
  let srv: TlsLibSession = srr.value;

  let names = two_str("h2", "http/1.1");
  let crr = tls_libssl.tls_libssl_client_session(lib, pair.cfd, &names);
  if !crr.is_ok {
    tls_libssl.tls_libssl_free(lib, &srv);
    socket.socket_close(pair.afd);
    socket.socket_close(pair.cfd);
    socket.socket_close(pair.lfd);
    return 14;
  }
  let cli: TlsLibSession = crr.value;

  let nb1 = socket.socket_set_nonblocking(pair.afd, true);
  let nb2 = socket.socket_set_nonblocking(pair.cfd, true);
  let _ = nb1;
  let _ = nb2;

  // Handshake.
  let hs = pump_handshake(lib, &srv, &cli);
  if hs != 0 {
    tls_libssl.tls_libssl_free(lib, &srv);
    tls_libssl.tls_libssl_free(lib, &cli);
    socket.socket_close(pair.afd);
    socket.socket_close(pair.cfd);
    socket.socket_close(pair.lfd);
    return 15;
  }

  // Data both directions.
  var rc = 0;
  let ping = bytes_of("wave157-ping");
  match tls_libssl.tls_libssl_write(lib, &cli, &ping) {
    Ok(n) => {
      if n != 12 { rc = 16; }
    },
    Err(_) => { rc = 16; },
  }
  if rc == 0 {
    match tls_libssl.tls_libssl_read(lib, &srv, 64) {
      Ok(got) => {
        if got.len() != 12 { rc = 16; }
        elif Str::from_utf8(got) != "wave157-ping" { rc = 16; }
      },
      Err(_) => { rc = 16; },
    }
  }
  let pong = bytes_of("wave157-pong");
  if rc == 0 {
    match tls_libssl.tls_libssl_write(lib, &srv, &pong) {
      Ok(n) => {
        if n != 12 { rc = 16; }
      },
      Err(_) => { rc = 16; },
    }
  }
  if rc == 0 {
    match tls_libssl.tls_libssl_read(lib, &cli, 64) {
      Ok(got) => {
        if got.len() != 12 { rc = 16; }
        elif Str::from_utf8(got) != "wave157-pong" { rc = 16; }
      },
      Err(_) => { rc = 16; },
    }
  }

  // ALPN negotiated read: client set the list, no server selector ->
  // both ends report "" (the documented state).
  if rc == 0 {
    let sa = tls_libssl.tls_libssl_alpn_selected(lib, &srv);
    let ca = tls_libssl.tls_libssl_alpn_selected(lib, &cli);
    if !sa.is_ok || !ca.is_ok {
      rc = 17;
    } elif sa.value.len() != 0 || ca.value.len() != 0 {
      rc = 17;
    }
  }

  // Clean close: server close_notify first (Ok(0)), the client's read
  // reports EOF, then the client's close_notify completes both sides.
  if rc == 0 {
    var sent = -1;
    var k = 0;
    while k < 200 {
      let r = tls_libssl.tls_libssl_shutdown(lib, &srv);
      if r.is_ok {
        if r.value >= 0 {
          sent = r.value;
          break;
        }
      } else {
        if r.error.kind == tls.TLS_ERR_WANT_READ {
          let _ = tls.tls_wait_readable(pair.afd, 25);
        } elif r.error.kind == tls.TLS_ERR_WANT_WRITE {
          let _ = tls.tls_wait_writable(pair.afd, 25);
        } else {
          sent = -2;
          break;
        }
      }
      k = k + 1;
    }
    if sent != 0 { rc = 18; }
  }
  if rc == 0 {
    match tls_libssl.tls_libssl_read(lib, &cli, 64) {
      Ok(_) => { rc = 18; },
      Err(e) => {
        if e.kind != TLS_ERR_EOF { rc = 18; }
      },
    }
  }
  if rc == 0 {
    let c_done = shutdown_progress(lib, &cli, pair.cfd);
    let s_done = shutdown_progress(lib, &srv, pair.afd);
    if c_done != 1 || s_done != 1 { rc = 18; }
  }

  tls_libssl.tls_libssl_free(lib, &srv);
  tls_libssl.tls_libssl_free(lib, &cli);
  socket.socket_close(pair.afd);
  socket.socket_close(pair.cfd);
  socket.socket_close(pair.lfd);
  rc
}

// =========================================================================
// Driver
// =========================================================================

fn main() -> Int {
  // Stage 1: pure parts, taxonomy, ALPN policy, fail-clean driver.
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

  // Stage 2: libssl leg (SKIP-safe).
  let r9 = row_alpn_wire();
  if r9 != 0 { return r9; }

  match tls_libssl.tls_libssl_load_named("definitely-missing-libssl-wave157.dll") {
    Ok(_) => { return 10; },
    Err(e) => {
      if e.kind != TLS_ERR_LOAD { return 10; }
    },
  }

  let lr = tls_libssl.tls_libssl_load();
  if !lr.is_ok {
    if lr.error.kind == TLS_ERR_LOAD {
      // No system libssl: the live rows are SKIPped by design (the
      // binding's suite uses the same classification).
      return 0;
    }
    return 11;
  }
  let lib: TlsLibssl = lr.value;

  if !tls_libssl.tls_libssl_available() { return 12; }

  let rl = row_live(&lib);
  let cl = tls_libssl.tls_libssl_close(&lib);
  if !cl.is_ok { return 19; }
  if rl != 0 { return rl; }
  return 0;
}
