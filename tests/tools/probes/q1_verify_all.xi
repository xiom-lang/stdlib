// q1_verify_all.xi -- imports every module edited by the Q1 T007 pass.
// Compile-only graph check: no T007 warnings may remain for these modules.
module q1_verify_all
use xiom.io;
use xiom.io.fs;
use xiom.io.buffer;
use xiom.io.console;
use xiom.io.pipe;
use xiom.thread;
use xiom.thread.spawn;
use xiom.thread.park;
use xiom.async;
use xiom.async.timer;
use xiom.mem;
use xiom.ptr;
use xiom.cell;
use xiom.rc;
use xiom.sync;
use xiom.sync.condvar;
use xiom.collections;
use xiom.core;
use xiom.contracts;
use xiom.convert.asref;
use xiom.convert.wstring;
use xiom.ffi;
use xiom.ffi.c;
use xiom.ffi.dl;
use xiom.ffi.errno;
use xiom.math;
use xiom.os;
use xiom.os.args;
use xiom.env;
use xiom.reflect;
use xiom.simd;
use xiom.serialize.endian;
use xiom.net;
use xiom.misc.levenshtein;
use xiom.text.diff;
use xiom.text.similarity;

fn main() -> Int {
  return 0;
}
