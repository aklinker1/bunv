const std = @import("std");
const os = std.os;
const mem = std.mem;
const fs = std.fs;
const json = std.json;
const builtin = @import("builtin");
const vm = @import("vm.zig");

pub const Cmd = enum {
    bun,
    bunx,
};

pub fn run(allocator: mem.Allocator, cmd: Cmd) !void {
    const is_debug = try isDebug(allocator);
    if (is_debug) std.debug.print("Executable: {}\n", .{cmd});

    const config_dir = try getConfigDir(allocator, is_debug);
    defer allocator.free(config_dir);

    if (is_debug) std.debug.print("Config Dir: {s}\n", .{config_dir});

    const project_version = try vm.detectProjectVersion(allocator, is_debug) orelse try vm.getLatestLocalVersion(allocator, is_debug, config_dir) orelse try vm.getLatestRemoteVersion(allocator, is_debug);
    defer allocator.free(project_version);

    try vm.ensureVersionDownloaded(allocator, config_dir, project_version);

    // Run bun command

    const bin = try fs.path.join(allocator, &[_][]const u8{ config_dir, "versions", project_version, "bin", "bun" });
    defer allocator.free(bin);

    var new_args = try std.ArrayList([]const u8).initCapacity(allocator, 5);
    defer new_args.deinit();

    try new_args.append(bin);
    if (cmd == .bunx) try new_args.append("x");

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    for (args[1..]) |arg| {
        try new_args.append(arg);
    }

    if (is_debug) std.debug.print("Original args: {s}\nModified args: {s}\n---\n", .{ args, new_args.items });
    return runBunCmd(allocator, new_args.items);
}

/// Grab the user's home directory
fn getHomeDir(allocator: mem.Allocator) ![]const u8 {
    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    if (env_map.get("HOME")) |home_path| {
        return allocator.dupe(u8, home_path);
    } else if (env_map.get("USERPROFILE")) |profile_path| {
        return allocator.dupe(u8, profile_path);
    } else {
        return error.HomeDirNotFound;
    }
}

/// Grab the BUNV_INSTALL environment variable or use ".bunv", and resolve relative to the home directory
pub fn getConfigDir(allocator: mem.Allocator, is_debug: bool) ![]const u8 {
    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    const bunv_install = env_map.get("BUNV_INSTALL") orelse ".bunv";

    const home_dir = try getHomeDir(allocator);
    defer allocator.free(home_dir);

    if (is_debug) std.debug.print("Home Dir: {s}\n", .{home_dir});
    return try fs.path.join(allocator, &[_][]const u8{ home_dir, bunv_install });
}

/// Check to see if the DEBUG environment variable is set to "bunv"
pub fn isDebug(allocator: mem.Allocator) !bool {
    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    if (env_map.get("DEBUG")) |value| {
        return mem.eql(u8, value, "bunv");
    }

    return false;
}

pub fn file_exists(file: []u8) !bool {
    std.fs.accessAbsolute(file, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => |e| return e,
    };
    return true;
}

fn runBunCmd(allocator: mem.Allocator, args: [][]const u8) (std.process.ExecvError || std.process.Child.SpawnError) {
    if (builtin.os.tag != .windows) {
        return std.process.execv(allocator, args);
    } else {
        var proc = std.process.Child.init(args, allocator);
        proc.stdin_behavior = .Inherit;
        proc.stdout_behavior = .Inherit;
        proc.stderr_behavior = .Inherit;
        try proc.spawn();
        switch (try proc.wait()) {
            .Exited => |code| std.process.exit(code),
            else => std.process.cleanExit(),
        }
    }
}
