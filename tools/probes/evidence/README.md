# Probe evidence archive (excluded from the probe runner)

Files here are kept for reference only. They are **not** part of the probe
gate: `run_smokes.ps1 -Corpus tools/probes` does not recurse, so this
subdirectory is invisible to it. Each file below fails on compiler R52
(2026-09-21) in a way that is already understood, superseded by a green
probe, or deliberate evidence -- none is an open compiler defect. Open
findings live in `tools/known_failures/`.

| File | Why it is archived |
|---|---|
| `p_alg_ext_b.xi` | Duplicate of the green `p_alg_ext_a.xi`; the only defect is the omitted `use xiom.io;` (T001 undefined variable 'io'). |
| `p_char_count.xi` | Expects `Option[Char]` from the byte-domain `.char_at` Char form; the working idiom is locked by the green `p_charat_probe.xi`. |
| `p_glob_min.xi` | Uses an invalid `Bool as Str` cast; the modern form (`convert.bool_to_string`) is locked by the green `p_glob_parity.xi`. |
| `p_mime_lock.xi` | Calls `multipart_*` through `xiom.net.mime`; the symbols live in `xiom.net.multipart` and the green `p_mime_lock2.xi` locks them. |
| `p_optmatch.xi` | Uses leaf-qualified type spelling (`regex.Match`), which the resolver never supported; the supported `use <module>.<Type>;` idiom is locked by the green `p_optstruct.xi`. |
| `p_parttype.xi` | Same leaf-qualified-type issue plus a missing `use xiom.io;`; the parse side is covered by `smoke_net_http2`. |
| `p_regex_dbg.xi` | Written against the pre-`Result` `Regex.new` shape; superseded by the green `p_regex_dbg4.xi` / `p_regex_dbg5.xi`. |
| `p_regex_dbg2.xi` | Same pre-`Result` shape; superseded by `p_regex_dbg4/5`. |
| `p_regex_dbg3.xi` | Same pre-`Result` shape; superseded by `p_regex_dbg4/5`. |
| `p_puny_parity.xi` | Deliberate parity evidence: prints 10/16 shared vectors that differ by convention (ACE-label vs raw-payload), documented as NOT a bug; the convert-side convention is pinned by `smoke_convert_punycode`. |
| `p_regex_val.xi` | Asserts group captures. Group support is a documented honest stub (whole-match only); whole-match captures are locked by the green `p_regex_dbg5.xi`. |
