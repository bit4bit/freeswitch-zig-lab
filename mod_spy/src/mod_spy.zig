pub const logic = @import("./logic.zig");

// TAKE FROM: https://github.com/zigtools/zls/blob/master/src/zls.zig
comptime {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
