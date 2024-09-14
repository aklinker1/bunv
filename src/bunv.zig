const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const is_debug = try utils.isDebug(allocator);
    const config_dir = try utils.getConfigDir(allocator, is_debug);
    defer allocator.free(config_dir);
    if (is_debug) std.debug.print("Config Dir: {s}\n", .{config_dir});

    var installed_versions = try utils.getInstalledVersions(allocator, config_dir);
    defer installed_versions.deinit();

    installed_versions.print();
}
