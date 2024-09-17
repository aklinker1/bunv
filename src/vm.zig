const std = @import("std");
const os = std.os;
const mem = std.mem;
const fs = std.fs;
const json = std.json;
const utils = @import("utils.zig");
const c = @import("colors.zig");

pub fn getInstalledVersions(allocator: mem.Allocator, config_dir: []const u8) !std.ArrayList([]const u8) {
    const versions_dir_path = try getVersionsDir(allocator, config_dir);
    defer allocator.free(versions_dir_path);

    var result = std.ArrayList([]const u8).init(allocator);

    var versions_dir = fs.openDirAbsolute(versions_dir_path, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return result,
        else => |e| return e,
    };
    defer versions_dir.close();

    var versions_iter = versions_dir.iterateAssumeFirstIteration();
    while (try versions_iter.next()) |entry| {
        if (entry.kind != .directory) continue;

        const version = try allocator.dupe(u8, entry.name);
        errdefer allocator.free(version);

        const bin = try getBinPath(allocator, config_dir, version);
        defer allocator.free(bin);

        if (try utils.file_exists(bin)) {
            try result.append(version);
        } else {
            allocator.free(version);
        }
    }

    return result;
}

/// Reads the different files potentially containing the bun version to use. Walks up the directory tree until it finds one of the files.
pub fn detectProjectVersion(allocator: mem.Allocator, is_debug: bool) !?[]const u8 {
    const files = comptime [_]VersionFile{
        PackageJsonVersionFile.init(),
        // BunVersionFile.init(),
        // ToolVersionsFile.init(),
    };

    var current_dir = try fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(current_dir);

    while (true) {
        if (is_debug) std.debug.print("Checking dir: {s}\n", .{current_dir});
        for (files) |version_file| {
            const file_path = try fs.path.join(allocator, &[_][]const u8{ current_dir, version_file.name });
            defer allocator.free(file_path);

            const file = fs.openFileAbsolute(file_path, .{}) catch |err| switch (err) {
                error.FileNotFound => continue,
                else => |e| return e,
            };
            defer file.close();

            const file_size = try file.getEndPos();
            const buffer = try allocator.alloc(u8, file_size);
            defer allocator.free(buffer);

            _ = try file.readAll(buffer);
            if (version_file.extractBunVersion(allocator, buffer)) |version| {
                if (is_debug) std.debug.print("Found v{s} in {s}\n", .{ version, file_path });
                return try allocator.dupe(u8, version);
            }
        }

        // Move up to the parent directory
        const parent_dir = fs.path.dirname(current_dir);
        if (parent_dir == null or mem.eql(u8, parent_dir.?, current_dir)) {
            // We've reached the root directory, stop searching
            break;
        }
        const new_dir = try fs.path.join(allocator, &[_][]const u8{parent_dir.?});
        allocator.free(current_dir);
        current_dir = new_dir;
    }

    return null;
}

pub fn getLatestLocalVersion(allocator: mem.Allocator, is_debug: bool, config_dir: []const u8) !?[]const u8 {
    if (is_debug) std.debug.print("Getting latest local verison...\n", .{});

    const installed_versions = try getInstalledVersions(allocator, config_dir);
    if (is_debug) std.debug.print("{d} versions: {s}\n", .{ installed_versions.items.len, installed_versions.items });
    defer {
        for (installed_versions.items) |item| {
            allocator.free(item);
        }
        installed_versions.deinit();
    }

    if (installed_versions.items.len == 0) {
        return null;
    }
    // TODO: installed versions are not sorted, so naively assuming the first item is the latest is wrong.
    return try allocator.dupe(u8, installed_versions.items[0]);
}

pub fn getLatestRemoteVersion(_: mem.Allocator, is_debug: bool) ![]u8 {
    if (is_debug) std.debug.print("Getting latest remote verison...\n", .{});
    return error.Todo;
}

pub fn ensureVersionDownloaded(allocator: mem.Allocator, config_dir: []const u8, version: []const u8) !void {
    const bin = try getBinPath(allocator, config_dir, version);
    defer allocator.free(bin);
    if (try utils.file_exists(bin)) {
        return;
    }

    try confirmInstallation(version);

    std.debug.print("Installing...\n", .{});

    const install_script_path = try fs.path.join(allocator, &[_][]const u8{ config_dir, "install.sh" });
    defer allocator.free(install_script_path);

    // Download install script

    const curlProcess = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{
            "curl",
            "-fsSL",
            "-o",
            install_script_path,
            "https://bun.sh/install",
        },
    });
    defer allocator.free(curlProcess.stderr);
    defer allocator.free(curlProcess.stdout);

    // Run install script

    const version_path = try fs.path.join(allocator, &[_][]const u8{ config_dir, "versions", version });
    defer allocator.free(version_path);

    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    try env.put("BUN_INSTALL", version_path);

    const version_arg = try std.fmt.allocPrint(
        allocator,
        "bun-v{s}",
        .{version},
    );
    defer allocator.free(version_arg);

    const installProcess = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{
            "sh",
            install_script_path,
            version_arg,
        },
        .env_map = &env,
    });
    defer allocator.free(installProcess.stderr);
    defer allocator.free(installProcess.stdout);

    std.debug.print("{s}✓{s} Done! {s}Bun v{s}{s} is installed\n", .{ c.green, c.reset, c.cyan, version, c.reset });
}

fn confirmInstallation(version: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    try stdout.print("{s}Bun v{s} is not installed. Do you want to install it? [y/N]{s} ", .{ c.yellow, version, c.reset });
    var buffer: [2]u8 = undefined;
    const user_input = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch |err| switch (err) {
        error.StreamTooLong => "N",
        else => return err,
    } orelse "N";

    if (mem.eql(u8, user_input, "y")) return;

    return error.UserAborted;
}

pub fn getVersionsDir(allocator: mem.Allocator, config_dir: []const u8) ![]u8 {
    return try fs.path.join(allocator, &[_][]const u8{ config_dir, "versions" });
}
pub fn getVersionDir(allocator: mem.Allocator, config_dir: []const u8, version: []const u8) ![]u8 {
    return try fs.path.join(allocator, &[_][]const u8{ config_dir, "versions", version });
}
pub fn getBinPath(allocator: mem.Allocator, config_dir: []const u8, version: []const u8) ![]u8 {
    return try fs.path.join(allocator, &[_][]const u8{ config_dir, "versions", version, "bin", "bun" });
}

const VersionFile = struct {
    name: []const u8,
    extractBunVersion: *const fn (allocator: mem.Allocator, contents: []u8) ?[]const u8,
};
const PackageJsonVersionFile = struct {
    fn init() VersionFile {
        return .{
            .name = "package.json",
            .extractBunVersion = &extractBunVersion,
        };
    }
    fn extractBunVersion(allocator: mem.Allocator, contents: []u8) ?[]const u8 {
        const parsed = json.parseFromSlice(std.json.Value, allocator, contents, .{}) catch |err| switch (err) {
            else => return null,
        };
        defer parsed.deinit();

        // "bun@X.Y.Z"
        if (parsed.value.object.get("packageManager")) |package_manager| {
            return allocator.dupe(u8, package_manager.string[4..]) catch return null;
        }
        return null;
    }
};

const BunVersionFile = struct {
    fn init() VersionFile {
        return .{
            .name = ".bun-version",
            .extractBunVersion = &extractBunVersion,
        };
    }
    fn extractBunVersion(allocator: mem.Allocator, contents: []u8) ?[]u8 {
        return try allocator.dupe(u8, contents) catch |err| switch (err) {
            else => return null,
        };
    }
};

const ToolVersionsFile = struct {
    fn init() VersionFile {
        return .{
            .name = ".tool-versions",
            .extractBunVersion = &extractBunVersion,
        };
    }
    fn extractBunVersion(allocator: mem.Allocator, contents: []u8) ?[]u8 {
        const regex = std.regex.compile(allocator, "^bun\\s*(.*?)$", .{});
        defer std.regex.free(regex);

        const match = try std.regex.match(allocator, regex, contents, 0, contents.len);
        defer allocator.free(match);

        if (match.len == 0) {
            return null;
        }

        const version = match[0].groups[0];
        return allocator.dupe(u8, version);
    }
};
