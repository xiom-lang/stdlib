// XIOM - Math: Finance
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.finance

// Depends on: xiom.math

// ============================================================================
// Time value of money, bonds, options, and portfolio risk analytics.
// TODO(compiler): implement.
// ============================================================================

// fn pv(rate: Float64, nper: Float64, pmt: Float64, fv: Float64) -> Float64 - present value of an annuity and lump sum.
// fn fv(rate: Float64, nper: Float64, pmt: Float64, pv: Float64) -> Float64 - future value of an annuity and lump sum.
// fn npv(rate: Float64, cashflows: &Vec[Float64]) -> Float64 - net present value of a cashflow series.
// fn irr(cashflows: &Vec[Float64]) -> Float64 - internal rate of return of a cashflow series.
// fn mirr(cashflows: &Vec[Float64], finance_rate: Float64, reinvest_rate: Float64) -> Float64 - modified internal rate of return.
// fn pmt(rate: Float64, nper: Float64, pv: Float64, fv: Float64) -> Float64 - periodic payment of an annuity.
// fn ipmt(rate: Float64, per: Int, nper: Float64, pv: Float64) -> Float64 - interest portion of payment per.
// fn ppmt(rate: Float64, per: Int, nper: Float64, pv: Float64) -> Float64 - principal portion of payment per.
// fn nper(rate: Float64, pmt: Float64, pv: Float64, fv: Float64) -> Float64 - number of periods to reach fv.
// fn rate(nper: Float64, pmt: Float64, pv: Float64, fv: Float64) -> Float64 - interest rate implied by an annuity.
// fn annuity(rate: Float64, nper: Float64, pmt: Float64) -> Float64 - present value of a level annuity.
// fn perpetuity(pmt: Float64, rate: Float64) -> Float64 - present value of a growing or level perpetuity.
// fn bond_price(face: Float64, coupon: Float64, ytm: Float64, n: Int, freq: Int) -> Float64 - price of a coupon bond.
// fn bond_yield(face: Float64, coupon: Float64, price: Float64, n: Int, freq: Int) -> Float64 - yield to maturity of a bond.
// fn duration(face: Float64, coupon: Float64, ytm: Float64, n: Int, freq: Int) -> Float64 - Macaulay duration of a bond.
// fn convexity(face: Float64, coupon: Float64, ytm: Float64, n: Int, freq: Int) -> Float64 - convexity of a bond.
// fn option_call(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 - Black-Scholes price of a European call.
// fn option_put(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 - Black-Scholes price of a European put.
// fn option_call_delta(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 - delta of a European call.
// fn option_put_delta(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 - delta of a European put.
// fn option_gamma(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 - gamma of a European option.
// fn option_theta(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 - theta of a European option.
// fn option_vega(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 - vega of a European option.
// fn option_rho(s: Float64, k: Float64, t: Float64, r: Float64, sigma: Float64) -> Float64 - rho of a European option.
// fn implied_volatility(market: Float64, s: Float64, k: Float64, t: Float64, r: Float64) -> Float64 - Black-Scholes implied volatility.
// fn cagr(begin_value: Float64, end_value: Float64, years: Float64) -> Float64 - compound annual growth rate.
// fn sharpe_ratio(returns: &Vec[Float64], rf: Float64) -> Float64 - risk-adjusted return per unit of total volatility.
// fn sortino_ratio(returns: &Vec[Float64], rf: Float64) -> Float64 - return per unit of downside deviation.
// fn calmar_ratio(returns: &Vec[Float64], max_drawdown: Float64) -> Float64 - annualized return divided by maximum drawdown.
// fn var(returns: &Vec[Float64], alpha: Float64, method: Int) -> Float64 - value at risk at confidence alpha.
// fn cvar(returns: &Vec[Float64], alpha: Float64) -> Float64 - conditional value at risk at confidence alpha.
// fn drawdown(returns: &Vec[Float64]) -> Vec[Float64] - drawdown series of returns.
// fn beta(asset_returns: &Vec[Float64], market_returns: &Vec[Float64]) -> Float64 - systematic risk of an asset versus the market.
// fn alpha(asset_returns: &Vec[Float64], market_returns: &Vec[Float64], rf: Float64) -> Float64 - Jensen's alpha of an asset.
// fn treynor_ratio(returns: &Vec[Float64], beta: Float64, rf: Float64) -> Float64 - excess return per unit of systematic risk.
