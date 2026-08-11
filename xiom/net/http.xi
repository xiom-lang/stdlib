// XIOM - Networking: HTTP Client
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.http

// Depends on: xiom.net + xiom.string

// ============================================================================
// HTTP client with GET/POST/PUT/DELETE/HEAD/PATCH requests, status, header and
// body access, redirect following, and URL percent-encoding. NOTE: current
// implementation lives in net.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// type HttpResponse - an HTTP response: status code (Int), headers, and raw body bytes.
// fn http_get(url: Str) -> Result[HttpResponse, Str] - perform an HTTP GET request. TODO(compiler): implement.
// fn http_post(url: Str, body: &Vec[UInt8]) -> Result[HttpResponse, Str] - perform an HTTP POST with a raw byte body. TODO(compiler): implement.
// fn http_put(url, body) -> Result[HttpResponse, Str] - perform an HTTP PUT with a raw byte body. TODO(compiler): implement.
// fn http_delete(url) -> Result[HttpResponse, Str] - perform an HTTP DELETE request. TODO(compiler): implement.
// fn http_head(url) -> Result[HttpResponse, Str] - perform an HTTP HEAD request. TODO(compiler): implement.
// fn http_patch(url, body) -> Result[HttpResponse, Str] - perform an HTTP PATCH with a raw byte body. TODO(compiler): implement.
// fn http_get_text(url) -> Result[Str, Str] - GET and return the response body decoded as text. TODO(compiler): implement.
// fn http_get_bytes(url) -> Result[Vec[UInt8], Str] - GET and return the raw response body bytes. TODO(compiler): implement.
// fn http_status_code(resp) -> Int - the HTTP status code of a response. TODO(compiler): implement.
// fn http_status_text(code: Int) -> Str - the standard reason phrase for a status code. TODO(compiler): implement.
// fn http_header(resp, name: Str) -> Option[Str] - the value of a named response header, if present. TODO(compiler): implement.
// fn http_body_text(resp) -> Str - the response body decoded as text. TODO(compiler): implement.
// fn http_redirect_follow(url, max: Int) -> Result[HttpResponse, Str] - follow up to max redirects before returning the final response. TODO(compiler): implement.
// fn http_request(method: Str, url: Str, headers: &Vec[(Str, Str)], body: &Vec[UInt8]) -> Result[HttpResponse, Str] - generic request; each tuple is a (name, value) header pair. TODO(compiler): implement.
// fn http_url_encode(s: Str) -> Str - percent-encode a string for use in a URL. TODO(compiler): implement.
// fn http_url_decode(s: Str) -> Result[Str, Str] - percent-decode a URL-encoded string. TODO(compiler): implement.
