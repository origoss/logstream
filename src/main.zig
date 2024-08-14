const std = @import("std");

fn abort(_: i32) callconv(.C) void {
    std.log.warn("aborting", .{});
    std.posix.abort();
}

pub fn main() !void {
    try std.posix.sigaction(std.posix.SIG.INT, &.{
        .handler = .{
            .handler = abort,
        },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    }, null);
    var i: u64 = 0;
    var env: [:0]const u8 = "undefined";
    if (std.posix.getenv("ENVIRONMENT")) |envValue| {
        env = envValue;
    }
    while (true) {
        std.log.info("#{[i]d} log message in {[env]s}", .{
            .i = i,
            .env = env,
        });
        std.time.sleep(1 * std.time.ns_per_s);
        i += 1;
    }
}
