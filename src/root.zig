//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
pub const c = @import("mruby_h.zig");

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
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
