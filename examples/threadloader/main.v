module main

import raylib as rl
import mv
import mv.resourcemanager { FileSource, LoadCommand, ThreadLoader }

// this example shows working with threadloader to help load multiple files on a thread
//
// loading from an rres file is also supported this way!

@[heap]
struct Game {
mut:
	app     ?&mv.App
	sprites []&mv.Sprite

	tl         &ThreadLoader = ThreadLoader.new(none)
	load_count int
}

fn (mut g Game) setup() {
	g.app = mv.App.new(g.init, g.update, g.draw, none, none)

	if mut app := g.app {
		app.run()
	}
}

fn (mut g Game) init() {
	if mut app := g.app {
		app.set_window_title('Hello, mv!')
		app.set_window_size(640, 480)
		app.set_viewport_size(320, 240)
		app.set_target_fps(60)
		app.set_clear_color(rl.darkblue)

		// a for loop is used here to load in sequence
		// mind that there's a cap on the command channel, check
		// the return value on request() to see if it got pushed
		for i in 1 .. 26 {
			mut tile_num := 'tile_${i:03}'
			println('tile: ${tile_num}')
			g.tl.request(LoadCommand{
				name:   tile_num
				kind:   .texture
				source: FileSource{
					path: 'tiles/${tile_num}.png'
				}
			})

			mut spr := app.new_node[mv.Sprite](tile_num, 20 + ((i - 1) % 5) * 53, 20 +
				((i - 1) / 5) * 39)
			spr.set_centered(false)
			g.sprites << spr
		}
	}
}

fn (mut g Game) update(_ f32) {
	for mut spr in g.sprites {
		mv.emit_notification(mut spr, .update)
	}
}

fn (mut g Game) draw() {
	if mut app := g.app {
		for event in g.tl.poll_events() {
			if event.err != '' {
				eprintln('threadloader: ${event.name}: ${event.err}')
				continue
			}
			match event.content {
				// use match to get cases for Image, Wave, ShaderFile and []u8
				rl.Image {
					app.textures.load_from_image(event.name, event.content)
					println('got ${event.name}')
					g.load_count++
				}
				else {} // do nothing
			}
		}

		if g.load_count >= 25 && !g.tl.is_closed() {
			println('everything loaded... closing worker thread')
			g.tl.shutdown()

			for i in 1 .. 26 {
				mut tile_num := 'tile_${i:03}'
				g.sprites[i - 1].set_texture_id(tile_num)
			}
		}
	}

	for mut spr in g.sprites {
		mv.emit_notification(mut spr, .draw)
	}

	rl.draw_text('threadloader sample', 2, 2, 4, rl.raywhite)
}

fn main() {
	mut game := Game{}
	game.setup()
}
