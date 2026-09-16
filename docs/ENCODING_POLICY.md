<!--
Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# Encoding Policy: Pure ASCII for Tracked Text Files

## Policy

Every tracked text file in this repository must be **pure ASCII**
(bytes 0x00-0x7F). This prevents the recurring "mojibake" problem:
typographic Unicode characters (em dash U+2014, curly quotes U+201C/U+201D,
curly apostrophes U+2018/U+2019, arrows U+2192) that were repeatedly
double-encoded through Windows-1252 and stored as garbage (for example,
byte sequences like `C3 83 C2 A2 C3 A2 E2 82 AC ...`).

Pure ASCII guarantees:

- compiler diagnostics and generated IR are never garbled, in any terminal;
- no codepage-dependent behavior on Windows (CP437/CP850/CP1252) vs Unix;
- diffs and reviews stay clean.

## Exceptions (intentional Unicode)

A short allowlist of files whose non-ASCII is **load-bearing** is maintained
in `EXCLUDED_PREFIXES` inside `tools/ascii_guard.py`:

- `registry/` - npm-style package registry mirror (legit metadata);
- `node_modules/` - third-party data (e.g. iconv-lite encoding tables);
- `stdlib/xiom/format/numbering.xi`, `stdlib/xiom/math/number_systems.xi` -
  Chinese/Korean numeral conversion (functionality);
- `examples/stdlib_smoke/smoke_*.xi` (convert_utf, text2, string_emoji,
  string_ea_width, string_unicode, encoding_punycode) and
  `crates/xiom-codegen/tests/fuzz_tests.rs`, `tests/regression/m36_e16.xi` -
  intentional UTF-8 test data;
- `xiom-playground/lessons/`, `xiom-playground/js/lessons.js`,
  `xiom-playground/index.html` - lesson UI content (emoji icons);
- `install.ps1` - ASCII-art logo.

Add new files to this list only when the Unicode is truly intentional
(functionality or test data), and document why.

## Tooling

`tools/ascii_guard.py` (Python 3.7+, stdlib only):

| Command | Purpose |
|---------|---------|
| `python tools/ascii_guard.py check` | Fail (exit 1) if any tracked text file has non-ASCII. Used by CI. |
| `python tools/ascii_guard.py check --staged` | Same, but only staged files. Used by the pre-commit hook. |
| `python tools/ascii_guard.py repair --dry-run` | Report what would change. |
| `python tools/ascii_guard.py repair --apply` | Reverse mojibake levels and transliterate remaining non-ASCII to ASCII. |

The repair is deterministic: it round-trips CP1252 mojibake levels back to
the original characters, then transliterates (em dash `-> --`, curly quotes
`->` straight, arrows `-> ->`, accents stripped via NFKD, emoji `->` bracketed
labels such as `[OK]`, everything else `-> [U+XXXX]` for manual review).

## Enforcement

- **CI**: `.github/workflows/ci.yml` runs `python tools/ascii_guard.py check`
  on every push/PR (all 3 OSes).
- **Pre-commit hook**: `.githooks/pre-commit` runs the staged-file check.
  Enable once per clone with:
  ```
  git config core.hooksPath .githooks
  ```
- **Editors**: `.editorconfig` (`charset = utf-8`) and
  `.vscode/settings.json` (`files.encoding: utf8`,
  `files.autoGuessEncoding: false`).

## Terminal display (optional)

Diagnostics are ASCII now, but for any remaining intentional Unicode
(playground lessons etc.), use a UTF-8 terminal on Windows:
`chcp 65001` or Windows Terminal.

## History

- 2026-08: repaired ~3,170 files (~378k mojibake occurrences at levels 1-4,
  plus BOMs and CP1252-saved files). 5 blocks in `crates/xiom-codegen/src`
  were corrupted at source (mixed-level, unrecoverable) and were rewritten
  by hand from context. See `docs/audit/PHASE6_CRATE_AUDIT.md` item 10.
