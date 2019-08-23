const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    zigcc(b);
    zigclang(b);
}

fn zigcc(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("zigcc", "zigcc.zig");
    exe.setBuildMode(mode);
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn zigclang(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("zigclang", "zigclang.zig");
    exe.setBuildMode(mode);
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn zigcl(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("zigcl", "zigcl.zig");
    exe.setBuildMode(mode);
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
