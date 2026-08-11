// XIOM - Network: MIME and HTTP Header Utils
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.mime

// Depends on: xiom.string

// ============================================================================
// MIME type parsing, extension mapping, and content negotiation plus
// related HTTP header utilities: charset, etag, accept, and link.
// ============================================================================

// struct MimeType { type: Str; subtype: Str; params: Map[Str, Str] }
// struct Link { href: Str; rel: Str; title: Str; type: Str }

// (Str, Int) - accept entry: mime pattern plus q value.

// fn mime_parse(s: Str) -> Result[MimeType, Str] - parse a MIME type string into its parts. TODO(compiler): implement.
// fn mime_type_of(path: Str) -> Str - guess the MIME type from a file extension. TODO(compiler): implement.
// fn mime_extension_of(mime: Str) -> Str - guess a file extension for a MIME type. TODO(compiler): implement.
// fn mime_matches(pattern: Str, mime: Str) -> Bool - wildcard pattern match against a MIME type. TODO(compiler): implement.
// fn mime_is_text(mime: Str) -> Bool - test if a MIME type is text-based. TODO(compiler): implement.
// fn mime_is_image(mime: Str) -> Bool - test if a MIME type is an image. TODO(compiler): implement.
// fn mime_is_audio(mime: Str) -> Bool - test if a MIME type is audio. TODO(compiler): implement.
// fn mime_is_video(mime: Str) -> Bool - test if a MIME type is video. TODO(compiler): implement.
// fn mime_is_application(mime: Str) -> Bool - test if a MIME type is an application type. TODO(compiler): implement.
// fn charset_detect(data: &Vec[UInt8]) -> Str - guess the character encoding of a byte buffer. TODO(compiler): implement.
// fn charset_normalize(s: Str, charset: Str) -> Result[Str, Str] - re-encode a string into a target charset. TODO(compiler): implement.
// fn etag_new(content: &Vec[UInt8]) -> Str - compute a quoted etag for a byte buffer. TODO(compiler): implement.
// fn etag_matches(etag: Str, if_none_match: Str) -> Bool - test an etag against an If-None-Match header. TODO(compiler): implement.
// fn accept_parse(header: Str) -> Vec[(Str, Int)] - parse an Accept header into mime and q pairs. TODO(compiler): implement.
// fn accept_q_value(header: Str, mime: Str) -> Int - look up the q value of a mime in an Accept header. TODO(compiler): implement.
// fn accept_negotiate(header: Str, available: &Vec[Str]) -> Option[Str] - pick the best available mime for an Accept header. TODO(compiler): implement.
// fn link_parse(header: Str) -> Vec[Link] - parse a Link header into typed links. TODO(compiler): implement.
// fn link_find(links: &Vec[Link], rel: Str) -> Option[Str] - find the href of a link with the given rel. TODO(compiler): implement.
