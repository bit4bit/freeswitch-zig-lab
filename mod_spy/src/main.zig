const std = @import("std");
const fszig = @import("fszig");
const fs = @cImport({
    @cInclude("switch.h");
});
const SpyLogic = @import("./logic.zig").SpyLogic;

// everything thread safe?
var global_allocator = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = global_allocator.allocator();
var mod_logic = SpyLogic.init(gpa);

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
    if (fs.switch_core_session_get_channel(session)) |channel| {
        const fsuuid = fs.switch_core_session_get_uuid(session);
        const uuid = std.fmt.allocPrintZ(gpa, "{s}", .{fsuuid}) catch unreachable;
        const userid = std.fmt.allocPrintZ(gpa, "{s}", .{data}) catch unreachable;
        mod_logic.spyChannel(uuid, userid);
        _ = channel;
    }
}

fn process_event(event: *fs.switch_event_t) bool {
    const alloc = global_allocator.allocator();
    const username = fs.switch_event_get_header(event, "variable_dialed_user");
    const domain = fs.switch_event_get_header(event, "variable_dialed_domain");

    if (username != null and domain != null) {
        const userid = std.fmt.allocPrintZ(alloc, "{s}@{s}", .{username, domain}) catch unreachable;
        std.debug.print("SPYING {s}\n\n", .{userid});
        
        var iter = mod_logic.spiedChannels(userid);
        std.debug.print("NEW ITER UUID\n\n", .{});

        while (iter.next()) |spy_uuid| {
            std.debug.print("FOUND SPY UUID {s}\n\n", .{spy_uuid});
            if (fszig.switch_core_session_locate(@ptrCast(spy_uuid))) |session| {
                defer fs.switch_core_session_rwunlock(session);
                const channel = fs.switch_core_session_get_channel(session);
                const my_uuid = fs.switch_event_get_header(event, "Unique-ID");
                const smy_uuid  = std.fmt.allocPrintZ(alloc, "{s}", .{my_uuid}) catch unreachable;

                std.debug.print("SESSION {s} FOR SPY UUID {s} UUID {s}\n\n", .{userid, spy_uuid, smy_uuid});
                _ = fs.switch_channel_set_variable(channel, "spy_uuid", my_uuid);
                _ = fszig.switch_channel_set_state(channel, fs.CS_EXCHANGE_MEDIA);
                fs.switch_channel_set_flag(channel, fs.CF_BREAK);
                return true;
            }
        }
    }
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
    //std.debug.print("SPYING SHUTDOWN {*}\n\n", .{&mod_logic});
    mod_logic.deinit();
    _ = global_allocator.deinit();

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_spy_runtime() fs.switch_status_t {
    return fs.SWITCH_STATUS_SUCCESS;
}
