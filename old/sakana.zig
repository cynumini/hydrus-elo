const std = @import("std");

pub const Elo = @import("elo.zig");

test {
    std.testing.refAllDecls(@This());
}
