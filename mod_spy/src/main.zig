const std = @import("std");
const fszig = @import("fszig");
const fs = @cImport({
    @cInclude("switch.h");
});
const SpyLogic = @import("./logic.zig").SpyLogic;

// this is truth?
var global_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var mod_logic = SpyLogic.init(global_allocator.allocator());

// freeswitch requires entrypoint <mod name>_module_interface
export const mod_spy_module_interface = fszig.module_definition(mod_spy_load, mod_spy_shutdown, mod_spy_runtime);
var node: fs.switch_event_t = .{};
const modname = "mod_spy";

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

export fn event_handler(event: [*c]fs.switch_event_t) void {
    _ = event;
}

export fn mod_spy_load(modi: [*c][*c]fszig.module_interface, pool: ?*fs.switch_memory_pool_t) fs.switch_status_t {
    modi.* = fs.switch_loadable_module_create_module_interface(pool, "mod_spy");

    _ = fs.switch_event_bind_removable(modname, fs.SWITCH_EVENT_CHANNEL_BRIDGE, null, event_handler, null, @ptrCast(&node));
    
    fszig.switch_add_app(modi.*, "userspy", "Spy on user constantly", "Spy on user constantly", userspy_function, "<user@domain> [uuid]", fs.SAF_NONE);
    fszig.switch_add_api(modi.*, "userspy_show", "Show current spies", dump_hash, "userspy_show");

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_spy_shutdown() fs.switch_status_t {
    mod_logic.deinit();
    _ = global_allocator.deinit();

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_spy_runtime() fs.switch_status_t {
    return fs.SWITCH_STATUS_SUCCESS;
}
