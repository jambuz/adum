const std = @import("std");

const flags = @import("flags");

const PM = @import("pm.zig").PM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);

    const f = flags.parseOrExit(args, "colors", Flags, .{
        .colors = &flags.ColorScheme{
            .error_label = &.{},
            .command_name = &.{},
            .header = &.{},
            .usage = &.{},
        },
    });

    var p = try PM.init(f.pid);
    defer p.deinit();

    const mem_range = try p.findModule(f.mod);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("start: {x}\tend: {x}\n", .{ mem_range.start, mem_range.end });
}

const Flags = struct {
    pub const description =
        \\Android Dumper Utility v1.1
    ;

    pid: ?i32,
    mod: []const u8,
};
