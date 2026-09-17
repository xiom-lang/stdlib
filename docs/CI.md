# CI credentials and cross-repo policy

Short version of the org policy that applies to the stdlib workflows.

## Tokens

| Name | Scope | Used for | Status |
|---|---|---|---|
| `XIOM_RELEASE_TOKEN` | fine-grained PAT: Contents read/write on `xiom-lang/xiom` + `xiom-lang/stdlib` | writes from CI: the `STDLIB_VERSION` pin PR in `release.yml` | org secret, set |
| `REGISTRY_PUBLISH_TOKEN` | registry publish auth | `xiom pkg publish` in `publish-registry.yml` | org secret, created after registry staging is live |
| `XIOM_CROSS_REPO_TOKEN` | (legacy) `xiom-lang/xiom` read | nothing -- kept only for other lanes while they migrate | set, but NOT used here |

Rules:

- Any step that writes uses `${{ secrets.XIOM_RELEASE_TOKEN || secrets.GITHUB_TOKEN }}`.
- Tokens are **org secrets, never repo-level**.
- `xiom-lang/xiom` is public: compiler checkouts and release-asset downloads
  are anonymous. Do not add `XIOM_CROSS_REPO_TOKEN` back into workflows.
- `MINISIGN_SECRET_KEY` is **deferred** (key ceremony pending). Releases ship
  `SHA256SUMS` plus a GitHub build-provenance attestation
  (`actions/attest-build-provenance`). Do not reference minisign.

## Cross-repo pieces

- `.github/actions/build-compiler`: anonymous clone of `xiom-lang/xiom` at
  the `COMPILER_VERSION` pin and a debug build. Workaround included for tags
  that predate the `resource/` asset fix (`e3714884`).
- `release.yml`: on `stdlib-v*` tags -- validate `package.xi`, run the gates
  on Windows + Linux, tar `xiom/ runtime/ package.xi` (+ licenses/README/
  CHANGELOG), `SHA256SUMS`, attest, GitHub Release, then the pin PR to xiom.
- `publish-registry.yml`: **dispatch only** until staging is verified. Takes
  the stdlib release version, resolves the compiler pin from `COMPILER_VERSION`
  at the matching tag, downloads the public release assets, and runs
  `xiom pkg publish` with `XIOM_REGISTRY` / `XIOM_REGISTRY_TOKEN`.

## Gate matrix

| Workflow | Trigger | Runs |
|---|---|---|
| `ci.yml` | PR + dispatch | coverage ratchet, pinned compiler build, check-modules, bare-name scan, KAT |
| `heavy.yml` | weekly + dispatch | full corpus on Windows + Linux, check-modules, bare-name, ratchet; scheduled runs test compiler `main` |
| `release.yml` | `stdlib-v*` tag + dispatch | validate, full gates on both OSes, package + attest + release + pin PR |
| `publish-registry.yml` | dispatch only | registry publish |
