const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

fn isUnreserved(char: u8) bool {
    return switch (char) {
        'A'...'Z', 'a'...'z', '0'...'9', '-', '.', '_', '~' => true,
        else => false,
    };
}

const base_url = "http://127.0.0.1:45869";

fn get(comptime T: type, allocator: std.mem.Allocator, client: *std.http.Client, hydrus_client_api: []const u8, path: []const u8, query: []const u8) !T {
    var uri = try std.Uri.parse(base_url);

    uri.path = std.Uri.Component{ .percent_encoded = path };
    uri.query = std.Uri.Component{ .percent_encoded = query };

    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();

    const headers: []const std.http.Header = &.{
        .{
            .name = "Hydrus-Client-API-Access-Key",
            .value = hydrus_client_api,
        },
    };

    _ = try client.fetch(.{
        .location = .{ .uri = uri },
        .extra_headers = headers,
        .response_storage = .{ .dynamic = &response },
    });

    return (try std.json.parseFromSlice(T, allocator, response.items, .{})).value;
}

fn hydrusNetwork(allocator: std.mem.Allocator, result: *std.ArrayList(u8)) !void {
    const hydrus_client_api = std.posix.getenv("HYDRUS_CLIENT_API").?;

    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    const tags = try std.json.stringifyAlloc(allocator, .{"system:everything"}, .{});

    var query = std.ArrayList(u8).init(allocator);
    defer query.deinit();

    try query.appendSlice("tags=");
    _ = try std.Uri.Component.percentEncode(query.writer(), tags, isUnreserved);

    const T = struct {
        file_ids: []u32,
        version: u32,
        hydrus_version: u32,
    };

    const search_files_result = try get(T, allocator, &client, hydrus_client_api, "/get_files/search_files", query.items);

    const M = struct {};

    const file_ids = try std.json.stringifyAlloc(allocator, search_files_result.file_ids[0..1], .{});
    query.clearAndFree();
    try query.appendSlice("file_ids=");
    _ = try std.Uri.Component.percentEncode(query.writer(), file_ids, isUnreserved);

    const files_metadata_result = try get(M, allocator, &client, hydrus_client_api, "/get_files/file_metadata", query.items);

    std.debug.print("{}\n", .{files_metadata_result});

    try result.appendSlice("Fuck you");
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var thread_safe_allocator = std.heap.ThreadSafeAllocator{ .child_allocator = arena.allocator() };
    const allocator = thread_safe_allocator.allocator();

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
