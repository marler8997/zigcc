const std = @import("std");

pub fn main() anyerror!u8 {
    var args = try std.process.argsAlloc(std.heap.direct_allocator);
    //for (args) |arg, i| {
    //    std.debug.warn("arg[{}] '{}'\n", i, arg);
    //}
    std.debug.warn("Error: zigclang not implemented\n");
    return 1;
}
