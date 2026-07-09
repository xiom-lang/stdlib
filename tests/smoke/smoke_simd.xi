// NOTE: link/run smoke only
// XIOM stdlib smoke test - xiom.simd
// Link-safe capability query + real ISA constants (scalar/detection path only).
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_simd
use xiom.simd;

fn main() -> Int {
  let _ = simd.simd_supported();
  if simd.SIMD_SSE == 1 && simd.SIMD_AVX == 4 {
    return 0;
  }
  return 1;
}
