package main

import "core:flags"
import "core:fmt"
import "core:mem"
// import "core:net"
import "core:os"
// import "core:strings"
// import rl "vendor:raylib"

flag_checker :: proc(
	model: rawptr,
	name: string,
	value: any,
	args_tag: string,
) -> (
	error: string,
) {
	if name == "count" {
		v := value.(u32)
		if (v < 2) {
			error = "Queue length must be greater than 1."
		}
	}
	return
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	Options :: struct {
		length: u32 `args:"pos=0,required" usage:"Queue length"`,
	}

	opt: Options

	flags.register_flag_checker(flag_checker)
	flags.parse_or_exit(&opt, os.args, .Odin)

	// fmt.println(opt.length)

	if !(hydrus_init() or_else false) do return
	defer hydrus_deinit()
	files, _ := hydrus_get_files(opt.length)
	_ = files
	fmt.println(files)
	// defer delete(file_ids)

	// rl.InitWindow(screen.x, screen.y, "hydrus-elo")
	// defer rl.CloseWindow()
	//
	// rl.SetTargetFPS(60)
	//
	// for (!rl.WindowShouldClose()) {
	// 	// update
	// 	rl.BeginDrawing()
	// 	rl.ClearBackground(rl.RAYWHITE)
	// 	// draw
	// 	rl.EndDrawing()
	// }
}
