// XIOM stdlib smoke test — xiom.error
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_error
use xiom.error;

fn main() -> Int {
  var errs = Vec[Str].new();
  errs.push("smoke failure");
  let chain = error.ErrorChain{ errors: errs; };
  if chain.display().len() > 0 {
    return 0;
  }
  return 1;
}
