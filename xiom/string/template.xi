// XIOM - String: Template
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.template

// Depends on: xiom.string

// ============================================================================
// Named-placeholder string templates. Placeholders look like {{name}} and are
// substituted from a map of values. Compilation separates the source text from
// its placeholder list so one template can be rendered repeatedly without a
// re-parse. Pure, zero dependencies.
// ============================================================================

// --- Template type and compilation ---

// Template struct (planned): holds `source: Str` (the original template text)
// and `placeholders: Vec[Str]` (the distinct named placeholders it contains).
// Constructed only by template_compile; consumed by template_render_compiled.
// type Template = { source: Str; placeholders: Vec[Str]; } TODO(compiler): implement.

// fn template_compile(tpl: Str) -> Result[Template, Str] - parse tpl into a Template, Err on malformed placeholders. TODO(compiler): implement.
// fn template_render_compiled(t: &Template, values: &Map) -> Result[Str, Str] - render a compiled template using values. TODO(compiler): implement.

// --- Rendering ---

// fn template_render(tpl: Str, values: &Map) -> Result[Str, Str] - parse and render tpl, substituting placeholders from values. TODO(compiler): implement.
// fn template_render_map(tpl: Str, keys: &Vec[Str], values: &Vec[Str]) -> Result[Str, Str] - render tpl, pairing keys with values positionally. TODO(compiler): implement.
// fn template_render_fallback(tpl: Str, values: &Map, fallback: Str) -> Result[Str, Str] - render tpl, using fallback for placeholders missing from values. TODO(compiler): implement.
// fn template_render_strict(tpl: Str, values: &Map) -> Result[Str, Str] - render tpl, Err when any placeholder is missing from values. TODO(compiler): implement.

// --- Placeholder inspection and escaping ---

// fn template_escape(s: Str) -> Str - escape literal text so "{{" and "}}" render verbatim. TODO(compiler): implement.
// fn template_unescape(s: Str) -> Str - reverse of template_escape, restoring "{{" and "}}". TODO(compiler): implement.
// fn template_has_placeholders(tpl: Str) -> Bool - true when tpl contains at least one "{{name}}" placeholder. TODO(compiler): implement.
// fn template_placeholders(tpl: Str) -> Vec[Str] - distinct placeholder names in tpl, in first-seen order. TODO(compiler): implement.
// fn template_placeholder_count(tpl: Str) -> Int - total number of placeholder occurrences in tpl. TODO(compiler): implement.
// fn template_validate(tpl: Str) -> Result[(), Str] - check tpl for balanced, well-formed placeholders. TODO(compiler): implement.
