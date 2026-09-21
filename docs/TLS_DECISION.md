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

## Interim posture (current, honest)

https/jwt modules warn plaintext-on-the-wire. No code may claim HTTPS
semantics until this binding exists and interop passes.
