const std = @import("std");
const builtin = @import("builtin");

const flags = @import("flags");
const zmaps = @import("zmaps");

const Dumper = @import("dumper.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);

    const f = flags.parseOrExit(args, "adum", Flags, .{});

    if (f.command.search.target_module_name) |target_mod| {
        var p = try zmaps.PM.init(f.pid);
        defer p.deinit();

        const map = try p.findModule(target_mod);
        std.log.debug("\x1b[0;37m{?s} at \x1b[0;36m{x}-{x}\x1b[0;97m", .{ map.path, map.start, map.end });
        if (f.command.search.dump) {
            if (f.command.search.dump_out_path) |path| {
                try Dumper.dumpMemoryToFile(f.pid, map.start, map.end, path);
            } else return error.NoDumpOutputPathSpecified;
        }
    }
}

const Flags = struct {
    pub const description =
        \\Android Dumper Utility by Mesidex
    ;

    pid: ?i32,

    command: union(enum) {
        search: struct {
            dump: bool,
            target_module_name: ?[]const u8,
            dump_out_path: ?[]const u8,

            pub const switches = .{
                .dump = 'd',
                .target_module_name = 't',
                .dump_out_path = 'o',
            };
        },

        pub const descriptions = .{
            .search = "Search for a module in memory and optionally dump.",
        };
    },

    pub const switches = .{
        .pid = 'p',
    };
};
