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

    const is_debug = try utils.isDebug(allocator);
    if (is_debug) {
        std.debug.print("Bunv Version: {}\n", .{config.version});
        std.debug.print("Operating System: {s}\n", .{@tagName(builtin.os.tag)});
        std.debug.print("Architecture: {s}\n", .{@tagName(builtin.cpu.arch)});
    }

    const config_dir = try utils.getConfigDir(allocator, is_debug);
    defer allocator.free(config_dir);
    if (is_debug) std.debug.print("Config Dir: {s}\n", .{config_dir});

    // Parse command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Skip the first argument (program name)
    if (args.len == 1) {
        // No arguments, list installed versions
        try listVersions(allocator, config_dir);
    } else {
        const command = args[1];
        if (mem.eql(u8, command, "help") or mem.eql(u8, command, "--help") or mem.eql(u8, command, "-h")) {
            try printHelp();
        } else if (mem.eql(u8, command, "rm")) {
            if (args.len < 3) {
                std.debug.print("{s}Error: 'rm' command requires a version argument{s}\n", .{ c.red, c.reset });
                std.debug.print("Usage: bunv rm <version>\n", .{});
                std.process.exit(1);
            }
            const version = args[2];
            try removeVersion(allocator, config_dir, version);
        } else {
            std.debug.print("{s}Error: Unknown command '{s}'{s}\n", .{ c.red, command, c.reset });
            std.debug.print("Run 'bunv help' for usage information\n", .{});
            std.process.exit(1);
        }
    }
}

fn listVersions(allocator: mem.Allocator, config_dir: []const u8) !void {
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
    if (versions.items.len == 0) {
        std.debug.print("  {s}No versions installed{s}\n", .{ c.yellow, c.reset });
        return;
    }
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

fn printHelp() !void {
    std.debug.print("\n{s}{s}Bunv{s} - Manage installed versions of Bun {s}({}){s}\n\n", .{ c.bold, c.blue, c.reset, c.dim, config.version, c.reset });
    std.debug.print("{s}Commands:{s}\n", .{ c.bold, c.reset });
    std.debug.print("                List installed Bun versions\n", .{});
    std.debug.print("  {s}{s}rm{s} {s}<version>{s}  Remove an installed Bun version\n", .{ c.bold, c.yellow, c.reset, c.dim, c.reset });
    std.debug.print("  {s}{s}help{s}          Show this help message\n", .{ c.bold, c.cyan, c.reset });
    std.debug.print("\n", .{});
}

fn removeVersion(allocator: mem.Allocator, config_dir: []const u8, version: []const u8) !void {
    // Check if version is installed
    const installed_versions = try vm.getInstalledVersions(allocator, config_dir);
    defer {
        for (installed_versions.items) |item| {
            allocator.free(item);
        }
        installed_versions.deinit();
    }

    var version_exists = false;
    for (installed_versions.items) |installed_version| {
        if (mem.eql(u8, installed_version, version)) {
            version_exists = true;
            break;
        }
    }

    if (!version_exists) {
        std.debug.print("{s}Error: Bun v{s} is not installed{s}\n", .{ c.red, version, c.reset });
        std.process.exit(1);
    }

    // Get the version directory path
    const version_dir = try vm.getVersionDir(allocator, config_dir, version);
    defer allocator.free(version_dir);

    // Remove the directory
    std.debug.print("Removing Bun v{s}...\n", .{version});

    std.fs.deleteTreeAbsolute(version_dir) catch |err| {
        std.debug.print("{s}Error: Failed to remove Bun v{s}: {s}{s}\n", .{ c.red, version, @errorName(err), c.reset });
        std.process.exit(1);
    };

    std.debug.print("{s}✓{s} Successfully removed Bun v{s}\n", .{ c.green, c.reset, version });
}
