const builtin = @import("builtin");
const std = @import("std");
const ArrayList = std.ArrayList;

usingnamespace @import("./zigcmd.zig");

const allocator = std.heap.direct_allocator;

pub fn errorf(comptime fmt: []const u8, args: ...) void {
    std.debug.warn("cc: error: " ++ fmt ++ "\n", args);
}
pub fn fatalErrorf(comptime fmt: []const u8, args: ...) void {
    std.debug.warn("cc: fatal error: " ++ fmt ++ "\n", args);
}

fn findzig(exe: []const u8) []const u8 {
    return "zig";
}

fn getCmdOpt(args: var, i: *usize) ![]const u8 {
    i.* = i.* + 1;
    if (i.* >= args.len) {
        errorf("missing argument for '{}'", args[i.* - 1]);
        return AlreadyReportedError.AlreadyReported;
    }
    return args[i.*];
}

const AlreadyReportedError = error {
    AlreadyReported,
};

const forwardFlags = [_][]const u8{
    "--verbose-cc",
};
const ignoreFlags = [_][]const u8{
    //"--ignore-me",
    // TODO: not sure what the zig equivalent of this is.
    //       it may be that --strip is the opposite?
    "-g",
};

pub fn main() !u8 {
    return main2() catch |err| {
        if (err == AlreadyReportedError.AlreadyReported)
            return 1;
        return err;
    };
}
fn main2() !u8 {
    const versionString = "gcc (Ubuntu 5.4.0-6ubuntu1~16.04.11) 5.4.0 20160609\n";
    const programsOutput =
        \\Using built-in specs.
        \\COLLECT_GCC=gcc
        \\COLLECT_LTO_WRAPPER=/usr/lib/gcc/x86_64-linux-gnu/5/lto-wrapper
        \\Target: x86_64-linux-gnu
        \\Configured with: ../src/configure -v --with-pkgversion='Ubuntu 5.4.0-6ubuntu1~16.04.11' --with-bugurl=file:///usr/share/doc/gcc-5/README.Bugs --enable-languages=c,ada,c++,java,go,d,fortran,objc,obj-c++ --prefix=/usr --program-suffix=-5 --enable-shared --enable-linker-build-id --libexecdir=/usr/lib --without-included-gettext --enable-threads=posix --libdir=/usr/lib --enable-nls --with-sysroot=/ --enable-clocale=gnu --enable-libstdcxx-debug --enable-libstdcxx-time=yes --with-default-libstdcxx-abi=new --enable-gnu-unique-object --disable-vtable-verify --enable-libmpx --enable-plugin --with-system-zlib --disable-browser-plugin --enable-java-awt=gtk --enable-gtk-cairo --with-java-home=/usr/lib/jvm/java-1.5.0-gcj-5-amd64/jre --enable-java-home --with-jvm-root-dir=/usr/lib/jvm/java-1.5.0-gcj-5-amd64 --with-jvm-jar-dir=/usr/lib/jvm-exports/java-1.5.0-gcj-5-amd64 --with-arch-directory=amd64 --with-ecj-jar=/usr/share/java/eclipse-ecj.jar --enable-objc-gc --enable-multiarch --disable-werror --with-arch-32=i686 --with-abi=m64 --with-multilib-list=m32,m64,mx32 --enable-multilib --with-tune=generic --enable-checking=release --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu
        \\Thread model: posix
        \\
        ;

    var argv = try std.process.argsAlloc(allocator);
    if (argv.len <= 1) {
        std.debug.warn("A wrapper around the Zig compiler to implement the CC compiler command-line interface\n");
        std.debug.warn("Usage: zigcc [--show-zig-cmd] [-o <file>] [-c] <file>.c...\n");
        return 1;
    }

    const zigExe = findzig(argv[0]);
    const ccargs = argv[1..];

    var showZigCmd = false;
    var extraCCArgs = ArrayList([]const u8).init(allocator);
    var outfile : ?[]const u8 = null;
    var zigCmd = ZigCmd {
        .link = true,
        .name = null,
        .buildMode = builtin.Mode.Debug,
        .addLibc = true,
        .cSources = ArrayList([]const u8).init(allocator),
        .clangArgs = ArrayList([]const u8).init(allocator),
        .inputFiles = ArrayList([]const u8).init(allocator),
        .flags = ArrayList([]const u8).init(allocator),
    };

    {
        var argIndex : usize = 0;
        while (argIndex < ccargs.len) : (argIndex += 1) {
            //std.debug.warn("argindex = {}\n", argIndex);
            const arg = ccargs[argIndex];
            if (arg[0] != '-') {
                if (std.mem.endsWith(u8, arg, ".c")) {
                    try zigCmd.cSources.append(arg);
                } else if (std.mem.endsWith(u8, arg, ".o")) {
                    try zigCmd.inputFiles.append(arg);
                } else {
                    errorf("unrecognized command line option ‘{}’", arg);
                    return 1;
                }
            } else if (std.mem.eql(u8, arg, "--show-zig-cmd")) {
                showZigCmd = true;
            } else if (std.mem.eql(u8, arg, "-o")) {
                outfile = try getCmdOpt(ccargs, &argIndex);
            } else if (std.mem.eql(u8, arg, "-c")) {
                zigCmd.link = false;
            } else if (std.mem.eql(u8, arg, "-E")) {
                //try extraCCArgs.append("-E");
                try zigCmd.clangArgs.append("-E");
            } else if (std.mem.eql(u8, arg, "--version")) {
                const stdout = try std.io.getStdOut();
                try stdout.write(versionString);
                return 0;
            } else if (std.mem.eql(u8, arg, "-v")) {
                const stdout = try std.io.getStdOut();
                try stdout.write(programsOutput);
                try stdout.write(versionString);
                return 0;
            } else if (std.mem.eql(u8, arg, "-O3") or std.mem.eql(u8, arg, "-O2")) {
                zigCmd.buildMode = builtin.Mode.ReleaseSmall;
            } else {
                var foundMatch = false;
                if (!foundMatch) {
                    for (forwardFlags) |forwardFlag| {
                        if (std.mem.eql(u8, arg, forwardFlag)) {
                            try zigCmd.flags.append(forwardFlag);
                            foundMatch = true;
                            break;
                        }
                    }
                }
                if (!foundMatch) {
                    for (ignoreFlags) |ignoreFlag| {
                        if (std.mem.eql(u8, arg, ignoreFlag)) {
                            foundMatch = true;
                            break;
                        }
                    }
                }
                if (!foundMatch) {
                    errorf("unrecognized command line option ‘{}’", arg);
                    return 1;
                }
            }
            //std.debug.warn("here\n");
        }
    }
    if (zigCmd.cSources.len == 0 and zigCmd.inputFiles.len == 0) {
        fatalErrorf("no input files");
        return 1;
    }

    if (zigCmd.link) {
        zigCmd.name = if (outfile) |outfile_s| outfile_s else "a.out";
    } else {
        if (outfile) |outfile_s| {
            if (!std.mem.endsWith(u8, outfile_s, ".o")) {
                errorf("output file must end with '.o' when using '-c'");
                return 1;
            }
            zigCmd.name = outfile_s[0..outfile_s.len - 2];
        }
    }

    var envMap = try std.process.getEnvMap(allocator);

    // If CC is set to this executable, then we want to remove it because
    // we don't want zig to use it. Not sure if this is a right solution?
    // For now I'm just going to always remove it until I find a case where
    // it should remain.
    envMap.delete("CC");

    if (extraCCArgs.len == 0) {
        var zigArgs = ArrayList([]const u8).init(allocator);
        try zigArgs.append(zigExe);
        try zigCmd.appendArgs(&zigArgs);
        if (showZigCmd)
            printArgs(zigArgs.toSlice());
        try std.os.execve(allocator, zigArgs.toSlice(), &envMap);
        return 0;
    }

    // Run the zig command to retreive all the arguments to "zig cc"
    {
        var zigArgs = ArrayList([]const u8).init(allocator);
        try zigArgs.append(zigExe);
        const saveName = zigCmd.name;
        defer zigCmd.name = saveName;
        zigCmd.name = "/dev/null";
        try zigCmd.appendArgs(&zigArgs);
        try zigArgs.append("--verbose-cc");
        if (showZigCmd)
            printArgs(zigArgs.toSlice());
        // TODO: run and get output, not execve
        try std.os.execve(allocator, zigArgs.toSlice(), &envMap);
    }
    // TODO: add --verbose-cc
    // TODO: add --dry-run
    // TODO: disable cache so we always run the CC commands

    errorf("extraCCArgs not implemented");
    return 1;
}
