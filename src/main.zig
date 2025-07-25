const std = @import("std");
const builtin = @import("builtin");

const flags = @import("flags");
const zmaps = @import("zmaps");

const Dumper = @import("dumper.zig");

pub const std_options: std.Options = .{
    .logFn = log,
};

pub fn log(
    comptime level: std.log.Level,
    comptime _: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.print("[{s}] " ++ format, .{level.asText()} ++ args);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);

    const f = flags.parseOrExit(args, "adum", Flags, .{});

    var p = try zmaps.PM.init(f.pid);
    defer p.deinit();

    const map = try p.findModule(f.module_name);

    std.log.debug("{?s} at \x1b[0;36m{x}-{x}\x1b[0;37m\n", .{ map.path, map.start, map.end });
    if (f.dump_path) |path| {
        try Dumper.dumpMemoryToFile(f.pid, map.start, map.end, path);
    }
}

const Flags = struct {
    pub const description =
        \\Android Dumper Utility by Mesidex
    ;

    pid: ?i32,
    module_name: []const u8,
    dump_path: ?[]const u8,

    pub const switches = .{
        .pid = 'p',
        .module_name = 'm',
        .dump_path = 'o',
    };
};
