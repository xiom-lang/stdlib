// p_http_resp_codegen.xi -- minimal probe for the http_parse_response
// codegen failure found 2026-09-17 by smoke_stress_fuzz_parsers.
// Expected (correct): compiles and prints 0.
// Observed on compiler tag v0.60.0: clang rejects the emitted IR with
// "invalid getelementptr indices" on %struct.HttpResponse field 2.
// Ownership: compiler lane -- record with this probe.
module p_http_resp_codegen
use xiom.net.http;

fn main() -> Int {
  let raw = "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello";
  let r = http_parse_response(raw);
  match r {
    Ok(_) => { return 0; },
    Err(_) => { return 1; },
  }
}
