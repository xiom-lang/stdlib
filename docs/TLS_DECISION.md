<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# TLS Decision -- Recommended Path for XIOM

**Status:** decision doc (stdlib session) - **Created:** 2026-08-25
**Context:** the audit's single biggest net-stack credibility gap: no TLS
ships, while https/jwt/websocket imply secure transport. Until this lands,
those modules carry plaintext warnings (added 2026-08-25).

## Decision

**Bind the OS TLS stack first; do NOT grow a homegrown TLS.**

Windows-first toolchain => **schannel via FFI** (secur32.dll /
SSPI), with an OpenSSL/libressl FFI adapter as the portable second front.
Rationale:

1. Correctness is the product. TLS has a 25-year history of catastrophic
   handrolled-implementation failures; schannel/OpenSSL are constantly
   fuzzed and patched by people whose day job is exactly that.
2. Zero new supply chain on Windows: secur32 ships with the OS -- same
   posture as xiom_os_entropy binding bcrypt/advapi32 dynamically.
3. Credential/cert handling (system trust store, machine cert pools) comes
   free; a homegrown stack would need its own trust store story anyway.
4. The stdlib audit + compiler audit both gate self-hosting on trust
   infrastructure FIRST; FFI-binding is weeks, not quarters.

## Rejected alternatives

- **Homegrown TLS in pure XIOM**: rejected -- even with perfect primitives
  (which we do not yet have KAT-proven end-to-end), the state machine and
  side-channel surface are not a student project.
- **Shipping OpenSSL binaries**: rejected for Windows default (supply chain
  + licensing noise); acceptable as opt-in portable adapter.

## Shape of the binding (phase C2)

1. `net/tls/` module family over SSPI:
   - credential acquisition (AcquireCredentialsHandleW, SCH_CRED_AUTO)
   - client handshake state machine (InitializeSecurityContext loop)
   - server handshake (AcceptSecurityContext) -- phase 2
   - stream encrypt/decrypt (EncryptMessage/DecryptMessage)
   - remote cert validation policy hooks (default: system trust)
2. `net/socket` gains a raw-tcp handle type the TLS layer wraps (today's
   thin runtime sockets suffice).
3. `https.xi` switches to the TLS-wrapped socket; jwt/ws docs update from
   "plaintext unless you bring your own" to "secured when tls feature used".
4. Constant-time guarantees inherited from OS libraries; our ct_compare
   stays for token comparison only.

## Prerequisites / dependencies

- Compiler stage-5 FFI hardening (unknown-type pass-through) before
  touching SSPI structures -- their queue.
- Struct-heavy FFI: watch the cross-module struct-param resolution bug
  (REPORT 3b-2 #10); keep SSPI types inside one module until fixed.
- KAT corpus for the wrapper itself: handshake against test endpoints +
  Interop tests with openssl s_server/s_client scripted in e2e.

## Status 2026-10-16 (wave 157 stage B): the two routes and the honest live boundary

The original decision ("bind the OS TLS stack first; do NOT grow a homegrown
TLS") stands. Two concrete routes now exist and compose:

**Route A -- ecosystem: the `xiom.ssl` package (registry, LIVE).** The
packages/bindings lane shipped `xiom.ssl 0.1.0` (published, eco-v0.1.189): a
dynamic-loader binding over system libssl (the `libssl-3-x64.dll` soname
chain) with contexts, PEM/DER cert/key/chain load from files and buffers,
fd-attached and memory-BIO handshake driving, ALPN client set-list +
negotiated read, verify modes, typed errors, and SKIP-safe loading
(SPEC.md/AUDIT.md in that package). Consumers on the registry path use that
package; its suite is live-proven 23/23 on libssl 3.2.4 and 4/4 SKIP.

**Route B -- in-tree: the `xiom.net.tls` session layer + the minimal
`xiom.net.tls_libssl` backend (wave 157).** This repo cannot import registry
packages, so the in-tree route is the `dl_open` seam:

1. `xiom.net.tls` defines the backend-independent **eight-symbol contract**
   (`tls_init`, `tls_server_new`, `tls_client_new`, `tls_handshake`,
   `tls_read`, `tls_write`, `tls_close`, `tls_alpn_selected`; signatures
   pinned in the module header) and now DRIVES it (wave-154 stage gate
   lifted): session open (server/client + fd attach + PEM cert/key paths),
   step (done / want-read / want-write / typed fatal), read, write,
   alpn-selected, close. Every handle and address is validated before any
   call, so a zero/absent backend or a bad handle fails with a typed
   `TlsError` kind, never a crash. No conforming native backend library for
   this contract exists on this box yet: the driver's happy path is proven
   only when such a backend is present (the contract is the seam a
   mbedTLS-class or shim backend would fill).
2. `xiom.net.tls_libssl` is the live in-tree leg: a **minimal** libssl
   session module (17 entry points, the binding's soname list; deliberately
   NOT a second xiom.ssl -- no buffer/DER material, no chain/CA stores, no
   memory BIOs, no SNI, no version/cipher/verify-result symbols) that runs
   real TLS sessions over a socket fd.

**What is LIVE today:** Route A in full (package suite). Route B: the
libssl leg runs a real loopback TLS handshake (encrypted ping/pong both
directions, clean `close_notify` with typed EOF) on this box (Git for
Windows libssl 3.2.4 via `C:\Program Files\Git\mingw64\bin` on PATH; absent
libssl is a clean load error and the probe SKIPs green); the pure halves --
error taxonomy, ALPN policy, material sniff/pre-validation, fd-readiness
pump -- are live on every host, and the eight-symbol driver's fail-clean
paths are probe-locked.

**What is NOT live (do not claim otherwise):** no in-tree consumer is wired
to TLS yet (https/ws still carry their plaintext warnings; nothing imports
`tls_libssl`); server-side ALPN *selection* (below); verify-result
classification in the minimal libssl surface (Route A binds
`SSL_get_verify_result`; the in-tree minimal module classifies fatal
handshakes as `TLS_ERR_HANDSHAKE` only); cert/key buffers/DER, chains, CA
stores, memory BIOs and SNI on the in-tree minimal surface.

**Server-side ALPN selection: documented limitation + policy workaround.**
OpenSSL selects the server-side ALPN protocol only through an
`SSL_CTX_set_alpn_select_cb` C callback; the XIOM FFI has no callback
bridging (the binding's AUDIT records the same lane survey), so a server
without one negotiates ALPN "none" (`alpn_selected == ""`; locked live by
the binding suite and the wave-157 probe). The workaround is policy at the
application layer: `xiom.net.tls.tls_alpn_select_server(server_pref,
client_offered)` returns the first server-preferred protocol the client
offered, or the classified `no_application_protocol` error (the RFC 7301 /
RFC 8446 alert-120 class). Applications negotiate in-band before serving or
refuse the connection; the selected name is not injected into the ALPN
extension itself until C-callback bridging exists.

Evidence: `tools/probes/p_wave157_shapes.xi` (wave-157 lock; green 3/3 on
the official v0.64.5 pin with the live leg, plus a green SKIP run without
Git on PATH, plus a WSL Ubuntu run), `tools/probes/p_wave154_shapes.xi`
(loader/ALPN codec), `tools/fixtures/tls/README.md` (test-only fixture
provenance), and the xiom-ssl SPEC/AUDIT for Route A.

## Interim posture (current, honest)

https/jwt modules warn plaintext-on-the-wire. No code may claim HTTPS
semantics until this binding exists and interop passes.
