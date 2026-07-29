// XIOM — Error Trait Hierarchy
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.error

pub interface Error {
  fn source(self) -> Option<Error>;
  fn description(self) -> Str;
  fn message(&self) -> Str { return self.description(); }  // M20: default alias
  fn cause(self) -> Option<Error>; // alias for source
}

pub type ErrorChain = { errors: Vec<Str>; } derive[Clone]

pub fn Error.chain(self) -> ErrorChain
  ensures: result.errors.len() >= 1
{
  var errors: Vec<Str> = Vec[Str].new();
  errors.push(self.description());
  var opt = self.source();
  while opt.is_some {
    errors.push(opt.value.description());
    opt = opt.value.source();
  };
  return ErrorChain{ errors: errors };
}

pub fn ErrorChain.display(self) -> Str {
  var result: Str = "";
  var i: Int = 0;
  while i < self.errors.len() {
    if i > 0 {
      result = result + ": ";
    }
    result = result + self.errors[i];
    i = i + 1;
  };
  return result;
}

pub fn wrap_error[T, E: Error](result: Result[T, E], context: Str) -> Result[T, Str] {
  match result {
    Ok(v) => { return Ok(v); }
    Err(e) => {
      var msg: Str = context + ": " + e.description();
      return Err(msg);
    }
  }
}

pub fn context[T, E](result: Result[T, E], msg: Str) -> Result[T, Str] {
  match result {
    Ok(v) => { return Ok(v); }
    Err(_) => { return Err(msg); }
  }
}

pub type Backtrace = { frames: Vec<Str>; } derive[Clone]

pub fn capture_backtrace() -> Backtrace {
  return Backtrace{ frames: Vec[Str].new() };
}

pub fn Backtrace.display(self) -> Str {
  if self.frames.len() == 0 {
    return "";
  }
  var result: Str = "";
  var i: Int = 0;
  while i < self.frames.len() {
    if i > 0 {
      result = result + "\n";
    }
    result = result + self.frames[i];
    i = i + 1;
  };
  return result;
}
