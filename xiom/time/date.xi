// XIOM - Time: Date
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.time.date

// Depends on: xiom.time

// ============================================================================
// Proleptic Gregorian calendar dates with day arithmetic.
// NOTE: current implementation lives in time.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Date - a calendar date of year, month, and day.
// fn date_new(year, month, day) -> Date - build a Date from its fields. TODO(compiler): implement.
// fn date_now() -> Date - today's date from the system clock. TODO(compiler): implement.
// fn date_from_timestamp(ts: Int) -> Date - the date at Unix timestamp ts (UTC). TODO(compiler): implement.
// fn date_to_timestamp(d) -> Int - the Unix timestamp at midnight UTC of d. TODO(compiler): implement.
// fn date_weekday(d) -> Int - the day of the week of d (0 = Sunday). TODO(compiler): implement.
// fn date_day_of_year(d) -> Int - the ordinal day of the year (1-366). TODO(compiler): implement.
// fn date_day_of_month(d) -> Int - the day-of-month field of d. TODO(compiler): implement.
// fn date_days_in_month(year, month) -> Int - the number of days in that month. TODO(compiler): implement.
// fn date_is_leap(year) -> Bool - true if year is a leap year. TODO(compiler): implement.
// fn date_add_days(d, n) -> Date - d offset by n days. TODO(compiler): implement.
// fn date_sub_days(d, n) -> Date - d offset by -n days. TODO(compiler): implement.
// fn date_diff_days(a, b) -> Int - the number of days between a and b (a - b). TODO(compiler): implement.
// fn date_compare(a, b) -> Int - negative, zero, or positive for a before, equal, after b. TODO(compiler): implement.
