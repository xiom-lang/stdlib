// XIOM - Math: Mathematical Biology
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.mathematical_biology

// Depends on: xiom.math

// ============================================================================
// Mathematical models of living systems: population dynamics, epidemiology,
// genetics, ecology, and neuroscience. TODO(compiler): implement.
// ============================================================================

// fn population_growth(r: Float64, n0: Float64, t: Float64) -> Float64 - exponential population size at time t.
// fn logistic_growth(r: Float64, k: Float64, n0: Float64, t: Float64) -> Float64 - carrying-capacity-limited population size at time t.
// fn lotka_volterra(alpha: Float64, beta: Float64, gamma: Float64, delta: Float64, prey: Float64, pred: Float64, dt: Float64) -> (Float64, Float64) - one Euler step of predator-prey dynamics.
// fn epidemiological_sir(beta: Float64, gamma: Float64, s: Float64, i: Float64, r: Float64, dt: Float64) -> (Float64, Float64, Float64) - one SIR compartment step.
// fn epidemiological_seir(beta: Float64, sigma: Float64, gamma: Float64, s: Float64, e: Float64, i: Float64, r: Float64, dt: Float64) -> (Float64, Float64, Float64, Float64) - one SEIR compartment step.
// fn chemotherapy(growth: Float64, kill: Float64, tumor: Float64, dose: Float64, dt: Float64) -> Float64 - tumor size after a treatment step.
// fn genetics(p: Float64, q: Float64, selection: Float64) -> Vec[Float64] - Hardy-Weinberg genotype frequencies under selection.
// fn ecology(species: &Vec[Float64], interaction: &Vec[Vec[Float64]], dt: Float64) -> Vec[Float64] - Lotka-Volterra multi-species step.
// fn immunology(antigen: Float64, antibody: Float64, infection_rate: Float64, clearance: Float64, dt: Float64) -> (Float64, Float64) - one immune-response step.
// fn neuroscience(v: Float64, input: Float64, tau: Float64, threshold: Float64, dt: Float64) -> (Float64, Bool) - leaky integrate-and-fire neuron update.
// fn evolution(fitness: &Vec[Float64], population: &Vec[Float64], mutation: Float64) -> Vec[Float64] - next-generation allele frequencies.
