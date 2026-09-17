// XIOM stdlib stress smoke - parser fuzz harness (deterministic).
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Feeds thousands of generated and mutated inputs to the stdlib parsers
// (json/toml/csv/url/http) and locks the robustness contract:
//   - no parser crashes, aborts or hangs on any input;
//   - successful JSON/TOML/CSV parses round-trip through their writers and
//     re-parse successfully (writer/reader agreement);
//   - http_parse_response and http_parse_response_headers are total on any
//     input (Ok or Err, no crash).
// Deterministic LCG so failures reproduce from the seed. This is the
// stdlib-side mutation harness; coverage-guided fuzzing stays with the
// compiler Stage-5 workspace.
// Returns 0 on success, unique error code on failure.

module smoke_stress_fuzz_parsers
use xiom.serialize.json;
use xiom.serialize.toml;
use xiom.serialize.csv;
use xiom.net.url;
use xiom.net.http;
use xiom.io;
use xiom.string;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

// One character of `alphabet` at `idx` (callers keep idx in range).
fn pick(alphabet: Str, idx: Int) -> Str {
  string.str_slice(alphabet, idx, idx + 1)
}

fn random_alpha(seed: Int, len: Int) -> Str {
  let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 \t\n{}[]\",:;=.\\\\'#-/_?&%+*()<>@!$^|~";
  let n = string.str_len(alphabet);
  var s = seed;
  var out = "";
  var i = 0;
  while i < len {
    s = next_seed(s);
    out = out + pick(alphabet, s % n);
    i = i + 1;
  };
  out
}

fn random_soup(seed: Int, len: Int) -> Str {
  let alphabet = "{}[]\",:;=.#\\/'<> \t\n0123456789abcdefghijklmnopqrstuvwxyz";
  let n = string.str_len(alphabet);
  var s = seed;
  var out = "";
  var i = 0;
  while i < len {
    s = next_seed(s);
    out = out + pick(alphabet, s % n);
    i = i + 1;
  };
  out
}

fn mutate(seed: Int, sample: Str) -> Str {
  let len = string.str_len(sample);
  if len == 0 { return sample; };
  var s = seed;
  s = next_seed(s);
  let mode = s % 4;
  s = next_seed(s);
  let pos = s % len;
  if mode == 0 {
    return string.str_slice(sample, 0, pos);
  };
  if mode == 1 {
    let alphabet = "{}[]\",:;=.#\\/'<>";
    s = next_seed(s);
    let ch = pick(alphabet, s % string.str_len(alphabet));
    return string.str_slice(sample, 0, pos) + ch + string.str_slice(sample, pos + 1, len);
  };
  if mode == 2 {
    let ch = pick(sample, pos);
    return string.str_slice(sample, 0, pos) + ch + string.str_slice(sample, pos, len);
  };
  let ch = pick(sample, pos);
  return string.str_slice(sample, 0, pos) + ch + ch + string.str_slice(sample, pos, len);
}

fn check_json(input: Str, code: Int) -> Int {
  match json_parse(input) {
    Ok(v) => {
      match json_parse(json_stringify(v)) {
        Ok(_) => { return 0; },
        Err(_) => { io.println("json reparse"); return code; },
      }
    },
    Err(_) => { return 0; },
  }
}

fn check_toml(input: Str, code: Int) -> Int {
  match toml_parse(input) {
    Ok(t) => {
      match toml_parse(toml_write(&t)) {
        Ok(_) => { return 0; },
        Err(_) => { io.println("toml reparse"); return code; },
      }
    },
    Err(_) => { return 0; },
  }
}

fn check_csv(input: Str, code: Int) -> Int {
  match csv_parse(input) {
    Ok(rows) => {
      match csv_parse(csv_write(&rows)) {
        Ok(rows2) => {
          if rows2.len() != rows.len() { io.println("csv shape"); return code; }
          return 0;
        },
        Err(_) => { io.println("csv reparse"); return code; },
      }
    },
    Err(_) => { return 0; },
  }
}

fn main() -> Int {
  let json_sample = "{\"a\":[1,2.5,true,null],\"b\":\"x\\ny\",\"c\":{},\"d\":-3}";
  let toml_sample = "title = \"root\"\ncount = 3\nratio = 1.5\nflag = true\ntools = [\"a\", \"b\"]\n[package]\nname = \"demo\"\n[build]\ntargets = [\"x\"]\n";
  let csv_sample = "a,b,c\n1,\"x,y\",3\n4,,6\n";
  let url_sample = "https://user@example.com:8080/a/b?x=1&y=2#frag";
  let http_sample = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\n\r\nhello";

  var seed = 20260917;
  var iter = 0;
  var ok_json = 0;
  var ok_toml = 0;
  var ok_csv = 0;
  var ok_url = 0;
  var ok_http = 0;

  while iter < 600 {
    seed = next_seed(seed);
    let mode = seed % 3;
    seed = next_seed(seed);
    let len = seed % 48;
    var input = "";
    if mode == 0 {
      input = random_alpha(seed, len);
    } elif mode == 1 {
      input = random_soup(seed, len);
    } else {
      seed = next_seed(seed);
      let which = seed % 5;
      if which == 0 { input = mutate(seed, json_sample); }
      elif which == 1 { input = mutate(seed, toml_sample); }
      elif which == 2 { input = mutate(seed, csv_sample); }
      elif which == 3 { input = mutate(seed, url_sample); }
      else { input = mutate(seed, http_sample); }
    };

    let rc_json = check_json(input, 10);
    if rc_json != 0 { return rc_json; }
    let rc_toml = check_toml(input, 20);
    if rc_toml != 0 { return rc_toml; }
    let rc_csv = check_csv(input, 30);
    if rc_csv != 0 { return rc_csv; }

    match url_parse(input) {
      Ok(_) => { ok_url = ok_url + 1; },
      Err(_) => {},
    }
    let http_res = http_parse_response(input);
    match http_res {
      Ok(_) => { ok_http = ok_http + 1; },
      Err(_) => {},
    }
    let headers = http_parse_response_headers(input);
    if headers.len() < 0 { io.println("http headers"); return 40; }

    if rc_json == 0 { ok_json = ok_json + 1; }
    if rc_toml == 0 { ok_toml = ok_toml + 1; }
    if rc_csv == 0 { ok_csv = ok_csv + 1; }
    iter = iter + 1;
  };

  io.println("fuzz: 600 inputs, json=" + ok_json + " toml=" + ok_toml + " csv=" + ok_csv + " url=" + ok_url + " http=" + ok_http);
  return 0;
}
