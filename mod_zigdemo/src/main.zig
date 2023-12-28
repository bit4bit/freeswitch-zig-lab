const std = @import("std");
const fszig = @import("fszig");
const fs = @cImport({
    @cInclude("switch.h");
});

const testing = std.testing;

// freeswitch requires entrypoint <mod name>_module_interface
export const mod_zigdemo_module_interface = fszig.module_definition(mod_zigdemo_load, mod_zigdemo_shutdown, mod_zigdemo_runtime);

export fn zigrun_api(cmd: [*c]const u8, session: ?*fs.switch_core_session_t, stream: [*c]fs.switch_stream_handle_t) callconv(.C) fs.switch_status_t {
    _ = cmd;
    _ = session;

    _ = fs.switch_console_stream_write(stream, "demo");

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_zigdemo_load(modi: [*c][*c]fszig.module_interface, pool: ?*fs.switch_memory_pool_t) fs.switch_status_t {
    modi.* = fs.switch_loadable_module_create_module_interface(pool, "mod_zigdemo");

    fszig.switch_add_api(modi.*, "zigrun", "run a zig demo", zigrun_api, "<name>");

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_zigdemo_shutdown() fs.switch_status_t {
    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_zigdemo_runtime() fs.switch_status_t {
    return fs.SWITCH_STATUS_SUCCESS;
}
