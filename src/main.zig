const std = @import("std");

const Hydrus = @import("hydrus.zig");
const File = @import("file.zig");
const Sakana = @import("sakana");
const Color = Sakana.Color;
const Texture = @import("sakana").Texture;

const queue_len = 64;
var texture: Texture = undefined;
var texture1: Texture = undefined;
var x: f32 = 0;

pub fn update() !void {
    Sakana.clear();
    try Sakana.drawRectangle(.{ x, 32 }, .{ 32, 32 }, Color.black);
    try Sakana.drawRectangle(.{ x * 1.5, 128 }, .{ 32, 32 }, Color.red);
    try Sakana.drawTexture(.{ 0, 0 }, texture.size / @as(@Vector(2, f32), @splat(2)), texture);
    try Sakana.drawTexture(.{ 512, 0 }, texture1.size / @as(@Vector(2, f32), @splat(2)), texture1);
    x += 0.5;
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    var hydrus = try Hydrus.init(allocator);
    defer hydrus.deinit();

    const files = try hydrus.searchFiles();
    defer allocator.free(files);

    const file = try hydrus.render(files[0]);
    defer allocator.free(file);

    const file2 = try hydrus.render(files[1]);
    defer allocator.free(file2);

    var sakana = try Sakana.init(allocator, .{
        .title = "hydrus-elo",
        .clear_color = .{ .r = 42, .g = 46, .b = 50, .a = 255 },
    });
    defer sakana.deinit();

    texture = try Texture.initFromMemory(file);
    defer texture.deinit();
    texture1 = try Texture.initFromMemory(file2);
    defer texture.deinit();

    try sakana.run(update);

    // const std_out = std.io.getStdOut().writer();

    //
    // var a = File{ .id = 23660, .elo = 1000, .hydrus = &hydrus };
    // var b = File{ .id = 23658, .elo = 1000, .hydrus = &hydrus };
    //
    // try a.play(&b, 0.5);

    //
    // const result_b = try hydrus.getFilesElo(result_a);
    // defer allocator.free(result_b);
    //
    // _ = try std_out.print("{any}", .{result_b});
    //
    // _ = try hydrus.setElo(23660, 1000);
}
