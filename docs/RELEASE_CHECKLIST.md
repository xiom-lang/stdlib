# Release checklist (next stdlib tag)

Mechanical steps for cutting the next release once the readiness plan is
100% complete. `release.yml` validates the first three items, so any
mismatch fails the release before the gates run.

## Before tagging

1. **`package.xi`** -- set `version: "X.Y.Z"` to the exact tag suffix
   (`stdlib-vX.Y.Z`). Keep `compiler = ">=0.60.0 <1.0.0"` in range form;
   `release.yml` greps for `compiler = ">=`.
2. **`COMPILER_VERSION`** -- must name an *existing* compiler tag (the
   release builds that tag from source: `.github/actions/build-compiler`).
   Current pin: `v0.61.3`. Do not point it at an unreleased/combined
   compiler release; the combined compiler cut happens AFTER this release,
   when the compiler lane bumps `STDLIB_VERSION` to this tag.
3. **`release-notes/<tag>.md`** -- present and schema-valid (website
   contract `xiom-lang/website/docs/release-notes-schema.md`): Summary
   <= 240 chars, plain ASCII, no internal IDs; highlights are `### Title` +
   `kind:` + body (<= 320 chars, title <= 60). The compiler release merges
   these with its own; the merged document must keep <= 6 highlights, and
   the compiler lane's v0.62.0 draft already carries 4, so the stdlib
   fragment must stay at **2** highlights.
   Current draft: `release-notes/v0.62.0.md` (2 highlights).
4. **`CHANGELOG.md`** -- move `## [Unreleased]` entries under
   `## [X.Y.Z] - YYYY-MM-DD` (Keep a Changelog layout).
5. **Local gate battery** (must be green on the exact commit):
   ```
   powershell -NoProfile -File tools/check_modules.ps1  -Compiler <pin build>
   powershell -NoProfile -File tools/run_smokes.ps1     -Compiler <pin build> -Workers 8 -RetryFailed
   powershell -NoProfile -File tools/run_smokes.ps1     -Compiler <pin build> -Corpus tools/probes -Workers 8 -RetryFailed
   powershell -NoProfile -File tools/barename_scan.ps1 -Compiler <pin build> -Workers 8
   powershell -NoProfile -File tools/coverage_scan.ps1 -RatchetFile tools/coverage_floors<N>.json
   powershell -NoProfile -File tools/doc_scan.ps1      -RatchetFile tools/doc_baseline4.json
   ```
6. **Author identity** -- `git log -1 --format='%an <%ae>'` must print
   `Lefteris Notas <lefterisnotas@gmail.com>`.

## Tag and publish

7. Tag `stdlib-vX.Y.Z` on the reviewed commit and push it **only when the
   release lane says so**; the tag push triggers `release.yml` (validate ->
   Windows + Linux gates -> deterministic tarball + SHA256SUMS -> attested
   GitHub Release -> compiler pin PR).
8. Registry publish (`publish-registry.yml` dispatch) after the release,
   then the staging canary. Assets are byte-reproducible now, so a re-run
   no longer changes the digest; re-canary only if an asset is regenerated.
9. Hand off to the compiler lane: they bump `STDLIB_VERSION` to this tag,
   run the full gate list on the pin, and cut the single combined compiler
   release (v0.62.0).

## Open pin-related dependencies (not blockers for tagging)

- **Registry compiler-pin correlation: RESOLVED (2026-09-25).** The
  `xiom pkg` client has emitted the per-version `compiler` field since m128
  (`--compiler <tag>` wins over a manifest `compiler:` field), and
  `publish-registry.yml` now passes
  `--compiler "$(COMPILER_VERSION at the tag)"` explicitly, so the pin
  travels with the publish and cannot drift from the release pin. Nothing
  to add to `package.xi` (the `compiler = ">=..."` range line stays for
  `release.yml` validation). `xiom-std@0.61.3` predates this and carries no
  compiler value.
- **publish-existing-tarball mode** (registry lane): would make registry
  bytes equal the release asset bytes; the release asset itself is already
  deterministic.
