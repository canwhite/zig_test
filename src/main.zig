const std = @import("std");
// const c = @cImport(@cInclude("stdio.h"));
const c = @cImport({
    //_NO_CRT_STDIO_INLINE
    //定义为 "1" 时，它将禁止CRT将某些标准输入/输出函数实现为内联函数
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    //引入c的标准库和三方库
    @cInclude("stdio.h");
    @cInclude("curl/curl.h");
});
//引入本地文件，直接
// const sld = @import("./sdl.zig");
const utils = @import("./utils/index.zig");

// 直接将print提出来
const print = std.debug.print;
const ArrayList = std.ArrayList;
// 内存分配器
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

//使用两种非同步手段，无锁数据结构和compare and swap
// const Atomic = std.atomic.Atomic(usize);
const Thread = std.Thread;
const Mutex = std.Thread.Mutex;

var counter = std.atomic.Atomic(usize).init(5);

//https://zigcc.github.io/zig-course/basic/advanced_type/struct.html
const Circle = struct {
    radius: u8,
    const PI: f16 = 3.14;
    pub fn init(radius: u8) Circle {
        //.{ .field = value} 这种算作是匿名结构体的初始化
        return Circle{ .radius = radius };
    }
    fn area(self: *Circle) f16 {
        return @as(f16, @floatFromInt(self.radius * self.radius)) * PI;
    }
};

//self
//注意这只是定义，need to init
const User = struct {
    const Self = @This();
    userName: []const u8,
    pub fn init(userName: []const u8) User {
        return User{
            .userName = userName,
        };
    }
    pub fn print(self: Self) void {
        //这里的.{}是创建数组和对象的字面量方法
        //字符串的输出可以直接用s
        std.debug.print("Hello, world! {s}\n", .{self.userName});
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

fn func3() u32 {
    return 5;
}

// while (condition) : (increment or mutation) {
//     body
// }
fn workerFn() void {
    var i: i32 = 0;
    while (i < 100000) : (i += 1) {
        _ = counter.fetchAdd(1, .Monotonic);
    }
}

//这里的!不是取反，而是一个类型说明符前缀，表示返回值不会为null
pub fn main() !void {

    //.{}一般用于字面量创建数组和结构体， .. 是区间，...是省略的意思，表示拓展符

    //变量和基本数据类型
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

    //TODO: 增加一些堆string的补充
    //定义和使用的时候注意const和非const的区别 [] const u8, [] u8
    //PS: 这里补充下

    //数组，动态数组，对象，数组对象

    //1）一般数组
    var message = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
    for (message, 0..) |val, index| {
        std.debug.print("{d}:{c}\n", .{ index, val });
    }
    //切片-当然下边这种事静态切片，不能更改
    var msg: []u8 = message[0..3];
    print("--message--{any} \n", .{msg});

    // 动态数组，不过下边这种已经被淘汰了，新版本的基本上都是ArrayList
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = &arena.allocator;
    // var message = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
    // var msg = try allocator.dupe(u8, message[0..3]);
    // defer allocator.free(msg);
    // try msg.append('a');
    // try msg.append('b');

    //2）动态数组
    // A）ArrayList是标准库里边给的创建动态数据的方式, 算是上述动态数组的简化版
    //参数是类型，init后边根的std里的heap，heap是许多的意，后边的属性是页面分配器
    //heap -堆，allocator-分配器
    var gpaList = ArrayList(f32).init(std.heap.page_allocator);
    //defer 关键字用于确保即使在函数早期退出时（例如，通过返回或错误），也可以执行某些必要的清理操作。在这个例子中，
    defer gpaList.deinit();
    //try 关键字用于处理可能会返回错误的函数或者操作
    try gpaList.append(4.0);
    try gpaList.append(3.5);
    try gpaList.append(1.0);
    for (gpaList.items) |gpaItem| {
        print("{}\n", .{gpaItem});
    }

    //3）对象
    const radius: u8 = 5;
    var circle = Circle.init(radius);
    print("The area of a circle with radius {} is {d:.2}\n", .{ radius, circle.area() });

    //字面量创建.{name = "xxx"}
    //这个也可以说是匿名结构体，当然.{}也可以用来创建数组

    const name = "xiaoming";
    var tt: User = User.init(name);
    tt.print();

    //3-1）看下官方的HashMap

    //使用动态内存分配器，arena 分出一块儿竞技场
    //std.heap.ArenaAllocator 是一个内存池分配器，它会预先分配一大块内存，然后按需分割和分配给请求的内存。
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // //这个test_allocator 可以放入下边的init，直接使用std.heap.page_allocator初始化和上述ArrayList保持一致
    // const test_allocator = arena.allocator();
    const Point = struct { x: i32, y: i32 };

    // var map = std.AutoHashMap(u32, Point).init(test_allocator);
    // std.heap.page_allocator 创建一个哈希表时，你实际上是要求操作系统按需分配页内存给这个哈希表，通常每页4kb
    var map = std.AutoHashMap(u32, Point).init(std.heap.page_allocator);
    defer map.deinit();

    try map.put(1525, .{ .x = 1, .y = -4 });
    try map.put(1550, .{ .x = 2, .y = -3 });
    try map.put(1575, .{ .x = 3, .y = -2 });
    try map.put(1600, .{ .x = 4, .y = -1 });

    print("map count : {} \n", .{map.count()});
    var sum = Point{ .x = 0, .y = 0 };
    //数组可以这样搞
    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        sum.x += entry.value_ptr.x;
        sum.y += entry.value_ptr.y;
    }
    print("--sum--{} \n", .{sum});

    //4）TODO:对象数组，我们来操作
    var list = ArrayList(Point).init(std.heap.page_allocator);
    defer list.deinit();
    //往里边添加东西
    try list.append(.{ .x = 1, .y = -4 });
    try list.append(.{ .x = 2, .y = -3 });
    std.debug.print("list的长度: {} \n", .{list.items.len});

    //TODO: 指针以及和C合作使用c的异步，但是我仿佛看到zig本身就有Threads

    //zig的异步转同步还不太完善，我们可以先用C的

    //基础指针：导入的C语言类型，如 c_int, c_char, c_float 等
    // io
    print("All your {s} are belong to us.\n", .{"codebase"});
    // 引入c的输出
    _ = c.printf("hello  world \n");

    const x: c_int = 10;
    print("x {} \n", .{x});

    //引入三方C包
    var curl = c.curl_easy_init();
    // 你可以开始使用curl库了
    print("curl  {any} \n", .{curl});

    //引入自己写的zig工具
    const a = 32;
    const result = utils.addFortyTwo(a);
    utils.log(result);

    //PASS , 条件语句和其他语言一样

    //TODO: 线程
    //Thread
    //1) 使用非同步锁，无锁数据结构
    //这种算是先给空间，然后再想着使用

    var thread_handles: [10]Thread = undefined;
    // 启动10个工作线程
    //|*handle|使我们能直接修改thread_handles数组内的指定元素，
    //而不仅仅是在循环体内部作用域中修改元素的一个副本
    //1.修改数据和共享数据的时候用指针呀
    for (thread_handles[0..]) |*handle| {
        //spawn 引发，大量生辰，这种促使值增加和变化的，都需要加上try
        const thread = try Thread.spawn(.{}, workerFn, .{});
        //给分配的thread赋值
        handle.* = thread;
    }
    // 等待所有工作线程完成
    for (thread_handles[0..]) |handle| {
        handle.join();
    }
    std.debug.print("共享计数器的最终值: {}\n", .{counter});

    //2）使用同步锁互斥锁

    //针对Thread操作要熟悉这种通过提供一个struct给值和方法的方式进行线程操作
    const NonAtomicCounter = struct {
        const Self = @This();
        value: [2]u64 = .{ 0, 0 },
        //get
        fn get(self: Self) u128 {
            //@as-会将value值转化为type类型，
            //@bitCast-运算符会将 value 的值转换为其位表示形式。
            // 转换后的值将具有与 value 相同的大小和字节顺序
            return @as(u128, @bitCast(self.value));
        }
        //add
        fn inc(self: *Self) void {
            //这种常规for循环的方法，
            //拿到一个数组，通过0.. 做step，然后 |vaule,index| 来拿细节操作
            for (@as([2]u64, @bitCast(self.get() + 1)), 0..) |v, i| {
                @as(*volatile u64, @ptrCast(&self.value[i])).* = v;
            }
        }
    };

    const num_threads = 4;
    const num_increments = 1000;
    const Runner = struct {
        mutex: Mutex = .{},
        thread: Thread = undefined,
        counter: NonAtomicCounter = .{},

        //此方法要提供给线程使用
        fn run(self: *@This()) void {
            var i: usize = num_increments;
            while (i > 0) : (i -= 1) {
                self.mutex.lock();
                defer self.mutex.unlock();
                self.counter.inc();
            }
        }
    };
    //[_]Runner{.{}}表示一个未指定长度的Runner结构体类型的数组
    //然后长度从后边给出，这是一个创建对象数组的方法
    var runners = [_]Runner{.{}} ** num_threads;
    //在这个例子中的 for(&array) |*e| e.xxx，e 是数组中元素的实例。
    //这段代码通过 &array 获取了数组的引用，并通过 |*e| 遍历后，解引用得到了数组元素的实例。
    for (&runners) |*r| r.thread = try Thread.spawn(.{}, Runner.run, .{r});
    //因为用实例赋过值了，所以这里可以直接使用
    for (runners) |r| r.thread.join();

    //TODO：async/sync

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
