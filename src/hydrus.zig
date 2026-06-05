const std = @import("std");

const Elo = @import("sakana").Elo;
const rl = @import("raylib");

const File = @import("file.zig");

const Self = @This();

const url = "http://127.0.0.1:45869";
gpa: std.mem.Allocator,
client: std.http.Client,
access_key: []const u8,
elo_service_key: ?[]const u8,
league_service_keys: std.StringHashMapUnmanaged([]const u8) = .empty,

pub fn init(io: std.Io, gpa: std.mem.Allocator, access_key: []const u8) !Self {
    return .{
        .gpa = gpa,
        .client = std.http.Client{ .allocator = gpa, .io = io },
        .access_key = access_key,
        .elo_service_key = null,
    };
}

pub fn deinit(self: *Self) void {
    if (self.elo_service_key) |elo_service_key| {
        self.gpa.free(elo_service_key);
    }
    var i = self.league_service_keys.iterator();
    while (i.next()) |e| {
        self.gpa.free(e.key_ptr.*);
        self.gpa.free(e.value_ptr.*);
    }
    self.league_service_keys.deinit(self.gpa);
    self.client.deinit();
}

pub fn getEloServiceKey(self: *Self) ![]const u8 {
    if (self.elo_service_key) |elo_service_key| {
        return elo_service_key;
    } else {
        try self.loadServiceKey();
        return self.elo_service_key.?;
    }
}

fn loadServiceKey(self: *Self) !void {
    const response = try self.get("/get_services", "");
    defer self.gpa.free(response);

    const json = try std.json.parseFromSlice(std.json.Value, self.gpa, response, .{});
    defer json.deinit();

    const services = json.value.object.get("services").?.object;

    for (services.keys(), services.values()) |key, value| {
        const name = value.object.get("name").?.string;
        if (std.mem.eql(u8, name, "elo")) {
            self.elo_service_key = try self.gpa.dupe(u8, key);
        }
        if (std.mem.startsWith(u8, name, "league.")) {
            try self.league_service_keys.put(
                self.gpa,
                try self.gpa.dupe(u8, name[7..]),
                try self.gpa.dupe(u8, key),
            );
        }
    }

    if (self.elo_service_key == null) {
        std.log.err("Please add local ind/dec rating service with name \"elo\"", .{});
        return error.NoEloSerice;
    }
}

/// The caller owns the returned memory.
pub fn get(self: *Self, path: []const u8, query: []const u8) ![]const u8 {
    var uri = try std.Uri.parse(url);

    uri.path = std.Uri.Component{ .percent_encoded = path };
    uri.query = std.Uri.Component{ .percent_encoded = query };

    var response = std.Io.Writer.Allocating.init(self.gpa);
    defer response.deinit();

    const headers = [_]std.http.Header{
        .{ .name = "Hydrus-Client-API-Access-Key", .value = self.access_key },
    };

    const result = try self.client.fetch(.{
        .location = .{ .uri = uri },
        .extra_headers = &headers,
        .response_writer = &response.writer,
    });

    std.debug.print("{s} {}\n", .{ query, result });
    std.debug.assert(result.status == .ok);

    return try response.toOwnedSlice();
}

/// The caller owns the returned memory.
pub fn post(self: *Self, path: []const u8, data: []const u8) ![]const u8 {
    var uri = try std.Uri.parse(url);

    uri.path = std.Uri.Component{ .percent_encoded = path };

    var response = std.Io.Writer.Allocating.init(self.gpa);
    defer response.deinit();

    const headers = [_]std.http.Header{
        .{ .name = "Hydrus-Client-API-Access-Key", .value = self.access_key },
        .{ .name = "Content-Type", .value = "application/json" },
    };

    _ = try self.client.fetch(.{
        .location = .{ .uri = uri },
        .extra_headers = &headers,
        .payload = data,
        .response_writer = &response.writer,
    });

    return try response.toOwnedSlice();
}

/// The caller owns the returned memory.
fn searchFiles(self: *Self, gpa: std.mem.Allocator, tags: []const u8) ![]u32 {
    var query_writer = std.Io.Writer.Allocating.init(self.gpa);
    defer query_writer.deinit();

    _ = try query_writer.writer.write("file_sort_type=4");
    _ = try query_writer.writer.write("&tags=");
    _ = try std.Uri.Component.percentEncode(&query_writer.writer, tags, isUnreserved);

    const T = struct {
        file_ids: []u32,
        version: u32,
        hydrus_version: u32,
    };

    const query = try query_writer.toOwnedSlice();
    defer gpa.free(query);

    const response = try self.get("/get_files/search_files", query);
    defer gpa.free(response);

    const json = try std.json.parseFromSlice(T, gpa, response, .{});
    defer json.deinit();

    return gpa.dupe(u32, json.value.file_ids);
}

pub const Format = enum(u8) {
    jpeg = 1,
    png = 2,
    wemp = 33,
    apng = 23,
    animated_webp = 83,
};

/// The caller owns thea returned memory.
pub fn render(self: *Self, gpa: std.mem.Allocator, id: usize, format: Format, size: rl.Vector2) ![]const u8 {
    var query_writer: std.Io.Writer.Allocating = .init(gpa);
    defer query_writer.deinit();

    try query_writer.writer.print(
        "width={}&height={}&file_id={}&render_format={}",
        .{ @round(size.x), @round(size.y), id, @intFromEnum(format) },
    );

    const query = try query_writer.toOwnedSlice();
    defer gpa.free(query);

    return self.get("/get_files/render", query);
}

/// The caller owns the returned memory.
pub fn getFiles(self: *Self, gpa: std.mem.Allocator, tags: []const u8, league_name: []const u8) ![]File {
    const elo_service_key = try self.getEloServiceKey();
    const league_service_key = self.league_service_keys.get(league_name) orelse {
        std.log.err("Please add local numerical rating service with name \"league.{s}\" and namer of \"star\" = 6", .{league_name});
        return error.NoLeagueSerice;
    };

    const ids = try self.searchFiles(gpa, tags);
    defer gpa.free(ids);

    var query_writer: std.Io.Writer.Allocating = .init(gpa);
    defer query_writer.deinit();
    var s = std.json.Stringify{ .writer = &query_writer.writer };

    var files = std.ArrayList(File).empty;

    try s.beginArray();
    for (ids) |id| try s.write(id);
    try s.endArray();

    const ids_json = try query_writer.toOwnedSlice();
    defer gpa.free(ids_json);

    _ = try query_writer.writer.write("file_ids=");

    _ = try std.Uri.Component.percentEncode(&query_writer.writer, ids_json, isUnreserved);

    const query = try query_writer.toOwnedSlice();
    defer gpa.free(query);

    const response = try self.get("/get_files/file_metadata", query);
    defer gpa.free(response);

    // std.debug.print("{s}\n", .{response});

    const json = try std.json.parseFromSlice(std.json.Value, gpa, response, .{});
    defer json.deinit();

    for (json.value.object.get("metadata").?.array.items) |metadata| {
        const rank: Elo.Rank = switch (metadata.object.get("ratings").?.object.get(league_service_key).?) {
            .null => .unranked,
            .integer => |i| @enumFromInt(i),
            else => unreachable,
        };
        var file: File = .{
            .id = @intCast(metadata.object.get("file_id").?.integer),
            .elo = @intCast(metadata.object.get("ratings").?.object.get(elo_service_key).?.integer),
            .rank = rank,
            .size = .{
                .x = @floatFromInt(metadata.object.get("width").?.integer),
                .y = @floatFromInt(metadata.object.get("height").?.integer),
            },
        };
        if (file.elo == 0) {
            file.elo = 1000;
        }
        try files.append(gpa, file);
    }

    return files.toOwnedSlice(gpa);
}

pub fn setElo(self: *Self, id: usize, elo: u32) !void {
    var query_writer: std.Io.Writer.Allocating = .init(self.gpa);
    defer query_writer.deinit();

    try query_writer.writer.print("{{\"file_id\":{},\"rating_service_key\":\"{s}\",\"rating\":{}}}", .{
        id,
        self.elo_service_key.?,
        elo,
    });

    const query = try query_writer.toOwnedSlice();
    defer self.gpa.free(query);

    const result = try self.post("/edit_ratings/set_rating", query);
    defer self.gpa.free(result);

    if (result.len != 0) {
        std.debug.print("Error: {s}\n", .{result});
        return error.SetEloError;
    }
}

/// The caller owns the returned memory.
pub fn setLeague(self: *Self, id: usize, league_name: []const u8, rank: Elo.Rank) !void {
    var query_writer: std.Io.Writer.Allocating = .init(self.gpa);
    defer query_writer.deinit();

    try query_writer.writer.print("{{\"file_id\":{},\"rating_service_key\":\"{s}\",\"rating\":{}}}", .{
        id,
        self.league_service_keys.get(league_name).?,
        @intFromEnum(rank),
    });

    const query = try query_writer.toOwnedSlice();
    defer self.gpa.free(query);

    const result = try self.post("/edit_ratings/set_rating", query);
    defer self.gpa.free(result);

    if (result.len != 0) {
        std.debug.print("Error: {s}\n", .{result});
        return error.SetEloError;
    }
}

fn isUnreserved(char: u8) bool {
    return switch (char) {
        'A'...'Z', 'a'...'z', '0'...'9', '-', '.', '_', '~' => true,
        else => false,
    };
}
