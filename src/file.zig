const std = @import("std");

const Hydrus = @import("hydrus.zig");

const Self = @This();

const k_factor = 32;

id: u32,
elo: u32,
hydrus: *Hydrus,

fn floatFromInt(T: type, value: anytype) T {
    return @floatFromInt(value);
}

pub fn setElo(self: *Self, elo: u32) !void {
    self.elo = elo;
    try self.hydrus.setElo(self.id, elo);
}

pub fn render(self: *Self) ![]const u8 {
    return self.hydrus.render(self.id);
}

pub fn play(self: *Self, other: *Self, result: f32) !void {
    const p_self_elo = 1.0 / (1 + std.math.pow(f32, 10, floatFromInt(f32, other.elo - self.elo) / 400.0));
    const p_other_elo = 1.0 - p_self_elo;
    std.debug.print("old elo {} {} {d} - ", .{ self.elo, other.elo, result });
    try self.setElo(
        @intFromFloat(@round(floatFromInt(f32, self.elo) + k_factor * (result - p_self_elo))),
    );
    try other.setElo(
        @intFromFloat(@round(floatFromInt(f32, other.elo) + k_factor * ((1 - result) - p_other_elo))),
    );
    std.debug.print("new elo {} {}\n", .{ self.elo, other.elo });
}
