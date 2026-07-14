// XIOM stdlib smoke test — xiom.net
// Does NOT open sockets: constructs a NetError value and checks its fields.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net
use xiom.net;
use xiom.net.NetError;

fn main() -> Int {
  let e = NetError{ message: "smoke"; code: -100; };
  if e.code == -100 && e.message == "smoke" {
    return 0;
  }
  return 1;
}
