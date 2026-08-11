// XIOM - Format: Tables
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.table

// Depends on: xiom.string

// ============================================================================
// Plain-text, aligned, markdown, CSV and HTML table rendering with sorting
// and cell access. NOTE: current implementation lives in fmt.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Table - a table of headers and rows of string cells with computed column widths.
// fn table_new(headers: &Vec[Str]) -> Table - create an empty table with the given headers. TODO(compiler): implement.
// fn table_add_row(t, cells: &Vec[Str]) - append a row; extra cells are truncated, missing cells pad empty. TODO(compiler): implement.
// fn table_render(t) -> Str - render the table as plain aligned text. TODO(compiler): implement.
// fn table_render_aligned(t, align: &Vec[Int]) -> Str - render with per-column alignment (left, right, center). TODO(compiler): implement.
// fn table_render_markdown(t) -> Str - render the table as a GitHub-flavored markdown table. TODO(compiler): implement.
// fn table_render_csv(t) -> Str - render the table as comma-separated values. TODO(compiler): implement.
// fn table_render_html(t) -> Str - render the table as an HTML table. TODO(compiler): implement.
// fn table_widths(t) -> Vec[Int] - the display width of each column. TODO(compiler): implement.
// fn table_rows(t) -> Int - the number of data rows. TODO(compiler): implement.
// fn table_columns(t) -> Int - the number of columns. TODO(compiler): implement.
// fn table_sort_by(t, col: Int) - sort rows in place by a column. TODO(compiler): implement.
// fn table_set_cell(t, row, col, value) - replace a single cell value. TODO(compiler): implement.
