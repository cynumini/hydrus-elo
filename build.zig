const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const clap = b.dependency("clap", .{});
    const sakana = b.dependency("sakana", .{});
    const raylib = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib_artifact = raylib.artifact("raylib"); // raylib C library
    const exe = b.addExecutable(.{
        .name = "hydrus-elo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "clap", .module = clap.module("clap") },
                .{ .name = "raylib", .module = raylib.module("raylib") },
                .{ .name = "sakana", .module = sakana.module("sakana") },
            },
        }),
    });
    b.installArtifact(exe);
    exe.root_module.linkLibrary(raylib_artifact);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run hydrus-elo");
    run_step.dependOn(&run_cmd.step);
    const exe_unit_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
