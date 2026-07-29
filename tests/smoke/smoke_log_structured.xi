module smoke_log_structured
use xiom.log;
use xiom.collections;

fn main() -> Int {
  var data = Map[Str, Str].new();
  data.insert("key1", "val1");
  data.insert("key2", "val2");

  log.set_level(log.LogLevel.Trace);
  log.trace_with("trace data", data);
  log.debug_with("debug data", data);
  log.info_with("info data", data);
  log.warn_with("warn data", data);
  log.error_with("error data", data);

  log.clear_log();
  return 0;
}
