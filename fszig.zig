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

pub fn switch_add_app(mod_int: *module_interface, int_name: []const u8, short_desc: []const u8, long_desc: []const u8, function: fs.switch_application_function_t, syntax: []const u8, flags: u8) void {
    var app_interface: *fs.switch_application_interface_t = @alignCast(@ptrCast(fs.switch_loadable_module_create_interface(@ptrCast(mod_int), fs.SWITCH_APPLICATION_INTERFACE)));
    app_interface.interface_name = @ptrCast(int_name);
    app_interface.application_function = function;
    app_interface.short_desc = @ptrCast(short_desc);
    app_interface.long_desc = @ptrCast(long_desc);
    app_interface.syntax = @ptrCast(syntax);
    app_interface.flags = flags;
}

pub fn switch_core_session_locate(uuid: [*c]const u8) ?*fs.switch_core_session_t {
    return @ptrCast(fs.switch_core_session_perform_locate(uuid, @src().file, @src().fn_name, @src().line));
}

pub fn switch_event_create(event: *const *fs.switch_event_t, event_id: fs.switch_event_types_t) fs.switch_status_t {
    return fs.switch_event_create_subclass_detailed(@src().file, @src().fn_name, @src().line, @ptrCast(@constCast(event)), event_id, @ptrCast(fs.SWITCH_EVENT_SUBCLASS_ANY));
}

pub fn switch_channel_set_state(channel: ?*fs.switch_channel_t, state: fs.switch_channel_state_t) fs.switch_channel_state_t {
    return fs.switch_channel_perform_set_state(@ptrCast(channel), @src().file, @src().fn_name, @src().line, state);
}

pub fn switch_event_destroy(event: *const *fs.switch_event_t) void {
    fs.switch_event_destroy(@ptrCast(@constCast(event)));
}
