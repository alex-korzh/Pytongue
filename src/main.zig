const Server = @import("server/server.zig").Server;
const std = @import("std");
const logging = @import("utils/logging.zig");
const h = @import("server/handlers.zig");

pub const std_options = .{
    .logFn = logging.logMessageFn,
};

pub fn initEnv(allocator: std.mem.Allocator) !void {
    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    if (env_map.get("PYTONGUE_LOG")) |lfn| {
        logging.log_file_name = try allocator.dupe(u8, lfn);
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try initEnv(allocator);
    defer {
        if (logging.log_file_name) |lfn| {
            allocator.free(lfn);
        }
    }

    var server = Server{ .baseHandler = &h.baseHandler };
    try server.serve(allocator);
}
