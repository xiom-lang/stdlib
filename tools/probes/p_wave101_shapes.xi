// p_wave101_shapes.xi -- wave 101 shape validation: graph_theory + machine_learning
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-101 clause guards:
//   (a) xiom.math.graph_theory: the empty-graph constructor identity, the
//       negative-input guards (add_vertex/add_edge/add_weighted_edge/
//       remove_vertex/has/degree/dfs/bfs/dijkstra/bellman_ford/astar),
//       the edge-list length mirrors, the presence guards on
//       bellman_ford/prim/kruskal/topological_sort/hamiltonian_path,
//       the flow/cut/tsp shape and empty identities;
//   (b) xiom.math.machine_learning: the activation pins, the loss/metric/
//       kernel/distance/similarity mismatch NaN guards, the empty-input
//       identities, the normalization/dropout shape guards and the
//       regularization zero pins.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave101_shapes

use xiom.math.graph_theory as gr;
use xiom.math.machine_learning as ml;

fn main() -> Int {
  // ---- graph_theory: empty constructor identity
  var g0 = gr.graph_new();
  let n0 = g0.n;
  if n0 != 0 { return 1; }
  let e0 = g0.edges.len();
  if e0 != 0 { return 2; }
  let w0 = g0.weights.len();
  if w0 != 0 { return 3; }

  // ---- graph_theory: vertex/edge construction guards
  var g = gr.graph_new();
  let av0 = gr.graph_add_vertex(&mut g, 2);
  if av0 != true { return 4; }
  let gn = g.n;
  if gn != 3 { return 5; }
  let av1 = gr.graph_add_vertex(&mut g, -1);
  if av1 != false { return 6; }

  let ae0 = gr.graph_add_edge(&mut g, 0, 1);
  if ae0 != true { return 7; }
  let ae1 = gr.graph_add_edge(&mut g, -1, 1);
  if ae1 != false { return 8; }
  let aw0 = gr.graph_add_weighted_edge(&mut g, 1, 2, 3.0);
  if aw0 != true { return 9; }
  let aw1 = gr.graph_add_weighted_edge(&mut g, 0, 1, -2.0);
  if aw1 != true { return 10; }
  let aw2 = gr.graph_add_weighted_edge(&mut g, 0, -1, 1.0);
  if aw2 != false { return 11; }
  let ae2 = gr.graph_add_edge(&mut g, 0, 2);
  if ae2 != true { return 12; }

  // ---- graph_theory: presence/degree/shape mirrors
  let hv0 = gr.graph_has_vertex(&g, 0);
  if hv0 != true { return 13; }
  let hv1 = gr.graph_has_vertex(&g, 9);
  if hv1 != false { return 14; }
  let he0 = gr.graph_has_edge(&g, 0, 1);
  if he0 != true { return 15; }
  let he1 = gr.graph_has_edge(&g, 0, 5);
  if he1 != false { return 16; }
  let he2 = gr.graph_has_edge(&g0, 0, 1);
  if he2 != false { return 17; }
  let dg0 = gr.graph_degree(&g, 0);
  if dg0 != 3 { return 18; }
  let dg1 = gr.graph_degree(&g, 9);
  if dg1 != 0 { return 19; }
  let vts = gr.graph_vertices(&g);
  let vn = vts.len();
  if vn != 3 { return 20; }
  let eds = gr.graph_edges(&g);
  let en = eds.len();
  if en != 8 { return 21; }
  let ad0 = gr.graph_adjacent(&g, 1, 0);
  if ad0 != true { return 22; }
  let ad1 = gr.graph_adjacent(&g, 0, 5);
  if ad1 != false { return 23; }
  let ad2 = gr.graph_adjacent(&g0, 0, 1);
  if ad2 != false { return 24; }

  // ---- graph_theory: traversal guards
  let dfs0 = gr.graph_dfs(&g, 0);
  if dfs0.len() != 3 { return 25; }
  let dfs1 = gr.graph_dfs(&g, -1);
  if dfs1.len() != 0 { return 26; }
  let bfs0 = gr.graph_bfs(&g, 0);
  if bfs0.len() != 3 { return 27; }
  let bfs1 = gr.graph_bfs(&g, 5);
  if bfs1.len() != 0 { return 28; }

  // ---- graph_theory: shortest paths
  var gw = gr.graph_new();
  gr.graph_add_weighted_edge(&mut gw, 0, 1, 2.0);
  gr.graph_add_weighted_edge(&mut gw, 1, 2, 3.0);
  let dw = gr.graph_dijkstra(&gw, 0);
  if dw.len() != 3 { return 29; }
  let dw0 = dw[0];
  if dw0 != 0.0 { return 30; }
  let dw2 = dw[2];
  if dw2 != 5.0 { return 31; }
  let dwi = gr.graph_dijkstra(&gw, 9);
  if dwi.len() != 0 { return 32; }

  let bf0 = gr.graph_bellman_ford(&gw, 0);
  if bf0.is_some != true { return 33; }
  let bf1 = gr.graph_bellman_ford(&gw, -1);
  if bf1.is_none != true { return 34; }

  let fw = gr.graph_floyd_warshall(&gw);
  if fw.len() != 3 { return 35; }

  let as0 = gr.graph_astar(&gw, 0, 2, fn(a: Int, b: Int) -> Float64 { return 0.0; });
  if as0.is_some != true { return 36; }
  let as1 = gr.graph_astar(&gw, 0, 9, fn(a: Int, b: Int) -> Float64 { return 0.0; });
  if as1.is_none != true { return 37; }

  // ---- graph_theory: spanning trees
  let pr0 = gr.graph_prim(&gw);
  if pr0.is_some != true { return 38; }
  let pr1 = gr.graph_prim(&g0);
  if pr1.is_none != true { return 39; }
  let kr0 = gr.graph_kruskal(&gw);
  if kr0.is_some != true { return 40; }
  let kr1 = gr.graph_kruskal(&g0);
  if kr1.is_none != true { return 41; }

  // ---- graph_theory: components / ordering
  let tc = gr.graph_tarjan_scc(&g);
  if tc.len() != 1 { return 42; }
  let tc0 = gr.graph_tarjan_scc(&g0);
  if tc0.len() != 0 { return 43; }
  let ks = gr.graph_kosaraju_scc(&g);
  if ks.len() != 1 { return 44; }
  let ks0 = gr.graph_kosaraju_scc(&g0);
  if ks0.len() != 0 { return 45; }
  let ts0 = gr.graph_topological_sort(&g0);
  if ts0.is_some != true { return 46; }
  let ts1 = gr.graph_topological_sort(&g);
  if ts1.is_none != true { return 47; }

  // ---- graph_theory: predicates
  let ic0 = gr.graph_is_connected(&g);
  if ic0 != true { return 48; }
  let ic1 = gr.graph_is_connected(&g0);
  if ic1 != true { return 49; }
  var g2 = gr.graph_new();
  gr.graph_add_vertex(&mut g2, 2);
  let ic2 = gr.graph_is_connected(&g2);
  if ic2 != false { return 50; }
  let cy0 = gr.graph_is_cyclic(&g);
  if cy0 != true { return 51; }
  let cy1 = gr.graph_is_cyclic(&g2);
  if cy1 != false { return 52; }
  let cy2 = gr.graph_is_cyclic(&g0);
  if cy2 != false { return 53; }
  var g3 = gr.graph_new();
  gr.graph_add_edge(&mut g3, 0, 1);
  gr.graph_add_edge(&mut g3, 1, 2);
  let bp0 = gr.graph_is_bipartite(&g3);
  if bp0 != true { return 54; }
  let bp1 = gr.graph_is_bipartite(&g);
  if bp1 != false { return 55; }
  let iso0 = gr.graph_isomorphic(&g3, &g3);
  if iso0 != true { return 56; }
  let iso1 = gr.graph_isomorphic(&g3, &g);
  if iso1 != false { return 57; }

  // ---- graph_theory: coloring
  let col = gr.graph_color(&g3);
  if col.len() != 3 { return 58; }
  let col0 = col[0];
  if col0 != 0 { return 59; }
  let col1 = col[1];
  if col1 != 1 { return 60; }

  // ---- graph_theory: flow / cut / hamiltonian / tsp
  let mf0 = gr.graph_max_flow(&g3, 0, 2);
  if mf0 < 0.0 { return 61; }
  let mf1 = gr.graph_max_flow(&g3, 0, 0);
  if mf1 != 0.0 { return 62; }
  let mf2 = gr.graph_max_flow(&g3, 3, 2);
  if mf2 != 0.0 { return 63; }
  let mc0 = gr.graph_min_cut(&g3, 0, 2);
  if mc0.len() < 1 { return 64; }
  let mc1 = gr.graph_min_cut(&g3, 9, 2);
  if mc1.len() != 0 { return 65; }
  let hp0 = gr.graph_hamiltonian_path(&g3);
  if hp0.is_some != true { return 66; }
  let hp1 = gr.graph_hamiltonian_path(&g2);
  if hp1.is_none != true { return 67; }
  let hp2 = gr.graph_hamiltonian_path(&g0);
  if hp2.is_some != true { return 68; }
  let tsp0 = gr.graph_tsp(&g3);
  if tsp0.len() != 4 { return 69; }
  let tspa = tsp0[0];
  if tspa != 0 { return 70; }
  let tspb = tsp0[3];
  if tspb != 0 { return 71; }
  let tsp1 = gr.graph_tsp(&g0);
  if tsp1.len() != 0 { return 72; }

  // ---- graph_theory: removals
  var grm = gr.graph_new();
  gr.graph_add_edge(&mut grm, 0, 1);
  gr.graph_add_edge(&mut grm, 1, 2);
  let rv0 = gr.graph_remove_vertex(&mut grm, 1);
  if rv0 != true { return 73; }
  let rv1 = gr.graph_remove_vertex(&mut grm, 9);
  if rv1 != false { return 74; }
  var gre = gr.graph_new();
  gr.graph_add_edge(&mut gre, 0, 1);
  let re0 = gr.graph_remove_edge(&mut gre, 0, 1);
  if re0 != true { return 75; }
  let re1 = gr.graph_remove_edge(&mut gre, 0, 1);
  if re1 != false { return 76; }
  let re2 = gr.graph_remove_edge(&g0, 0, 1);
  if re2 != false { return 77; }

  // ---- machine_learning: activations
  let sg0 = ml.activation_sigmoid(0.0);
  if sg0 < 0.499 || sg0 > 0.501 { return 78; }
  let sg1 = ml.activation_sigmoid(2.0);
  if sg1 <= 0.0 || sg1 > 1.0 { return 79; }
  let sg2 = ml.activation_sigmoid(-2.0);
  if sg2 < 0.0 || sg2 >= 0.5 { return 80; }
  let th0 = ml.activation_tanh(0.0);
  if th0 != 0.0 { return 81; }
  let th1 = ml.activation_tanh(1.0);
  if th1 <= 0.0 || th1 >= 1.0 { return 82; }
  let th2 = ml.activation_tanh(-1.0);
  if th2 >= 0.0 || th2 <= -1.0 { return 83; }
  let rl0 = ml.activation_relu(2.0);
  if rl0 != 2.0 { return 84; }
  let rl1 = ml.activation_relu(-2.0);
  if rl1 != 0.0 { return 85; }
  let ge0 = ml.activation_gelu(0.0);
  if ge0 != 0.0 { return 86; }
  let sw0 = ml.activation_swish(0.0);
  if sw0 != 0.0 { return 87; }

  // ---- machine_learning: fixtures
  var ef = Vec[Float64].new();
  var v1 = Vec[Float64].new();
  v1.push(1.0);
  var v2 = Vec[Float64].new();
  v2.push(3.0);
  v2.push(4.0);
  var da = Vec[Float64].new();
  da.push(0.0);
  da.push(0.0);
  var i0 = Vec[Int].new();
  i0.push(0);
  var i1 = Vec[Int].new();
  i1.push(1);

  // ---- machine_learning: losses
  let lm0 = ml.loss_mse(&v1, &v1);
  if lm0 != 0.0 { return 88; }
  let lm1 = ml.loss_mse(&v1, &v2);
  if lm1 == lm1 { return 89; }
  let la0 = ml.loss_mae(&v1, &v1);
  if la0 != 0.0 { return 90; }
  let la1 = ml.loss_mae(&v2, &v1);
  if la1 == la1 { return 91; }
  let lh0 = ml.loss_huber(&v1, &v1, 0.0);
  if lh0 == lh0 { return 92; }
  let lh1 = ml.loss_huber(&v1, &v1, 1.0);
  if lh1 != 0.0 { return 93; }
  let lhi0 = ml.loss_hinge(&ef, &ef);
  if lhi0 == lhi0 { return 94; }
  let lce0 = ml.loss_cross_entropy(&ef, &ef);
  if lce0 != 0.0 { return 95; }
  let lce1 = ml.loss_cross_entropy(&v1, &v2);
  if lce1 == lce1 { return 96; }

  // ---- machine_learning: metrics
  let ma0 = ml.metric_accuracy(&ef, &ef);
  if ma0 != 0.0 { return 97; }
  let ma1 = ml.metric_accuracy(&i1, &i1);
  if ma1 != 1.0 { return 98; }
  let ma2 = ml.metric_accuracy(&i1, &ef);
  if ma2 == ma2 { return 99; }
  let mp0 = ml.metric_precision(&i0, &i0);
  if mp0 != 0.0 { return 100; }
  let mp1 = ml.metric_precision(&i1, &ef);
  if mp1 == mp1 { return 101; }
  let mr0 = ml.metric_recall(&i0, &i0);
  if mr0 != 0.0 { return 102; }
  let mr1 = ml.metric_recall(&i1, &ef);
  if mr1 == mr1 { return 103; }
  let mf0 = ml.metric_f1(&i0, &i0);
  if mf0 != 0.0 { return 104; }
  let mf1 = ml.metric_f1(&i1, &ef);
  if mf1 == mf1 { return 105; }
  var aucy = Vec[Int].new();
  aucy.push(0);
  aucy.push(1);
  var aucp = Vec[Float64].new();
  aucp.push(0.1);
  aucp.push(0.9);
  let auc0 = ml.metric_auc(&aucy, &aucp);
  if auc0 < 0.999 { return 106; }
  var yy = Vec[Int].new();
  yy.push(1);
  yy.push(1);
  let auc1 = ml.metric_auc(&yy, &aucp);
  if auc1 == auc1 { return 107; }
  let auc2 = ml.metric_auc(&aucy, &v1);
  if auc2 == auc2 { return 108; }

  // ---- machine_learning: regularization / normalization / dropout
  let rg0 = ml.regularization_l1(&ef, 1.0);
  if rg0 != 0.0 { return 109; }
  let rg1 = ml.regularization_l2(&ef, 1.0);
  if rg1 != 0.0 { return 110; }
  let rg2 = ml.regularization_elastic_net(&ef, 1.0, 1.0);
  if rg2 != 0.0 { return 111; }
  let nl0 = ml.normalization_layer(&ef);
  if nl0.len() != 0 { return 112; }
  let nl1 = ml.normalization_layer(&v1);
  if nl1.len() != 1 { return 113; }
  let ng0 = ml.normalization_group(&v2, 0);
  if ng0.len() != 0 { return 114; }
  var v4 = Vec[Float64].new();
  v4.push(1.0);
  v4.push(2.0);
  v4.push(3.0);
  v4.push(4.0);
  let ng1 = ml.normalization_group(&v4, 2);
  if ng1.len() != 4 { return 115; }
  let ng2 = ml.normalization_group(&v4, 3);
  if ng2.len() != 0 { return 116; }
  let dp0 = ml.dropout(&v4, -0.5, 1);
  if dp0.len() != 0 { return 117; }
  let dp1 = ml.dropout(&v4, 1.0, 1);
  if dp1.len() != 0 { return 118; }
  let dp2 = ml.dropout(&v4, 0.5, 7);
  if dp2.len() != 4 { return 119; }

  // ---- machine_learning: kernels
  let kr0 = ml.kernel_rbf(&ef, &ef, 0.5);
  if kr0 != 1.0 { return 120; }
  let kr1 = ml.kernel_rbf(&v1, &v2, 0.5);
  if kr1 == kr1 { return 121; }
  let kp0 = ml.kernel_polynomial(&v1, &v1, 0, 0.0);
  if kp0 != 1.0 { return 122; }
  let kp1 = ml.kernel_polynomial(&v1, &v2, 2, 0.0);
  if kp1 == kp1 { return 123; }
  let ks1 = ml.kernel_sigmoid(&v1, &v2, 1.0, 0.0);
  if ks1 == ks1 { return 124; }

  // ---- machine_learning: distances
  let de0 = ml.distance_euclidean(&ef, &ef);
  if de0 != 0.0 { return 125; }
  let de1 = ml.distance_euclidean(&da, &v2);
  if de1 != 5.0 { return 126; }
  let de2 = ml.distance_euclidean(&v1, &v2);
  if de2 == de2 { return 127; }
  let dm0 = ml.distance_manhattan(&ef, &ef);
  if dm0 != 0.0 { return 128; }
  let dm1 = ml.distance_manhattan(&da, &v2);
  if dm1 != 7.0 { return 129; }
  let dk0 = ml.distance_minkowski(&v1, &v2, 0.0);
  if dk0 == dk0 { return 130; }
  let dk1 = ml.distance_minkowski(&ef, &ef, 2.0);
  if dk1 != 0.0 { return 131; }
  let dc0 = ml.distance_cosine(&da, &v2);
  if dc0 == dc0 { return 132; }
  let dc1 = ml.distance_cosine(&v2, &v2);
  if dc1 != 0.0 { return 133; }
  let dc2 = ml.distance_cosine(&v1, &v2);
  if dc2 == dc2 { return 134; }

  // ---- machine_learning: similarities
  let sc0 = ml.similarity_cosine(&ef, &ef);
  if sc0 == sc0 { return 135; }
  let sc1 = ml.similarity_cosine(&v2, &v2);
  if sc1 != 1.0 { return 136; }
  let sc2 = ml.similarity_cosine(&v1, &v2);
  if sc2 == sc2 { return 137; }
  let sj0 = ml.similarity_jaccard(&ef, &ef);
  if sj0 != 1.0 { return 138; }
  let sd0 = ml.similarity_dice(&ef, &ef);
  if sd0 != 1.0 { return 139; }

  return 0;
}
