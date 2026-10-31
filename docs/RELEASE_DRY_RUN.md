# Release dry-run (next stdlib cut)

Status: **no tag, no release, no registry write.** This document is the
pre-cut package: what the workflow does, the dry-run that was executed, the
exact GO checklist, and a draft of the next release notes. The version
number and `COMPILER_VERSION` pin are the owner's decision.

**Verified candidate (2026-10-31):** stdlib main `1a17405` (code) on top of
`a0e91cd`; docs head `7620c64`. The tree carries two post-v0.65.4
deliverables: the persistent worker pool with real arguments (`a0e91cd`)
and the engine P1/P2 gaps (`1a17405`). Neither is in v0.65.4/d267317.

**Prepared branch (2026-10-31):** `release/v0.65.5-prep` carries the
owner-decision proposal in one commit: `package.xi` 0.65.5,
`COMPILER_VERSION` v0.65.4, CHANGELOG [0.65.5], and
`release-notes/v0.65.5.md` (two highlights; the local validator merges it
green against a placeholder compiler file). Main is NOT bumped: merge and
tag only on the owner's GO. No tag, release, or registry write exists for
0.65.5.

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

The v0.65.5 dry-run was dispatched on `release/v0.65.5-prep` with
`version=0.65.5` and no `tag` input: run **41217827358** completed
**success** on 2026-10-31T16:57:36Z.

- **validate package.xi**: green (version 0.65.5, compiler range).
- **release gates (windows-latest)**: green, 16:04 to 16:57 (compiler build,
  smoke corpus, modules, barename, coverage, module-smoke).
- **release gates (ubuntu-latest)**: green, 16:04 to 16:44.
- **package**: green (deterministic tarball, SHA256SUMS, attestation).
- **Create GitHub Release**: SKIPPED (no tag input).
- **STDLIB_VERSION pin PR**: SKIPPED.
- **staging registry canary**: SKIPPED.

No release, pin PR, or registry write was created. The earlier `0.65.2`
dry-run (40683465791) also passed and remains history.

Local battery on the candidate tree with the official v0.65.4 windows-x64
archive and `XIOM_STDLIB` set to this checkout:

- probes **422/422** (new `p_engine_p1p2_gaps` included)
- smokes **963/963**
- modules **533/533**
- barename **0/533**
- gate9 **OK**: 10/10 + 30 known-failure pass + 1 intended T001, 0
  unexpected
- coverage `coverage_floors197` **OK** (io and collections 100%)
- `doc_baseline4` **100%**, module-smoke ratchet **OK**

## 3. Preflight for the real cut (owner GO required)

1. **Owner decides**: the version label (proposed `0.65.5`), whether to move
   `COMPILER_VERSION` (proposed `v0.65.4`, the current released compiler;
   main still says `v0.64.8`), and the tag commit.
2. **Prepare the tree** in one commit (drafted on
   `release/v0.65.5-prep`; merge it or re-cut on GO):
   - `package.xi` version bump (and compiler range if the pin moves);
   - `CHANGELOG.md` section for the version;
   - `release-notes/v<version>.md` (see the draft below; two highlights);
   - docs/session snapshot.
3. **Run the release battery** on that commit with the chosen archive:
   `check_modules`, probes, smokes, `barename_scan`, `coverage_floors197`,
   `doc_baseline4`, `module_smoke_floors`, plus `tools/gate9_scan.ps1`
   (10/10 + 30 pass/1 intended T001 expected).
4. **Tag + push** `stdlib-v<version>` at the release commit; the tag triggers
   `release.yml`. If the tag is on a branch, merge it to `main --no-ff` after
   the release.
5. **Registry**: dispatch `publish-registry.yml` (the tag path auto-dispatches
   the staging canary), approve the `registry-publish` environment, verify the
   package metadata (sha256, compiler field) at
   `registry.xiom-lang.org/packages/xiom-std`. Record the intended compiler
   at the FIRST publish: move `COMPILER_VERSION` to `v0.65.4` before
   tagging, or pass `compiler=v0.65.4` on that first dispatch. Do not plan
   a post-publish override: versions are immutable and a re-publish returns
   409 `version_exists`, so the already-live 0.65.4 record (compiler
   `v0.64.8`) cannot be corrected through the publish API
   (REL-20261031-1554-stdlib).
6. **Coordinate**: reply on the relay item with tag/SHA/run/registry; the
   compiler lane pins `STDLIB_VERSION=stdlib-v<version>` (the automated pin
   PR may hit the token-scope gap; the branch is still pushed). The
   coordination item for this candidate is REL-20261031-1542-stdlib.
7. **Tags are immutable**: never move a released tag. Fix forward if a
   problem surfaces.

## 4. Draft release notes (next cut; two highlights)

Title: `XIOM stdlib <version>`

Summary (<=240 chars): The standard library ships the persistent worker
pool and real thread arguments, plus a flushed stderr diagnostics sink,
lexical path normalization, and the last small Vec mutators. No breaking
changes.

Highlights:

### Persistent worker pool and real thread arguments

kind: stdlib

thread.pool now owns a persistent OS worker fleet with a bounded FIFO
queue, a true join, and a shutdown drain. tp_submit_with runs f(arg) on a
worker, and thread.spawn_with is a real OS thread with its argument. Named
or top-level jobs only. Probes p_wave_workerpool, p_wave145, p_wave153;
Windows 30/30 and Linux 5/5.

### Diagnostics sink and path ergonomics

kind: stdlib

io.eprintln writes one flushed stderr line and io.flush_stderr exposes the
explicit flush, so a later crash cannot lose the marker. io.normalize_path
cleans separators and dot segments, and io.join_paths treats backslash as a
separator. Vec gains swap_remove and a sort_by method. Probe
p_engine_p1p2_gaps.

## Breaking changes

- None.

## Known issues

- The compiler drop-family residual (REL-20261020-1704) still retains
  memory under repeated JSON build/parse/stringify; this is compiler-side.
- macOS and BSD event-loop support still returns an explicit error until the
  kqueue backend lands; it is gated on a green macOS witness.
- Contract coverage remains partial in the documented no-clause tail (iter,
  os, math, thread, ffi, serialize, format).
- A by-value function passed where a by-reference fn is required is still
  accepted by the compiler and misreads the payload on v0.65.4
  (REL-20261031-1552-stdlib); declare predicate parameters with a reference
  until fixed.
- The battery above uses the v0.65.4 official archive. The pin for the real
  cut is the owner's choice at GO; `COMPILER_VERSION` is currently v0.64.8.

## 5. What is intentionally NOT done here

- No `release-notes/v<version>.md` (pending the owner's GO / version).
- No `package.xi` bump, no `COMPILER_VERSION` change, no tag, no release,
  no registry write until the owner's GO.
- The local battery above creates no release and touches no registry.
