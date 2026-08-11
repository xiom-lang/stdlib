// XIOM - Collections: Spatial Indexes
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.spatial

// ============================================================================
// Spatial indexes for 2D and 3D points. KD-tree supports nearest-neighbor and
// rectangular range queries; quadtree and octree partition space recursively
// into cells. Queries return the stored values; empty regions yield empty Vecs.
// ============================================================================

// fn kdtree_new() - create an empty KD-tree. TODO(compiler): implement.
// fn kdtree_insert(t, x: Int, y: Int, value: Int) - insert a 2D point. TODO(compiler): implement.
// fn kdtree_nearest(t, x: Int, y: Int) -> Option[Int] - value of the closest point, or None. TODO(compiler): implement.
// fn kdtree_range(t, x1: Int, y1: Int, x2: Int, y2: Int) -> Vec[Int] - values inside the rectangle. TODO(compiler): implement.
// fn kdtree_size(t) -> Int - number of points. TODO(compiler): implement.
// fn quadtree_new(x: Int, y: Int, w: Int, h: Int) - create a quadtree for the given bounds. TODO(compiler): implement.
// fn quadtree_insert(q, x: Int, y: Int, value: Int) -> Bool - insert a 2D point; false if out of bounds. TODO(compiler): implement.
// fn quadtree_query(q, x1: Int, y1: Int, x2: Int, y2: Int) -> Vec[Int] - values inside the rectangle. TODO(compiler): implement.
// fn quadtree_size(q) -> Int - number of points. TODO(compiler): implement.
// fn octree_new(x: Int, y: Int, z: Int, w: Int, h: Int, d: Int) - create an octree for the given bounds. TODO(compiler): implement.
// fn octree_insert(o, x: Int, y: Int, z: Int, value: Int) -> Bool - insert a 3D point; false if out of bounds. TODO(compiler): implement.
// fn octree_query(o, x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int) -> Vec[Int] - values inside the box. TODO(compiler): implement.
// fn octree_size(o) -> Int - number of points. TODO(compiler): implement.
