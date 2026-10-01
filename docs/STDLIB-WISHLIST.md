# Stdlib wishlist (packages/consumers -> stdlib lane)

Intake record for feature and defect requests relayed by the packages lane.
Source of record: the packages lane's `docs/STDLIB-WISHLIST.md` sheet; this
file mirrors the rows relayed on 2026-10-01 so they survive lane handoffs.
Rows are informational until a stdlib wave picks them up; defects are
fix-first.

Status legend: **open** = not started; **fixed** = landed with a probe lock
(commit noted); **declined** = with reason.

| # | Item | Kind | Notes | Status |
|---|------|------|-------|--------|
| 1 | `str_contains` / `index_of` empty-needle contract violation | defect | `string.index_of` carried `requires: substr.len() > 0` while its body returned `Some(0)` for an empty needle and `str_contains` delegates to it; same contradiction on `string.str_index_of` (doc promises `Some(0)`) and `str_replace_all` (doc promises `s` unchanged; `replace` handles it). Fixed by removing the three preconditions and adding empty-needle `ensures` (`p_empty_needle_contracts.xi`). `string.str_split`'s delimiter precondition is genuine (no empty-delimiter promise) and stays. | **fixed** (2026-10-01) |
| 2 | Allocation-free line accessors | enhancement | Iterate lines without allocating a new `Str` per line (byte-range or cursor view), for line scanners on large inputs. | open |
| 3 | Keyed FIFO / mailboxes | feature | FIFO queues addressable by key (multiple logical mailboxes over one structure), with the same non-blocking semantics as the existing queue helpers. | open |
| 4 | Stable argmax | feature | Index of the maximum with first-wins stability and documented NaN policy (match the stats module's conventions). | open |
| 5 | Event-log cursors | feature | Opaque cursor over an append-only event log: read-new-since-cursor without copying the whole log. | open |
| 6 | Composite-key lookups | feature | Map/set lookups on multi-field keys (struct keys or tuple keys) without manual string packing. | open |
| 7 | Non-aborting assertion catalog | feature | Test-assertion helpers that report failures and continue (collect-all mode) instead of aborting on the first failure, for packages' conformance suites. | open |
| 8 | Fixed-point MSE | feature | Mean squared error for the fixed-point numeric types, matching the float stats MSE semantics. | open |

The relay summary named 8 of the ~11 rows (the remainder land when the
packages sheet is forwarded). The packages lane's other 2026-10-01 notes
(catalog bugs obs-fold trimming and `max-age=abc` were package-side and
fixed there; `str_replace_all` proved useful for policy rewriting; avoid
`==` on Result values in tests -- no guaranteed `Eq`) need no stdlib action
beyond row 1.
