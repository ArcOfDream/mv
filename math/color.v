module math

pub struct Color {
pub mut:
	value u32 = u32(0xffffffff)
}

pub fn (c Color) str() string {
	return '${c.r()} ${c.g()} ${c.b()} ${c.a()}'
}

pub fn (c Color) eq(b Color) bool {
	return c.value == b.value
}

pub fn Color.from_bytes(r u8, g u8, b u8, a u8) Color {
	return Color{r | (u32(g) << 8) | (u32(b) << 16) | (u32(a) << 24)}
}

pub fn Color.rgb(r f32, g f32, b f32) Color {
	return Color.from_bytes(u8(r * 255), u8(g * 255), u8(b * 255), u8(255))
}

pub fn Color.rgba(r f32, g f32, b f32, a f32) Color {
	return Color.from_bytes(u8(r * 255), u8(g * 255), u8(b * 255), u8(a * 255))
}

pub fn Color.from_ints(r int, g int, b int, a int) Color {
	return Color.from_bytes(u8(r), u8(g), u8(b), u8(a))
}

pub fn (c Color) r() u8 {
	return u8(c.value)
}

pub fn (c Color) g() u8 {
	return u8(c.value >> 8)
}

pub fn (c Color) b() u8 {
	return u8(c.value >> 16)
}

pub fn (c Color) a() u8 {
	return u8(c.value >> 24)
}

pub fn (c Color) r_f() f32 {
	return f32(c.r()) / 255
}

pub fn (c Color) g_f() f32 {
	return f32(c.g()) / 255
}

pub fn (c Color) b_f() f32 {
	return f32(c.b()) / 255
}

pub fn (c Color) a_f() f32 {
	return f32(c.a()) / 255
}

pub fn (mut c Color) set_r(r u8) {
	c.value = (c.value & 0xffffff00) | r
}

pub fn (mut c Color) set_g(g u8) {
	c.value = (c.value & 0xffff00ff) | u32(g) << 8
}

pub fn (mut c Color) set_b(b u8) {
	c.value = (c.value & 0xff00ffff) | u32(b) << 16
}

pub fn (mut c Color) set_a(a u8) {
	c.value = (c.value & 0x00ffffff) | u32(a) << 24
}

pub fn (c Color) mul(scale f32) Color {
	r := int(f32(c.r()) * scale)
	g := int(f32(c.g()) * scale)
	b := int(f32(c.b()) * scale)
	a := int(f32(c.a()) * scale)
	return Color.from_ints(r, g, b, a)
}

pub fn Color.alice_blue() Color {
	return Color{0xfffff8f0}
}

pub fn Color.antique_white() Color {
	return Color{0xffd7ebfa}
}

pub fn Color.aqua() Color {
	return Color{0xffffff00}
}

pub fn Color.aquamarine() Color {
	return Color{0xffd4ff7f}
}

pub fn Color.azure() Color {
	return Color{0xfffffff0}
}

pub fn Color.beige() Color {
	return Color{0xffdcf5f5}
}

pub fn Color.bisque() Color {
	return Color{0xffc4e4ff}
}

pub fn Color.black() Color {
	return Color{0xff000000}
}

pub fn Color.blanched_almond() Color {
	return Color{0xffcdebff}
}

pub fn Color.blue() Color {
	return Color{0xffff0000}
}

pub fn Color.blue_violet() Color {
	return Color{0xffe22b8a}
}

pub fn Color.brown() Color {
	return Color{0xff2a2aa5}
}

pub fn Color.burly_wood() Color {
	return Color{0xff87b8de}
}

pub fn Color.cadet_blue() Color {
	return Color{0xffa09e5f}
}

pub fn Color.chartreuse() Color {
	return Color{0xff00ff7f}
}

pub fn Color.chocolate() Color {
	return Color{0xff1e69d2}
}

pub fn Color.coral() Color {
	return Color{0xff507fff}
}

pub fn Color.cornflower_blue() Color {
	return Color{0xffed9564}
}

pub fn Color.cornsilk() Color {
	return Color{0xffdcf8ff}
}

pub fn Color.crimson() Color {
	return Color{0xff3c14dc}
}

pub fn Color.cyan() Color {
	return Color{0xffffff00}
}

pub fn Color.dark_blue() Color {
	return Color{0xff8b0000}
}

pub fn Color.dark_cyan() Color {
	return Color{0xff8b8b00}
}

pub fn Color.dark_goldenrod() Color {
	return Color{0xff0b86b8}
}

pub fn Color.dark_gray() Color {
	return Color{0xffa9a9a9}
}

pub fn Color.dark_green() Color {
	return Color{0xff006400}
}

pub fn Color.dark_khaki() Color {
	return Color{0xff6bb7bd}
}

pub fn Color.dark_magenta() Color {
	return Color{0xff8b008b}
}

pub fn Color.dark_olive_green() Color {
	return Color{0xff2f6b55}
}

pub fn Color.dark_orange() Color {
	return Color{0xff008cff}
}

pub fn Color.dark_orchid() Color {
	return Color{0xffcc3299}
}

pub fn Color.dark_red() Color {
	return Color{0xff00008b}
}

pub fn Color.dark_salmon() Color {
	return Color{0xff7a96e9}
}

pub fn Color.dark_sea_green() Color {
	return Color{0xff8bbc8f}
}

pub fn Color.dark_slate_blue() Color {
	return Color{0xff8b3d48}
}

pub fn Color.dark_slate_gray() Color {
	return Color{0xff4f4f2f}
}

pub fn Color.dark_turquoise() Color {
	return Color{0xffd1ce00}
}

pub fn Color.dark_violet() Color {
	return Color{0xffd30094}
}

pub fn Color.deep_pink() Color {
	return Color{0xff9314ff}
}

pub fn Color.deep_sky_blue() Color {
	return Color{0xffffbf00}
}

pub fn Color.dim_gray() Color {
	return Color{0xff696969}
}

pub fn Color.dodger_blue() Color {
	return Color{0xffff901e}
}

pub fn Color.firebrick() Color {
	return Color{0xff2222b2}
}

pub fn Color.floral_white() Color {
	return Color{0xfff0faff}
}

pub fn Color.forest_green() Color {
	return Color{0xff228b22}
}

pub fn Color.fuchsia() Color {
	return Color{0xffff00ff}
}

pub fn Color.gainsboro() Color {
	return Color{0xffdcdcdc}
}

pub fn Color.ghost_white() Color {
	return Color{0xfffff8f8}
}

pub fn Color.gold() Color {
	return Color{0xff00d7ff}
}

pub fn Color.goldenrod() Color {
	return Color{0xff20a5da}
}

pub fn Color.gray() Color {
	return Color{0xff808080}
}

pub fn Color.green() Color {
	return Color{0xff008000}
}

pub fn Color.green_yellow() Color {
	return Color{0xff2fffad}
}

pub fn Color.honeydew() Color {
	return Color{0xfff0fff0}
}

pub fn Color.hot_pink() Color {
	return Color{0xffb469ff}
}

pub fn Color.indian_red() Color {
	return Color{0xff5c5ccd}
}

pub fn Color.indigo() Color {
	return Color{0xff82004b}
}

pub fn Color.ivory() Color {
	return Color{0xfff0ffff}
}

pub fn Color.khaki() Color {
	return Color{0xff8ce6f0}
}

pub fn Color.lavender() Color {
	return Color{0xfffae6e6}
}

pub fn Color.lavender_blush() Color {
	return Color{0xfff5f0ff}
}

pub fn Color.lawn_green() Color {
	return Color{0xff00fc7c}
}

pub fn Color.lemon_chiffon() Color {
	return Color{0xffcdfaff}
}

pub fn Color.light_blue() Color {
	return Color{0xffe6d8ad}
}

pub fn Color.light_coral() Color {
	return Color{0xff8080f0}
}

pub fn Color.light_cyan() Color {
	return Color{0xffffffe0}
}

pub fn Color.light_goldenrod_yellow() Color {
	return Color{0xffd2fafa}
}

pub fn Color.light_gray() Color {
	return Color{0xffd3d3d3}
}

pub fn Color.light_green() Color {
	return Color{0xff90ee90}
}

pub fn Color.light_pink() Color {
	return Color{0xffc1b6ff}
}

pub fn Color.light_salmon() Color {
	return Color{0xff7aa0ff}
}

pub fn Color.light_sea_green() Color {
	return Color{0xffaab220}
}

pub fn Color.light_sky_blue() Color {
	return Color{0xffface87}
}

pub fn Color.light_slate_gray() Color {
	return Color{0xff998877}
}

pub fn Color.light_steel_blue() Color {
	return Color{0xffdec4b0}
}

pub fn Color.light_yellow() Color {
	return Color{0xffe0ffff}
}

pub fn Color.lime() Color {
	return Color{0xff00ff00}
}

pub fn Color.lime_green() Color {
	return Color{0xff32cd32}
}

pub fn Color.linen() Color {
	return Color{0xffe6f0fa}
}

pub fn Color.magenta() Color {
	return Color{0xffff00ff}
}

pub fn Color.maroon() Color {
	return Color{0xff000080}
}

pub fn Color.medium_aquamarine() Color {
	return Color{0xffaacd66}
}

pub fn Color.medium_blue() Color {
	return Color{0xffcd0000}
}

pub fn Color.medium_orchid() Color {
	return Color{0xffd355ba}
}

pub fn Color.medium_purple() Color {
	return Color{0xffdb7093}
}

pub fn Color.medium_sea_green() Color {
	return Color{0xff71b33c}
}

pub fn Color.medium_slate_blue() Color {
	return Color{0xffee687b}
}

pub fn Color.medium_spring_green() Color {
	return Color{0xff9afa00}
}

pub fn Color.medium_turquoise() Color {
	return Color{0xffccd148}
}

pub fn Color.medium_violet_red() Color {
	return Color{0xff8515c7}
}

pub fn Color.midnight_blue() Color {
	return Color{0xff701919}
}

pub fn Color.mint_cream() Color {
	return Color{0xfffafff5}
}

pub fn Color.misty_rose() Color {
	return Color{0xffe1e4ff}
}

pub fn Color.moccasin() Color {
	return Color{0xffb5e4ff}
}

pub fn Color.mono_game_orange() Color {
	return Color{0xff003ce7}
}

pub fn Color.navajo_white() Color {
	return Color{0xffaddeff}
}

pub fn Color.navy() Color {
	return Color{0xff800000}
}

pub fn Color.old_lace() Color {
	return Color{0xffe6f5fd}
}

pub fn Color.olive() Color {
	return Color{0xff008080}
}

pub fn Color.olive_drab() Color {
	return Color{0xff238e6b}
}

pub fn Color.orange() Color {
	return Color{0xff00a5ff}
}

pub fn Color.orange_red() Color {
	return Color{0xff0045ff}
}

pub fn Color.orchid() Color {
	return Color{0xffd670da}
}

pub fn Color.pale_goldenrod() Color {
	return Color{0xffaae8ee}
}

pub fn Color.pale_green() Color {
	return Color{0xff98fb98}
}

pub fn Color.pale_turquoise() Color {
	return Color{0xffeeeeaf}
}

pub fn Color.pale_violet_red() Color {
	return Color{0xff9370db}
}

pub fn Color.papaya_whip() Color {
	return Color{0xffd5efff}
}

pub fn Color.peach_puff() Color {
	return Color{0xffb9daff}
}

pub fn Color.peru() Color {
	return Color{0xff3f85cd}
}

pub fn Color.pink() Color {
	return Color{0xffcbc0ff}
}

pub fn Color.plum() Color {
	return Color{0xffdda0dd}
}

pub fn Color.powder_blue() Color {
	return Color{0xffe6e0b0}
}

pub fn Color.purple() Color {
	return Color{0xff800080}
}

pub fn Color.red() Color {
	return Color{0xff0000ff}
}

pub fn Color.rosy_brown() Color {
	return Color{0xff8f8fbc}
}

pub fn Color.royal_blue() Color {
	return Color{0xffe16941}
}

pub fn Color.saddle_brown() Color {
	return Color{0xff13458b}
}

pub fn Color.salmon() Color {
	return Color{0xff7280fa}
}

pub fn Color.sandy_brown() Color {
	return Color{0xff60a4f4}
}

pub fn Color.sea_green() Color {
	return Color{0xff578b2e}
}

pub fn Color.sea_shell() Color {
	return Color{0xffeef5ff}
}

pub fn Color.sienna() Color {
	return Color{0xff2d52a0}
}

pub fn Color.silver() Color {
	return Color{0xffc0c0c0}
}

pub fn Color.sky_blue() Color {
	return Color{0xffebce87}
}

pub fn Color.slate_blue() Color {
	return Color{0xffcd5a6a}
}

pub fn Color.slate_gray() Color {
	return Color{0xff908070}
}

pub fn Color.snow() Color {
	return Color{0xfffafaff}
}

pub fn Color.spring_green() Color {
	return Color{0xff7fff00}
}

pub fn Color.steel_blue() Color {
	return Color{0xffb48246}
}

pub fn Color.teal() Color {
	return Color{0xff808000}
}

pub fn Color.thistle() Color {
	return Color{0xffd8bfd8}
}

pub fn Color.tomato() Color {
	return Color{0xff4763ff}
}

pub fn Color.turquoise() Color {
	return Color{0xffd0e040}
}

pub fn Color.violet() Color {
	return Color{0xffee82ee}
}

pub fn Color.wheat() Color {
	return Color{0xffb3def5}
}

pub fn Color.white() Color {
	return Color{}
}

pub fn Color.white_smoke() Color {
	return Color{0xfff5f5f5}
}

pub fn Color.yellow() Color {
	return Color{0xff00ffff}
}

pub fn Color.yellow_green() Color {
	return Color{0xff32cd9a}
}
