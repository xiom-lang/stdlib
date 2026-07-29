module smoke_log_config
use xiom.log;

fn main() -> Int {
  log.set_level(log.LogLevel.Debug);
  if log.get_level() != log.LogLevel.Debug { return 1; }

  log.set_level(log.LogLevel.Warn);
  if log.get_level() != log.LogLevel.Warn { return 2; }

  log.set_output_json(true);
  log.set_output_color(false);

  log.warn("json mode test");

  log.set_output_json(false);
  log.set_output_color(true);

  log.clear_log();
  return 0;
}
