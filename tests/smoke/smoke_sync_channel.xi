// XIOM stdlib smoke - xiom.sync.channel + xiom.async.channel
// Returns 0 on success with "OK" printed; nonzero + tag on failure.

module smoke_sync_channel
use xiom.sync.channel;
use xiom.async.channel.async_channel_new;
use xiom.async.channel.async_send;
use xiom.async.channel.async_try_send;
use xiom.async.channel.async_try_recv;
use xiom.async.channel.async_channel_close;
use xiom.async.channel.async_channel_len;
use xiom.async.channel.broadcast_new;
use xiom.async.channel.broadcast_send;
use xiom.async.channel.broadcast_recv;
use xiom.io;

fn main() -> Int {
  // sync channel: FIFO push/pop
  var ch = channel.channel_new(0);
  var s1 = channel.channel_send(&mut ch, 10);
  if s1.is_err { io.println("sync:send"); return 1; }
  var s2 = channel.channel_send(&mut ch, 20);
  if s2.is_err { io.println("sync:send2"); return 2; }
  var s3 = channel.channel_send(&mut ch, 30);
  if s3.is_err { io.println("sync:send3"); return 3; }
  if channel.channel_len(&ch) != 3 { io.println("sync:len"); return 4; }
  var r1 = channel.channel_recv(&mut ch);
  match r1 {
    Some(v) => { if v != 10 { io.println("sync:fifo1"); return 5; } }
    None => { io.println("sync:recv_none"); return 6; }
  }
  var r2 = channel.channel_recv(&mut ch);
  match r2 {
    Some(v) => { if v != 20 { io.println("sync:fifo2"); return 7; } }
    None => { io.println("sync:recv_none2"); return 8; }
  }
  var r3 = channel.channel_recv(&mut ch);
  match r3 {
    Some(v) => { if v != 30 { io.println("sync:fifo3"); return 9; } }
    None => { io.println("sync:recv_none3"); return 10; }
  }
  var r4 = channel.channel_try_recv(&mut ch);
  match r4 {
    Some(_) => { io.println("sync:empty"); return 11; }
    None => {}
  }

  // bounded: try_send refuses when full
  var bch = channel.channel_new(1);
  if !channel.channel_try_send(&mut bch, 5) { io.println("sync:try_send"); return 12; }
  if channel.channel_try_send(&mut bch, 6) { io.println("sync:try_send_full"); return 13; }
  if channel.channel_len(&bch) != 1 { io.println("sync:bounded_len"); return 14; }
  if channel.channel_capacity(&bch) != 1 { io.println("sync:capacity"); return 15; }

  // close: pending sends fail, queued items stay readable
  var cch = channel.channel_new(0);
  var cs1 = channel.channel_send(&mut cch, 7);
  if cs1.is_err { io.println("sync:close_send"); return 16; }
  channel.channel_close(&mut cch);
  if !channel.channel_is_closed(&cch) { io.println("sync:is_closed"); return 17; }
  var cs2 = channel.channel_send(&mut cch, 8);
  if !cs2.is_err { io.println("sync:send_closed"); return 18; }
  var cr = channel.channel_recv(&mut cch);
  match cr {
    Some(v) => { if v != 7 { io.println("sync:close_recv"); return 19; } }
    None => { io.println("sync:close_recv_none"); return 20; }
  }
  var cr2 = channel.channel_recv(&mut cch);
  match cr2 {
    Some(_) => { io.println("sync:drained"); return 21; }
    None => {}
  }

  // (channel_select is not smoke-testable: Vec[Channel[T]] with a Vec field
  // triggers the compiler's nested-Vec codegen limitation)

  // async channel: FIFO + try semantics
  var ach = async_channel_new(0);
  var as1 = async_send(&mut ach, 100);
  if as1.is_err { io.println("async:send"); return 25; }
  var ar1 = async_try_recv(&mut ach);
  match ar1 {
    Some(v) => { if v != 100 { io.println("async:fifo"); return 26; } }
    None => { io.println("async:recv_none"); return 27; }
  }
  var ar2 = async_try_recv(&mut ach);
  match ar2 {
    Some(_) => { io.println("async:empty"); return 28; }
    None => {}
  }
  var ab = async_channel_new(1);
  if !async_try_send(&mut ab, 1) { io.println("async:try_send"); return 29; }
  if async_try_send(&mut ab, 2) { io.println("async:try_send_full"); return 30; }
  if async_channel_len(&ab) != 1 { io.println("async:len"); return 31; }
  async_channel_close(&mut ab);

  // broadcast: every subscriber sees each item once
  var bd = broadcast_new(0);
  broadcast_send(&mut bd, 1);
  broadcast_send(&mut bd, 2);
  broadcast_send(&mut bd, 3);
  var b1 = broadcast_recv(&mut bd);
  match b1 {
    Some(v) => { if v != 1 { io.println("broadcast:1"); return 32; } }
    None => { io.println("broadcast:none1"); return 33; }
  }
  var b2 = broadcast_recv(&mut bd);
  match b2 {
    Some(v) => { if v != 2 { io.println("broadcast:2"); return 34; } }
    None => { io.println("broadcast:none2"); return 35; }
  }
  var b3 = broadcast_recv(&mut bd);
  match b3 {
    Some(v) => { if v != 3 { io.println("broadcast:3"); return 36; } }
    None => { io.println("broadcast:none3"); return 37; }
  }
  var b4 = broadcast_recv(&mut bd);
  match b4 {
    Some(_) => { io.println("broadcast:caught_up"); return 38; }
    None => {}
  }

  io.println("OK");
  return 0;
}
