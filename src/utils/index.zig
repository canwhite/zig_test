const std = @import("std");
const print = std.debug.print;

//zig如何在utils工具类中定义一个方法，可以输出任何输入值
// fn printAnything(comptime T: type, value: T) void {
//     std.debug.print("Value: {}\n", .{value});
// }

pub fn addFortyTwo(x: anytype) @TypeOf(x) {
    return x + 42;
}

pub fn log(x: anytype) void {
    print("{} \n", .{x});
}
