// p_result_payload_contract.xi -- minimal repro (compiler main R46b 504fcc1e).
// Fails codegen when ONE module declares two Result-returning functions whose
// ensures clauses READ THE PAYLOAD (`result.value`) and the payload
// lowerings differ: a scalar payload (Int -> i64) plus a Vec payload
// (-> %struct.Vec). clang then rejects the IR with:
//   error: '%tmpNN' defined with type '%struct.Vec = { ptr, i64, i64, i64 }'
//   but expected 'ptr'   (call i64 @xiom_str_len(i8* %tmpNN))
// Either function compiles alone; the pair is the trigger. The Err-payload
// form (`result is Err => result.value.len() > 0`) fails the same way when
// combined with a Vec-payload contract.
module p_result_payload_contract

fn scalar_payload(n: Int) -> Result[Int, Str]
  ensures: result is Ok => result.value >= 0
{
  if n < 0 { return Err("neg"); }
  return Ok(n);
}

fn vec_payload() -> Result[Vec[UInt8], Str]
  ensures: result is Ok => result.value.len() >= 0
{
  return Ok(Vec[UInt8].new());
}

fn main() -> Int {
  return 0;
}
