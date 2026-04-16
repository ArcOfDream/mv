module physics

import math

pub struct SweepResult {
pub:
    hit      bool
    ti       f32  // [0,1] parametric time of first contact; 0 = already overlapping
    normal_x f32  // collision normal, pointing away from obstacle toward mover
    normal_y f32
    touch_x  f32  // mover.min.x at moment of contact
    touch_y  f32
}

// sweep_aabb sweeps mover against a stationary obstacle along (vel_x, vel_y).
// Uses the Minkowski difference + Liang-Barsky approach from Bump.lua.
// Returns SweepResult{hit: false} if no contact occurs in [0, 1].
pub fn sweep_aabb(mover AABB, obstacle AABB, vel_x f32, vel_y f32) SweepResult {
    mw := mover.max.x - mover.min.x
    mh := mover.max.y - mover.min.y

    // Inflate obstacle by mover's size so we can treat mover as a point (its min corner)
    diff_min_x := obstacle.min.x - mw
    diff_min_y := obstacle.min.y - mh
    diff_max_x := obstacle.max.x
    diff_max_y := obstacle.max.y

    px := mover.min.x
    py := mover.min.y

    // Already overlapping: find minimum separation direction
    if px > diff_min_x && px < diff_max_x && py > diff_min_y && py < diff_max_y {
        left   := px - diff_min_x
        right  := diff_max_x - px
        top    := py - diff_min_y
        bottom := diff_max_y - py
        min_d  := math.min(math.min(left, right), math.min(top, bottom))
        mut nx := f32(0)
        mut ny := f32(0)
        if      min_d == left   { nx = -1 }
        else if min_d == right  { nx =  1 }
        else if min_d == top    { ny = -1 }
        else                    { ny =  1 }
        return SweepResult{ hit: true, ti: 0, normal_x: nx, normal_y: ny, touch_x: px, touch_y: py }
    }

    if vel_x == 0 && vel_y == 0 {
        return SweepResult{}
    }

    // Liang-Barsky clip against the four slab boundaries
    mut ti1 := f32(-math.max_f32)
    mut ti2 :=  f32(math.max_f32)
    mut nx  := f32(0)
    mut ny  := f32(0)

    if !lb_clip(-vel_x, px - diff_min_x, mut ti1, mut ti2, mut nx, mut ny, -1,  0) { return SweepResult{} }
    if !lb_clip( vel_x, diff_max_x - px, mut ti1, mut ti2, mut nx, mut ny,  1,  0) { return SweepResult{} }
    if !lb_clip(-vel_y, py - diff_min_y, mut ti1, mut ti2, mut nx, mut ny,  0, -1) { return SweepResult{} }
    if !lb_clip( vel_y, diff_max_y - py, mut ti1, mut ti2, mut nx, mut ny,  0,  1) { return SweepResult{} }

    if ti1 >= 1 || ti1 < 0 || ti2 <= 0 {
        return SweepResult{}
    }

    return SweepResult{
        hit:      true
        ti:       ti1
        normal_x: nx
        normal_y: ny
        touch_x:  px + vel_x * ti1
        touch_y:  py + vel_y * ti1
    }
}

// lb_clip performs one Liang-Barsky slab test.
// Updates the entry time ti1 (and its normal) and exit time ti2.
// Returns false if the segment is entirely outside this slab.
@[inline]
fn lb_clip(p f32, q f32, mut ti1 &f32, mut ti2 &f32, mut nx &f32, mut ny &f32, nxi f32, nyi f32) bool {
    if p == 0 {
        return q >= 0  // parallel to slab: inside only if q >= 0
    }
    r := q / p
    if p < 0 {
        if r > ti2 { return false }
        if r > ti1 { ti1 = r; nx = nxi; ny = nyi }
    } else {
        if r < ti1 { return false }
        if r < ti2 { ti2 = r }
    }
    return true
}