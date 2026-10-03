// XIOM -- SMTP Protocol Helpers (xiom.net.smtp)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure SMTP command and reply helpers. No network I/O; commands are
// formatted as presentation strings per RFC 5321.

module xiom.net.smtp

use xiom.string;

/// smtp_default_port returns the default SMTP port (25).
/// Complexity: O(1). Pure.
pub fn smtp_default_port() -> Int
  ensures: result == 25
{
  25
}

/// smtp_command_helo formats a HELO command.
/// Complexity: O(1). Pure.
pub fn smtp_command_helo(host: Str) -> Str
  ensures: result.len() == host.len() + 7
{
  "HELO " + host + "\r\n"
}

/// smtp_command_ehlo formats an EHLO command.
/// Complexity: O(1). Pure.
pub fn smtp_command_ehlo(host: Str) -> Str
  ensures: result.len() == host.len() + 7
{
  "EHLO " + host + "\r\n"
}

/// smtp_command_mail_from formats a MAIL FROM command with an address.
/// Complexity: O(1). Pure.
pub fn smtp_command_mail_from(addr: Str) -> Str
  ensures: result.len() == addr.len() + 14
{
  "MAIL FROM:<" + addr + ">\r\n"
}

/// smtp_command_rcpt_to formats a RCPT TO command with an address.
/// Complexity: O(1). Pure.
pub fn smtp_command_rcpt_to(addr: Str) -> Str
  ensures: result.len() == addr.len() + 12
{
  "RCPT TO:<" + addr + ">\r\n"
}

/// smtp_command_data formats a DATA command.
/// Complexity: O(1). Pure.
pub fn smtp_command_data() -> Str
  ensures: result.len() == 6
{
  "DATA\r\n"
}

/// smtp_command_quit formats a QUIT command.
/// Complexity: O(1). Pure.
pub fn smtp_command_quit() -> Str
  ensures: result.len() == 6
{
  "QUIT\r\n"
}

/// smtp_command_noop formats a NOOP command.
/// Complexity: O(1). Pure.
pub fn smtp_command_noop() -> Str
  ensures: result.len() == 6
{
  "NOOP\r\n"
}

/// smtp_command_rset formats a RSET command.
/// Complexity: O(1). Pure.
pub fn smtp_command_rset() -> Str
  ensures: result.len() == 6
{
  "RSET\r\n"
}

/// smtp_command_auth_login formats an AUTH LOGIN command.
/// Complexity: O(1). Pure.
pub fn smtp_command_auth_login() -> Str
  ensures: result.len() == 12
{
  "AUTH LOGIN\r\n"
}

/// smtp_body_end formats the end-of-data marker (dot on its own line).
/// Complexity: O(1). Pure.
pub fn smtp_body_end() -> Str
  ensures: result.len() == 5
{
  "\r\n.\r\n"
}

/// smtp_parse_reply parses an SMTP reply line like "250 OK" into
/// (code, text). Returns None if the line does not start with a
/// 3-digit code. Complexity: O(1). Pure.
pub fn smtp_parse_reply(line: Str) -> Option[(Int, Str)]
  ensures: ((line.len() < 3) => (result.is_none == true)) && ((result.is_some == true) => (line.len() >= 3))
{
  let len = line.len();
  if len < 3 {
    return None;
  }
  var code = 0;
  var i = 0;
  while i < 3 {
    let b = line.byte_at(i);
    if b < 48 || b > 57 {
      return None;
    }
    code = code * 10 + (b as Int - 48);
    i = i + 1;
  }
  var text = "";
  if len > 3 {
    if line.byte_at(3) == 32 || line.byte_at(3) == 45 {
      text = string.str_slice(line, 4, len);
    }
  }
  Some((code, text))
}

/// smtp_reply_is_success returns true for 2xx replies.
/// Complexity: O(1). Pure.
pub fn smtp_reply_is_success(code: Int) -> Bool
  ensures: result == (code >= 200 && code < 300)
{
  code >= 200 && code < 300
}
