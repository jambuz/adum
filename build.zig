const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "pmp",
        .root_module = exe_mod,
    });

    const zmaps_dep = b.dependency("zmaps", .{
        .target = target,
        .optimize = optimize,
    });

    const flags_dep = b.dependency("flags", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zmaps", zmaps_dep.module("zmaps"));
    exe.root_module.addImport("flags", flags_dep.module("flags"));

    b.installArtifact(exe);
}
