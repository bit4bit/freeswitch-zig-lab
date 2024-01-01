const std = @import("std");
const fszig = @import("fszig");
const fs = @cImport({
    @cInclude("switch.h");
});

// freeswitch requires entrypoint <mod name>_module_interface
export const mod_spy_module_interface = fszig.module_definition(mod_spy_load, mod_spy_shutdown, mod_spy_runtime);

export fn dump_hash(cmd: [*c]const u8, session: ?*fs.switch_core_session_t, stream: [*c]fs.switch_stream_handle_t) callconv(.C) fs.switch_status_t {
    _ = cmd;
    _ = session;

    _ = fs.switch_console_stream_write(stream, "\n0 total spy\n");

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn userspy_function(session: ?*fs.switch_core_session_t, data: [*c]const u8) callconv(.C) void {
    _ = session;
    _ = data;
}

export fn mod_spy_load(modi: [*c][*c]fszig.module_interface, pool: ?*fs.switch_memory_pool_t) fs.switch_status_t {
    modi.* = fs.switch_loadable_module_create_module_interface(pool, "mod_spy");

    fszig.switch_add_app(modi.*, "userspy", "Spy on user constantly", "Spy on user constantly", userspy_function, "<user@domain> [uuid]", fs.SAF_NONE);
    fszig.switch_add_api(modi.*, "userspy_show", "Show current spies", dump_hash, "userspy_show");

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_spy_shutdown() fs.switch_status_t {
    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_spy_runtime() fs.switch_status_t {
    return fs.SWITCH_STATUS_SUCCESS;
}

const Channels = std.ArrayList([]const u8);

const SpyLogic = struct {
    allocator: std.mem.Allocator,
    spy_hash: std.hash_map.StringHashMap(Channels),

    const Self = @This();
    
    pub fn init(allocator: std.mem.Allocator) SpyLogic {
        return SpyLogic{
            .allocator = allocator,
            .spy_hash = std.hash_map.StringHashMap(Channels).init(allocator)
        };
    }

    pub fn spyChannel(self: *Self, uuid: []const u8, hash: []const u8) void {
        self.channelsOf(hash).append(uuid) catch unreachable;
        return;
    }

    fn lastChannel(self: *Self, hash: []const u8) []const u8 {
        return self.channelsOf(hash).getLastOrNull() orelse return "";
    }
   
    pub fn deinit(self: *Self) void {
        var iter = self.spy_hash.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.spy_hash.deinit();
    }

    fn channelsOf(self: *Self, hash: []const u8) *Channels {
        if (self.spy_hash.getPtr(hash)) |channels| {
            return channels;
        }

        self.spy_hash.put(hash, Channels.init(self.allocator)) catch unreachable;

        return self.spy_hash.getPtr(hash).?;
    }
};

const testing = std.testing;
test "spy a channel" {
    var logic = SpyLogic.init(std.testing.allocator);
    defer logic.deinit();

    logic.spyChannel("12345", "demo");

    try std.testing.expectEqualStrings("12345", logic.lastChannel("demo"));
}
