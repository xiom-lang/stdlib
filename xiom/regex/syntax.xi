// XIOM - Regex: Syntax
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.regex.syntax

// Depends on: xiom.string

// ============================================================================
// Regex pattern syntax utilities: escape, parse, validate, build blocks.
// NOTE: current implementation lives in regex.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn regex_escape(s: Str) -> Str - escape every metacharacter so s matches literally. TODO(compiler): implement.
// fn regex_unescape(s: Str) -> Result[Str, Str] - decode escape sequences back to plain text, or Err. TODO(compiler): implement.
// fn regex_parse(pattern: Str) -> Result[Ast, Str] - parse into an AST (Ast is the regex syntax tree struct), or Err. TODO(compiler): implement.
// fn regex_validate(pattern: Str) -> Bool - true if the pattern is syntactically valid. TODO(compiler): implement.
// fn regex_syntax_error(pattern) -> Option[Str] - first syntax error message, or None if valid. TODO(compiler): implement.
// fn regex_character_class(name: Str) -> Str - pattern text for a named class such as alpha, digit, space. TODO(compiler): implement.
// fn regex_quantifier(min: Int, max: Int) -> Str - pattern text for a {min,max} quantifier. TODO(compiler): implement.
