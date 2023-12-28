const std = @import("std");
const fs = @cImport({
    @cInclude("switch.h");
});

const testing = std.testing;

const Status = enum(u32) {
    SUCCESS = 0
};

const memory_pool = fs.switch_memory_pool_t;
const module_interface = fs.switch_loadable_module_interface_t;
const module_load = fn(**module_interface,
                       ?*memory_pool) callconv(.C) fs.switch_status_t;
const module_shutdown = fn() callconv(.C) Status;
const module_runtime = fn() callconv(.C) Status;
const module_flag = u32;
const LoadableModuleTable = extern struct {
    api_version: c_int,
    load: *const module_load,
    shutdown: *const module_shutdown,
    runtime: *const module_runtime,
    flags: module_flag
};

export const  mod_zig_module_interface: LoadableModuleTable = .{
    .api_version = 5,
    .load = mod_zig_load,
    .shutdown = mod_zig_shutdown,
    .runtime = mod_zig_runtime,
    .flags = 0
};

export fn zigrun_api(cmd: [*c]const u8, session: ?*fs.switch_core_session_t, stream: [*c]fs.switch_stream_handle_t) callconv(.C) fs.switch_status_t {
    _ = cmd;
    _ = session;

    _ = fs.switch_console_stream_write(stream, "demo");

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_zig_load(modi: **module_interface, pool: ?*fs.switch_memory_pool_t) fs.switch_status_t {
    
    modi.* = fs.switch_loadable_module_create_module_interface(pool, "mod_zig");

    //fs.SWITCH_ADD_API(api_interface, "zigrun", "run a zig", zigrun_api, "<name>");
    {
        var api_interface: *fs.switch_api_interface_t = @alignCast(@ptrCast(fs.switch_loadable_module_create_interface(@ptrCast(modi.*), fs.SWITCH_API_INTERFACE)));
        api_interface.interface_name = "zigrun";
        api_interface.desc = "run a zig demo";
        api_interface.function = zigrun_api;
        api_interface.syntax = "<name>";
    }

    return fs.SWITCH_STATUS_SUCCESS;
}

export fn mod_zig_shutdown() Status {
    return Status.SUCCESS;
}

export fn mod_zig_runtime() Status {
    return Status.SUCCESS;
}

