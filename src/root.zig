//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
pub const c = @import("mruby_h.zig");

export var edata: u8 = 0;
export var end: u8 = 0;
export var etext: u8 = 0;

pub fn bufferedPrint() !void {
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try stdout.flush(); // Don't forget to flush!
}

export fn zig_ping(mrb: ?*c.mrb_state, self:c.mrb_value) c.mrb_value {
    _ = self;

    var str: c.mrb_value = undefined;
    _ = c.mrb_get_args(mrb, "S", &str);

    const cstr = c.mrb_str_to_cstr(mrb, str);
    const bytes: []const u8 = std.mem.span(cstr);
    std.debug.print("ip: {s}\n", .{bytes});

    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var body = std.Io.Writer.Allocating.init(allocator);
    const bodywriter: *std.Io.Writer = &body.writer;
    defer body.deinit();

    if (std.Uri.parse(bytes)) |uri| {
        var client = std.http.Client{ .allocator = allocator };
        defer client.deinit();

        if (client.fetch(.{ 
            .method = .GET,
            .location = .{ .uri = uri },
            .response_writer = bodywriter,
        })) |response| {
            std.debug.print("got code {}\n", .{response.status});
            if (response.status != .ok) {
//                @panic("oh no...");
            } else {
//                std.debug.print("{s}\n", .{body.written()});
                return c.mrb_true_value();
            }
        } else |_| {
            std.debug.print("Fetch URI error: {s}\n", .{bytes});
        }
    } else |_| {
        std.debug.print("Parse URI error: {s}\n", .{bytes});
    }
    return c.mrb_false_value();
}

export fn zig_add(mrb: ?*c.mrb_state, self:c.mrb_value) c.mrb_value {
    _ = self;
    var a: c.mrb_int = 0;
    var b: c.mrb_int = 0;

    _ = c.mrb_get_args(mrb, "ii", &a, &b);
    return c.mrb_fixnum_value(a+b);
}

pub fn registerFunctions(mrb: *c.mrb_state) void {
    const kernel = mrb.kernel_module;
    c.mrb_define_method(
        mrb,
        kernel,
        "zig_add",
        zig_add,
        c.MRB_ARGS_REQ(2),
    );
    c.mrb_define_method(
        mrb,
        kernel,
        "zig_ping",
        zig_ping,
        c.MRB_ARGS_REQ(1),
    );
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
