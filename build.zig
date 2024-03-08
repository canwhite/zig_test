const std = @import("std");

// 虽然这个函数看起来是命令式的，
// 但请注意，其工作是声明性地构建一个由外部执行器执行的构建图。
// Although this function looks imperative,
// note that its job is to declaratively construct a build graph that will be executed by an external runner.
pub fn build(b: *std.Build) void {

    // 标准目标选项允许运行 zig build 的人选择要构建的目标。
    // 在这里，我们并未改写默认配置，即允许任何目标，而默认目标是原生的。
    // 还有其他选项可以限制支持的目标集。
    // Standard target options allows the person running zig build to choose what target to build for.
    // Here we do not override the defaults, which means any target is allowed, and the default is native.
    // Other options for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // 标准优化选项允许运行 zig build 的人在Debug、ReleaseSafe、ReleaseFast和ReleaseSmall之间进行选择。
    // 在这里，我们并未设置优选的发布模式，
    // 由用户决定如何进行优化。
    // Standard optimization options allow the person running zig build to select between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    // Here we do not set a preferred release mode,
    // allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig_test",
        // 在这种情况下，主源文件仅仅是一个路径，
        // 然而，在更复杂的构建脚本中，这可能是一个生成的文件。
        // In this case the main source file is merely a path,
        // however, in more complicated build scripts, this could be a generated file.
        //TODO,如果是一组东西，自写的东西或者一些三方包这里要如何处理呢
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // 这声明了当用户调用 "install" 步骤时（默认步骤为运行 zig build），
    // 生成的可执行程序将被安装到标准位置的意图。
    // This declares intent for the executable to be installed into the standard location
    // when the user invokes the "install" step (the default step when running zig build).
    b.installArtifact(exe);

    // 这里 创建 了一个在构建图中的“Run”步骤，该步骤将在评估依赖于它的另一步骤时执行。
    // 下面的下一行将建立这样的依赖关系。
    // This creates a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.

    // PS：这个run步骤，需要有run命令才会触发
    const run_cmd = b.addRunArtifact(exe);

    // 通过使运行步骤依赖于安装步骤，它将从安装目录中运行，而不是直接从缓存目录中运行。
    // 然而，如果应用程序依赖于其他已安装的文件，这并不是必需的，这确保它们将存在并在预期的位置。
    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.

    run_cmd.step.dependOn(b.getInstallStep());

    // 这允许用户在构建命令中直接传递参数给应用程序，比如这样：zig build run -- arg1 arg2 等
    // This allows the user to pass arguments to the application in the build
    // command itself, like this: zig build run -- arg1 arg2 etc
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
