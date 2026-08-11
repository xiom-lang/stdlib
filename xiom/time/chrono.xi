// XIOM - Time: Chrono
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.time.chrono

// Depends on: xiom.time

// ============================================================================
// Calendar-aware DateTime values with civil arithmetic and timezones.
// NOTE: current implementation lives in time.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type DateTime - a calendar date plus time-of-day and weekday.
// fn chrono_now() -> DateTime - the current local date and time. TODO(compiler): implement.
// fn chrono_from_timestamp(ts: Int) -> DateTime - the DateTime at Unix timestamp ts. TODO(compiler): implement.
// fn chrono_to_timestamp(dt) -> Int - the Unix timestamp of dt. TODO(compiler): implement.
// fn chrono_add_seconds(dt, n) -> DateTime - dt advanced by n seconds. TODO(compiler): implement.
// fn chrono_add_days(dt, n) -> DateTime - dt advanced by n days. TODO(compiler): implement.
// fn chrono_add_months(dt, n) -> DateTime - dt advanced by n months, clamping the day. TODO(compiler): implement.
// fn chrono_add_years(dt, n) -> DateTime - dt advanced by n years, clamping Feb 29. TODO(compiler): implement.
// fn chrono_diff(a, b) -> Duration - the elapsed time between a and b. TODO(compiler): implement.
// fn chrono_weekday(dt) -> Int - the day of the week of dt. TODO(compiler): implement.
// fn chrono_compare(a, b) -> Int - negative, zero, or positive for a before, equal, after b. TODO(compiler): implement.
// fn chrono_timezone_offset(dt) -> Int - the UTC offset of dt in seconds. TODO(compiler): implement.
// fn chrono_utc_now() -> DateTime - the current UTC date and time. TODO(compiler): implement.
