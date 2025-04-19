const std = @import("std");

const File = @import("file.zig");
const Hydrus = @import("hydrus.zig");
const skn = @import("sakana");

const GameState = struct {
    const Self = @This();

    max_monitor_size: skn.Vector2,
    rand: std.Random,
    hydrus: *Hydrus,
    files: []File,
    queue: std.ArrayList(*File),
    next_queue: std.ArrayList(*File),
    allocator: std.mem.Allocator,
    screen: skn.Vector2,
    should_run: bool = true,

    pub fn init(allocator: std.mem.Allocator, screen: skn.Vector2) !Self {
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);

        var queue_len: usize = undefined;

        if (args.len < 2) {
            std.debug.print("Specify the queue length as the first argument.\n", .{});
            return error.NoQueueLen;
        } else {
            queue_len = try std.fmt.parseInt(usize, args[1], 0);
            if (queue_len < 2) {
                std.debug.print("Queue length must be greater than 1.\n", .{});
                return error.QueueTooSmall;
            }
        }

        var hydrus = try allocator.create(Hydrus);
        hydrus.* = try Hydrus.init(allocator);
        const files = try hydrus.getFiles(queue_len);

        std.debug.assert(files.len > 1);

        var queue = std.ArrayList(*File).init(allocator);
        for (files) |*file| {
            try queue.append(file);
        }

        var next_queue = std.ArrayList(*File).init(allocator);
        if (queue.items.len % 2 != 0) {
            try next_queue.append(queue.pop().?);
        }

        return .{
            .max_monitor_size = skn.getMaxMonitorSize(),
            .rand = std.crypto.random,
            .hydrus = hydrus,
            .files = files,
            .allocator = allocator,
            .screen = screen,
            .queue = queue,
            .next_queue = next_queue,
        };
    }

    pub fn deinit(self: *Self) void {
        defer self.allocator.destroy(self.hydrus);
        defer self.hydrus.deinit();
        defer {
            for (self.files) |*file| {
                file.deinit();
            }
            self.allocator.free(self.files);
        }
        defer self.queue.deinit();
        defer self.next_queue.deinit();
    }
};

var gs: GameState = undefined;

pub fn play(result: f32) !void {
    const left_file = gs.queue.orderedRemove(0);
    const right_file = gs.queue.orderedRemove(0);
    if (result == 1) {
        try gs.next_queue.append(left_file);
    } else if (result == 0) {
        try gs.next_queue.append(right_file);
    } else if (result == 0.5) {
        try gs.next_queue.append(left_file);
        try gs.next_queue.append(right_file);
    }

    if (result != -1) {
        try left_file.play(right_file, result);
    }

    if (gs.queue.items.len < 2) {
        if (gs.queue.items.len > 0) {
            try gs.next_queue.appendSlice(gs.queue.items);
            try gs.queue.resize(0);
        }
        if (gs.next_queue.items.len < 2) skn.exit();
        try gs.queue.appendSlice(gs.next_queue.items);
        std.Random.shuffle(gs.rand, *File, gs.queue.items);
        try gs.next_queue.resize(0);

        if (gs.queue.items.len % 2 != 0) {
            try gs.next_queue.append(gs.queue.swapRemove(0));
        }
    }
}

pub fn update() !void {
    if (skn.isKeyReleased(.a)) {
        try play(1);
    }
    if (skn.isKeyReleased(.d)) {
        try play(0);
    }
    if (skn.isKeyReleased(.w)) {
        try play(0.5);
    }
    if (skn.isKeyReleased(.s)) {
        try play(-1);
    }
    for (gs.files) |*file| if (file.image != null) try file.loadTexture();
}

pub fn draw() !void {
    const left = if (gs.queue.items.len > 0) gs.queue.items[0] else null;
    const right = if (gs.queue.items.len > 1) gs.queue.items[1] else null;

    if (left != null and right != null and left.?.texture != null and right.?.texture != null) {
        const left_texture = left.?.texture.?;
        const right_texture = right.?.texture.?;

        var left_scaled_size = left_texture.size;
        var right_scaled_size = right_texture.size;

        const max_height = @max(left_scaled_size.y, right_scaled_size.y);

        left_scaled_size = left_scaled_size.scale(max_height / left_scaled_size.y);
        right_scaled_size = right_scaled_size.scale(max_height / right_scaled_size.y);

        const coefficient = left_scaled_size.x / (left_scaled_size.x + right_scaled_size.x);

        left_scaled_size = left_scaled_size.scaleTo(.init(gs.screen.x * coefficient, gs.screen.y));
        right_scaled_size = right_scaled_size.scaleTo(.init(gs.screen.x * (1 - coefficient), gs.screen.y));

        const x_padding = (gs.screen.x - (left_scaled_size.x + right_scaled_size.x)) / 3;
        const y_padding = (gs.screen.y - left_scaled_size.y) / 2;

        skn.drawTexture(
            left_texture,
            .init(x_padding, y_padding),
            left_scaled_size.x / left_texture.size.x,
        );
        skn.drawTexture(
            right_texture,
            .init(x_padding * 2 + left_scaled_size.x, y_padding),
            right_scaled_size.x / right_texture.size.x,
        );

        const left_text = try std.fmt.allocPrint(gs.allocator, "Elo: {}", .{left.?.elo});
        defer gs.allocator.free(left_text);
        skn.drawText(left_text, .init(0, 0), 20, skn.Color.red);

        const right_text = try std.fmt.allocPrint(gs.allocator, "Elo: {}", .{right.?.elo});
        const right_text_width: f32 = @floatFromInt(skn.measureText(right_text, 20));
        defer gs.allocator.free(right_text);
        skn.drawText(right_text, .init(gs.screen.x - right_text_width, 0), 20, skn.Color.red);

        const progress = try std.fmt.allocPrint(gs.allocator, "Queue: {}, Next queue: {}", .{
            gs.queue.items.len,
            gs.next_queue.items.len,
        });
        defer gs.allocator.free(progress);
        skn.drawText(progress, .init(0, gs.screen.y - 20), 20, skn.Color.red);
    }
}

pub fn resize(size: skn.Vector2) void {
    gs.screen = size;
}

pub fn loadImages(allocator: std.mem.Allocator) !void {
    for (gs.files) |*file| {
        try file.loadImage(allocator, gs.max_monitor_size);
        if (!gs.should_run) return;
    }
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    const screen = skn.Vector2.init(1280, 720);

    try skn.init(allocator, .{
        .title = "hydrus-elo",
        .clear_color = .{ .r = 42, .g = 46, .b = 50, .a = 255 },
        .resize_callback = &resize,
        .size = screen,
    });
    defer skn.deinit();

    gs = try .init(allocator, screen);
    defer gs.deinit();

    var thread = try std.Thread.spawn(.{}, loadImages, .{
        allocator,
    });
    defer thread.join();

    try skn.run(update, draw);
    gs.should_run = false;
}
