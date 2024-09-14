const std = @import("std");
const mem = std.mem;
const utils = @import("utils.zig");
const vm = @import("vm.zig");
const builtin = @import("builtin");
const config = @import("config");
const c = @import("colors.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("Bunv Version: {}\n", .{config.version});
    std.debug.print("Operating System: {s}\n", .{@tagName(builtin.os.tag)});
    std.debug.print("Architecture: {s}\n", .{@tagName(builtin.cpu.arch)});

    const is_debug = try utils.isDebug(allocator);
    const config_dir = try utils.getConfigDir(allocator, is_debug);
    defer allocator.free(config_dir);
    if (is_debug) std.debug.print("Config Dir: {s}\n", .{config_dir});

    const installed_versions = try vm.getInstalledVersions(allocator, config_dir);
    defer {
        for (installed_versions.items) |item| {
            allocator.free(item);
        }
        installed_versions.deinit();
    }

    try printInstalledVersions(allocator, config_dir, installed_versions);
}

fn printInstalledVersions(allocator: mem.Allocator, config_dir: []const u8, versions: std.ArrayList([]const u8)) !void {
    std.debug.print("{s}Installed versions:{s}\n", .{ c.bold, c.reset });
    for (versions.items) |version| {
        const directory = try vm.getVersionDir(allocator, config_dir, version);
        defer allocator.free(directory);

        const bin = try vm.getBinPath(allocator, config_dir, version);
        defer allocator.free(bin);

        std.debug.print("  {s}{s}v{s}{s}\n", .{ c.bold, c.blue, version, c.reset });
        std.debug.print("    {s}│ {s} Directory: {s}{s}{s}\n", .{ c.grey, c.reset, c.cyan, directory, c.reset });
        std.debug.print("    {s}└─{s} Bin:       {s}{s}{s}\n", .{ c.grey, c.reset, c.cyan, bin, c.reset });
    }
}
