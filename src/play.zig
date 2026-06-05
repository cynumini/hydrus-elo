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
files: []File,
players: std.ArrayList(Elo.Player) = .empty,

width: i32 = 1280,
height: i32 = 720,

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
    var self: Self = .{
        .io = io,
        .gpa = gpa,
        .leagues = leagues,
        .league_name = league_name,
        .hydrus = hydrus,
        .files = undefined,
    };
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(self.width, self.height, "hydrus-elo");

    const tags = try leagues.get(gpa, league_name);
    defer gpa.free(tags);

    self.files = try self.hydrus.getFiles(gpa, tags, league_name);

    self.players = try std.ArrayList(Elo.Player).initCapacity(gpa, self.files.len);

    for (self.files) |file| {
        try self.players.append(gpa, .{ .id = file.id, .elo = file.elo, .rank = file.rank });
    }

    return self;
}

pub fn deinit(self: *Self) void {
    self.players.deinit(self.gpa);
    self.gpa.free(self.files);
    rl.closeWindow();
}

pub fn play(
    self: *Self,
    strategy: Elo.Strategy,
) !void {
    for (self.players.items) |p| {
        std.debug.print("{}\n", .{p});
    }
    var elo = try Elo.init(self.gpa, self.io, self.players.items, strategy);
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
            try resources.append(self.gpa, getResource(self.files, id).?);
        }
    }

    const max_width = rl.getMonitorWidth(0);
    const max_height = rl.getMonitorHeight(0);

    var running = true;

    var thread = try std.Thread.spawn(.{}, loadImages, .{ self.gpa, resources.items, rl.Vector2{ .x = @floatFromInt(max_width), .y = @floatFromInt(max_height) }, &running, self.hydrus });
    defer thread.join();

    var action = try elo.next();
    var p1: ?File = null;
    var p2: ?File = null;

    var arena = std.heap.ArenaAllocator.init(self.gpa);
    defer arena.deinit();
    const frame_gpa = arena.allocator();

    while (running and action != null) {
        defer _ = arena.reset(.retain_capacity);
        running = !rl.windowShouldClose();
        if (rl.isWindowResized()) {
            self.width = rl.getScreenWidth();
            self.height = rl.getScreenHeight();
        }
        switch (action.?.*) {
            .match => |value| {
                const need_print = p1 == null;
                p1 = getResource(resources.items, elo.getId(value.player1));
                p1.?.elo = elo.getElo(value.player1);
                p2 = getResource(resources.items, elo.getId(value.player2));
                p2.?.elo = elo.getElo(value.player2);
                if (need_print) {
                    std.log.info("{} vs {}", .{ elo.getId(value.player1), elo.getId(value.player2) });
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

    running = false;
}
