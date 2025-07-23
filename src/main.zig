const std = @import("std");

const flags = @import("flags");
const zmaps = @import("zmaps");

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

    var p = try zmaps.PM.init(f.pid);
    defer p.deinit();

    const map = try p.findModule(f.mod);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("[*] {?s} at \x1b[1;37m{x}-{x}\x1b[0;37m\n", .{ map.path, map.start, map.end });
}

const Flags = struct {
    pub const description =
        \\Android Dumper Utility v1.1
    ;

    pid: ?i32,
    mod: []const u8,
};
