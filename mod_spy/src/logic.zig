const std = @import("std");

const Channels = std.ArrayList([]const u8);

const SpyLogic = struct {
    allocator: std.mem.Allocator,
    spy_user: std.hash_map.StringHashMap(Channels),

    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) SpyLogic {
        return SpyLogic{
            .allocator = allocator,
            .spy_user = std.hash_map.StringHashMap(Channels).init(allocator)
        };
    }

    pub fn spyChannel(self: *Self, uuid: []const u8, userid: []const u8) void {
        self.channelsOf(userid).append(uuid) catch unreachable;
        return;
    }

    pub fn ignoreChannel(self: *Self, uuid: []const u8, userid: []const u8) void {
        var offset: usize = 0;
        for (self.channelsOf(userid).items) |item| {
            if (std.mem.eql(u8, uuid, item)) {
                _ = self.channelsOf(userid).orderedRemove(offset);
                break;
            }
            offset += 1;
        }
    }
    
    pub fn hasSpyChannel(self: *Self, userid: []const u8) bool {
        return self.channelsOf(userid).items.len > 0;
    }

    pub fn deinit(self: *Self) void {
        var iter = self.spy_user.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.spy_user.deinit();
    }

    fn channelsOf(self: *Self, userid: []const u8) *Channels {
        if (self.spy_user.getPtr(userid)) |channels| {
            return channels;
        }

        self.spy_user.put(userid, Channels.init(self.allocator)) catch unreachable;

        return self.spy_user.getPtr(userid).?;
    }
};

const testing = std.testing;
test "spy a channel" {
    var logic = SpyLogic.init(std.testing.allocator);
    defer logic.deinit();

    logic.spyChannel("12345", "demo");

    try std.testing.expect(logic.hasSpyChannel("demo") == true);
    try std.testing.expect(logic.hasSpyChannel("notexists") == false);
}

test "ignore a spied channel" {
    var logic = SpyLogic.init(std.testing.allocator);
    defer logic.deinit();

    logic.spyChannel("12345", "demo");
    try std.testing.expect(logic.hasSpyChannel("demo") == true);

    logic.ignoreChannel("12345", "demo");
    try std.testing.expect(logic.hasSpyChannel("demo") == false);
}
