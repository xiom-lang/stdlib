// p_wave291_h2_stream_state.xi -- RFC 9113 section 5.1 per-stream states.
// Locks idle/open/half-closed/closed transitions and the invalid cases.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave291_h2_stream_state

use xiom.net.h2;

fn main() -> Int {
  if h2.h2_stream_state_name(h2.H2StreamState.Idle) != "idle" { return 1; }
  if h2.h2_stream_state_name(h2.H2StreamState.HalfClosedLocal) != "half-closed-local" { return 2; }

  let a = h2.h2_stream_transition(h2.H2StreamState.Idle, h2.H2StreamEvent.SendHeaders);
  if a.is_err { return 3; }
  if a.value != h2.H2StreamState.Open { return 4; }

  let b = h2.h2_stream_transition(h2.H2StreamState.Open, h2.H2StreamEvent.SendEndStream);
  if b.is_err { return 5; }
  if b.value != h2.H2StreamState.HalfClosedLocal { return 6; }

  let c = h2.h2_stream_transition(h2.H2StreamState.HalfClosedLocal, h2.H2StreamEvent.RecvEndStream);
  if c.is_err { return 7; }
  if c.value != h2.H2StreamState.Closed { return 8; }

  if h2.h2_stream_transition(h2.H2StreamState.Closed, h2.H2StreamEvent.RecvData).is_ok { return 9; }
  if h2.h2_stream_transition(h2.H2StreamState.Idle, h2.H2StreamEvent.SendData).is_ok { return 10; }
  if h2.h2_stream_transition(h2.H2StreamState.Idle, h2.H2StreamEvent.SendRst).is_ok { return 11; }

  let d = h2.h2_stream_transition(h2.H2StreamState.Open, h2.H2StreamEvent.RecvEndStream);
  if d.is_err { return 12; }
  if d.value != h2.H2StreamState.HalfClosedRemote { return 13; }

  let e = h2.h2_stream_transition(h2.H2StreamState.HalfClosedRemote, h2.H2StreamEvent.SendEndStream);
  if e.is_err { return 14; }
  if e.value != h2.H2StreamState.Closed { return 15; }

  if h2.h2_stream_transition(h2.H2StreamState.HalfClosedRemote, h2.H2StreamEvent.RecvData).is_ok { return 16; }
  if h2.h2_stream_transition(h2.H2StreamState.HalfClosedLocal, h2.H2StreamEvent.SendData).is_ok { return 17; }

  let f = h2.h2_stream_transition(h2.H2StreamState.Open, h2.H2StreamEvent.SendRst);
  if f.is_err { return 18; }
  if f.value != h2.H2StreamState.Closed { return 19; }

  let g = h2.h2_stream_transition(h2.H2StreamState.Open, h2.H2StreamEvent.SendHeaders);
  if g.is_err { return 20; }
  if g.value != h2.H2StreamState.Open { return 21; }

  return 0;
}
