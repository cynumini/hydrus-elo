const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub fn hydrusNetwork(allocator: std.mem.Allocator, result: *std.ArrayList(u8)) !void {
    std.debug.print("I'm doing hydrus network staff!\n", .{});
    const hydrus_client_api = std.posix.getenv("HYDRUS_CLIENT_API").?;

    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    _ = try client.fetch(.{
        .location = .{ .url = "http://127.0.0.1:45869/api_version" },
        .extra_headers = &.{
            .{
                .name = "Hydrus-Client-API-Access-Key",
                .value = hydrus_client_api,
            },
        },
        .response_storage = .{ .dynamic = result },
    });

    std.debug.print("Api key: {s}\n", .{hydrus_client_api});
    std.debug.print("I have done!\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    var thread = try std.Thread.spawn(
        .{},
        hydrusNetwork,
        .{ allocator, &result },
    );
    defer thread.join();

    const screen_width = 800;
    const screen_height = 450;

    c.InitWindow(screen_width, screen_height, "hydrus-elo");
    defer c.CloseWindow();

    c.SetTargetFPS(60);

    while (!c.WindowShouldClose()) {
        // Update
        std.debug.print("{s}\n", .{result.items});

        // Draw
        c.BeginDrawing();
        c.ClearBackground(c.WHITE);
        c.DrawText(
            "Congrats! You created your first window!",
            190,
            200,
            20,
            c.LIGHTGRAY,
        );
        c.EndDrawing();
    }
}
