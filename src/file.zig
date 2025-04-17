const std = @import("std");

const skn = @import("sakana");

const Hydrus = @import("hydrus.zig");

const Self = @This();

const k_factor = 32;
const max_render_size = skn.Vector2.init(1920, 1080);

id: u32,
elo: i32,
size: skn.Vector2,
image: ?skn.Image = null,
texture: ?skn.Texture = null,

fn setElo(self: *Self, hydrus: *Hydrus, elo: i32) !void {
    self.elo = elo;
    try hydrus.setElo(self.id, elo);
}

pub fn loadImage(self: *Self, allocator: std.mem.Allocator, hydrus: *Hydrus) !void {
    const size = blk: {
        if (self.size.x > max_render_size.x or self.size.y > max_render_size.y) {
            break :blk self.size.scaleTo(max_render_size);
        } else {
            break :blk self.size;
        }
    };

    const data = try hydrus.render(self.id, size);
    defer allocator.free(data);
    self.image = try skn.Image.init(data, .memory, .jpeg);
}

pub fn loadTexture(self: *Self) !void {
    self.texture = try skn.Texture.initFromImage(self.image.?);
    self.image.?.deinit();
    self.image = null;
}

pub fn floatElo(self: Self) f32 {
    return @floatFromInt(self.elo);
}

pub fn play(self: *Self, hydrus: *Hydrus, other: *Self, result: f32) !void {
    const elo_diff: f32 = @floatFromInt(other.elo - self.elo);
    const p_self_elo = 1.0 / (1 + std.math.pow(f32, 10, elo_diff / 400.0));
    const p_other_elo = 1.0 - p_self_elo;
    std.debug.print("old elo {} {} {d} - ", .{ self.elo, other.elo, result });
    try self.setElo(hydrus, @intFromFloat(@round(self.floatElo() + k_factor * (result - p_self_elo))));
    try other.setElo(hydrus, @intFromFloat(@round(other.floatElo() + k_factor * ((1 - result) - p_other_elo))));
    std.debug.print("new elo {} {}\n", .{ self.elo, other.elo });
}
