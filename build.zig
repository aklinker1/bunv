const std = @import("std");
const json = std.json;

const bun = "bun";
const bunx = "bunx";
const bunv = "bunv";

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const version_json = @embedFile("package.json");
    var parsed = json.parseFromSlice(std.json.Value, b.allocator, version_json, .{}) catch unreachable;
    defer parsed.deinit();
    const version_str = parsed.value.object.get("version").?.string;
    const version = try std.SemanticVersion.parse(version_str);

    addExe(b, target, optimize, version, bun);
    addExe(b, target, optimize, version, bunx);
    addExe(b, target, optimize, version, bunv);
}

fn addExe(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, version: std.SemanticVersion, comptime name: []const u8) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/" ++ name ++ ".zig"),
        .target = target,
        .optimize = optimize,
        .version = version,
    });

    const options = b.addOptions();
    options.addOption(std.SemanticVersion, "version", version);
    exe.root_module.addOptions("config", options);

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_exe_step = b.step(name, "Run the bunx executable");
    run_exe_step.dependOn(&run_exe.step);
}
