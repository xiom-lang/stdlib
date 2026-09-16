// XIOM - Math: Trigonometric Constants
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.trigonometric_constants

// Depends on: none

// ============================================================================
// Compile-time angle conversion factors and fractional turn constants.
// Every constant is a module-level `pub const` with a SCALAR LITERAL
// initializer (BUG 3: fn-call initializers on module globals are silently
// zero). Literals are the correctly-rounded f64/f32 of the exact real value.
// ============================================================================

/// degrees to radians conversion factor: pi/180.
pub const DEG_TO_RAD: Float64 = 0.017453292519943295;

/// radians to degrees conversion factor: 180/pi.
pub const RAD_TO_DEG: Float64 = 57.29577951308232;

/// Float32 degrees to radians conversion factor: pi/180.
pub const DEG_TO_RAD32: Float32 = 0.017453292519943295 as Float32;

/// Float32 radians to degrees conversion factor: 180/pi.
pub const RAD_TO_DEG32: Float32 = 57.29577951308232 as Float32;

/// pi/2, quarter turn.
pub const PI_2: Float64 = 1.5707963267948966;

/// pi/4, eighth turn.
pub const PI_4: Float64 = 0.7853981633974483;

/// pi/8, sixteenth turn.
pub const PI_8: Float64 = 0.39269908169872414;

/// pi/3, one-third of a half turn.
pub const PI_3: Float64 = 1.0471975511965976;

/// pi/6, twelfth turn.
pub const PI_6: Float64 = 0.5235987755982988;

/// tau/2, half turn, equals pi.
pub const TAU_2: Float64 = 3.141592653589793;

/// tau/4, quarter turn, equals pi/2.
pub const TAU_4: Float64 = 1.5707963267948966;

/// tau/8, eighth turn, equals pi/4.
pub const TAU_8: Float64 = 0.7853981633974483;

/// tau/3, third of a full turn.
pub const TAU_3: Float64 = 2.0943951023931953;

/// tau/6, sixth of a full turn, equals pi/3.
pub const TAU_6: Float64 = 1.0471975511965976;

/// tau/12, twelfth of a full turn, equals pi/6.
pub const TAU_12: Float64 = 0.5235987755982988;
