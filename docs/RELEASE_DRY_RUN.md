# Release dry-run (next stdlib cut)

Status: **no tag, no release, no registry write.** This document is the
pre-cut package: what the workflow does, the dry-run that was executed, the
exact GO checklist, and a draft of the next release notes. The version
number and `COMPILER_VERSION` pin are the owner's decision.

**Verified candidate (2026-10-29):** compiler `605c6a879`, binary
`target/candidate/xiom-605c6a879.exe`, sha256
`50A10EBEF9F728519243487E1B785A5E6A93C3B6A5EF7F6CA56FF66454CF09DE`.
It fixes the last stdlib-visible blocker, 1641 (implicit tail-return
ownership). The package is ready for the owner's GO; the tree has not been
bumped yet.

## 1. What `.github/workflows/release.yml` does

Trigger: `push` on `stdlib-v*`, or `workflow_dispatch`.

- **validate** (ubuntu): `package.xi` must contain `name: "xiom-std"`,
  `version: "<label>"`, and a `compiler = ">=..."` range. On a dispatch the
  label comes from the `version` input (or from an existing `tag`).
- **gates** (ubuntu + windows): builds the compiler from `COMPILER_VERSION`,
  then runs the smoke corpus (with `tools/known_failures/gate-exclusions.txt`),
  `check_modules`, `barename_scan`, `coverage_floors197`, and
  `module_smoke_floors`.
- **package** (ubuntu): stages `xiom/`, `runtime/`, `package.xi`, licenses,
  README and CHANGELOG; packs a deterministic tarball
  (`SOURCE_DATE_EPOCH`, sorted entries, mtime/owner pinned, `gzip -n -9`);
  writes `SHA256SUMS`; attests provenance; uploads the artifact.
  **Creates the GitHub Release only for a tag push or a dispatch with
  `tag` set.**
- **pin-pr / canary-dispatch**: also tag-only (`inputs.tag != ''`).

So a dispatch with only `version` is a genuine dry-run: validate + gates +
package staging, **no release, no pin PR, no registry canary**.

## 2. Dry-run executed (workflow path)

Because validate requires `package.xi` to match the label, the dry-run uses
the current released label; a next-version dry-run needs the owner's version
bump first.

```powershell
gh workflow run release.yml --repo xiom-lang/stdlib -f version=0.65.2
```

Result: **run 40683465791 completed `success`.** validate package.xi
green; release gates on **ubuntu-latest** and **windows-latest** green;
package staging green (deterministic tarball + SHA256SUMS + attestation).
`STDLIB_VERSION pin PR` and `dispatch staging registry canary` were
correctly **skipped** because the dispatch had no `tag`: no GitHub
Release, no registry write. The run exercised the tree at `4426942` (the
release-workflow path is independent of the later h2_io wave; that wave
was validated by the local battery below).

## 3. Preflight for the real cut (owner GO required)

1. **Owner decides**: next version, whether to move `COMPILER_VERSION` (and
   to which accepted archive), and the tag commit.
2. **Prepare the tree** in one commit:
   - `package.xi` version bump (and compiler range if the pin moves);
   - `CHANGELOG.md` section for the version;
   - `release-notes/v<version>.md` (see the draft below);
   - docs/session snapshot.
3. **Run the release battery** on that commit with the chosen archive:
   `check_modules`, probes, smokes, `barename_scan`, `coverage_floors197`,
   `doc_baseline4`, `module_smoke_floors`, plus
   `tools/gate9_scan.ps1` (10/10 + 26 pass/1 intended T001 expected).
4. **Tag + push** `stdlib-v<version>` at the release commit; the tag triggers
   `release.yml`. If the tag is on a branch, merge it to `main --no-ff` after
   the release.
5. **Registry**: dispatch `publish-registry.yml` (tag path auto-dispatches
   the staging canary), approve the `registry-publish` environment, verify
   the package metadata (sha256, compiler field) at
   `registry.xiom-lang.org/packages/xiom-std`.
6. **Coordinate**: reply on the relay item with tag/SHA/run/registry; the
   compiler lane pins `STDLIB_VERSION` (the automated pin PR may hit the
   token-scope gap; the branch is still pushed).
7. **Tags are immutable**: never move `stdlib-v0.65.2`, `v0.65.1`, `v0.65.0`.
   Fix forward if a problem surfaces.

## 4. Draft release notes (next cut; version pending)

Title: `XIOM stdlib <version>`

Highlights:

- **Request parsing without the whole-head copies.** `net.server
  .server_parse_request` now parses directly from the request bytes using
  (start, len) spans, lowercases header names in the same copy, and
  pre-sizes the header vector. Measured over 50k parses: ~8,954 ->
  ~857 B/iteration on Windows x64 (official v0.64.8/v0.65.2 archives),
  ~1,138 B/iteration on Linux/WSL glibc. API and error semantics are
  unchanged; new probe `p_http_parse_alloc`.
- **Server-side SSE.** `sse_encode_event` / `sse_encode_comment` /
  `sse_encode_heartbeat` build LF wire frames (CR/LF injection rejected,
  multi-line data as repeated `data:` fields); `sse_write_event` /
  `sse_write_comment` / `sse_heartbeat` write them over a `TcpStream`.
  Probe `p_wave298_sse_wire` includes a real loopback write.
- **HTTP/2 connection multiplexing.** `H2Connection` + `h2_conn_*`:
  concurrency cap, local stream ids, received-GOAWAY drain (streams above
  the peer's last id are dropped, an increased last id is rejected per
  RFC 9113 6.8), and local graceful drain. This completes the h2 primitive
  layer; frame I/O stays with the caller. Probe `p_wave298_h2_conn_mux`.

Validation on 605c6a879 (Windows, 2026-10-29):

- gate-9 set **10/10**; `tools/known_failures` **30 pass + 1 intended
  T001, 0 unexpected** -> `gate9_scan` VERDICT OK.
- `p_wave162_shapes` **20/20 rc 0**; `p_borrowed_mut_grown_vec_uaf`
  **20/20 rc 0**.
- modules **533/533**; probes **418/418**; smokes **963/963**; barename
  **0/533**; coverage floors197 OK; doc **100%**; module-smoke ratchet OK.
- Compiler pin: `v0.64.8` unless the owner moves it at GO.

Registry: `xiom-std <version>`, compiler field `<pin decided at GO>`.

## 5. What is intentionally NOT done here

- No `release-notes/v<version>.md` (pending the owner's GO / version).
- No `package.xi` bump, no `COMPILER_VERSION` change, no tag, no release,
  no registry write until the owner's GO.
- The dry-run above uses the current label and creates no release.
