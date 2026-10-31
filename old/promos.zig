const std = @import("std");

const clap = @import("clap");

const Hydrus = @import("hydrus.zig");
const Leagues = @import("leagues.zig");

const params = clap.parseParamsComptime(
    \\-h, --help              Display this help and exit.
    \\<str>                   Name of the league
    \\
);

fn help(writer: *std.Io.Writer, name: []const u8) !void {
    try writer.print("uage: {s} elo promos ", .{name});
    try clap.usage(writer, clap.Help, &params);
    try writer.print("\n", .{});
    try clap.help(writer, clap.Help, &params, .{});
    try writer.flush();
}

pub fn run(
    init: std.process.Init,
    iter: *std.process.Args.Iterator,
    program_name: [:0]const u8,
    writer: *std.Io.Writer,
    leagues: Leagues,
    hydrus: *Hydrus,
) !void {
    var diag = clap.Diagnostic{};
    var sub_res = clap.parseEx(
        clap.Help,
        &params,
        clap.parsers.default,
        iter,
        .{ .diagnostic = &diag, .allocator = init.gpa },
    ) catch |err| {
        if (err == error.InvalidArgument) {
            try help(writer, program_name);
            return;
        }
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer sub_res.deinit();

    if (sub_res.args.help != 0 or sub_res.positionals[0] == null) {
        try help(writer, program_name);
        return;
    }

    const league_name = sub_res.positionals[0].?;

    var play = try @import("play.zig").init(
        init.io,
        init.gpa,
        leagues,
        league_name,
        hydrus,
    );
    defer play.deinit();

    try play.play(.promos);
}
