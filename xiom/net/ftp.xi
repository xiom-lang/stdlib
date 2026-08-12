// XIOM — FTP Protocol Helpers (xiom.net.ftp)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Pure FTP command and reply helpers. No network I/O; commands are
// formatted as presentation strings per RFC 959.

module xiom.net.ftp

use xiom.string;

// ftp_default_port returns the default FTP control port (21).
// Complexity: O(1). Pure.
pub fn ftp_default_port() -> Int {
  21
}

// ftp_command_user formats a USER command.
// Complexity: O(1). Pure.
pub fn ftp_command_user(user: Str) -> Str {
  "USER " + user + "\r\n"
}

// ftp_command_pass formats a PASS command.
// Complexity: O(1). Pure.
pub fn ftp_command_pass(pass: Str) -> Str {
  "PASS " + pass + "\r\n"
}

// ftp_command_retr formats a RETR command for a remote path.
// Complexity: O(1). Pure.
pub fn ftp_command_retr(path: Str) -> Str {
  "RETR " + path + "\r\n"
}

// ftp_command_stor formats a STOR command for a remote path.
// Complexity: O(1). Pure.
pub fn ftp_command_stor(path: Str) -> Str {
  "STOR " + path + "\r\n"
}

// ftp_command_list formats a LIST command with an optional path.
// Complexity: O(1). Pure.
pub fn ftp_command_list(path: Str) -> Str {
  if path.len() == 0 {
    return "LIST\r\n";
  }
  "LIST " + path + "\r\n"
}

// ftp_command_quit formats a QUIT command.
// Complexity: O(1). Pure.
pub fn ftp_command_quit() -> Str {
  "QUIT\r\n"
}

// ftp_command_cwd formats a CWD command.
// Complexity: O(1). Pure.
pub fn ftp_command_cwd(dir: Str) -> Str {
  "CWD " + dir + "\r\n"
}

// ftp_command_type formats a TYPE command (A or I).
// Complexity: O(1). Pure.
pub fn ftp_command_type(kind: Str) -> Str {
  "TYPE " + kind + "\r\n"
}

// ftp_parse_reply parses an FTP reply line like "220 Ready" into
// (code, text). Returns None if the line does not start with a
// 3-digit code. Complexity: O(1). Pure.
pub fn ftp_parse_reply(line: Str) -> Option[(Int, Str)] {
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

// ftp_reply_is_success returns true for 2xx replies.
// Complexity: O(1). Pure.
pub fn ftp_reply_is_success(code: Int) -> Bool {
  code >= 200 && code < 300
}

// ftp_reply_is_positive_preliminary returns true for 1xx replies.
// Complexity: O(1). Pure.
pub fn ftp_reply_is_positive_preliminary(code: Int) -> Bool {
  code >= 100 && code < 200
}
