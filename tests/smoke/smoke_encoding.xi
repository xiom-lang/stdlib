// XIOM stdlib smoke test — xiom.encoding
// base64_encode known-answer: "hello" -> "aGVsbG8=".
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_encoding
use xiom.encoding;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push(104); // h
  data.push(101); // e
  data.push(108); // l
  data.push(108); // l
  data.push(111); // o
  var encoded = xiom.encoding.base64_encode(&data);
  if encoded == "aGVsbG8=" {
    return 0;
  }
  return 1;
}
