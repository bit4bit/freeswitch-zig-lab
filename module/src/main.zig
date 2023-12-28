const std = @import("std");
const fs = @cImport({
    @cInclude("switch.h");
});

const testing = std.testing;

const Status = enum(u32) {
    SUCCESS = 0
};

const memory_pool = opaque {};
const module_interface = opaque {};
const module_load = fn(**module_interface,
                       *memory_pool) callconv(.C) Status;
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

export fn mod_zig_load(modi: **module_interface, pool: *memory_pool) Status {
    _ = pool;
    _ = modi;
    return Status.SUCCESS;
}

export fn mod_zig_shutdown() Status {
    return Status.SUCCESS;
}

export fn mod_zig_runtime() Status {
    return Status.SUCCESS;
}

