const std = @import("std");

const Self = @This();

const Tags = std.ArrayList([]const u8);

data: std.StringHashMapUnmanaged(Tags),
gpa: std.mem.Allocator,
io: std.Io,
path: []const u8,

pub fn init(io: std.Io, gpa: std.mem.Allocator, path: []const u8) !Self {
    const exists = blk: {
        std.Io.Dir.cwd().access(io, path, .{}) catch |err| switch (err) {
            error.FileNotFound => break :blk false,
            else => return err,
        };
        break :blk true;
    };

    var self = Self{
        .io = io,
        .gpa = gpa,
        .data = .empty,
        .path = path,
    };

    if (exists) {
        std.log.info("Load hydrus-elo.json", .{});
        const string = try std.Io.Dir.cwd().readFileAlloc(
            io,
            path,
            gpa,
            .unlimited,
        );
        defer gpa.free(string);

        const data = try std.json.parseFromSlice(
            std.json.Value,
            self.gpa,
            string,
            .{},
        );
        defer data.deinit();

        const root = data.value.object;

        var i = root.iterator();

        while (i.next()) |entry| {
            const array = entry.value_ptr.array;
            var tags: Tags = .empty;
            for (array.items) |value| {
                try tags.append(self.gpa, try self.gpa.dupe(u8, value.string));
            }
            try self.data.put(self.gpa, try self.gpa.dupe(u8, entry.key_ptr.*), tags);
        }
    } else {
        std.log.info("Create hydrus-elo.json", .{});
        var all: Tags = .empty;
        try all.append(gpa, try gpa.dupe(u8, "system:filetype is image"));
        try self.data.put(gpa, "all", all);

        var out: std.Io.Writer.Allocating = .init(self.gpa);
        defer out.deinit();
        var s = std.json.Stringify{ .writer = &out.writer, .options = .{ .whitespace = .indent_4 } };
        try s.beginObject();
        var i = self.data.iterator();
        while (i.next()) |entry| {
            try s.objectField(entry.key_ptr.*);
            try s.beginArray();
            for (entry.value_ptr.items) |item| {
                try s.write(item);
            }
            try s.endArray();
        }
        try s.endObject();

        const result = try out.toOwnedSlice();
        defer self.gpa.free(result);

        try std.Io.Dir.cwd().writeFile(
            self.io,
            .{ .data = result, .sub_path = self.path },
        );
    }

    return self;
}

pub fn deinit(self: *Self) void {
    var i = self.data.iterator();
    while (i.next()) |entry| {
        self.gpa.free(entry.key_ptr.*);
        const tags = entry.value_ptr;
        for (tags.items) |item| self.gpa.free(item);
        tags.deinit(self.gpa);
    }
    self.data.deinit(self.gpa);
}

/// The caller owns the returned memory.
pub fn get(self: Self, gpa: std.mem.Allocator, name: []const u8) ![]const u8 {
    const tags = self.data.get(name).?;
    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    var s = std.json.Stringify{ .writer = &out.writer };
    try s.beginArray();
    for (tags.items) |tag| try s.write(tag);
    try s.endArray();
    return out.toOwnedSlice();
}
