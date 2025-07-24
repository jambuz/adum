const std = @import("std");

pub fn dumpMemoryToFile(
    pid: ?std.os.linux.pid_t,
    mem_start: usize,
    mem_end: usize,
    dump_path: []const u8,
) !void {
    const payload_len = mem_end - mem_start;
    const max_buf_len = 2 * 1024 * 1024;
    var buf: [max_buf_len]u8 = undefined;

    const read_len = @min(payload_len, buf.len);

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

    if (result < 0) return error.ProcessVmReadvFailed;

    const f = try std.fs.createFileAbsolute(dump_path, .{});
    defer f.close();
    try f.writer().writeAll(buf[0..result]);
}
