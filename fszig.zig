const fs = @cImport({
    @cInclude("switch.h");
});

pub const module_interface = fs.switch_loadable_module_interface_t;
const module_load = fs.switch_module_load_t;
const module_shutdown = fs.switch_module_shutdown_t;
const module_runtime = fs.switch_module_runtime_t;
const module_flag = u32;

// freeswitch requires this structure as entrypoint
const LoadableModuleTable = extern struct { api_version: c_int, load: module_load, shutdown: module_shutdown, runtime: module_runtime, flags: module_flag };

/// Export definition for FreeSWITCH
/// Example:
///  export const mod_mymod_module_interface = fszig.module_definition(mod_mymod_load, mod_mymod_shutdown, mod_mymod_runtime);
pub fn module_definition(load: module_load, shutdown: module_shutdown, runtime: module_runtime) LoadableModuleTable {
    return LoadableModuleTable{ .api_version = fs.SWITCH_API_VERSION, .load = load, .shutdown = shutdown, .runtime = runtime, .flags = fs.SMODF_NONE };
}

pub fn switch_add_api(mod_int: *module_interface, int_name: []const u8, descript: []const u8, function: fs.switch_api_function_t, syntax: []const u8) void {
    var api_interface: *fs.switch_api_interface_t = @alignCast(@ptrCast(fs.switch_loadable_module_create_interface(@ptrCast(mod_int), fs.SWITCH_API_INTERFACE)));
    api_interface.interface_name = @ptrCast(int_name);
    api_interface.desc = @ptrCast(descript);
    api_interface.function = function;
    api_interface.syntax = @ptrCast(syntax);
}
