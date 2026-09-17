// p_never_called_zeroarg.xi -- sweep over public zero-arg functions that no
// smoke or module references (reference scan 2026-09-17: 1010 public fns are
// never referenced; 72 zero-arg and safe to call). Purpose: catch latent
// codegen/link failures of the http_parse_response class on otherwise
// untested API. Compile is the detector; the calls are side-effect safe
// (no blocking, exit, or destructive functions included). Re-run after
// compiler bumps and extend when new zero-arg API lands.
// Returns 0 on success.
module p_never_called_zeroarg

use xiom.async;
use xiom.contracts;
use xiom.convert.datetime;
use xiom.crypto.curves;
use xiom.crypto.keyx;
use xiom.crypto.sign;
use xiom.debug.trace;
use xiom.ecc;
use xiom.env;
use xiom.ffi;
use xiom.format.terminal;
use xiom.geom;
use xiom.io.console;
use xiom.log;
use xiom.os;
use xiom.os.unix;
use xiom.platform;
use xiom.rand;
use xiom.rand.pcg;
use xiom.simd;
use xiom.thread;
use xiom.time.chrono;

fn main() -> Int {
  xiom.async.async_now_ms();
  xiom.async.async_yield_now();
  xiom.contracts.any_contracts();
  xiom.contracts.export_contracts_json();
  xiom.contracts.export_contracts_markdown();
  xiom.contracts.export_contracts_openapi();
  xiom.contracts.get_contract_coverage();
  xiom.contracts.reset_contract_coverage();
  xiom.contracts.total_ensures();
  xiom.contracts.total_invariants();
  xiom.contracts.total_requires();
  xiom.contracts.types_with_invariants();
  xiom.convert.datetime.datetime_now();
  xiom.crypto.curves.secp256k1_generator();
  xiom.crypto.sign.ed25519_keypair();
  xiom.debug.trace.trace_current_file();
  xiom.debug.trace.trace_print();
  xiom.ecc.curve_secp256k1();
  xiom.ecc.ed25519_keygen();
  xiom.env.args_os();
  xiom.env.cache_dir();
  xiom.env.config_dir();
  xiom.env.data_dir();
  xiom.env.executable_dir();
  xiom.ffi.ffi_ok();
  xiom.format.terminal.ansi_bg_black();
  xiom.format.terminal.ansi_bg_blue();
  xiom.format.terminal.ansi_bg_cyan();
  xiom.format.terminal.ansi_bg_magenta();
  xiom.format.terminal.ansi_bg_red();
  xiom.format.terminal.ansi_bg_white();
  xiom.format.terminal.ansi_bg_yellow();
  xiom.format.terminal.ansi_cursor_home();
  xiom.format.terminal.ansi_erase_above();
  xiom.format.terminal.ansi_erase_below();
  xiom.format.terminal.ansi_fg_black();
  xiom.format.terminal.ansi_fg_blue();
  xiom.format.terminal.ansi_fg_cyan();
  xiom.format.terminal.ansi_fg_green();
  xiom.format.terminal.ansi_fg_magenta();
  xiom.format.terminal.ansi_fg_white();
  xiom.format.terminal.ansi_fg_yellow();
  xiom.geom.mat2_identity();
  xiom.geom.mat3_identity();
  xiom.io.console.console_clear();
  xiom.log.log_clear_entries();
  xiom.log.log_entries_as_json();
  xiom.log.log_entries_as_text();
  xiom.log.log_entry_count();
  xiom.log.log_flush();
  xiom.log.log_last_entry();
  xiom.os.create_pipe();
  xiom.os.unix.unix_domainname();
  xiom.platform.arch_name();
  xiom.platform.endian_is_little();
  xiom.platform.is_bsd();
  xiom.platform.os_name();
  xiom.platform.os_version();
  xiom.rand.random_fraction();
  xiom.rand.seed_from_entropy();
  xiom.rand.pcg.pcg_new();
  xiom.simd.has_avx2();
  xiom.simd.has_avx512();
  xiom.simd.has_neon();
  xiom.simd.has_sse();
  xiom.thread.current_thread_id();
  xiom.thread.hardware_threads();
  xiom.thread.thread_name_current();
  xiom.thread.thread_yield();
  xiom.time.chrono.chrono_now();
  xiom.time.chrono.chrono_utc_now();
  return 0;
}
