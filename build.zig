const std = @import("std");

const bun = "bun";
const bunx = "bunx";
const bunv = "bunv";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    addExe(b, target, optimize, bun);
    addExe(b, target, optimize, bunx);
    addExe(b, target, optimize, bunv);
}

fn addExe(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, comptime name: []const u8) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/" ++ name ++ ".zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_exe_step = b.step(name, "Run the bunx executable");
    run_exe_step.dependOn(&run_exe.step);
}
