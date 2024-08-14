const std = @import("std");

pub fn main() !void {
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
