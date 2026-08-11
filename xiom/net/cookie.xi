// XIOM - Network: HTTP Cookies
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.cookie

// Depends on: xiom.string, xiom.time

// ============================================================================
// HTTP cookie parsing, serialization, and jar management per RFC 6265.
// Provides the Cookie struct plus parse/serialize helpers and a jar
// with domain/path matching for request cookies.
// ============================================================================

// struct Cookie { name: Str; value: Str; domain: Str; path: Str; expires: Int; max_age: Int; secure: Bool; http_only: Bool; same_site: Str }

// fn cookie_parse(header: Str) -> Result[Cookie, Str] - parse a request Cookie header into a cookie. TODO(compiler): implement.
// fn cookie_parse_set_cookie(header: Str) -> Result[Cookie, Str] - parse a Set-Cookie header into a cookie. TODO(compiler): implement.
// fn cookie_serialize(c: Cookie) -> Str - serialize a cookie into Cookie header form. TODO(compiler): implement.
// fn cookie_jar_new() - create an empty cookie jar. TODO(compiler): implement.
// fn cookie_jar_set(jar, c: Cookie) - store a cookie in the jar. TODO(compiler): implement.
// fn cookie_jar_get(jar, name: Str, url: Str) -> Option[Cookie] - fetch a cookie by name for a url. TODO(compiler): implement.
// fn cookie_jar_matches(c: Cookie, url: Str) -> Bool - test if a cookie applies to a url. TODO(compiler): implement.
// fn cookie_jar_size(jar) -> Int - count cookies held in the jar. TODO(compiler): implement.
// fn cookie_expires_after(c: Cookie, seconds: Int) -> Bool - test if the cookie expires within the given seconds. TODO(compiler): implement.
// fn cookie_domain_matches(domain: Str, host: Str) -> Bool - RFC 6265 domain-match test. TODO(compiler): implement.
// fn cookie_path_matches(path: Str, request_path: Str) -> Bool - RFC 6265 path-match test. TODO(compiler): implement.
