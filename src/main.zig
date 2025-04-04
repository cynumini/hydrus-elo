const std = @import("std");

const File = @import("file.zig");
const Hydrus = @import("hydrus.zig");
const Sakana = @import("sakana");
const Input = Sakana.Input;
const Action = Input.Action;
const Color = Sakana.Color;
const Image = Sakana.Image;
const Key = Input.Key;
const Mods = Input.Mods;
const Texture = Sakana.Texture;
const Vector2 = Sakana.Vector2;

const queue_len = 64;
var texture_left: ?Texture = undefined;
var texture_right: ?Texture = undefined;
var screen = Vector2.init(1280, 720);
var textures: std.ArrayList(?Texture) = undefined;
var images: std.ArrayList(Image) = undefined;
var files: []Hydrus.File = undefined;
var index: usize = 2;
var end = false;

pub fn calcOffset(left: Vector2, right: Vector2) f32 {
    const scaled_left = left.scaleTo(screen);
    const scaled_right = right.scaleTo(screen);
    const left_scale = scaled_left.x / (scaled_left.x + scaled_right.x);
    return left_scale * screen.x;
}

pub fn update() !void {
    Sakana.clear();
    // Keep it until program fully works
    if (images.items.len != 0) {
        var image = images.pop().?;
        defer image.deinit();
        try textures.append(try Texture.initFromImage(image));
        if (textures.items.len == 2) {
            texture_left = textures.items[0];
            texture_right = textures.items[1];
        }
    }
    if (texture_left != null and texture_right != null) {
        const x_offset = calcOffset(texture_left.?.size, texture_right.?.size);
        try Sakana.drawTexture(texture_left.?, Vector2.init(0, 0), Vector2.init(x_offset, screen.y), .keep);
        try Sakana.drawTexture(texture_right.?, Vector2.init(x_offset, 0), Vector2.init(screen.x - x_offset, screen.y), .keep);
    }
    var value: f32 = @floatFromInt(index);
    value /= queue_len;
    try Sakana.drawRectangle(
        Vector2.init(0, 0),
        Vector2.init(value * screen.x, 4),
        Color{ .r = 0, .g = 255, .b = 0, .a = 180 },
    );
}

pub fn resize(size: Vector2) void {
    screen = size;
}

pub fn key_callback(key: Key, action: Action, mods: Mods) void {
    _ = mods;
    if (key == .space and action == .release) {
        if (textures.items.len >= index + 2) {
            texture_left = textures.items[index];
            texture_right = textures.items[index + 1];
            index += 2;
            std.debug.print("index =  {}\n", .{index});
        } else if (index == 64) {
            Sakana.exit();
        }
    }
}

pub fn loadImages(allocator: std.mem.Allocator, hydrus: *Hydrus) !void {
    for (0.., files) |i, file| {
        if (end) {
            return;
        }
        const size = if (file.size.x > 1920 or file.size.y > 1080) file.size.scaleTo(Vector2.init(1920, 1080)) else file.size;
        const image = try hydrus.render(files[i].id, size);
        defer allocator.free(image);
        try images.append(try Image.init(image, .memory));
    }
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    var hydrus = try Hydrus.init(allocator);
    defer hydrus.deinit();

    try Sakana.init(allocator, .{
        .title = "hydrus-elo",
        .clear_color = .{ .r = 42, .g = 46, .b = 50, .a = 255 },
        .resize_callback = &resize,
        .key_callback = &key_callback,
        .size = screen,
    });
    defer Sakana.deinit();

    const ids = try hydrus.searchFiles();
    defer allocator.free(ids);

    files = try hydrus.getFiles(ids);
    defer allocator.free(files);

    images = .init(allocator);
    defer {
        while (images.pop()) |*image| {
            @constCast(image).deinit();
        }
        images.deinit();
    }

    textures = .init(allocator);
    defer {
        for (textures.items) |texture| texture.?.deinit();
        textures.deinit();
    }

    var thread = try std.Thread.spawn(.{}, loadImages, .{ allocator, &hydrus });
    defer thread.join();

    try Sakana.run(update);
    end = true;
}
