// XIOM stdlib smoke -- xiom.log.levels + color + json + sinks
// Returns 0 on success, nonzero (and a tag) on failure.

module smoke_log
use xiom.log.levels;
use xiom.log.color;
use xiom.log.json;
use xiom.log.sinks;
use xiom.io;
use xiom.convert;
use xiom.string;

fn fail(tag: Str) -> Int {
  io.println("smoke_log FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  // levels: constants / names / from_name / threshold / enabled / all
  if levels.log_level_trace() != 0 { return fail("trace"); }
  if levels.log_level_debug() != 1 { return fail("debug"); }
  if levels.log_level_info() != 2 { return fail("info"); }
  if levels.log_level_warn() != 3 { return fail("warn"); }
  if levels.log_level_error() != 4 { return fail("error"); }
  if levels.log_level_fatal() != 5 { return fail("fatal"); }
  if levels.log_level_name(0) != "TRACE" { return fail("name-trace"); }
  if levels.log_level_name(3) != "WARN" { return fail("name-warn"); }
  if levels.log_level_name(9) != "FATAL" { return fail("name-fatal"); }
  let fn_info = levels.log_level_from_name("info");
  match fn_info {
    Some(lv) => {
      if lv != 2 { return fail("from-info"); }
    };
    None => { return fail("from-info-none"); }
  }
  let fn_warn = levels.log_level_from_name("WARNING");
  match fn_warn {
    Some(lv) => {
      if lv != 3 { return fail("from-warning"); }
    };
    None => { return fail("from-warning-none"); }
  }
  let fn_none = levels.log_level_from_name("nope");
  if fn_none.is_some { return fail("from-none"); }
  if levels.log_level_threshold() != 2 { return fail("default-threshold"); }
  if !levels.log_enabled(2) { return fail("enabled-info"); }
  if levels.log_enabled(1) { return fail("enabled-debug"); }
  levels.log_set_level(0);
  if !levels.log_enabled(1) { return fail("enabled-after-set"); }
  if levels.log_level_threshold() != 0 { return fail("threshold-after-set"); }
  levels.log_set_level(2);
  let all = levels.log_level_all();
  if all.len() != 6 { return fail("all-len"); }
  if all[0] != 0 { return fail("all-0"); }
  if all[5] != 5 { return fail("all-5"); }

  // color: codes / reset / enable / colorize / strip / has
  if color.log_color_by_level(4) != 31 { return fail("color-error-code"); }
  if color.log_color_by_level(2) != 32 { return fail("color-info-code"); }
  if color.log_color(2) != "\u{001b}[32m" { return fail("color-info"); }
  if color.log_color_reset() != "\u{001b}[0m" { return fail("color-reset"); }
  if !color.log_color_enabled() { return fail("color-enabled"); }
  color.log_set_color_enabled(false);
  if color.log_color_enabled() { return fail("color-disabled"); }
  if color.log_colorize(4, "boom") != "boom" { return fail("colorize-off"); }
  color.log_set_color_enabled(true);
  let colored = color.log_colorize(4, "boom");
  if !color.log_has_color(colored) { return fail("colorize-on"); }
  if color.log_has_color("plain") { return fail("has-plain"); }
  if color.log_strip_color(colored) != "boom" { return fail("strip"); }

  // json: timestamp / entry / fields / parse / format / thread id
  let ts = json.log_json_timestamp();
  if ts.len() == 0 { return fail("timestamp"); }
  let entry = json.log_json_entry(2, "hello world");
  if entry.len() == 0 { return fail("entry-empty"); }
  if !string.str_contains(entry, "\"level\":\"INFO\"") { return fail("entry-level"); }
  if !string.str_contains(entry, "hello world") { return fail("entry-msg"); }
  var fields = Vec[(Str, Str)].new();
  fields.push(("app", "smoke"));
  fields.push(("n", "1"));
  let fields_json = json.log_json_fields(&fields);
  if !string.str_contains(fields_json, "\"app\":\"smoke\"") { return fail("fields"); }
  if fields_json.len() == 0 { return fail("fields-empty"); }
  let parsed = json.log_json_parse(entry);
  match parsed {
    Ok(pe) => {
      if pe.level != 2 { return fail("parse-level"); }
      if pe.message != "hello world" { return fail("parse-msg"); }
      if pe.thread_id != 1 { return fail("parse-thread"); }
      let reformatted = json.log_json_format(pe);
      if reformatted.len() == 0 { return fail("reformat-empty"); }
    };
    Err(_) => { return fail("parse-err"); }
  }
  let bad_line = json.log_json_parse("not json");
  if bad_line.is_ok { return fail("parse-bad"); }
  if json.log_json_thread_id() != 1 { return fail("thread-id"); }

  // sinks: new / null / stdout / stderr / add / remove / list / rotate / close
  let sn = sinks.log_sink_null();
  if sn.target != 0 { return fail("sink-null"); }
  let so = sinks.log_sink_stdout();
  if so.target != 1 { return fail("sink-out"); }
  let se = sinks.log_sink_stderr();
  if se.target != 2 { return fail("sink-err"); }
  let sf = sinks.log_sink_new(7);
  if sf.target != 7 { return fail("sink-new"); }
  if sinks.log_sinks().len() != 0 { return fail("sinks-empty"); }
  sinks.log_add_sink(so);
  sinks.log_add_sink(se);
  if sinks.log_sinks().len() != 2 { return fail("sinks-two"); }
  sinks.log_flush_all();
  sinks.log_sink_rotate(so, 1000);
  sinks.log_sink_close(so);
  if sinks.log_sinks().len() != 1 { return fail("sinks-after-close"); }
  sinks.log_sink_close(se);
  if sinks.log_sinks().len() != 0 { return fail("sinks-clear"); }
  let file_res = sinks.log_sink_file("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\agent_misc3\\smoke_sink.log");
  match file_res {
    Ok(fs) => {
      if fs.target != 3 { return fail("sink-file-target"); }
      sinks.log_sink_close(fs);
    };
    Err(_) => { return fail("sink-file"); }
  }

  io.println("smoke_log OK");
  return 0;
}
