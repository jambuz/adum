const std = @import("std");

pub fn dumpMemoryToFile(
    pid: ?std.os.linux.pid_t,
    mem_start: usize,
    mem_end: usize,
    dump_path: []const u8,
) !void {
    const payload_len = mem_end - mem_start;
    var buf: [128 * 1024 * 1024]u8 = undefined;

    const read_len = @min(payload_len, buf.len);
    std.log.debug("Byte amount to read: {d}\n", .{read_len});

    const iov_local = &[_]std.posix.iovec{
        .{
            .base = &buf,
            .len = read_len,
        },
    };

    const iov_remote = &[_]std.posix.iovec_const{
        .{
            .base = @ptrFromInt(mem_start),
            .len = read_len,
        },
    };

    const result = std.os.linux.process_vm_readv(
        pid orelse std.os.linux.getpid(),
        iov_local,
        iov_remote,
        0,
    );

    if (result < 0) {
        std.log.err("Reading process memory failed. Status: {}", .{std.posix.errno(result)});
        return error.ProcessVmReadvFailed;
    }

    const f = try std.fs.createFileAbsolute(dump_path, .{});
    defer f.close();
    try f.writer().writeAll(buf[0..result]);
}
