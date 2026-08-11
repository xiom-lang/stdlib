// XIOM - Format: Units
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.units

// Depends on: xiom.string

// ============================================================================
// Human-readable formatting of bytes, bits, percentages, ratios, SI and
// binary prefixes, temperature, currency, duration and frequency. NOTE:
// current implementation lives in fmt.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn format_bytes(bytes: Int) -> Str - decimal byte size with unit suffix (KB, MB, GB). TODO(compiler): implement.
// fn format_bytes_binary(bytes: Int) -> Str - binary byte size with unit suffix (KiB, MiB, GiB). TODO(compiler): implement.
// fn format_bits(bits: Int) -> Str - bit count with unit suffix (Kb, Mb, Gb). TODO(compiler): implement.
// fn format_percent(f: Float64, decimals: Int) -> Str - format a fraction in [0,1] as a percentage. TODO(compiler): implement.
// fn format_ratio(num, den) -> Str - format num/den as a ratio, handling zero denominators. TODO(compiler): implement.
// fn format_scientific(f: Float64, prec: Int) -> Str - scientific notation with the given precision. TODO(compiler): implement.
// fn format_engineering(f: Float64) -> Str - engineering notation with exponents as multiples of three. TODO(compiler): implement.
// fn format_si(f: Float64, unit: Str) -> Str - value with an SI prefix (k, M, G) and unit. TODO(compiler): implement.
// fn format_binary_prefix(f: Float64, unit: Str) -> Str - value with a binary prefix (Ki, Mi, Gi) and unit. TODO(compiler): implement.
// fn format_temperature_celsius(c: Float64) -> Str - degrees Celsius with the degree sign and C suffix. TODO(compiler): implement.
// fn format_temperature_fahrenheit(f: Float64) -> Str - degrees Fahrenheit with the degree sign and F suffix. TODO(compiler): implement.
// fn format_currency(amount_cents: Int, currency: Str) -> Str - integer cents as a localized currency string. TODO(compiler): implement.
// fn format_seconds(secs: Int) -> Str - seconds as a compact human duration (e.g. 1h 2m 3s). TODO(compiler): implement.
// fn format_ms(ms: Int) -> Str - milliseconds as a compact human duration. TODO(compiler): implement.
// fn format_hertz(hz: Float64) -> Str - frequency with unit suffix (Hz, kHz, MHz, GHz). TODO(compiler): implement.
// fn format_percent_sign(f: Float64) -> Str - percentage with a percent sign and no decimals. TODO(compiler): implement.
