const builtin = @import("builtin");
const std = @import("std");
const ArrayList = std.ArrayList;
const root = @import("root");

pub const ZigCmd = struct {
    link: bool,
    name: ?[]const u8,
    buildMode: builtin.Mode,
    addLibc: bool,
    cSources: ArrayList([]const u8),
    clangArgs: ArrayList([]const u8),
    inputFiles: ArrayList([]const u8),
    flags: ArrayList([]const u8),
    pub fn appendArgs(self: *const ZigCmd, args: *ArrayList([]const u8)) !void {
        if (self.link) {
            try args.append("build-exe");
        } else {
            try args.append("build-obj");
        }
        if (self.name) |name_s| {
            try args.append("--name");
            try args.append(name_s);
        }
        switch (self.buildMode) {
            .Debug => {},
            .ReleaseSafe => try args.append("--release-safe"),
            .ReleaseSmall => try args.append("--release-small"),
            .ReleaseFast => try args.append("--release-fast"),
        }
        if (self.addLibc) {
            try args.append("--library");
            try args.append("c");
        }
        if (self.clangArgs.len > 0 and self.cSources.len == 0) {
            root.errorf("there were {} clang args given but no C source files, zig can't accept this", self.clangArgs.len);
            return error.InvalidData;
        }
        for (self.cSources.toSlice()) |cSource, i| {
            try args.append("--c-source");
            if (i == 0) {
                // All non-positional arguments between --c-source and the C file go to clang
                for (self.clangArgs.toSlice()) |clangArg| {
                    if (!std.mem.startsWith(u8, clangArg, "-")) {
                        root.errorf("zig doesn't support clang arguments that don't start with  '-' yet '{}' does not", clangArg);
                        return error.InvalidData;
                    }
                    try args.append(clangArg);
               }
            }
            try args.append(cSource);
        }
        for (self.inputFiles.toSlice()) |inputFile| {
            try args.append(inputFile);
        }
        for (self.flags.toSlice()) |flag| {
            try args.append(flag);
        }
    }
};

pub fn printArgs(args: [][]const u8) void {
    var prefix = ""[0..];
    for (args) |arg| {
        std.debug.warn("{}{}", prefix, arg);
        prefix = " ";
    }
    std.debug.warn("\n");
}
