// REL-20261030-1628: socket handle-returning externs must agree on the i64
// stdlib ABI on every target. On arm64 the pre-fix runtime defined
// xiom_socket_create/accept/close as i32-returning, so this module failed IR
// verification; on x64 it also exercises create/close at runtime.
module p_socket_ffi_width

use xiom.io;
use xiom.net.socket;

fn main() -> Int {
  let tcp = socket.socket_tcp();
  if tcp.is_err { return 1; }
  let fd = tcp.value;
  if fd < 0 { return 2; }
  socket.socket_close(fd);

  let udp = socket.socket_udp();
  if udp.is_err { return 3; }
  if udp.value < 0 { return 4; }
  socket.socket_close(udp.value);

  io.println("socket ffi width ok");
  return 0;
}
