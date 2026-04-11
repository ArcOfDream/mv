module physics

const max_polygon_verts = 8

// adaptation of C2_TYPE
const collision_none = 0
const collision_circle = 1
const collision_aabb = 2
const collision_capsule = 3
const collision_poly = 4

pub enum CollisionType {
	none
	circle
	aabb
	capsule
	poly
}

// 2d vector
struct C.c2v {
	x f32
	y f32
}

// 2d rotation composed of cos/sin pair for a single angle
// We use two floats as a small optimization to avoid computing sin/cos unnecessarily
struct C.c2r {
	c f32
	s f32
}

struct C.c2m {
	x Vec
	y Vec
}

// 2d transformation "x"
// These are used especially for c2Poly when a c2Poly is passed to a function.
// Since polygons are prime for "instancing" a c2x transform can be used to
// transform a polygon from local space to world space. In functions that take
// a c2x pointer (like c2PolytoPoly), these pointers can be NULL, which represents
// an identity transformation and assumes the verts inside of c2Poly are already
// in world space.
struct C.c2x {
	p Vec
	r Rotation
}

// 2d halfspace (aka plane, aka line)
struct C.c2h {
	n Vec // normal, normalized
	d f32 // distance to origin from plane, or ax + by = d
}

struct C.c2Circle {
	p Vec
	r f32
}

struct C.c2AABB {
	min Vec
	max Vec
}

// a capsule is defined as a line segment (from a to b) and radius r
struct C.c2Capsule {
	a Vec
	b Vec
	r f32
}

struct C.c2Poly {
	count int
	verts [max_polygon_verts]Vec
	norms [max_polygon_verts]Vec
}

// IMPORTANT:
// Many algorithms in this file are sensitive to the magnitude of the
// ray direction (c2Ray::d). It is highly recommended to normalize the
// ray direction and use t to specify a distance. Please see this link
// for an in-depth explanation: https://github.com/RandyGaul/cute_headers/issues/30
struct C.c2Ray {
	p Vec // position
	d Vec // direction
	t f32 // distance along d from position p to find endpoint of ray
}

struct C.c2Raycast {
	t f32 // time of impact
	n Vec // normal of surface at impact (unit length)
}

// contains all information necessary to resolve a collision, or in other words
// this is the information needed to separate shapes that are colliding. Doing
// the resolution step is *not* included in cute_c2.
struct C.c2Manifold {
	count          int
	depths         [2]f32
	contact_points [2]Vec

	// always points from shape A to shape B (first and second shapes passed into
	// any of the c2***to***Manifold functions)
	n Vec
}

pub type Vec = C.c2v
pub type Rotation = C.c2r
pub type RotationMatrix = C.c2m
pub type XTransform = C.c2x
pub type Circle = C.c2Circle
pub type AABB = C.c2AABB
pub type Capsule = C.c2Capsule
pub type Polygon = C.c2Poly
pub type Ray = C.c2Ray
pub type Raycast = C.c2Raycast
pub type Manifold = C.c2Manifold

// boolean collision detection (returns 1 for hit, 0 for miss)
fn C.c2CircletoCircle(a Circle, b Circle) int
fn C.c2CircletoAABB(a Circle, b AABB) int
fn C.c2CircletoCapsule(a Circle, b Capsule) int
fn C.c2AABBtoAABB(a AABB, b AABB) int
fn C.c2AABBtoCapsule(a AABB, b Capsule) int
fn C.c2CapsuletoCapsule(a Capsule, b Capsule) int

// polygons and transforms are passed by pointer in C
fn C.c2CircletoPoly(a Circle, const_b &Polygon, const_bx &XTransform) int
fn C.c2AABBtoPoly(a AABB, const_b &Polygon, const_bx &XTransform) int
fn C.c2CapsuletoPoly(a Capsule, const_b &Polygon, const_bx &XTransform) int
fn C.c2PolytoPoly(const_a &Polygon, const_ax &XTransform, const_b &Polygon, const_bx &XTransform) int

// ray operations
fn C.c2RaytoCircle(a Ray, b Circle, out &Raycast) int
fn C.c2RaytoAABB(a Ray, b AABB, out &Raycast) int
fn C.c2RaytoCapsule(a Ray, b Capsule, out &Raycast) int
fn C.c2RaytoPoly(a Ray, const_b &Polygon, const_bx_ptr &XTransform, out &Raycast) int

// manifold generation (returns void, populates the manifold pointer)
fn C.c2CircletoCircleManifold(a Circle, b Circle, m &Manifold)
fn C.c2CircletoAABBManifold(a Circle, b AABB, m &Manifold)
fn C.c2CircletoCapsuleManifold(a Circle, b Capsule, m &Manifold)
fn C.c2AABBtoAABBManifold(a AABB, b AABB, m &Manifold)
fn C.c2AABBtoCapsuleManifold(a AABB, b Capsule, m &Manifold)
fn C.c2CapsuletoCapsuleManifold(a Capsule, b Capsule, m &Manifold)

fn C.c2CircletoPolyManifold(a Circle, const_b &Polygon, const_bx &XTransform, m &Manifold)
fn C.c2AABBtoPolyManifold(a AABB, const_b &Polygon, const_bx &XTransform, m &Manifold)
fn C.c2CapsuletoPolyManifold(a Capsule, const_b &Polygon, const_bx &XTransform, m &Manifold)
fn C.c2PolytoPolyManifold(const_a &Polygon, const_ax &XTransform, const_b &Polygon, const_bx &XTransform, m &Manifold)

fn C.c2Collided(shape_a voidptr, x_a &XTransform, type_a int, shape_b voidptr, x_b &XTransform, type_b int) int

// adaptation of c2Impact macro
// impact point: p = ray.p + ray.d * t
pub fn (ray Ray) impact(t f32) Vec {
	return Vec{
		x: ray.p.x + (ray.d.x * t)
		y: ray.p.y + (ray.d.y * t)
	}
}

// This is an advanced function, intended to be used by people who know what they're doing.
//
// Runs the GJK algorithm to find closest points, returns distance between closest points.
// outA and outB can be NULL, in this case only distance is returned. ax_ptr and bx_ptr
// can be NULL, and represent local to world transformations for shapes A and B respectively.
// use_radius will apply radii for capsules and circles (if set to false, spheres are
// treated as points and capsules are treated as line segments i.e. rays). The cache parameter
// should be NULL, as it is only for advanced usage (unless you know what you're doing, then
// go ahead and use it). iterations is an optional parameter.
//
// IMPORTANT NOTE:
// The GJK function is sensitive to large shapes, since it internally will compute signed area
// values. `c2GJK` is called throughout cute c2 in many ways, so try to make sure all of your
// collision shapes are not gigantic. For example, try to keep the volume of all your shapes
// less than 100.0f. If you need large shapes, you should use tiny collision geometry for all
// cute c2 function, and simply render the geometry larger on-screen by scaling it up.
// fn C.c2GJK(shape_a voidptr, type_a int, x_a &XTransform, shape_b voidptr, type_b int, x_b &XTransform, out_v_a &Vec, out_v_b &Vec, use_radius int) f32

// --- boolean tests ---

@[inline]
pub fn circle_to_circle(a Circle, b Circle) bool {
	return C.c2CircletoCircle(a, b) != 0
}

@[inline]
pub fn circle_to_aabb(a Circle, b AABB) bool {
	return C.c2CircletoAABB(a, b) != 0
}

@[inline]
pub fn circle_to_capsule(a Circle, b Capsule) bool {
	return C.c2CircletoCapsule(a, b) != 0
}

@[inline]
pub fn aabb_to_aabb(a AABB, b AABB) bool {
	return C.c2AABBtoAABB(a, b) != 0
}

@[inline]
pub fn aabb_to_capsule(a AABB, b Capsule) bool {
	return C.c2AABBtoCapsule(a, b) != 0
}

@[inline]
pub fn capsule_to_capsule(a Capsule, b Capsule) bool {
	return C.c2CapsuletoCapsule(a, b) != 0
}

@[inline]
pub fn circle_to_poly(a Circle, b &Polygon, bx &XTransform) bool {
	return C.c2CircletoPoly(a, b, bx) != 0
}

@[inline]
pub fn aabb_to_poly(a AABB, b &Polygon, bx &XTransform) bool {
	return C.c2AABBtoPoly(a, b, bx) != 0
}

@[inline]
pub fn capsule_to_poly(a Capsule, b &Polygon, bx &XTransform) bool {
	return C.c2CapsuletoPoly(a, b, bx) != 0
}

@[inline]
pub fn poly_to_poly(a &Polygon, ax &XTransform, b &Polygon, bx &XTransform) bool {
	return C.c2PolytoPoly(a, ax, b, bx) != 0
}

// --- raycasting ---

@[inline]
pub fn ray_to_circle(a Ray, b Circle, mut out Raycast) bool {
	return C.c2RaytoCircle(a, b, out) != 0
}

@[inline]
pub fn ray_to_aabb(a Ray, b AABB, mut out Raycast) bool {
	return C.c2RaytoAABB(a, b, out) != 0
}

@[inline]
pub fn ray_to_capsule(a Ray, b Capsule, mut out Raycast) bool {
	return C.c2RaytoCapsule(a, b, out) != 0
}

@[inline]
pub fn ray_to_poly(a Ray, b &Polygon, bx &XTransform, mut out Raycast) bool {
	return C.c2RaytoPoly(a, b, bx, out) != 0
}

// --- manifolds ---

@[inline]
pub fn circle_to_circle_manifold(a Circle, b Circle, mut m Manifold) {
	C.c2CircletoCircleManifold(a, b, m)
}

@[inline]
pub fn circle_to_aabb_manifold(a Circle, b AABB, mut m Manifold) {
	C.c2CircletoAABBManifold(a, b, m)
}

@[inline]
pub fn circle_to_capsule_manifold(a Circle, b Capsule, mut m Manifold) {
	C.c2CircletoCapsuleManifold(a, b, m)
}

@[inline]
pub fn aabb_to_aabb_manifold(a AABB, b AABB, mut m Manifold) {
	C.c2AABBtoAABBManifold(a, b, m)
}

@[inline]
pub fn aabb_to_capsule_manifold(a AABB, b Capsule, mut m Manifold) {
	C.c2AABBtoCapsuleManifold(a, b, m)
}

@[inline]
pub fn capsule_to_capsule_manifold(a Capsule, b Capsule, mut m Manifold) {
	C.c2CapsuletoCapsuleManifold(a, b, m)
}

@[inline]
pub fn circle_to_poly_manifold(a Circle, b &Polygon, bx &XTransform, mut m Manifold) {
	C.c2CircletoPolyManifold(a, b, bx, m)
}

@[inline]
pub fn aabb_to_poly_manifold(a AABB, b &Polygon, bx &XTransform, mut m Manifold) {
	C.c2AABBtoPolyManifold(a, b, bx, m)
}

@[inline]
pub fn capsule_to_poly_manifold(a Capsule, b &Polygon, bx &XTransform, mut m Manifold) {
	C.c2CapsuletoPolyManifold(a, b, bx, m)
}

@[inline]
pub fn poly_to_poly_manifold(a &Polygon, ax &XTransform, b &Polygon, bx &XTransform, mut m Manifold) {
	C.c2PolytoPolyManifold(a, ax, b, bx, m)
}

@[inline]
pub fn collided(shape_a voidptr, x_a &XTransform, type_a CollisionType, shape_b voidptr, x_b &XTransform, type_b CollisionType) bool {
	// we cast the V enum to an int for the C call
	return C.c2Collided(shape_a, x_a, int(type_a), shape_b, x_b, int(type_b)) != 0
}

@[inline]
pub fn collided_smart(shape_a voidptr, x_a ?&XTransform, type_a CollisionType, shape_b voidptr, x_b ?&XTransform, type_b CollisionType) bool {
	// if no transform is provided, we pass a null pointer to C
	mut ptr_a := unsafe { nil }
	mut ptr_b := unsafe { nil }
	if x := x_a { ptr_a = x }
	if x := x_b { ptr_b = x }

	return C.c2Collided(shape_a, ptr_a, int(type_a), shape_b, ptr_b, int(type_b)) != 0
}
