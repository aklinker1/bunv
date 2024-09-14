const std = @import("std");
const os = std.os;
const mem = std.mem;
const fs = std.fs;
const json = std.json;

pub const Cmd = enum {
    bun,
    bunx,
};

const reset = "\x1b[0m";
const bold = "\x1b[1m";
const dim = "\x1b[2m";
const grey = "\x1b[90m";
const red = "\x1b[31m";
const green = "\x1b[32m";
const yellow = "\x1b[33m";
const blue = "\x1b[34m";
const magenta = "\x1b[35m";
const cyan = "\x1b[36m";

pub fn run(allocator: mem.Allocator, cmd: Cmd) !void {
    const is_debug = try isDebug(allocator);
    if (is_debug) std.debug.print("Executable: {}\n", .{cmd});

    const config_dir = try getConfigDir(allocator, is_debug);
    defer allocator.free(config_dir);

    if (is_debug) std.debug.print("Config Dir: {s}\n", .{config_dir});

    const project_version = try getProjectVersion(allocator, is_debug) orelse try getLatestLocalVersion(allocator, is_debug, config_dir) orelse try getLatestRemoteVersion(allocator, is_debug);
    defer allocator.free(project_version);

    try ensureVersionDownloaded(allocator, project_version, config_dir);

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

    if (is_debug) std.debug.print("Original args: {s}\nModified args: {s}\n---\n", .{ args, args });
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

pub const InstalledVersion = struct {
    version: []const u8,
    directory: []const u8,
    bin_dir: []const u8,
    bin: []const u8,
};

pub const InstalledVersionList = struct {
    allocator: mem.Allocator,
    versions: std.ArrayList(InstalledVersion),

    pub fn init(allocator: mem.Allocator) !InstalledVersionList {
        return .{
            .allocator = allocator,
            .versions = try std.ArrayList(InstalledVersion).initCapacity(allocator, 10),
        };
    }

    pub fn deinit(self: *InstalledVersionList) void {
        for (self.versions.items) |version| {
            self.allocator.free(version.version);
            self.allocator.free(version.directory);
            self.allocator.free(version.bin_dir);
            self.allocator.free(version.bin);
        }
        self.versions.deinit();
    }

    pub fn addVersion(self: *InstalledVersionList, version: []const u8, directory: []const u8, bin_dir: []const u8, bin: []const u8) !void {
        const item = InstalledVersion{
            .version = try self.allocator.dupe(u8, version),
            .directory = try self.allocator.dupe(u8, directory),
            .bin_dir = try self.allocator.dupe(u8, bin_dir),
            .bin = try self.allocator.dupe(u8, bin),
        };
        try self.versions.append(item);
    }

    pub fn print(self: *InstalledVersionList) void {
        std.debug.print("{s}Installed versions:{s}\n", .{ bold, reset });
        for (self.versions.items) |version| {
            std.debug.print("  {s}{s}v{s}{s}\n", .{ bold, blue, version.version, reset });
            std.debug.print("    {s}│ {s} Directory: {s}{s}{s}\n", .{ grey, reset, cyan, version.directory, reset });
            std.debug.print("    {s}│ {s} Bin Dir:   {s}{s}{s}\n", .{ grey, reset, cyan, version.bin_dir, reset });
            std.debug.print("    {s}└─{s} Bin:       {s}{s}{s}\n", .{ grey, reset, cyan, version.bin, reset });
        }
    }

    pub fn findVersion(self: *InstalledVersionList, version: []const u8) !?*const InstalledVersion {
        for (self.versions.items) |installed_version| {
            if (mem.eql(u8, installed_version.version, version)) {
                return &installed_version;
            }
        }
        return null;
    }

    pub fn getLatestVersion(self: *InstalledVersionList) ?*const InstalledVersion {
        if (self.versions.items.len == 0) {
            return null;
        }

        return &self.versions.items[0];
    }
};

/// Look for directories inside $config_dir/versions
pub fn getInstalledVersions(allocator: mem.Allocator, config_dir: []const u8) !InstalledVersionList {
    const versions_dir_path = try fs.path.join(allocator, &[_][]const u8{ config_dir, "versions" });
    defer allocator.free(versions_dir_path);

    var versions_dir = try fs.openDirAbsolute(versions_dir_path, .{ .iterate = true });
    defer versions_dir.close();

    var versions_dir_iter = versions_dir.iterate();
    var installed_versions = try InstalledVersionList.init(allocator);
    while (try versions_dir_iter.next()) |entry| {
        if (entry.kind != .directory) continue;

        const version = entry.name;
        const directory = try fs.path.join(allocator, &[_][]const u8{ versions_dir_path, version });
        defer allocator.free(directory);

        const bin_dir = try fs.path.join(allocator, &[_][]const u8{ directory, "bin" });
        defer allocator.free(bin_dir);

        const bin = try fs.path.join(allocator, &[_][]const u8{ bin_dir, "bun" });
        defer allocator.free(bin);

        if (try file_exists(bin)) {
            try installed_versions.addVersion(version, directory, bin_dir, bin);
        }
    }

    return installed_versions;
}

fn file_exists(file: []u8) !bool {
    std.fs.accessAbsolute(file, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => |e| return e,
    };
    return true;
}

const VersionFile = struct {
    name: []const u8,
    extractBunVersion: *const fn (allocator: mem.Allocator, contents: []u8) ?[]const u8,
};
const PackageJson = struct {
    packageManager: ?[]const u8,
};
const PackageJsonVersionFile = struct {
    fn init() VersionFile {
        return .{
            .name = "package.json",
            .extractBunVersion = &extractBunVersion,
        };
    }
    fn extractBunVersion(allocator: mem.Allocator, contents: []u8) ?[]const u8 {
        const parsed = json.parseFromSlice(PackageJson, allocator, contents, .{}) catch |err| switch (err) {
            else => return null,
        };
        defer parsed.deinit();

        const package_json = parsed.value;
        // "bun@X.Y.Z"
        const package_manager = package_json.packageManager orelse return null;
        return package_manager[4..];
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

/// Reads the different files potentially containing the bun version to use. Walks up the directory tree until it finds one of the files.
pub fn getProjectVersion(allocator: mem.Allocator, is_debug: bool) !?[]const u8 {
    const files = comptime [_]VersionFile{
        PackageJsonVersionFile.init(),
        // BunVersionFile.init(),
        // ToolVersionsFile.init(),
    };

    for (files) |version_file| {
        const file = fs.cwd().openFile(version_file.name, .{}) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => |e| return e,
        };
        defer file.close();

        const file_size = try file.getEndPos();
        const buffer = try std.heap.page_allocator.alloc(u8, file_size);
        defer std.heap.page_allocator.free(buffer);

        _ = try file.readAll(buffer);
        if (version_file.extractBunVersion(allocator, buffer)) |version| {
            if (is_debug) std.debug.print("Found v{s} in {s}\n", .{ version, version_file.name });
            return try allocator.dupe(u8, version);
        }
    }

    return error.NoBunVersionFound;
}

pub fn getLatestLocalVersion(allocator: mem.Allocator, is_debug: bool, config_dir: []const u8) !?[]const u8 {
    if (is_debug) std.debug.print("Getting latest local verison...", .{});

    var installed_versions = try getInstalledVersions(allocator, config_dir);
    defer installed_versions.deinit();

    const latest_version = installed_versions.getLatestVersion() orelse return null;
    return latest_version.version;
}

pub fn getLatestRemoteVersion(_: mem.Allocator, is_debug: bool) ![]u8 {
    if (is_debug) std.debug.print("Getting latest remote verison...", .{});
    return error.Todo;
}

pub fn ensureVersionDownloaded(allocator: mem.Allocator, version: []const u8, config_dir: []const u8) !void {
    const bin = try fs.path.join(allocator, &[_][]const u8{ config_dir, "versions", version, "bin", "bun" });
    defer allocator.free(bin);
    if (try file_exists(bin)) {
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

    std.debug.print("{s}✓{s} Done! {s}Bun v{s}{s} is installed\n", .{ green, reset, cyan, version, reset });
}

fn confirmInstallation(version: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    try stdout.print("{s}Bun v{s} is not installed. Do you want to install it? [y/N]{s} ", .{ yellow, version, reset });
    var buffer: [2]u8 = undefined;
    const user_input = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch |err| switch (err) {
        error.StreamTooLong => "N",
        else => return err,
    } orelse "N";

    if (mem.eql(u8, user_input, "y")) return;

    return error.UserAborted;
}

fn runBunCmd(allocator: mem.Allocator, args: [][]const u8) std.process.ExecvError {
    return std.process.execv(allocator, args);
}
