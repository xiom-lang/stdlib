module smoke_log_levels
use xiom.log;

fn main() -> Int {
  log.set_level(log.LogLevel.Trace);
  log.trace("trace msg");
  log.debug("debug msg");
  log.info("info msg");
  log.warn("warn msg");
  log.error("error msg");
  log.fatal("fatal msg");

  log.set_level(log.LogLevel.Error);
  log.trace("should not appear");
  log.info("should not appear");
  log.error("this is an error");

  log.clear_log();

  return 0;
}
