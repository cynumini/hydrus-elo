const std = @import("std");

const skn = @import("sakana");

const Hydrus = @import("hydrus.zig");

const Self = @This();

const k_factor = 32;

id: u32,
elo: i32,
size: skn.Vector2,
image: ?skn.Image = null,
texture: ?skn.Texture = null,
hydrus: *Hydrus,

fn setElo(self: *Self, hydrus: *Hydrus, elo: i32) !void {
    self.elo = elo;
    try hydrus.setElo(self.id, elo);
}

pub fn loadImage(self: *Self, allocator: std.mem.Allocator, max_size: skn.Vector2) !void {
    if (self.size.x > max_size.x or self.size.y > max_size.y) self.size = self.size.scaleTo(max_size);

    const data = try self.hydrus.render(self.id, .jpeg, self.size);
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

pub fn play(self: *Self, other: *Self, result: f32) !void {
    const elo_diff: f32 = @floatFromInt(other.elo - self.elo);
    const p_self_elo = 1.0 / (1 + std.math.pow(f32, 10, elo_diff / 400.0));
    const p_other_elo = 1.0 - p_self_elo;
    std.debug.print("old elo {} {} {d} - ", .{ self.elo, other.elo, result });
    try self.setElo(self.hydrus, @intFromFloat(@round(self.floatElo() + k_factor * (result - p_self_elo))));
    try other.setElo(self.hydrus, @intFromFloat(@round(other.floatElo() + k_factor * ((1 - result) - p_other_elo))));
    std.debug.print("new elo {} {}\n", .{ self.elo, other.elo });
}

pub fn deinit(self: *Self) void {
    if (self.image) |*image| {
        image.deinit();
    }
    if (self.texture) |*texture| {
        texture.deinit();
    }
}
