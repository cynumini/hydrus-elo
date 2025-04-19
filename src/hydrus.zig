const std = @import("std");

const skn = @import("sakana");

const File = @import("file.zig");

const Self = @This();

const url = "http://127.0.0.1:45869";
allocator: std.mem.Allocator,
client: std.http.Client,
access_key: []const u8,
elo_service_key: ?[]const u8,

pub fn init(allocator: std.mem.Allocator) !Self {
    var self: Self = .{
        .allocator = allocator,
        .client = std.http.Client{ .allocator = allocator },
        .access_key = std.posix.getenv("HYDRUS_CLIENT_API").?,
        .elo_service_key = null,
    };
    try self.setEloServiceKey();
    return self;
}

pub fn deinit(self: *Self) void {
    if (self.elo_service_key) |elo_service_key| {
        self.allocator.free(elo_service_key);
    }
    self.client.deinit();
}

/// The caller owns the returned memory.
pub fn get(self: *Self, path: []const u8, query: []const u8) ![]const u8 {
    var uri = try std.Uri.parse(url);

    uri.path = std.Uri.Component{ .percent_encoded = path };
    uri.query = std.Uri.Component{ .percent_encoded = query };

    var response = std.ArrayList(u8).init(self.allocator);

    const headers = [_]std.http.Header{
        .{ .name = "Hydrus-Client-API-Access-Key", .value = self.access_key },
    };

    _ = try self.client.fetch(.{
        .location = .{ .uri = uri },
        .extra_headers = &headers,
        .response_storage = .{ .dynamic = &response },
        .max_append_size = std.math.maxInt(usize),
    });

    return try response.toOwnedSlice();
}

/// The caller owns the returned memory.
pub fn post(self: *Self, path: []const u8, data: []const u8) ![]const u8 {
    var uri = try std.Uri.parse(url);

    uri.path = std.Uri.Component{ .percent_encoded = path };

    var response = std.ArrayList(u8).init(self.allocator);

    const headers = [_]std.http.Header{
        .{ .name = "Hydrus-Client-API-Access-Key", .value = self.access_key },
        .{ .name = "Content-Type", .value = "application/json" },
    };

    _ = try self.client.fetch(.{
        .location = .{ .uri = uri },
        .extra_headers = &headers,
        .payload = data,
        .response_storage = .{ .dynamic = &response },
        .max_append_size = std.math.maxInt(usize),
    });

    return try response.toOwnedSlice();
}

/// The caller owns the returned memory.
fn searchFiles(self: *Self, len: usize) ![]u32 {
    var query = std.ArrayList(u8).init(self.allocator);
    defer query.deinit();

    // std.debug.print("here: {any}", .{query});
    try query.appendSlice("file_sort_type=4");
    try query.appendSlice("&tags=");
    _ = try std.Uri.Component.percentEncode(query.writer(), "[\"system:limit is ", isUnreserved);
    try query.writer().print("{}", .{len});
    _ = try std.Uri.Component.percentEncode(query.writer(), "\", \"system:filetype is image\"]", isUnreserved);

    const T = struct {
        file_ids: []u32,
        version: u32,
        hydrus_version: u32,
    };

    const response = try self.get("/get_files/search_files", query.items);
    defer self.allocator.free(response);

    const json = try std.json.parseFromSlice(T, self.allocator, response, .{});
    defer json.deinit();

    return self.allocator.dupe(u32, json.value.file_ids);
}

/// The caller owns the returned memory.
pub fn render(self: *Self, id: u32, format: skn.Image.Format, size: skn.Vector2) ![]const u8 {
    var query = std.ArrayList(u8).init(self.allocator);
    defer query.deinit();

    try query.writer().print("width={}&height={}&file_id={}&render_format={}", .{
        try size.getX(i32),
        try size.getY(i32),
        id,
        @intFromEnum(format),
    });

    return self.get("/get_files/render", query.items);
}

/// The caller owns the returned memory.
pub fn getFiles(self: *Self, len: usize) ![]File {
    const ids = try self.searchFiles(len);
    defer self.allocator.free(ids);

    var query = std.ArrayList(u8).init(self.allocator);
    defer query.deinit();

    var files = std.ArrayList(File).init(self.allocator);

    try query.append('[');

    for (ids) |id| {
        try query.writer().print("{},", .{id});
    }

    query.items[query.items.len - 1] = ']';

    const ids_json = try query.toOwnedSlice();
    defer self.allocator.free(ids_json);

    try query.appendSlice("file_ids=");

    _ = try std.Uri.Component.percentEncode(query.writer(), ids_json, isUnreserved);

    const response = try self.get("/get_files/file_metadata", query.items);
    defer self.allocator.free(response);

    const json = try std.json.parseFromSlice(std.json.Value, self.allocator, response, .{});
    defer json.deinit();

    for (json.value.object.get("metadata").?.array.items) |metadata| {
        var file: File = .{
            .id = @intCast(metadata.object.get("file_id").?.integer),
            .elo = @intCast(metadata.object.get("ratings").?.object.get(self.elo_service_key.?).?.integer),
            .size = .{
                .x = @floatFromInt(metadata.object.get("width").?.integer),
                .y = @floatFromInt(metadata.object.get("height").?.integer),
            },
            .hydrus = self,
        };
        if (file.elo == 0) {
            file.elo = 1000;
        }
        try files.append(file);
    }

    return files.toOwnedSlice();
}

/// The caller owns the returned memory.
pub fn setElo(self: *Self, id: u32, elo: i32) !void {
    var query = std.ArrayList(u8).init(self.allocator);
    defer query.deinit();

    try query.writer().print("{{\"file_id\":{},\"rating_service_key\":\"{s}\",\"rating\":{}}}", .{
        id,
        self.elo_service_key.?,
        elo,
    });

    const result = try self.post("/edit_ratings/set_rating", query.items);
    defer self.allocator.free(result);

    if (result.len != 0) {
        std.debug.print("Error: {s}\n", .{result});
        return error.SetEloError;
    }
}

/// The caller owns the returned memory.
fn setEloServiceKey(self: *Self) !void {
    const response = try self.get("/get_services", "");
    defer self.allocator.free(response);

    const json = try std.json.parseFromSlice(std.json.Value, self.allocator, response, .{});
    defer json.deinit();

    const services = json.value.object.get("services").?.object;

    const elo_service_key: []const u8 = blk: {
        for (services.keys(), services.values()) |key, value| {
            if (std.mem.eql(u8, value.object.get("name").?.string, "elo")) break :blk key;
        }
        return error.NoEloService;
    };
    self.elo_service_key = try self.allocator.dupe(u8, elo_service_key);
}

fn isUnreserved(char: u8) bool {
    return switch (char) {
        'A'...'Z', 'a'...'z', '0'...'9', '-', '.', '_', '~' => true,
        else => false,
    };
}
