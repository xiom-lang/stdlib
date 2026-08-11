// XIOM - Geom: Geometry 2D
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom.geometry_2d

// Depends on: xiom.geom

// ============================================================================
// 2D primitives, point containment, intersections, and polygon operations.
// NOTE: current implementation lives in geom/collision.xi + geom/polyhedra.xi
// - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// type Point2 - 2D point; struct { x: Float64; y: Float64 }.
// type Line2 - infinite line; struct { a: Float64; b: Float64; c: Float64 } (a*x + b*y + c = 0).
// type Ray2 - ray; struct { origin: Point2; dir: Vec2 }.
// type Segment2 - segment; struct { a: Point2; b: Point2 }.
// type Circle - circle; struct { center: Point2; radius: Float64 }.
// type Rect - axis-aligned rectangle; struct { min: Point2; max: Point2 }.
// type Triangle2 - triangle; struct { a: Point2; b: Point2; c: Point2 }.
// type Polygon2 - polygon; struct { vertices: Vec[Point2] }.
// fn point_distance(a: Point2, b: Point2) -> Float64 - Euclidean distance between two points. TODO(compiler): implement.
// fn point_in_circle(p: Point2, c: Circle) -> Bool - true if p lies in or on c. TODO(compiler): implement.
// fn point_in_rect(p: Point2, r: Rect) -> Bool - true if p lies in or on r. TODO(compiler): implement.
// fn point_in_triangle(p: Point2, t: Triangle2) -> Bool - true if p lies in or on t. TODO(compiler): implement.
// fn point_in_polygon(p: Point2, poly: Polygon2) -> Bool - ray-casting containment test. TODO(compiler): implement.
// fn line_intersection(l1: Line2, l2: Line2) -> Option[Point2] - intersection of two lines; None if parallel. TODO(compiler): implement.
// fn segment_intersection(s1: Segment2, s2: Segment2) -> Option[Point2] - intersection of two segments; None if disjoint. TODO(compiler): implement.
// fn segment_point_distance(s: Segment2, p: Point2) -> Float64 - shortest distance from p to s. TODO(compiler): implement.
// fn line_point_distance(l: Line2, p: Point2) -> Float64 - perpendicular distance from p to l. TODO(compiler): implement.
// fn circle_intersection(c: Circle, l: Line2) -> Option[Vec[Point2]] - circle-line intersection points. TODO(compiler): implement.
// fn circle_line_intersection(c: Circle, l: Line2) -> Option[Vec[Point2]] - alias of circle_intersection. TODO(compiler): implement.
// fn circle_circle_intersection(c1: Circle, c2: Circle) -> Option[Vec[Point2]] - circle-circle intersection points. TODO(compiler): implement.
// fn area_triangle(t: Triangle2) -> Float64 - signed area of a triangle. TODO(compiler): implement.
// fn area_polygon(poly: Polygon2) -> Float64 - signed area via the shoelace formula. TODO(compiler): implement.
// fn centroid(poly: Polygon2) -> Point2 - area centroid of a polygon. TODO(compiler): implement.
// fn convex_hull(points: &Vec[Point2]) -> Polygon2 - convex hull via monotone chain. TODO(compiler): implement.
// fn is_convex(poly: Polygon2) -> Bool - true if every interior angle is <= 180 degrees. TODO(compiler): implement.
// fn polygon_contains(poly: Polygon2, p: Point2) -> Bool - containment test for p in poly. TODO(compiler): implement.
// fn polygon_intersection(a: Polygon2, b: Polygon2) -> Option[Polygon2] - boolean intersection polygon. TODO(compiler): implement.
// fn polygon_union(a: Polygon2, b: Polygon2) -> Option[Polygon2] - boolean union polygon. TODO(compiler): implement.
// fn polygon_difference(a: Polygon2, b: Polygon2) -> Option[Polygon2] - boolean difference a minus b. TODO(compiler): implement.
// fn polygon_circumference(poly: Polygon2) -> Float64 - perimeter of the polygon. TODO(compiler): implement.
