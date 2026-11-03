# Release checklist (next stdlib tag)

Mechanical steps for cutting the next release once the readiness plan is
100% complete. `release.yml` validates the package, compiler and notes
items, so any mismatch fails the release before the gates run.

## Before tagging

1. **`main` contains the previous release** -- merge the last
   `release/vX.Y.Z-prep` branch (or sync its metadata) before starting.
   The v0.65.5 branch (`release/v0.65.5-prep`, tag `stdlib-v0.65.5`)
   landed linearly as `062d660` on 2026-11-03 (COMPILER_VERSION kept at
   v0.65.5; CHANGELOG gained the 0.65.5 section). The remote ruleset
   forbids merge commits on main -- use a linear cherry-pick/rebase.
   Do not start the next cut from a stale main.
2. **`package.xi`** -- set `version: "X.Y.Z"` to the exact tag suffix
   (`stdlib-vX.Y.Z`). Keep `compiler = ">=0.60.0 <1.0.0"` in range form;
   `release.yml` greps for `compiler = ">=`.
3. **`COMPILER_VERSION`** -- must name an *existing* compiler tag (the
   release builds that tag from source: `.github/actions/build-compiler`).
   Current pin: `v0.65.5`. For the next cut, point it at the
   then-current released compiler. Do not point it at an
   unreleased/combined compiler release; the combined compiler cut happens
   AFTER this release, when the compiler lane bumps `STDLIB_VERSION` to
   this tag.
4. **`release-notes/<tag>.md`** -- present and schema-valid (website
   contract `xiom-lang/website/docs/release-notes-schema.md`): Summary
   <= 240 chars, plain ASCII, no internal IDs; highlights are `### Title` +
   `kind:` + body (<= 320 chars, title <= 60). The compiler release merges
   these with its own; the merged document must keep <= 6 highlights, and
   the compiler lane's draft already carries 4, so the stdlib fragment must
   stay at **2** highlights.
   Next draft: `release-notes/v0.65.5.md` (2 highlights; drafted on
   `release/v0.65.5-prep`, merged on GO).
   Run the compiler's validator locally BEFORE tagging (it is the
   authority; the v0.64.3 fragment failed it three times -- arrows, an
   `(mNNN)` token, and a `&`):
   ```
   cargo run -q -p xiom-release-notes -- convert --tag <tag> --stdlib <stdlib checkout>
   ```
   It validates highlights AND known issues: no `>` `<` `&` or backtick in
   plain text (spell arrows as "to"), no internal task ids (tokens like
   `m242`/`r123`), plain ASCII.
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
   release (the next candidate, v0.65.5).

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
