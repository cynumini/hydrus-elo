const std = @import("std");

const clap = @import("clap");
const Elo = @import("sakana").Elo;
const Hydrus = @import("hydrus.zig");
const rl = @import("raylib");

const Leagues = @import("leagues.zig");

const Commands = enum { ranks, promos, player, season };

const main_params = clap.parseParamsComptime(
    \\-h, --help            Display this help and exit.
    \\<command>
    \\
);

fn mainHelp(writer: *std.Io.Writer, name: []const u8) !void {
    try writer.print("uage: {s} ", .{name});
    try clap.usage(writer, clap.Help, &main_params);
    try writer.print("\n", .{});
    try clap.help(writer, clap.Help, &main_params, .{});
    try writer.print(
        \\Available commands:
        \\    ranks  - random matches in all ranks
        \\    promos - promotion matches between ranks
        \\    player - play as one player
        \\    season - run ranks + promos
        \\
    , .{});
    try writer.flush();
}

pub fn main(init: std.process.Init) !void {
    var writer = std.Io.File.Writer.init(.stdout(), init.io, &.{});

    var iter = try init.minimal.args.iterateAllocator(init.gpa);
    defer iter.deinit();

    const program_name = iter.next().?;

    const main_parsers = .{
        .command = clap.parsers.enumeration(Commands),
        .path = clap.parsers.string,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &main_params, main_parsers, &iter, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
        .terminating_positional = 0,
    }) catch |err| {
        if (err == error.NameNotPartOfEnum) {
            try mainHelp(&writer.interface, program_name);
            return;
        }
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0 or res.positionals[0] == null) {
        try mainHelp(&writer.interface, program_name);
        return;
    }

    var leagues: Leagues = try .init(init.io, init.gpa, "hydrus-elo.json");
    defer leagues.deinit();

    const access_key = init.environ_map.get("HYDRUS_CLIENT_API").?;
    var hydrus: Hydrus = try .init(init.io, init.gpa, access_key);
    defer hydrus.deinit();

    if (res.positionals[0]) |command| {
        switch (command) {
            .ranks => try @import("ranks.zig").run(
                init,
                &iter,
                program_name,
                &writer.interface,
                leagues,
                &hydrus,
            ),
            .promos => try @import("promos.zig").run(
                init,
                &iter,
                program_name,
                &writer.interface,
                leagues,
                &hydrus,
            ),
            .season => try @import("season.zig").run(
                init,
                &iter,
                program_name,
                &writer.interface,
                leagues,
                &hydrus,
            ),
            .player => {},
        }
    }
}

test {
    std.testing.refAllDecls(@This());
}
