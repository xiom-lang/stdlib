// XIOM stdlib smoke -- xiom.convert.json
// Returns 0 on success, nonzero on failure (process exit code).
module smoke_convert_json
use xiom.io;
use xiom.convert.json;

fn main() -> Int {
  // escape / unescape round-trip
  var je = json.json_escape("a\"b\n");
  if je != "a\\\"b\\n" {
    io.println("smoke_convert_json: json_escape failed: " + je);
    return 1;
  }
  var ju = json.json_unescape(je);
  if !ju.is_ok {
    io.println("smoke_convert_json: json_unescape failed");
    return 2;
  }
  match ju {
    Ok(v) => {
      if v != "a\"b\n" {
        io.println("smoke_convert_json: json_unescape value failed: " + v);
        return 3;
      }
    },
    Err(e) => {
      io.println("smoke_convert_json: json_unescape err: " + e);
      return 3;
    },
  }
  var bad = json.json_unescape("\\q");
  if bad.is_ok {
    io.println("smoke_convert_json: json_unescape accepted bad");
    return 4;
  }

  // quote
  var jq = json.json_quote("hi");
  if jq != "\"hi\"" {
    io.println("smoke_convert_json: json_quote failed: " + jq);
    return 5;
  }

  // validation
  if !json.json_is_valid("{\"a\": [1, 2.5, \"x\"], \"b\": true}") {
    io.println("smoke_convert_json: json_is_valid positive failed");
    return 6;
  }
  if !json.json_is_valid("\"str\"") {
    io.println("smoke_convert_json: json_is_valid string failed");
    return 7;
  }
  if !json.json_is_valid("123.45e2") {
    io.println("smoke_convert_json: json_is_valid number failed");
    return 8;
  }
  if json.json_is_valid("{\"a\": }") {
    io.println("smoke_convert_json: json_is_valid missing value failed");
    return 9;
  }
  if json.json_is_valid("{\"a\": 1,}") {
    io.println("smoke_convert_json: json_is_valid trailing comma failed");
    return 10;
  }
  if json.json_is_valid("[1,]") {
    io.println("smoke_convert_json: json_is_valid array trailing comma failed");
    return 11;
  }
  if json.json_is_valid("{") {
    io.println("smoke_convert_json: json_is_valid unbalanced failed");
    return 12;
  }

  // pretty printing (round-trip must still validate)
  var jp = json.json_pretty("{\"a\":1,\"b\":[1,2]}");
  if !jp.is_ok {
    io.println("smoke_convert_json: json_pretty failed");
    return 13;
  }
  match jp {
    Ok(pv) => {
      if !json.json_is_valid(pv) {
        io.println("smoke_convert_json: json_pretty output invalid: " + pv);
        return 14;
      }
      if json.json_is_valid(pv) && pv == "{\"a\":1,\"b\":[1,2]}" {
        io.println("smoke_convert_json: json_pretty did not reformat");
        return 15;
      }
    },
    Err(e2) => {
      io.println("smoke_convert_json: json_pretty err: " + e2);
      return 14;
    },
  }
  // json_pretty is a tokenizer-based reformatter; it reports errors only for
  // unterminated strings, so no structural-validation negative test here.

  io.println("OK");
  return 0;
}
