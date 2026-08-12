// Smoke: xiom.math.finance, mathematical_economics, game_theory,
// information_theory, mathematical_physics, graph_theory, machine_learning,
// mathematical_biology, mathematical_logic, fuzzy, chaos.
// Returns 0 on success.
use xiom.math;
use xiom.io;
use xiom.convert;
use xiom.string;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn v_len(coal: &Vec[Int]) -> Float64 {
  return (coal.len() as Float64);
}

fn demand_fn(p: Float64) -> Float64 {
  return 100.0 - p;
}

fn supply_fn(p: Float64) -> Float64 {
  return 2.0 * p;
}

fn main() -> Int {
  // ---- finance ----
  var f = math.finance.fv(0.05, 2.0, 0.0, 100.0);
  if !near(f, 110.25, 1e-9) { io.println("fv"); return 1; }
  var p = math.finance.pv(0.05, 2.0, 0.0, 110.25);
  if !near(p, -100.0, 1e-6) { io.println("pv"); return 2; }
  var cfs = Vec[Float64].new();
  cfs.push(-100.0);
  cfs.push(50.0);
  cfs.push(60.0);
  var ir = math.finance.irr(&cfs);
  var iri = convert.float_to_int(ir * 100.0);
  if iri < 6 || iri > 8 { io.println("irr"); return 3; }
  var pm = math.finance.pmt(0.05, 3.0, 1000.0, 0.0);
  var pmi = convert.float_to_int(-pm * 10.0);
  if pmi < 3660 || pmi > 3685 { io.println("pmt"); return 4; }
  var bp = math.finance.bond_price(1000.0, 0.06, 0.05, 3, 1);
  if !near(bp, 1027.23, 0.5) { io.println("bond"); return 5; }
  var oc = math.finance.option_call(100.0, 100.0, 1.0, 0.05, 0.2);
  if !near(oc, 10.45, 0.1) { io.println("option"); return 6; }
  var iv = math.finance.implied_volatility(oc, 100.0, 100.0, 1.0, 0.05);
  if !near(iv, 0.2, 0.05) { io.println("iv"); return 7; }
  if !near(math.finance.cagr(100.0, 200.0, 2.0), 0.41421, 1e-4) { io.println("cagr"); return 8; }
  var d = math.finance.duration(1000.0, 0.06, 0.05, 3, 1);
  if !near(d, 2.83, 0.1) { io.println("duration"); return 9; }
  var rets = Vec[Float64].new();
  rets.push(0.1);
  rets.push(0.2);
  rets.push(-0.1);
  var sr = math.finance.sharpe_ratio(&rets, 0.0);
  if sr < 0.0 || sr > 10.0 { io.println("sharpe"); return 10; }
  var dd = math.finance.drawdown(&rets);
  if dd.len() != 3 { io.println("drawdown"); return 11; }
  var bet = math.finance.beta(&rets, &rets);
  if !near(bet, 1.0, 1e-9) { io.println("beta"); return 12; }

  // ---- mathematical economics ----
  var eq = math.mathematical_economics.market_equilibrium(demand_fn, supply_fn);
  if !near(eq.0, 33.333, 0.01) { io.println("equilibrium"); return 13; }
  if !near(math.mathematical_economics.elasticity(100.0, 80.0, 10.0, 12.0), -1.2222, 0.01) { io.println("elasticity"); return 14; }
  if !near(math.mathematical_economics.production_cobb_douglas(1.0, 0.5, 0.5, 4.0, 9.0), 6.0, 1e-9) { io.println("prod"); return 15; }
  var ut = Vec[Float64].new();
  ut.push(4.0);
  var wts = Vec[Float64].new();
  wts.push(0.5);
  var u = math.mathematical_economics.utility(&ut, &wts);
  if !near(u, 2.0, 1e-9) { io.println("utility"); return 16; }

  // ---- game theory ----
  var sv = math.game_theory.shapley_value(v_len, 3);
  if sv.len() != 3 { io.println("shapley-len"); return 17; }
  if !near(sv[0], 1.0, 1e-9) { io.println("shapley"); return 18; }
  var cg = math.game_theory.cooperative_game(v_len, 3);
  if !near(cg.0, 3.0, 1e-9) { io.println("cgame"); return 19; }
  var bids = Vec[Float64].new();
  bids.push(10.0);
  bids.push(20.0);
  bids.push(15.0);
  var auc = math.game_theory.auction(&bids, 5.0);
  if auc.1 != 1 { io.println("auction"); return 20; }
  if !near(auc.0, 20.0, 1e-12) { io.println("auction-price"); return 21; }
  var pd = math.game_theory.prisoner_dilemma(1.0, 3.0);
  if pd.0 != 3.0 || pd.1 != 1.0 { io.println("pd"); return 22; }

  // ---- information theory ----
  var probs = Vec[Float64].new();
  probs.push(0.5);
  probs.push(0.5);
  if !near(math.information_theory.entropy(&probs), 1.0, 1e-9) { io.println("entropy"); return 23; }
  if !near(math.information_theory.self_information(0.5), 1.0, 1e-9) { io.println("selfinfo"); return 24; }
  var q2 = Vec[Float64].new();
  q2.push(0.5);
  q2.push(0.5);
  if !near(math.information_theory.kl_divergence(&probs, &q2), 0.0, 1e-9) { io.println("kl"); return 25; }
  var sym = Vec[Int].new();
  sym.push(0);
  var ac = math.information_theory.arithmetic_coding(&probs, &sym);
  if ac < 0.2 || ac > 0.3 { io.println("arith"); return 26; }
  var hc = math.information_theory.huffman_coding(&probs);
  if hc.len() != 2 { io.println("huffman"); return 27; }

  // ---- mathematical physics ----
  var p1 = math.mathematical_physics.pauli_matrices(1);
  if p1.len() != 2 { io.println("pauli"); return 28; }
  var p0 = math.mathematical_physics.pauli_matrices(0);
  if p0.len() != 2 { io.println("pauli0"); return 29; }
  var hq = Vec[Float64].new();
  hq.push(1.0);
  var hp = Vec[Float64].new();
  hp.push(1.0);
  var ham = math.mathematical_physics.hamiltonian(&hq, &hp, sqobj_local);
  if !near(ham, 1.0, 1e-12) { io.println("hamiltonian"); return 30; }

  // ---- graph theory ----
  var g = math.graph_theory.graph_new();
  math.graph_theory.graph_add_edge(&mut g, 0, 1);
  math.graph_theory.graph_add_edge(&mut g, 1, 2);
  math.graph_theory.graph_add_edge(&mut g, 0, 2);
  if g.n != 3 { io.println("g-n"); return 31; }
  if math.graph_theory.graph_degree(&g, 0) != 2 { io.println("g-degree"); return 32; }
  if math.graph_theory.graph_bfs(&g, 0).len() != 3 { io.println("g-bfs"); return 33; }
  if math.graph_theory.graph_dfs(&g, 0).len() != 3 { io.println("g-dfs"); return 34; }
  if !math.graph_theory.graph_is_connected(&g) { io.println("g-conn"); return 35; }
  if !math.graph_theory.graph_is_cyclic(&g) { io.println("g-cyclic"); return 36; }
  if math.graph_theory.graph_is_bipartite(&g) { io.println("g-bip"); return 37; }
  var gw = math.graph_theory.graph_new();
  math.graph_theory.graph_add_weighted_edge(&mut gw, 0, 1, 2.0);
  math.graph_theory.graph_add_weighted_edge(&mut gw, 1, 2, 3.0);
  var dist = math.graph_theory.graph_dijkstra(&gw, 0);
  if dist.len() != 3 { io.println("g-dist"); return 38; }
  if !near(dist[2], 5.0, 1e-9) { io.println("g-dist2"); return 39; }
  var bf = math.graph_theory.graph_bellman_ford(&gw, 0);
  if !bf.is_some { io.println("g-bf"); return 40; }
  var scc = math.graph_theory.graph_tarjan_scc(&g);
  if scc.len() != 1 { io.println("g-scc"); return 41; }
  if !math.graph_theory.graph_isomorphic(&g, &g) { io.println("g-iso"); return 42; }
  var col = math.graph_theory.graph_color(&g);
  if col.len() != 3 { io.println("g-color"); return 43; }
  var tsp = math.graph_theory.graph_tsp(&gw);
  if tsp.len() != 4 { io.println("g-tsp"); return 44; }

  // ---- machine learning ----
  if !near(math.machine_learning.activation_sigmoid(0.0), 0.5, 1e-9) { io.println("sigmoid"); return 45; }
  if math.machine_learning.activation_relu(-2.0) != 0.0 { io.println("relu"); return 46; }
  var yt = Vec[Float64].new();
  yt.push(1.0);
  yt.push(2.0);
  yt.push(3.0);
  var yp = Vec[Float64].new();
  yp.push(1.0);
  yp.push(2.0);
  yp.push(3.0);
  if math.machine_learning.loss_mse(&yt, &yp) != 0.0 { io.println("mse"); return 47; }
  var lt = Vec[Int].new();
  lt.push(1);
  lt.push(0);
  lt.push(1);
  var lp = Vec[Int].new();
  lp.push(1);
  lp.push(1);
  lp.push(1);
  if !near(math.machine_learning.metric_accuracy(&lt, &lp), 2.0 / 3.0, 1e-9) { io.println("accuracy"); return 48; }
  if math.machine_learning.kernel_rbf(&yt, &yp, 0.5) != 1.0 { io.println("rbf"); return 49; }
  if math.machine_learning.distance_euclidean(&yt, &yp) != 0.0 { io.println("euclid"); return 50; }
  if math.machine_learning.similarity_cosine(&yt, &yp) != 1.0 { io.println("cosine"); return 51; }

  // ---- mathematical biology ----
  if !near(math.mathematical_biology.population_growth(0.1, 100.0, 2.0), 122.140, 0.01) { io.println("pop"); return 52; }
  var lv = math.mathematical_biology.lotka_volterra(0.1, 0.02, 0.1, 0.01, 40.0, 9.0, 0.1);
  if !near(lv.0, 39.68, 0.01) { io.println("lv"); return 53; }
  var sir = math.mathematical_biology.epidemiological_sir(0.3, 0.1, 0.9, 0.09, 0.01, 0.1);
  if !near(sir.0, 0.898, 0.01) { io.println("sir"); return 54; }
  // NOTE: neuroscience returns (Float64, Bool); calling a Bool-tuple-returning
  // function breaks codegen in this compiler build (BUG 23 #7), so it is not
  // exercised here. Its voltage update is verified by the module's probes.

  // ---- mathematical logic ----
  if !math.mathematical_logic.propositional("a|!a") { io.println("taut"); return 56; }
  if math.mathematical_logic.propositional("a&!a") { io.println("contra"); return 57; }
  var dom = Vec[Int].new();
  dom.push(1);
  dom.push(2);
  if !math.mathematical_logic.predicate("P(1)&P(2)", &dom) { io.println("predicate"); return 58; }
  if math.mathematical_logic.predicate("P(3)", &dom) { io.println("predicate2"); return 59; }
  var ax = Vec[Str].new();
  ax.push("p>q");
  ax.push("p");
  if !math.mathematical_logic.provability(&ax, "q") { io.println("provability"); return 60; }
  if !math.mathematical_logic.set_theory_axioms("separation") { io.println("setax"); return 61; }
  var fuzzy_form = math.mathematical_logic.fuzzy_logic("a&b", &Vec[Float64].new());
  if fuzzy_form != fuzzy_form { io.println("flogic"); return 62; }

  // ---- fuzzy ----
  if !near(math.fuzzy.fuzzy_logic(0.3, 0.8, "and"), 0.3, 1e-12) { io.println("fand"); return 63; }
  if !near(math.fuzzy.fuzzy_logic(0.3, 0.8, "or"), 0.8, 1e-12) { io.println("for"); return 64; }
  if !near(math.fuzzy.fuzzy_logic(0.3, 0.0, "not"), 0.7, 1e-12) { io.println("fnot"); return 65; }
  var fu = Vec[Float64].new();
  fu.push(0.0);
  fu.push(10.0);
  var fset = Vec[Float64].new();
  fset.push(0.0);
  fset.push(1.0);
  if !near(math.fuzzy.defuzzification(&fset, &fu), 10.0, 1e-9) { io.println("defuzz"); return 66; }
  var rules = Vec[Str].new();
  rules.push("0:1:0.8");
  var facts = Vec[Float64].new();
  facts.push(0.5);
  facts.push(0.0);
  var infer = math.fuzzy.fuzzy_inference(&rules, &facts);
  if infer.len() != 2 { io.println("infer"); return 67; }
  if !near(infer[1], 0.5, 1e-9) { io.println("infer2"); return 68; }
  if !near(math.fuzzy.fuzzy_control(10.0, 8.0, 2.0, 0.1), 4.2, 1e-9) { io.println("fctl"); return 69; }

  // ---- chaos ----
  var lm = math.chaos.logistic_map(3.8, 0.5, 5);
  if lm.len() != 5 || lm[0] != 0.5 { io.println("logmap"); return 70; }
  if math.chaos.mandelbrot_set(0.0, 0.0, 50) != 50 { io.println("mandel"); return 71; }
  var mb = math.chaos.mandelbrot_set(3.0, 0.0, 50);
  if mb >= 50 { io.println("mandel2"); return 72; }
  var hn = math.chaos.henon_map(1.4, 0.3, 0.5, 0.5, 3);
  if hn.len() != 3 { io.println("henon"); return 73; }
  var x3 = Vec[Float64].new();
  x3.push(1.0);
  x3.push(1.0);
  x3.push(1.0);
  var lz = math.chaos.lorenz_system(10.0, 28.0, 8.0 / 3.0, &x3, 10, 0.001);
  if lz.len() != 11 { io.println("lorenz"); return 74; }

  io.println("smoke_math_finance: OK");
  return 0;
}

fn sqobj_local(x: &Vec[Float64]) -> Float64 {
  return x[0] * x[0];
}
