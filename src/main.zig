const std = @import("std");
// const c = @cImport(@cInclude("stdio.h"));
const c = @cImport({
    //_NO_CRT_STDIO_INLINE 定义为 "1" 时，它将禁止CRT将某些标准输入/输出函数实现为内联函数
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
});
// 直接将print提出来
const print = std.debug.print;
const ArrayList = std.ArrayList;

const Circle = struct {
    radius: u8,
    const PI: f16 = 3.14;
    pub fn init(radius: u8) Circle {
        //结构体初始化赋值需.赋值的
        return Circle{ .radius = radius };
    }
    fn area(self: *Circle) f16 {
        return @as(f16, @floatFromInt(self.radius * self.radius)) * PI;
    }
};

//和c做下对比吧

// typedef struct Rectangle {
//     float height;
//     float width;
// } Rectangle;

// float getArea(Rectangle* self) {
//     //return self->height * self->width;
//     //or
//     return (*self).height * (*self).width
// }

//这里的!不是取反，而是一个类型说明符前缀，表示返回值不会为null
pub fn main() !void {
    // io
    print("All your {s} are belong to us.\n", .{"codebase"});
    // 引入c的输出
    _ = c.printf("hello  world \n");

    //变量和基本数据类型
    //基础指针：导入的C语言类型，如 c_int, c_char, c_float 等
    const x: c_int = 10;
    print("x {} \n", .{x});

    var integer: i16 = 666;
    const ptr = &integer;
    ptr.* = ptr.* + 1;

    // Integer: i8, u8, i16, u16, i32, u32, i64, u64, isize, usize
    // Floating Point: f32, f64
    // Boolean: bool (取值为 true 或 false)
    // Char: u8 (用于表示单个 UTF-8 字节)
    // 字符串
    const str = "12344";
    const cha = 'a';
    const num = 123;
    const is = true;
    const f = 1.23;
    var un: u32 = undefined; //undefined如果要后续赋值，可以用var，但是要声明类型
    un = 100;
    // zig中导入的c语言类型如何用呢？

    //.{str}是把后续的值（即str）打包成一个数组传递给print函数
    print("data {s} \n", .{str});
    print("data {c}  \n", .{cha});
    print("data {d} \n", .{num});
    //bool和undefined不需要占位符, 这种也是通用输出格式
    print("data {}  \n", .{is});
    print("data {}  \n", .{f});

    //数组，动态数组，对象，数组对象

    //1）一般数组
    const message = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
    for (message, 0..) |val, index| {
        std.debug.print("{d}:{c}\n", .{ index, val });
    }

    //2）动态数组
    //参数是类型，init后边根的std里的heap，heap是许多的意，后边的属性是页面分配器
    var gpaList = ArrayList(f32).init(std.heap.page_allocator);
    //defer 关键字用于确保即使在函数早期退出时（例如，通过返回或错误），也可以执行某些必要的清理操作。在这个例子中，
    defer gpaList.deinit();
    //try 关键字用于处理可能会返回错误的函数或者操作
    try gpaList.append(4.0);
    try gpaList.append(3.5);
    try gpaList.append(1.0);
    for (gpaList.items) |gpa| {
        print("{}\n", .{gpa});
    }

    //3）对象
    const radius: u8 = 5;
    var circle = Circle.init(radius);
    print("The area of a circle with radius {} is {d:.2}\n", .{ radius, circle.area() });

    //4）数组对象

    //TODO，指针

    //条件语句和其他语言一样

    //TODO，异步转同步

    //TODO，引入三方包和自己的文件

    //TODO，和C合作

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
