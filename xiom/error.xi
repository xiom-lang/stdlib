// XIOM — Error Trait Hierarchy
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.error

pub interface Error {
  fn source(self) -> Option<Error>;
  fn description(self) -> Str;
  fn cause(self) -> Option<Error>; // alias for source
}

pub type ErrorChain = { errors: Vec<Str>; } derive[Clone]
pub fn Error.chain(self) -> ErrorChain;
pub fn ErrorChain.display(self) -> Str;

pub fn wrap_error[T, E: Error](result: Result[T, E], context: Str) -> Result[T, Str];
pub fn context[T, E](result: Result[T, E], msg: Str) -> Result[T, Str];

pub type Backtrace = { frames: Vec<Str>; } derive[Clone]
pub fn capture_backtrace() -> Backtrace;
pub fn Backtrace.display(self) -> Str;
