const std = @import("std");

const Elo = @import("sakana").Elo;
const rl = @import("raylib");

const Hydrus = @import("hydrus.zig");

const Self = @This();

id: usize,
elo: u32,
size: rl.Vector2,
rank: Elo.Rank = .unranked,
image: ?rl.Image = null,
texture: ?rl.Texture = null,

pub fn scaleTo(self: rl.Vector2, max: rl.Vector2) rl.Vector2 {
    const aspect = self.x / self.y;

    if (max.x / max.y > aspect) {
        return .{
            .x = max.y * aspect,
            .y = max.y,
        };
    } else {
        return .{
            .x = max.x,
            .y = max.x / aspect,
        };
    }
}

pub fn loadImage(self: *Self, gpa: std.mem.Allocator, max_size: rl.Vector2, hydrus: *Hydrus) !void {
    if (self.size.x > max_size.x or self.size.y > max_size.y) self.size = scaleTo(self.size, max_size);

    const data = try hydrus.render(gpa, self.id, .png, self.size);
    defer gpa.free(data);

    self.image = try rl.loadImageFromMemory(".png", data);
}

pub fn loadTexture(self: *Self) !void {
    self.texture = try rl.loadTextureFromImage(self.image.?);
    self.image.?.unload();
    self.image = null;
}

pub fn deinit(self: *Self) void {
    if (self.image) |*image| {
        image.unload();
    }
    if (self.texture) |*texture| {
        texture.unload();
    }
}
