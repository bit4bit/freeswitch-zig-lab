const std = @import("std");

const Channels = std.ArrayList([]const u8);

pub const SpyState = struct {
    allocator: std.mem.Allocator,
    spy_user: std.hash_map.StringHashMap(Channels),

    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) SpyState {
        return SpyState{
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

// Implementation of use cases
pub const SpyLogic = struct {
    state: SpyState,

    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .state = SpyState.init(allocator)
        };
    }

    pub fn deinit(self: *Self) void {
        self.state.deinit();
    }

    pub fn spyChannel(self: *Self, uuid: []const u8, userid: []const u8) void {
        self.state.spyChannel(uuid, userid);
    }

    pub fn ignoreChannel(self: *Self, uuid: []const u8, userid: []const u8) void {
        self.state.ignoreChannel(uuid, userid);
    }

    pub fn spiedChannels(self: *Self, userid: []const u8) ChannelsIterator {
        return ChannelsIterator{
            .channels = self.state.channelsOf(userid),
        };
    }
};

pub const ChannelsIterator = struct {
    channels: *Channels,
    index: usize = 0,
    pub fn next(self: *ChannelsIterator) ?[]const u8 {
        const index = self.index;
        if (index == self.channels.items.len)
            return null;
        self.index += 1;
        return self.channels.items[index];
    }
};

const testing = std.testing;
test "spy a channel" {
    var state = SpyState.init(std.testing.allocator);
    defer state.deinit();

    state.spyChannel("12345", "demo");

    try std.testing.expect(state.hasSpyChannel("demo") == true);
    try std.testing.expect(state.hasSpyChannel("notexists") == false);
}

test "ignore a spied channel" {
    var state = SpyState.init(std.testing.allocator);
    defer state.deinit();

    state.spyChannel("12345", "demo");
    try std.testing.expect(state.hasSpyChannel("demo") == true);

    state.ignoreChannel("12345", "demo");
    try std.testing.expect(state.hasSpyChannel("demo") == false);
}

test "ignore a spied channel on hangup" {
    var logic = SpyLogic.init(std.testing.allocator);
    defer logic.deinit();

    logic.spyChannel("12345", "demo");
    try std.testing.expect(logic.state.hasSpyChannel("demo") == true);
    
    logic.ignoreChannel("12345", "demo");
    try std.testing.expect(logic.state.hasSpyChannel("demo") == false);
}

test "iterate over spied channels" {
    var logic = SpyLogic.init(std.testing.allocator);
    defer logic.deinit();
    logic.spyChannel("12345", "demo");
    
    var spieds = logic.spiedChannels("demo");
    
    try std.testing.expectEqualStrings("12345", spieds.next().?);
}

test "iterate works on empty channels" {
    var logic = SpyLogic.init(std.testing.allocator);
    defer logic.deinit();

    var spieds = logic.spiedChannels("demo");
    while (spieds.next()) |spy_uuid| {
        _ = spy_uuid;
        try std.testing.expect(false);
    }
    try std.testing.expect(spieds.next() == null);
    try std.testing.expect(spieds.next() == null);
}
