// Smoke: xiom.math.vectors (fixed-size Vec2/3/4 + dynamic vec_* functions).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // Vec2 construction / arithmetic
  var a2 = math.vectors.vec2_new(1.0, 2.0);
  var b2 = math.vectors.vec2_new(3.0, 4.0);
  var s2 = math.vectors.vec2_add(a2, b2);
  if s2.x != 4.0 || s2.y != 6.0 { io.println("v2-add"); return 1; }
  var d2 = math.vectors.vec2_sub(b2, a2);
  if d2.x != 2.0 || d2.y != 2.0 { io.println("v2-sub"); return 2; }
  var sc2 = math.vectors.vec2_scale(a2, 2.0);
  if sc2.x != 2.0 || sc2.y != 4.0 { io.println("v2-scale"); return 3; }
  var dot2 = math.vectors.vec2_dot(a2, b2);
  if dot2 != 11.0 { io.println("v2-dot"); return 4; }
  var len2 = math.vectors.vec2_len(math.vectors.vec2_new(3.0, 4.0));
  if len2 != 5.0 { io.println("v2-len"); return 5; }
  var n2 = math.vectors.vec2_norm(math.vectors.vec2_new(3.0, 4.0));
  if !near(n2.x, 0.6) || !near(n2.y, 0.8) { io.println("v2-norm"); return 6; }
  var z2 = math.vectors.vec2_norm(math.vectors.vec2_new(0.0, 0.0));
  if z2.x != 0.0 || z2.y != 0.0 { io.println("v2-norm-zero"); return 7; }
  var dist2 = math.vectors.vec2_dist(math.vectors.vec2_new(1.0, 2.0), math.vectors.vec2_new(4.0, 6.0));
  if dist2 != 5.0 { io.println("v2-dist"); return 8; }
  var l2 = math.vectors.vec2_lerp(math.vectors.vec2_new(0.0, 0.0), math.vectors.vec2_new(2.0, 4.0), 0.5);
  if l2.x != 1.0 || l2.y != 2.0 { io.println("v2-lerp"); return 9; }

  // Vec3 construction / arithmetic
  var a3 = math.vectors.vec3_new(1.0, 2.0, 3.0);
  var b3 = math.vectors.vec3_new(4.0, 5.0, 6.0);
  var s3 = math.vectors.vec3_add(a3, b3);
  if s3.x != 5.0 || s3.y != 7.0 || s3.z != 9.0 { io.println("v3-add"); return 10; }
  var d3 = math.vectors.vec3_sub(b3, a3);
  if d3.x != 3.0 || d3.y != 3.0 || d3.z != 3.0 { io.println("v3-sub"); return 11; }
  var sc3 = math.vectors.vec3_scale(a3, 2.0);
  if sc3.x != 2.0 || sc3.y != 4.0 || sc3.z != 6.0 { io.println("v3-scale"); return 12; }
  var dot3 = math.vectors.vec3_dot(a3, b3);
  if dot3 != 32.0 { io.println("v3-dot"); return 13; }
  var c3 = math.vectors.vec3_cross(math.vectors.vec3_new(1.0, 0.0, 0.0), math.vectors.vec3_new(0.0, 1.0, 0.0));
  if c3.x != 0.0 || c3.y != 0.0 || c3.z != 1.0 { io.println("v3-cross"); return 14; }
  var len3 = math.vectors.vec3_len(math.vectors.vec3_new(1.0, 2.0, 2.0));
  if len3 != 3.0 { io.println("v3-len"); return 15; }
  var n3 = math.vectors.vec3_norm(math.vectors.vec3_new(3.0, 0.0, 0.0));
  if n3.x != 1.0 || n3.y != 0.0 || n3.z != 0.0 { io.println("v3-norm"); return 16; }

  // Vec4 construction / arithmetic
  var a4 = math.vectors.vec4_new(1.0, 2.0, 3.0, 4.0);
  var b4 = math.vectors.vec4_new(1.0, 1.0, 1.0, 1.0);
  var s4 = math.vectors.vec4_add(a4, b4);
  if s4.x != 2.0 || s4.y != 3.0 || s4.z != 4.0 || s4.w != 5.0 { io.println("v4-add"); return 17; }
  var d4 = math.vectors.vec4_sub(a4, b4);
  if d4.x != 0.0 || d4.y != 1.0 || d4.z != 2.0 || d4.w != 3.0 { io.println("v4-sub"); return 18; }
  var sc4 = math.vectors.vec4_scale(a4, 2.0);
  if sc4.x != 2.0 || sc4.y != 4.0 || sc4.z != 6.0 || sc4.w != 8.0 { io.println("v4-scale"); return 19; }
  var dot4 = math.vectors.vec4_dot(a4, b4);
  if dot4 != 10.0 { io.println("v4-dot"); return 20; }
  var len4 = math.vectors.vec4_len(math.vectors.vec4_new(1.0, 1.0, 1.0, 1.0));
  if len4 != 2.0 { io.println("v4-len"); return 21; }
  var n4 = math.vectors.vec4_norm(math.vectors.vec4_new(2.0, 0.0, 0.0, 0.0));
  if n4.x != 1.0 || n4.y != 0.0 || n4.z != 0.0 || n4.w != 0.0 { io.println("v4-norm"); return 22; }

  // Dynamic vectors (main-created Vec[Float64] passed by reference).
  var va = Vec[Float64].new();
  va.push(1.0);
  va.push(2.0);
  va.push(3.0);
  var vb = Vec[Float64].new();
  vb.push(4.0);
  vb.push(5.0);
  vb.push(6.0);
  var vdot = math.vectors.vec_dot(&va, &vb);
  if vdot != 32.0 { io.println("vec-dot"); return 23; }
  var vn = math.vectors.vec_norm(&va);
  var vn2 = math.roots.sqrt(14.0);
  var nd = vn - vn2;
  if nd < 0.0 { nd = -nd; }
  if nd > 1e-9 { io.println("vec-norm"); return 24; }

  // vec_scale: verify through scalar invariants (dot with original, norm).
  var scaled = math.vectors.vec_scale(&va, 2.0);
  var sdot = math.vectors.vec_dot(&scaled, &va);
  if sdot != 28.0 { io.println("vec-scale-dot"); return 25; }
  var snorm = math.vectors.vec_norm(&scaled);
  var snorm2 = math.roots.sqrt(56.0);
  var sd2 = snorm - snorm2;
  if sd2 < 0.0 { sd2 = -sd2; }
  if sd2 > 1e-9 { io.println("vec-scale-norm"); return 26; }

  // vec_dot on mismatched lengths returns NaN (documented sentinel).
  var vc = Vec[Float64].new();
  vc.push(1.0);
  var bad = math.vectors.vec_dot(&va, &vc);
  if !math.is_nan(bad) { io.println("vec-dot-mismatch"); return 27; }

  io.println("smoke_math_vectors: OK");
  return 0;
}
