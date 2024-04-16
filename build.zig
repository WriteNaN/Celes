const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies
    // since LSP wasn't able to detect types, maybe I should just import :)
    //const chameleon = b.addModule("chameleon", .{ .root_source_file = .{ .path = "src/deps/chameleon/chameleon.zig" } });


   // Compiler
    const exe = b.addExecutable(.{
        .name = "celes",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();

    //exe.root_module.addImport("chameleon", chameleon);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the program");
    run_step.dependOn(&run_cmd.step);
}
