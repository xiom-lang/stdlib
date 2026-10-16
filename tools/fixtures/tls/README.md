# tools/fixtures/tls -- TEST-ONLY TLS material

These files exist only for the wave-157 TLS probes (`p_wave157_shapes`).
They are a self-signed localhost certificate/key pair for the loopback
handshake leg of the probe, NOT secrets, NOT for any production use, and
NOT part of the shipped stdlib (tools/ is not packaged).

| File | What | SHA256 |
|------|------|--------|
| `server-cert.pem` | self-signed cert, CN=127.0.0.1, SAN IP:127.0.0.1, RSA-2048, 10 years | `E41DF3963769ECE8A91FBD0E7CB8959B6F44D3286D99742789A32ACA3F7448AC` |
| `server-key.pem` | PKCS#8 private key for the cert above | `E52E5103D338EBBD4D5DA2F8F395251F9192ADF83E054E4EEAB50DF40BF573C9` |
| `empty.pem` | zero-byte file: locks the empty-material rejection row | (empty) |

Generated once (2026-10-16) with the Git for Windows OpenSSL CLI
(`C:\Program Files\Git\mingw64\bin\openssl.exe`, OpenSSL 3.2.4):

```powershell
openssl req -x509 -newkey rsa:2048 -keyout server-key.pem -out server-cert.pem `
  -days 3650 -nodes -subj "/CN=127.0.0.1" -addext "subjectAltName=IP:127.0.0.1"
```

Regeneration note: the key is random per run, so a regenerated pair has
different hashes; update this table in the same commit if you regenerate.
