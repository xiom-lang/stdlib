// Smoke test for xiom.string.lcp + xiom.string.lcs + xiom.string.lcsuffix
// Returns 0 on success, non-zero on the first failing assertion.

module smoke_string_lcp_lcs
use xiom.string.lcp;
use xiom.string.lcs;
use xiom.string.lcsuffix;
use xiom.io;

fn main() -> Int {
  if lcp.longest_common_prefix("abcX", "abcY") != 3 { io.println("lcp abc"); return 1; }
  if lcp.longest_common_prefix("hello", "world") != 0 { io.println("lcp none"); return 2; }
  if lcp.longest_common_prefix("", "abc") != 0 { io.println("lcp empty"); return 3; }
  if lcp.longest_common_prefix("same", "same") != 4 { io.println("lcp same"); return 4; }
  var s1 = Vec[Str].new();
  s1.push("abcdef");
  s1.push("abcxyz");
  s1.push("abcmn");
  if lcp.lcp_of_many(&s1) != 3 { io.println("lcp many"); return 5; }
  var s2 = Vec[Str].new();
  if lcp.lcp_of_many(&s2) != 0 { io.println("lcp many empty"); return 6; }
  var s3 = Vec[Str].new();
  s3.push("zz");
  if lcp.lcp_of_many(&s3) != 2 { io.println("lcp many one"); return 7; }
  var s4 = Vec[Str].new();
  s4.push("abc");
  s4.push("abd");
  s4.push("x");
  if lcp.lcp_of_many(&s4) != 0 { io.println("lcp many zero"); return 8; }
  // lcs
  if lcs.longest_common_subsequence("ABCDGH", "AEDFHR") != 3 { io.println("lcs adh"); return 9; }
  if lcs.longest_common_subsequence("abc", "abc") != 3 { io.println("lcs same"); return 10; }
  if lcs.longest_common_subsequence("", "abc") != 0 { io.println("lcs empty"); return 11; }
  if lcs.longest_common_substring("abcdef", "zcdemf") != 3 { io.println("lcsub cd"); return 12; }
  if lcs.longest_common_substring("abc", "def") != 0 { io.println("lcsub none"); return 13; }
  // lcsuffix
  if lcsuffix.longest_common_suffix("XXabc", "YYabc") != 3 { io.println("lcsuf abc"); return 14; }
  if lcsuffix.longest_common_suffix("hello", "cello") != 4 { io.println("lcsuf hello"); return 15; }
  if lcsuffix.longest_common_suffix("abc", "xyz") != 0 { io.println("lcsuf none"); return 16; }
  if lcsuffix.longest_common_suffix("same", "same") != 4 { io.println("lcsuf same"); return 17; }
  io.println("smoke_string_lcp_lcs: OK");
  return 0;
}
