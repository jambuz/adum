const std = @import("std");

pub const PM = struct {
    file: std.fs.File,

    const MemoryRange = struct {
        start: usize,
        end: usize,
    };

    pub fn init(pid: ?std.os.linux.pid_t) !PM {
        var path_buf: [64]u8 = undefined;
        const path = try if (pid) |p|
            std.fmt.bufPrint(&path_buf, "/proc/{d}/maps", .{p})
        else
            std.fmt.bufPrint(&path_buf, "/proc/self/maps", .{});

        const file = try std.fs.openFileAbsolute(path, .{});

        return .{ .file = file };
    }

    pub fn findModule(self: *PM, module_name: []const u8) !MemoryRange {
        var buf: [65536]u8 = undefined;
        const bytes_read = try self.file.readAll(&buf);
        const maps_data = buf[0..bytes_read];

        var min_start: usize = std.math.maxInt(usize);
        var max_end: usize = 0;
        var found = false;

        var lines = std.mem.splitSequence(u8, maps_data, "\n");
        while (lines.next()) |line| {
            if (std.mem.indexOf(u8, line, module_name) == null) continue;

            const space_pos = std.mem.indexOfScalar(u8, line, ' ') orelse continue;
            const range = line[0..space_pos];
            const dash_pos = std.mem.indexOfScalar(u8, range, '-') orelse continue;

            const start = std.fmt.parseInt(usize, range[0..dash_pos], 16) catch continue;
            const end = std.fmt.parseInt(usize, range[dash_pos + 1 ..], 16) catch continue;

            min_start = @min(min_start, start);
            max_end = @max(max_end, end);
            found = true;
        }

        if (!found) return error.ModuleNotFound;
        return .{ .start = min_start, .end = max_end };
    }

    // pub fn findModule(self: *PM, module_name: []const u8) !MemoryRange {
    //     var buf: [4096]u8 = undefined;
    //     var min_start: usize = std.math.maxInt(usize);
    //     var max_end: usize = 0;
    //     var found = false;

    //     while (try self.file.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
    //         if (std.mem.indexOf(u8, line, module_name) == null) continue;

    //         const space_pos = std.mem.indexOfScalar(u8, line, ' ') orelse continue;
    //         const range = line[0..space_pos];
    //         const dash_pos = std.mem.indexOfScalar(u8, range, '-') orelse continue;

    //         const start = std.fmt.parseInt(usize, range[0..dash_pos], 16) catch continue;
    //         const end = std.fmt.parseInt(usize, range[dash_pos + 1 ..], 16) catch continue;

    //         min_start = @min(min_start, start);
    //         max_end = @max(max_end, end);
    //         found = true;
    //     }

    //     if (!found) return error.ModuleNotFound;
    //     return .{ .start = min_start, .end = max_end };
    // }

    pub fn deinit(self: *PM) void {
        self.file.close();
    }
};

test "a" {
    var p = try PM.init(null);
    const res = try p.findModule("lib");
    std.debug.print("{x}\t{x}\n", .{ res.start, res.end });
}
