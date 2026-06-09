const std = @import("std");
const cast = std.math.lossyCast;

const clap = @import("clap");
const Elo = @import("sakana").Elo;
const rl = @import("raylib");

const File = @import("file.zig");
const Hydrus = @import("hydrus.zig");
const Leagues = @import("leagues.zig");

const Self = @This();

io: std.Io,
gpa: std.mem.Allocator,
leagues: Leagues,
league_name: []const u8,
hydrus: *Hydrus,

width: i32 = 1280,
height: i32 = 720,

running: bool = true,

fn loadImages(gpa: std.mem.Allocator, files: []File, max_size: rl.Vector2, running: *bool, hydrus: *Hydrus) !void {
    for (files) |*file| {
        try file.loadImage(gpa, max_size, hydrus);
        if (!running.*) return;
    }
}

fn getResource(slice: []const File, id: usize) ?File {
    for (slice) |item| {
        if (item.id == id) {
            return item;
        }
    }
    return null;
}

pub fn init(
    io: std.Io,
    gpa: std.mem.Allocator,
    leagues: Leagues,
    league_name: []const u8,
    hydrus: *Hydrus,
) !Self {
    const self: Self = .{
        .io = io,
        .gpa = gpa,
        .leagues = leagues,
        .league_name = league_name,
        .hydrus = hydrus,
    };
    rl.setTraceLogLevel(.none);
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(self.width, self.height, "hydrus-elo");
    return self;
}

pub fn deinit(self: *Self) void {
    self.running = false;
    rl.closeWindow();
}

pub fn findBestElo(gpa: std.mem.Allocator, hydrus: *Hydrus, max_ids: usize, tags: std.ArrayList([]const u8)) !u32 {
    var scratch = std.heap.ArenaAllocator.init(gpa);
    defer scratch.deinit();

    const a = scratch.allocator();

    var best_elo: u32 = 0;
    var elo: u32 = 0;

    var ids = try hydrus.searchFiles(a, tags.items);

    std.log.info("With no elo, count = {}", .{ids.len});

    while (ids.len >= max_ids) {
        defer _ = scratch.reset(.retain_capacity);

        best_elo = elo;
        if (ids.len == max_ids) return best_elo;
        elo += 100;

        var tmp_tags = try tags.clone(a);
        const elo_tag = try std.fmt.allocPrint(a, "system:count for elo more than {}", .{elo});
        try tmp_tags.append(a, elo_tag);

        ids = try hydrus.searchFiles(a, tmp_tags.items);

        std.log.info("With elo = {}, count = {}", .{ elo, ids.len });
    } else {
        return best_elo;
    }
}

/// The caller owns the returned memory.
pub fn getFiles(gpa: std.mem.Allocator, hydrus: *Hydrus, strategy: Elo.Strategy, league_name: []const u8, leagues: Leagues) ![]File {
    var ids = std.ArrayList(usize).empty;
    defer ids.deinit(gpa);

    var scratch = std.heap.ArenaAllocator.init(gpa);
    defer scratch.deinit();

    const a = scratch.allocator();

    var ranked_ids_len: usize = 0;

    {
        const tag = try std.fmt.allocPrint(a, "system:has rating for league.{s}", .{league_name});
        const ranked_ids = hydrus.searchFiles(a, &.{tag}) catch |err| switch (err) {
            error.BadRequest => {
                if (hydrus.league_service_keys.get(league_name) == null) {
                    std.log.err("Please add local numerical rating service with name \"league.{s}\" and number of \"stars\" = 6", .{league_name});
                    std.process.exit(1);
                } else return err;
            },
            else => return err,
        };
        try ids.appendSlice(gpa, ranked_ids);
        ranked_ids_len = ranked_ids.len;
        std.log.info("Ranked files = {}", .{ranked_ids_len});
    }

    var tags = std.ArrayList([]const u8).empty;
    try tags.appendSlice(a, leagues.get(league_name));
    const no_rating_tag = try std.fmt.allocPrint(a, "system:no rating for league.{s}", .{league_name});
    try tags.append(a, no_rating_tag);
    // The limit is currently Elo.Rank.wood.max(), but it may change
    switch (strategy) {
        .ranks => {
            const limit_tag = try std.fmt.allocPrint(a, "system:limit is {}", .{Elo.Rank.wood.max()});
            try tags.append(a, limit_tag);
            const unranked_ids = try hydrus.searchFiles(a, tags.items);
            try ids.appendSlice(gpa, unranked_ids);
        },
        .promos => {
            const elo = try findBestElo(a, hydrus, Elo.Rank.MaxLeagueLen - ranked_ids_len + 1, tags);
            const elo_tag = try std.fmt.allocPrint(a, "system:count for elo more than {}", .{elo});
            try tags.append(a, elo_tag);
            const unranked_ids = try hydrus.searchFiles(a, tags.items);
            try ids.appendSlice(gpa, unranked_ids);
        },
        .player => |p| {
            var need_to_add = true;
            for (ids.items) |id| {
                if (p.id == id) need_to_add = false;
            }
            if (need_to_add) {
                try ids.append(gpa, p.id);
            }
        },
    }
    std.log.info("Unranked files = {}", .{ids.items.len - ranked_ids_len});

    return try hydrus.getFiles(gpa, ids.items, league_name);
}

pub fn play(
    self: *Self,
    strategy: Elo.Strategy,
) !void {
    const files = try getFiles(self.gpa, self.hydrus, strategy, self.league_name, self.leagues);
    defer self.gpa.free(files);

    var players = try std.ArrayList(Elo.Player).initCapacity(self.gpa, files.len);
    for (files) |file| {
        try players.append(self.gpa, .{ .id = file.id, .elo = file.elo, .rank = file.rank });
    }
    defer players.deinit(self.gpa);

    var elo = try Elo.init(self.gpa, self.io, players.items, strategy);
    defer elo.deinit();

    try elo.generate();

    elo.printQueue();

    var resources = std.ArrayList(File).empty;
    defer {
        for (resources.items) |*item| item.deinit();
        resources.deinit(self.gpa);
    }

    {
        var chosen_ids = try elo.getChosenIds(self.gpa, false);
        defer chosen_ids.deinit(self.gpa);

        for (chosen_ids.items) |id| {
            try resources.append(self.gpa, getResource(files, id).?);
        }
    }

    const max_width = rl.getMonitorWidth(0);
    const max_height = rl.getMonitorHeight(0);

    var thread = try std.Thread.spawn(
        .{},
        loadImages,
        .{ self.gpa, resources.items, rl.Vector2{ .x = @floatFromInt(max_width), .y = @floatFromInt(max_height) }, &self.running, self.hydrus },
    );
    defer thread.join();

    var action = try elo.next();
    var p1: ?File = null;
    var p2: ?File = null;

    var arena = std.heap.ArenaAllocator.init(self.gpa);
    defer arena.deinit();
    const frame_gpa = arena.allocator();

    var need_print = true;

    while (self.running and action != null) : ({
        self.running = !rl.windowShouldClose();
    }) {
        defer _ = arena.reset(.retain_capacity);

        if (rl.isWindowResized()) {
            self.width = rl.getScreenWidth();
            self.height = rl.getScreenHeight();
        }
        switch (action.?.*) {
            .match => |value| {
                p1 = getResource(resources.items, elo.getId(value.player1));
                p1.?.elo = elo.getElo(value.player1);
                p2 = getResource(resources.items, elo.getId(value.player2));
                p2.?.elo = elo.getElo(value.player2);
                if (need_print) {
                    std.log.info("{} ({}) vs {} ({})", .{
                        elo.getId(value.player1),
                        elo.getElo(value.player1),
                        elo.getId(value.player2),
                        elo.getElo(value.player2),
                    });
                    need_print = false;
                }
            },
            .rank => |value| {
                std.log.info("{s}", .{value.toString()});
                action = try elo.next();
            },
            .promotion => |value| {
                std.log.info("{} from {s} to {s}", .{
                    elo.getId(value.player),
                    value.from.toString(),
                    value.to.toString(),
                });
                action = try elo.next();
            },
        }

        var user_input: ?Elo.UserInput = null;

        if (rl.isKeyReleased(.h)) user_input = .win;
        if (rl.isKeyReleased(.l)) user_input = .lose;
        if (rl.isKeyReleased(.j)) user_input = .draw;
        if (rl.isKeyReleased(.u)) user_input = .undo;
        if (rl.isKeyReleased(.q)) user_input = .quit;

        if (user_input) |value| {
            const result = try elo.act(value, action.?);
            if (result) |r| {
                std.log.info("{} - {}", r);
            }
            action = try elo.next();
            if (action) |a| {
                if (a.* == .match) {
                    need_print = true;
                }
            }
        }

        for (resources.items) |*file| if (file.image != null) try file.loadTexture();

        rl.beginDrawing();
        rl.clearBackground(.white);
        const left_texture = if (p1 != null and p1.?.texture != null) p1.?.texture else null;
        const right_texture = if (p2 != null and p2.?.texture != null) p2.?.texture else null;
        if (left_texture != null and right_texture != null) {
            const lt = left_texture.?;
            const rt = right_texture.?;
            const height_f32 = cast(f32, self.height);
            const width_f32 = cast(f32, self.width);
            var lt_final_size = rl.Vector2{
                .x = height_f32 * cast(f32, lt.width) / cast(f32, lt.height),
                .y = height_f32,
            };
            var rt_final_size = rl.Vector2{
                .x = height_f32 * cast(f32, rt.width) / cast(f32, rt.height),
                .y = height_f32,
            };
            if ((lt_final_size.x + rt_final_size.x) > width_f32) {
                const scale = width_f32 / (lt_final_size.x + rt_final_size.x);
                lt_final_size = lt_final_size.scale(scale);
                rt_final_size = rt_final_size.scale(scale);
            }
            const lt_final_scale = lt_final_size.y / cast(f32, lt.height);
            const rt_final_scale = rt_final_size.y / cast(f32, rt.height);
            const padding: rl.Vector2 = .{
                .x = (width_f32 - (lt_final_size.x + rt_final_size.x)) / 3,
                .y = (height_f32 - rt_final_size.y) / 2,
            };
            lt.drawEx(
                padding,
                0,
                lt_final_scale,
                .white,
            );
            rt.drawEx(
                (.{ .x = padding.x * 2 + lt_final_size.x, .y = padding.y }),
                0,
                rt_final_scale,
                .white,
            );

            const left_text = try std.fmt.allocPrintSentinel(
                frame_gpa,
                "Elo: {} - {s}",
                .{ p1.?.elo, p1.?.rank.toString() },
                0,
            );
            rl.drawText(left_text, 0, 0, 20, .red);

            const right_text = try std.fmt.allocPrintSentinel(
                frame_gpa,
                "Elo: {} - {s}",
                .{ p2.?.elo, p2.?.rank.toString() },
                0,
            );
            const x = self.width - rl.measureText(right_text, 20);
            rl.drawText(right_text, x, 0, 20, .red);
        }
        rl.endDrawing();
    }
    var i = elo.result.iterator();
    while (i.next()) |entry| {
        const id = entry.key_ptr.*;
        const elo_value = entry.value_ptr.elo;
        const rank = entry.value_ptr.rank;
        try self.hydrus.setElo(id, elo_value);
        try self.hydrus.setLeague(id, self.league_name, rank);
    }
}
