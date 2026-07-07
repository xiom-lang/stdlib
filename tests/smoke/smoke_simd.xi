// NOTE: link/run smoke only
// XIOM stdlib smoke test — xiom.simd
// Link-safe capability query + real ISA constants (scalar/detection path only).
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_simd
use xiom.simd;

fn main() -> Int {
  let _ = simd_supported();
  if SIMD_SSE == 1 && SIMD_AVX == 4 {
    return 0;
  }
  return 1;
}
