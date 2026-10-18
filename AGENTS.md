# AGENTS.md -- working instructions for the XIOM stdlib lane

Repository: `E:\xiom-lang\stdlib` (lane slug: `stdlib`).
Cross-lane coordination goes through the private relay bus at
`E:\xiom-lang\xiom-relays` (repo `xiom-lang/xiom-relays`). Read its
`README.md` and `PROTOCOL.md` before using it.

## Cross-lane coordination (xiom-relays)

- At session start and before finishing any task: pull xiom-relays and
  process items addressed to your lane
  (`git -C E:\xiom-lang\xiom-relays pull --ff-only` then
  `python E:\xiom-lang\xiom-relays\tools\relay.py view --lane stdlib`).
- Never edit another lane's item; open a new item instead.

The bus is one file per item under `items/`, id `REL-YYYYMMDD-HHMM-<lane>`.
Lifecycle: open -> acked -> fixed -> verified -> closed; only the addressed
lane moves open -> acked -> fixed, only the reporter moves fixed ->
verified -> closed. Link evidence (commits, run ids, file paths); never copy
logs into items. A recurring doorbell (every 2 hours) polls the bus while
this lane is active.

## Lane essentials

- Compiler pin: v0.64.5 -- use the OFFICIAL RELEASE ARCHIVE binary
  `%TEMP%\kilo\stdlib_ws\v0.64.5-official\bin\xiom.exe` for wave batteries
  (zip sha256 bd71e2d3...). TRAP: `v0.64.5-rel` (67e57dfe) is the
  2026-10-14 pre-fix candidate and `v0.64.5b-rel` (9b391ef4) the fixed
  dry-run -- verify the zip hash against the GitHub release digest; dir
  names do not indicate release status. (The shared
  `E:\xiom-lang\xiom\target\release\xiom.exe` drifted past the tag
  on 2026-10-10; see docs/failed_attempts.md.)
- Session handoff and wave history: `docs/stdlib_session.md` (snapshots at
  the top; newest wave block first in the block list).
- Open internal reproductions: `tools/known_failures/` (public evidence;
  cross-lane ones are items on the relay bus).
- Coverage ratchet: `tools/coverage_floors<NNN>.json` wired into
  `.github/workflows/{ci,heavy,release}.yml` and `tools/README.md`.
