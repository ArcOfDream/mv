module engine

import raylib as rl
import animation { LoopMode }
import resourcemanager { TextureResource }

// SpriteFrame is a single frame in an animation
pub struct SpriteFrame {
pub mut:
	texture_id string
	source     rl.Rectangle
}

pub struct SpriteAnimation {
pub mut:
	name      string
	frames    []SpriteFrame
	fps       f32      = 8.0
	loop_mode LoopMode = .loop
}

pub struct SpriteFrames {
pub mut:
	animations []SpriteAnimation
}

// --- animation management ---

// find returns the index of the named animation, or -1 if not found.
fn (sf &SpriteFrames) find(name string) int {
	for i, a in sf.animations {
		if a.name == name {
			return i
		}
	}
	return -1
}

pub fn (sf &SpriteFrames) has_animation(name string) bool {
	return sf.find(name) >= 0
}

// add_animation adds a new animation if one with that name doesn't already exist.
pub fn (mut sf SpriteFrames) add_animation(name string, fps f32, loop_mode LoopMode) {
	if sf.find(name) < 0 {
		sf.animations << SpriteAnimation{
			name:      name
			fps:       fps
			loop_mode: loop_mode
		}
	}
}

pub fn (mut sf SpriteFrames) remove_animation(name string) {
	idx := sf.find(name)
	if idx >= 0 {
		sf.animations.delete(idx)
	}
}

pub fn (mut sf SpriteFrames) rename_animation(from string, to string) {
	idx := sf.find(from)
	if idx >= 0 {
		sf.animations[idx].name = to
	}
}

pub fn (mut sf SpriteFrames) set_animation_fps(name string, fps f32) {
	idx := sf.find(name)
	if idx >= 0 {
		sf.animations[idx].fps = fps
	}
}

pub fn (mut sf SpriteFrames) set_animation_loop_mode(name string, mode LoopMode) {
	idx := sf.find(name)
	if idx >= 0 {
		sf.animations[idx].loop_mode = mode
	}
}

// get_animation returns a copy of the named animation for reading
// (frame count, fps, loop mode). use the add_frame / remove_frame methods
// on SpriteFrames to mutate frames without risking slice pointer invalidation.
pub fn (sf &SpriteFrames) get_animation(name string) ?SpriteAnimation {
	idx := sf.find(name)
	if idx >= 0 {
		return sf.animations[idx]
	}
	return none
}

// --- frame management ---

// add_frame appends a frame with an explicit source rectangle.
pub fn (mut sf SpriteFrames) add_frame(anim_name string, texture_id string, source rl.Rectangle) {
	idx := sf.find(anim_name)
	if idx >= 0 {
		sf.animations[idx].frames << SpriteFrame{
			texture_id: texture_id
			source:     source
		}
	}
}

// add_frame_from_texture copies the rectangle at `index` out of the
// TextureResource's frames slice. This is the convenience authoring path:
// the stored data is still an owned rectangle, not an index.
pub fn (mut sf SpriteFrames) add_frame_from_texture(anim_name string, texture_id string, res &TextureResource, index int) {
	if index < 0 || index >= res.frames.len {
		return
	}
	sf.add_frame(anim_name, texture_id, res.frames[index])
}

// add_all_frames_from_texture appends every rectangle in the TextureResource's
// frames slice as consecutive frames in the animation.
pub fn (mut sf SpriteFrames) add_all_frames_from_texture(anim_name string, texture_id string, res &TextureResource) {
	for rect in res.frames {
		sf.add_frame(anim_name, texture_id, rect)
	}
}

pub fn (mut sf SpriteFrames) remove_frame(anim_name string, index int) {
	idx := sf.find(anim_name)
	if idx >= 0 && index >= 0 && index < sf.animations[idx].frames.len {
		sf.animations[idx].frames.delete(index)
	}
}

pub fn (mut sf SpriteFrames) clear_frames(anim_name string) {
	idx := sf.find(anim_name)
	if idx >= 0 {
		sf.animations[idx].frames.clear()
	}
}

pub fn (sf &SpriteFrames) get_frame_count(anim_name string) int {
	idx := sf.find(anim_name)
	if idx >= 0 {
		return sf.animations[idx].frames.len
	}
	return 0
}
