const std = @import("std");

const Hydrus = @import("hydrus.zig");
const File = @import("file.zig");
const Sakana = @import("sakana");
const Color = Sakana.Color;

const queue_len = 64;
var x: f32 = 0;

pub fn update() !void {
    Sakana.clear();
    Sakana.drawRectangle(.{ x, 32 }, .{ 32, 32 }, Color.white);
    x += 0.5;
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    var sakana = try Sakana.init(allocator, .{
        .title = "hydrus-elo",
        .clear_color = .{ .r = 42, .g = 46, .b = 50, .a = 255 },
    });

    defer sakana.deinit();
    try sakana.run(update);

    // const std_out = std.io.getStdOut().writer();

    // var hydrus = try Hydrus.init(allocator);
    // defer hydrus.deinit();
    //
    // var a = File{ .id = 23660, .elo = 1000, .hydrus = &hydrus };
    // var b = File{ .id = 23658, .elo = 1000, .hydrus = &hydrus };
    //
    // try a.play(&b, 0.5);

    // const result_a = try hydrus.searchFiles();
    // defer allocator.free(result_a);
    //
    // const result_b = try hydrus.getFilesElo(result_a);
    // defer allocator.free(result_b);
    //
    // _ = try std_out.print("{any}", .{result_b});
    //
    // _ = try hydrus.setElo(23660, 1000);
}
