const std = @import("std");
const mrubyOnZig = @import("mrubyOnZig");
const c = mrubyOnZig.c;

pub fn main() !void {
    const mrb = c.mrb_open();
    if (mrb) |m| {
        mrubyOnZig.registerFunctions(m);
        _ = c.mrb_load_irep(m, c.rb_main);

        block_test(m);

        monads_test(m);

        defer c.mrb_close(m);
    }
}

// MONADS TEST
const MValue = struct {
    value: c.mrb_value,

    fn apply(self: *MValue, func:*const fn (self:*MValue) *MValue) *MValue {
        return func(self);
    }
};

fn tap(self: *MValue) *MValue {
    return self;
}

fn plus_one(self: *MValue) *MValue {
    const v = c.mrb_fixnum(self.value);
    self.value = c.mrb_fixnum_value(v+1);
    return self;
}

fn monads_test(mrb: *c.mrb_state) void {
    var one:MValue = .{.value = c.mrb_fixnum_value(1)};
//    const result = one.tap().plus_one();
    const result = one.apply(tap).apply(plus_one);
    std.debug.print("=== Monads test ===\n", .{});
    _ = c.mrb_funcall(mrb, c.mrb_top_self(mrb), "puts", 1, result.value);
}

// BLOCK TEST
export fn proc_func(mrb: ?*c.mrb_state, self: c.mrb_value) c.mrb_value {
    _ = mrb;
    _ = self;
    return c.mrb_false_value();
}

fn block_test(mrb: *c.mrb_state) void {
    const pfunc = c.mrb_proc_new_cfunc(mrb, proc_func);
    const b = c.mrb_obj_value(pfunc);
    const result = c.mrb_yield(mrb, b, c.mrb_nil_value());
    std.debug.print("=== Block (Proc) test ===\n", .{});
    _ = c.mrb_funcall(mrb, c.mrb_top_self(mrb), "puts", 1, result);
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
