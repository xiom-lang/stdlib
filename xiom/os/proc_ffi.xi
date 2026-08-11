// XIOM - OS: proc_ffi (process control via FFI syscalls)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.proc_ffi

// ============================================================================
// Low-level process control beyond process.xi: fork/wait, popen pipes,
// posix_spawn/exec, process identity and signal delivery. All via minimal C
// FFI; zero external libraries. The unsafe-extern path is fixed (BUG 11).
// ============================================================================

// fn fork() -> Result[Int, Str] - fork the current process (child gets 0). TODO(compiler): implement.
// fn waitpid(pid: Int, options: Int) -> Result[Int, Str] - wait for a child. TODO(compiler): implement.
// fn wait() -> Result[Int, Str] - wait for any child. TODO(compiler): implement.
// fn popen(cmd: Str, mode: Str) -> Result[Int, Str] - open a pipe to/from a command. TODO(compiler): implement.
// fn pclose(pipe: Int) -> Result[Int, Str] - close a popen pipe and get the status. TODO(compiler): implement.
// fn posix_spawn(path: Str, args: &Vec[Str]) -> Result[Int, Str] - spawn a process by path. TODO(compiler): implement.
// fn posix_spawnp(file: Str, args: &Vec[Str]) -> Result[Int, Str] - spawn searching PATH. TODO(compiler): implement.
// fn execv(path: Str, args: &Vec[Str]) -> Result[Int, Str] - replace the process image. TODO(compiler): implement.
// fn execvp(file: Str, args: &Vec[Str]) -> Result[Int, Str] - exec searching PATH. TODO(compiler): implement.
// fn getpid() -> Int - current process id. TODO(compiler): implement.
// fn getppid() -> Int - parent process id. TODO(compiler): implement.
// fn getsid(pid: Int) -> Int - session id. TODO(compiler): implement.
// fn kill(pid: Int, sig: Int) -> Result[Unit, Str] - send a signal. TODO(compiler): implement.
// fn raise(sig: Int) -> Result[Unit, Str] - send a signal to the current process. TODO(compiler): implement.
// fn exit_code(status: Int) -> Int - extract the exit code from a wait status. TODO(compiler): implement.
// fn exit_signal(status: Int) -> Int - extract the terminating signal from a wait status. TODO(compiler): implement.
// fn process_status(pid: Int) -> Option[Int] - poll a process (None if still running). TODO(compiler): implement.
