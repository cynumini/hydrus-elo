const std = @import("std");

const File = @import("file.zig");
const Hydrus = @import("hydrus.zig");
const skn = @import("sakana");
const Action = skn.Action;
const Color = skn.Color;
const Image = skn.Image;
const Key = skn.Key;
const Mods = skn.Mods;
const Texture = skn.Texture;
const Vector2 = skn.Vector2;

var queue_len: usize = 5;
var screen = Vector2.init(1280, 720);
var files: []File = undefined;
var files_with_nothing: std.ArrayList(*File) = undefined;
var files_with_image: std.ArrayList(*File) = undefined;
var queue: std.ArrayList(*File) = undefined;
var next_queue: std.ArrayList(*File) = undefined;
var index: usize = 0;
var end = false;
var hydrus: Hydrus = undefined;
var rand: std.Random = undefined;

pub fn calcOffset(left: Vector2, right: Vector2) f32 {
    const scaled_left = left.scaleTo(screen);
    const scaled_right = right.scaleTo(screen);
    const left_scale = scaled_left.x / (scaled_left.x + scaled_right.x);
    return left_scale * screen.x;
}

pub fn update() !void {
    try input();
    while (files_with_image.pop()) |file| {
        try file.loadTexture();
        try queue.append(file);
    }
}

pub fn draw() !void {
    skn.clear();
    if (queue.items.len >= 2 and nextIsPossibe()) {
        const left_file = queue.items[index];
        const right_file = queue.items[index + 1];
        const x_offset = calcOffset(left_file.texture.?.size, right_file.texture.?.size);
        try skn.drawTexture(left_file.texture.?, Vector2.init(0, 0), Vector2.init(x_offset, screen.y), .keep);
        try skn.drawTexture(right_file.texture.?, Vector2.init(x_offset, 0), Vector2.init(screen.x - x_offset, screen.y), .keep);
    }
    var value: f32 = @floatFromInt(index + 1);
    value /= @floatFromInt(queue.items.len);
    try skn.drawRectangle(
        Vector2.init(0, 0),
        Vector2.init(value * screen.x, 4),
        Color{ .r = 0, .g = 255, .b = 0, .a = 180 },
    );
}

pub fn resize(size: Vector2) void {
    screen = size;
}

pub fn nextIsPossibe() bool {
    return queue.items.len >= index + 2;
}

pub fn next() !void {
    index += 2;
    if (queue_len % 2 != 0) {
        queue_len -= 1;
        try next_queue.append(queue.swapRemove(queue_len));
    }
    if (index == queue_len) {
        if (next_queue.items.len < 2) skn.exit();
        try queue.resize(0);
        try queue.appendSlice(next_queue.items);
        std.Random.shuffle(rand, *File, queue.items);
        try next_queue.resize(0);
        queue_len = queue.items.len;
        index = 0;
    }
}

pub fn play(result: f32) !void {
    var left_file = queue.items[index];
    const right_file = queue.items[index + 1];
    if (result == 1) {
        try next_queue.append(left_file);
    } else if (result == 0) {
        try next_queue.append(right_file);
    } else if (result == 0.5) {
        try next_queue.append(left_file);
        try next_queue.append(right_file);
    } else unreachable;

    try left_file.play(&hydrus, right_file, result);
    try next();
}

pub fn input() !void {
    if (skn.isKeyReleased(.a)) {
        if (!nextIsPossibe()) return;
        try play(1);
    }
    if (skn.isKeyReleased(.d)) {
        if (!nextIsPossibe()) return;
        try play(0);
    }
    if (skn.isKeyReleased(.w)) {
        if (!nextIsPossibe()) return;
        try play(0.5);
    }
    if (skn.isKeyReleased(.s)) {
        if (!nextIsPossibe()) return;
        try next();
    }
}

pub fn loadImages(allocator: std.mem.Allocator) !void {
    while (files_with_nothing.pop()) |file| {
        try file.loadImage(allocator, &hydrus);
        try files_with_image.append(file);
        if (end) return;
    }
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    rand = std.crypto.random;

    if (args.len < 2) {
        std.debug.print("Specify the queue length as the first argument.\n", .{});
        return;
    } else {
        queue_len = try std.fmt.parseInt(usize, args[1], 0);
        if (queue_len < 2) {
            std.debug.print("Queue length must be greater than 1.\n", .{});
            return;
        }
    }

    hydrus = try Hydrus.init(allocator);
    defer hydrus.deinit();

    try skn.init(allocator, .{
        .title = "hydrus-elo",
        .clear_color = .{ .r = 42, .g = 46, .b = 50, .a = 255 },
        .resize_callback = &resize,
        .size = screen,
    });
    defer skn.deinit();

    files = try hydrus.getFiles(queue_len);
    defer {
        for (files) |*file| {
            if (file.image) |*image| {
                image.deinit();
            }
            if (file.texture) |*texture| {
                texture.deinit();
            }
        }
        allocator.free(files);
    }

    files_with_nothing = .init(allocator);
    defer files_with_nothing.deinit();

    for (files) |*file| {
        try files_with_nothing.append(file);
    }

    files_with_image = .init(allocator);
    defer files_with_image.deinit();

    queue = .init(allocator);
    defer queue.deinit();

    next_queue = .init(allocator);
    defer next_queue.deinit();

    var thread = try std.Thread.spawn(.{}, loadImages, .{
        allocator,
    });
    defer thread.join();

    try skn.run(update, draw);
    end = true;
}
