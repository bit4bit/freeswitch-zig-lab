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

fn process_event(event: *fs.switch_event_t) bool {
    _ = event;

    return true;
}

export fn event_handler(event: [*c]fs.switch_event_t) void {
    if (!process_event(@ptrCast(event))) {
        const peer_uuid = fs.switch_event_get_header(event, "variable_signal_bond");

        // TODO: test
        if (peer_uuid == null) {
            return;
        }

        // TODO: test
        const peer_session = fszig.switch_core_session_locate(peer_uuid);
        if (peer_session == null) {
            // TODO: switch_log_printf
            return;
        }
        defer fs.switch_core_session_rwunlock(peer_session);

        const peer_channel = fs.switch_core_session_get_channel(peer_session);
        const peer_event: *fs.switch_event_t = undefined;
        if (fszig.switch_event_create(&peer_event, fs.SWITCH_EVENT_CHANNEL_BRIDGE) != fs.SWITCH_STATUS_SUCCESS) {
            // TODO: switch_log_printf
            return;
        }
        defer fszig.switch_event_destroy(&peer_event);

        fs.switch_channel_event_set_data(peer_channel, peer_event);
        _ = process_event(peer_event);
        _ = fs.switch_channel_set_variable(peer_channel, "_test_mod_spy_processed_event_", "true");
    }
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
