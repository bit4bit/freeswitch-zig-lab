const std = @import("std");
const fszig = @import("fszig");
const fs = @cImport({
    @cInclude("switch.h");
});
const logic = @import("./logic.zig");

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
