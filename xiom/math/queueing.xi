// XIOM - Math: Queueing Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.queueing

// Depends on: xiom.math

// ============================================================================
// Queueing models (M/M/1, M/M/c, M/G/1, G/G/1), loss systems, and traffic
// approximations. TODO(compiler): implement.
// ============================================================================

// fn m_m_1(arrival_rate: Float64, service_rate: Float64) -> (Float64, Float64) - mean queue length and mean waiting time of M/M/1.
// fn m_m_c(arrival_rate: Float64, service_rate: Float64, servers: Int) -> (Float64, Float64) - mean queue length and waiting time of M/M/c.
// fn m_g_1(arrival_rate: Float64, mean_service: Float64, var_service: Float64) -> Float64 - Pollaczek-Khinchine mean queue length.
// fn g_g_1(mean_interarrival: Float64, var_interarrival: Float64, mean_service: Float64, var_service: Float64) -> Float64 - approximate mean waiting time for G/G/1.
// fn erlang_b(offered_load: Float64, servers: Int) -> Float64 - Erlang B blocking probability for M/M/c/c.
// fn erlang_c(offered_load: Float64, servers: Int) -> Float64 - Erlang C delay probability for M/M/c.
// fn little_law(lambda: Float64, w: Float64) -> Float64 - number in system from arrival rate and sojourn time.
// fn utilization(arrival_rate: Float64, service_rate: Float64, servers: Int) -> Float64 - server utilization rho.
// fn queue_length(arrival_rate: Float64, service_rate: Float64, servers: Int) -> Float64 - expected number of customers waiting in queue.
// fn waiting_time(arrival_rate: Float64, service_rate: Float64, servers: Int) -> Float64 - expected waiting time in queue.
// fn loss_probability(arrival_rate: Float64, service_rate: Float64, capacity: Int) -> Float64 - probability an arrival finds the system full.
// fn blocking_probability(arrival_rate: Float64, service_rate: Float64, capacity: Int) -> Float64 - probability that a call is blocked.
// fn heavy_traffic(arrival_rate: Float64, service_rate: Float64, servers: Int) -> Float64 - Kingman heavy-traffic approximation of queue size.
// fn diffusion_approx(arrival_rate: Float64, service_rate: Float64, time: Float64) -> Float64 - diffusion approximation of queue size at time.
