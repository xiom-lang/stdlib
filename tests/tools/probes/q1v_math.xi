// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module q1v_math
use xiom.math;
fn main() -> Int { var x = math.sin(1.0); if x < 0.5 { return 1; } return 0; }
