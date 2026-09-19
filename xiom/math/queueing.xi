// XIOM - Math: Queueing Theory
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.queueing

// Depends on: xiom.math

// ============================================================================
// Queueing models (M/M/1, M/M/c, M/G/1, G/G/1), loss systems, and traffic
// approximations. Unstable systems (utilization rho >= 1) return +inf where
// the closed-form diverges (documented). Complexity is documented per
// function.
// ============================================================================

use xiom.math;

const _LN2: Float64 = 0.6931471805599453;

/// M/M/1 mean queue length L and mean waiting time W = L/lambda. The tuple is
/// (L, W). Unstable (rho >= 1) returns (+inf, +inf). Complexity: O(1).
pub fn m_m_1(arrival_rate: Float64, service_rate: Float64) -> (Float64, Float64) {
  if arrival_rate <= 0.0 || service_rate <= 0.0 { return (0.0 / 0.0, 0.0 / 0.0); }
  var rho = arrival_rate / service_rate;
  if rho >= 1.0 { return (1.0 / 0.0, 1.0 / 0.0); }
  var l = rho * rho / (1.0 - rho);
  var w = l / arrival_rate;
  return (l, w);
}

/// M/M/c mean queue length L_q and mean waiting time W_q via the Erlang-C
/// formula. The tuple is (L_q, W_q). Unstable returns (+inf, +inf).
/// Complexity: O(c).
pub fn m_m_c(arrival_rate: Float64, service_rate: Float64, servers: Int) -> (Float64, Float64) {
  if arrival_rate <= 0.0 || service_rate <= 0.0 || servers <= 0 {
    return (0.0 / 0.0, 0.0 / 0.0);
  }
  var rho = arrival_rate / (service_rate * (servers as Float64));
  if rho >= 1.0 { return (1.0 / 0.0, 1.0 / 0.0); }
  var a = arrival_rate / service_rate;
  var p0 = 1.0;
  var acc = 1.0;
  var k = 1;
  while k <= servers {
    acc = acc * a / (k as Float64);
    p0 = p0 + acc;
    k = k + 1;
  }
  var last = acc;
  p0 = p0 + last * rho / (1.0 - rho);
  if p0 == 0.0 { return (1.0 / 0.0, 1.0 / 0.0); }
  p0 = 1.0 / p0;
  var c = last * p0 * rho / (1.0 - rho);
  var lq = c * rho / (1.0 - rho);
  var wq = lq / arrival_rate;
  return (lq, wq);
}

/// M/G/1 mean queue length via the Pollaczek-Khinchine formula
/// L_q = lambda^2 (var + mean^2) / (2 (1 - rho)). Complexity: O(1).
pub fn m_g_1(arrival_rate: Float64, mean_service: Float64, var_service: Float64) -> Float64 {
  if arrival_rate <= 0.0 || mean_service <= 0.0 { return 0.0 / 0.0; }
  var rho = arrival_rate * mean_service;
  if rho >= 1.0 { return 1.0 / 0.0; }
  var num = arrival_rate * arrival_rate * (var_service + mean_service * mean_service);
  return num / (2.0 * (1.0 - rho));
}

/// G/G/1 approximate mean waiting time via Kingman's heavy-traffic bound
/// W_q ~ (rho/(1 - rho)) * (c_a^2 + c_s^2)/2 * mean_service. Complexity: O(1).
pub fn g_g_1(mean_interarrival: Float64, var_interarrival: Float64, mean_service: Float64, var_service: Float64) -> Float64 {
  if mean_interarrival <= 0.0 || mean_service <= 0.0 { return 0.0 / 0.0; }
  var rho = mean_service / mean_interarrival;
  if rho >= 1.0 { return 1.0 / 0.0; }
  var ca2 = var_interarrival / (mean_interarrival * mean_interarrival);
  var cs2 = var_service / (mean_service * mean_service);
  return rho / (1.0 - rho) * (ca2 + cs2) / 2.0 * mean_service;
}

/// Erlang B blocking probability B(c, A) for the M/M/c/c loss system, by the
/// iterative recurrence. Complexity: O(c).
pub fn erlang_b(offered_load: Float64, servers: Int) -> Float64 {
  if offered_load < 0.0 || servers < 0 { return 0.0 / 0.0; }
  if servers == 0 { return 1.0; }
  var b = 1.0;
  var k = 1;
  while k <= servers {
    b = offered_load * b / ((k as Float64) + offered_load * b);
    k = k + 1;
  }
  return b;
}

/// Erlang C delay probability C(c, A) for M/M/c, from the Erlang B value.
/// Complexity: O(c).
pub fn erlang_c(offered_load: Float64, servers: Int) -> Float64 {
  if offered_load < 0.0 || servers <= 0 { return 0.0 / 0.0; }
  var b = erlang_b(offered_load, servers);
  var rho = offered_load / (servers as Float64);
  if rho >= 1.0 { return 1.0; }
  var denom = 1.0 - rho * (1.0 - b);
  if denom == 0.0 { return 1.0 / 0.0; }
  return b / denom;
}

/// Little's law: number of customers in the system L = lambda * W.
/// Complexity: O(1).
pub fn little_law(lambda: Float64, w: Float64) -> Float64 {
  return lambda * w;
}

/// Server utilization rho = lambda / (mu * c). Complexity: O(1).
pub fn utilization(arrival_rate: Float64, service_rate: Float64, servers: Int) -> Float64 {
  if service_rate <= 0.0 || servers <= 0 { return 0.0 / 0.0; }
  return arrival_rate / (service_rate * (servers as Float64));
}

/// Expected number of customers waiting in the M/M/c queue. Unstable returns
/// +inf. Complexity: O(c).
pub fn queue_length(arrival_rate: Float64, service_rate: Float64, servers: Int) -> Float64 {
  var mm = m_m_c(arrival_rate, service_rate, servers);
  return mm.0;
}

/// Expected waiting time in the M/M/c queue. Unstable returns +inf.
/// Complexity: O(c).
pub fn waiting_time(arrival_rate: Float64, service_rate: Float64, servers: Int) -> Float64 {
  var mm = m_m_c(arrival_rate, service_rate, servers);
  return mm.1;
}

/// Probability that an arrival finds the system full (M/M/c/c loss): the
/// Erlang B blocking probability. Complexity: O(c).
pub fn loss_probability(arrival_rate: Float64, service_rate: Float64, capacity: Int) -> Float64 {
  if service_rate <= 0.0 { return 0.0 / 0.0; }
  return erlang_b(arrival_rate / service_rate, capacity);
}

/// Probability that a call is blocked: the Erlang B blocking probability.
/// Complexity: O(c).
pub fn blocking_probability(arrival_rate: Float64, service_rate: Float64, capacity: Int) -> Float64 {
  return loss_probability(arrival_rate, service_rate, capacity);
}

/// Kingman heavy-traffic approximation of the queue size for G/G/c:
/// L_q ~ (rho^2/(1 - rho)) * (c_a^2 + c_s^2)/2 (unit-coefficient traffic).
/// Complexity: O(1).
pub fn heavy_traffic(arrival_rate: Float64, service_rate: Float64, servers: Int) -> Float64 {
  if arrival_rate <= 0.0 || service_rate <= 0.0 || servers <= 0 { return 0.0 / 0.0; }
  var rho = arrival_rate / (service_rate * (servers as Float64));
  if rho >= 1.0 { return 1.0 / 0.0; }
  var ca2 = 1.0;
  var cs2 = 1.0;
  return rho * rho / (1.0 - rho) * (ca2 + cs2) / 2.0;
}

/// Diffusion approximation of the M/M/1 queue length at time t:
/// L(t) = max(0, (lambda - mu) t). Complexity: O(1).
pub fn diffusion_approx(arrival_rate: Float64, service_rate: Float64, time: Float64) -> Float64 {
  if time < 0.0 { return 0.0 / 0.0; }
  var drift = arrival_rate - service_rate;
  if drift <= 0.0 { return 0.0; }
  return drift * time;
}
