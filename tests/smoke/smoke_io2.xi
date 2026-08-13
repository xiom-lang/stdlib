// XIOM stdlib smoke - xiom.io.fs / buffer / pipe / console
// Returns 0 on success with "OK" printed; nonzero + tag on failure.

module smoke_io2
use xiom.io.fs;
use xiom.io.buffer;
use xiom.io.pipe;
use xiom.io.console;
use xiom.io;
use xiom.convert;

fn main() -> Int {
  // fs: write/read text + bytes round-trip
  var data = bytes("hello\nworld\n");
  var w = fs.fs_write("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin", &data);
  if w.is_err { io.println("fs:write"); return 1; }
  var rb = fs.fs_read("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin");
  match rb {
    Ok(b) => { if b.len() != 12 { io.println("fs:read_len"); return 2; } }
    Err(_) => { io.println("fs:read_err"); return 3; }
  }
  var rt = fs.fs_read_text("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin");
  match rt {
    Ok(s) => { if s.len() != 12 { io.println("fs:read_text"); return 4; } }
    Err(_) => { io.println("fs:read_text_err"); return 5; }
  }
  if !fs.fs_exists("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin") { io.println("fs:exists"); return 6; }
  if !fs.fs_is_file("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin") { io.println("fs:is_file"); return 7; }
  var sz = fs.fs_size("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin");
  match sz {
    Ok(n) => { if n != 12 { io.println("fs:size"); return 8; } }
    Err(_) => { io.println("fs:size_err"); return 9; }
  }
  var mt = fs.fs_mtime("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin");
  if mt.is_err { io.println("fs:mtime"); return 10; }

  // fs: copy / move / append / range / touch / temp dir
  var cp = fs.fs_copy("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin", "C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_c.bin");
  if cp.is_err { io.println("fs:copy"); return 11; }
  if !fs.fs_exists("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_c.bin") { io.println("fs:copy2"); return 12; }
  var mv = fs.fs_move("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_c.bin", "C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_m.bin");
  if mv.is_err { io.println("fs:move"); return 13; }
  if !fs.fs_exists("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_m.bin") { io.println("fs:move2"); return 14; }
  var ap = fs.fs_append("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin", bytes("X"));
  if ap.is_err { io.println("fs:append"); return 15; }
  var rr = fs.fs_read_range("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin", 0, 5);
  match rr {
    Ok(b) => { if b.len() != 5 { io.println("fs:range"); return 16; } }
    Err(_) => { io.println("fs:range_err"); return 17; }
  }
  var wr = fs.fs_write_range("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_t.bin", 6, bytes("B"));
  match wr {
    Ok(n) => { if n != 1 { io.println("fs:write_range"); return 18; } }
    Err(_) => { io.println("fs:write_range_err"); return 19; }
  }
  var tt = fs.fs_touch("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_touch.txt");
  if tt.is_err { io.println("fs:touch"); return 20; }
  var td = fs.fs_temp_dir();
  if td.len() == 0 { io.println("fs:temp_dir"); return 21; }

  // buffer: buffered reader over a file
  var wb = fs.fs_write("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_buf.txt", bytes("hello\nworld\n"));
  if wb.is_err { io.println("buf:setup"); return 22; }
  var file: *UInt8 = fs.fopen("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_buf.txt", "r");
  var fdi: Int;
  unsafe { fdi = file as Int; }
  if fdi == 0 { io.println("buf:open"); return 23; }
  var br = buffer.buf_reader_new(fdi);
  var l1 = buffer.br_read_line(&mut br);
  match l1 {
    Ok(s) => { if s != "hello" { io.println("buf:line1"); return 24; } }
    Err(_) => { io.println("buf:line1_err"); return 25; }
  }
  var pk = buffer.br_peek(&mut br, 2);
  match pk {
    Ok(b) => { if b.len() != 2 { io.println("buf:peek"); return 26; } }
    Err(_) => { io.println("buf:peek_err"); return 27; }
  }
  var l2 = buffer.br_read_line(&mut br);
  match l2 {
    Ok(s) => { if s != "world" { io.println("buf:line2"); return 28; } }
    Err(_) => { io.println("buf:line2_err"); return 29; }
  }
  var tl = buffer.br_tell(&br);
  if tl <= 0 { io.println("buf:tell"); return 30; }
  buffer.br_seek(&mut br, 0);
  var l3 = buffer.br_read_line(&mut br);
  match l3 {
    Ok(s) => { if s != "hello" { io.println("buf:seek"); return 31; } }
    Err(_) => { io.println("buf:seek_err"); return 32; }
  }
  fs.fclose(file);

  // buffer: buffered writer then flush to file
  var outfile: *UInt8 = fs.fopen("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_bw.txt", "w");
  var fdo: Int;
  unsafe { fdo = outfile as Int; }
  if fdo == 0 { io.println("buf:bw_open"); return 33; }
  var bw = buffer.buf_writer_new(fdo);
  var bw1 = buffer.bw_write_str(&mut bw, "buffered");
  if bw1.is_err { io.println("buf:bw_write"); return 34; }
  var fl = buffer.bw_flush(&mut bw);
  if fl.is_err { io.println("buf:bw_flush"); return 35; }
  var fd = buffer.bw_into_inner(&mut bw);
  if fd == 0 { io.println("buf:into_inner"); return 36; }
  fs.fclose(outfile);
  var bwr = fs.fs_read_text("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_io2_bw.txt");
  match bwr {
    Ok(s) => { if s != "buffered" { io.println("buf:bw_read"); return 37; } }
    Err(_) => { io.println("buf:bw_read_err"); return 38; }
  }

  // pipe: write/read round-trip
  var p = pipe.pipe_create();
  if p.0 < 0 { io.println("pipe:create"); return 39; }
  var wd = pipe.pipe_write(p.1, bytes("ping"));
  match wd {
    Ok(n) => { if n != 4 { io.println("pipe:write"); return 40; } }
    Err(_) => { io.println("pipe:write_err"); return 41; }
  }
  var pbuf: Vec[UInt8] = Vec[UInt8]::with_capacity(8);
  var rd = pipe.pipe_read(p.0, &mut pbuf);
  match rd {
    Ok(n) => { if n != 4 { io.println("pipe:read"); return 42; } }
    Err(_) => { io.println("pipe:read_err"); return 43; }
  }
  var wl = pipe.pipe_write_line(p.1, "line");
  if wl.is_err { io.println("pipe:write_line"); return 44; }
  var rl = pipe.pipe_read_line(p.0);
  match rl {
    Ok(s) => { if s != "line" { io.println("pipe:read_line"); return 45; } }
    Err(_) => { io.println("pipe:read_line_err"); return 46; }
  }
  var w0 = pipe.pipe_write(p.1, bytes("tt"));
  if w0.is_err { io.println("pipe:write2"); return 47; }
  var rto = pipe.pipe_read_timeout(p.0, 5);
  if rto.is_err { io.println("pipe:read_timeout"); return 48; }
  var wto = pipe.pipe_write_timeout(p.1, bytes("t"), 5);
  if wto.is_err { io.println("pipe:write_timeout"); return 49; }
  if !pipe.pipe_is_open(p.0) { io.println("pipe:is_open"); return 50; }
  pipe.pipe_close(p.0);
  pipe.pipe_close(p.1);

  // console: write paths, tty, size
  console.console_write("x");
  console.console_write_line("y");
  console.console_write_error("z");
  console.console_flush();
  if console.console_is_tty() { io.println("console:tty"); return 51; }
  var size = console.console_get_size();
  if size.0 != 24 { io.println("console:size"); return 52; }

  io.println("OK");
  return 0;
}

fn bytes(s: Str) -> Vec[UInt8] {
  var out: Vec[UInt8] = Vec[UInt8]::with_capacity(s.len() as UInt);
  var i: Int = 0;
  while i < s.len() {
    out.push(s.byte_at(i));
    i = i + 1;
  }
  return out;
}

