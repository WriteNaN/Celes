const std = @import("std");
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("signal.h");
});
const utils = @import("utils.zig");
const Target = std.Target;

const Chameleon = @import("deps/chameleon/chameleon.zig").Chameleon;

const print = std.debug.print;
const fs = std.fs;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    comptime var cham = Chameleon.init(.Auto);

    const SEMVER_CELES_VERSION = cham.bold().cyanBright().fmt("v1.0.0");
    const REPL = cham.gray().fmt("REPL");

    const args = try std.process.argsAlloc(allocator);

    if (args.len > 1) {
        const file = fs.cwd().openFile(args[1], .{ .mode = .read_only }) catch |err| {
            print(cham.redBright().fmt("Failed to open file: \"{s}\",\nError: {any}\n"), .{ args[1], err });
            std.process.exit(1);
        };

        while (true) {
            const content = try file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 5e6);
            if (content != null) {
                print("{s}\n", .{content.?});
            } else break;
        }
    } else {
        _ = utils.clearConsole() catch print(cham.red().fmt("OS not supported\n"), .{});

        const stdin = std.io.getStdIn().reader();

        //print(cham.redBright().fmt("No file to execute provided!\n"), .{});
        const CELES = cham.underline().blue().fmt("CELES");
        print(cham.italic().whiteBright().fmt("Welcome to {s} {s} {s}\n"), .{ CELES, SEMVER_CELES_VERSION, REPL });
        print(cham.cyanBright().fmt("Type \".help\" for more information.\n"), .{});
        print("> ", .{});

        _ = c.signal(c.SIGINT, utils.handleSigInt);

        const maxBytes = 69;

        var buf: [maxBytes]u8 = undefined;

        const delimiter = utils.getDelimiter();

        while (true) {
            const input = stdin.readUntilDelimiter(buf[0..], delimiter) catch |err| {
                switch (err) {
                    std.io.AnyReader.Error.StreamTooLong => {
                        print("{s}{s}", .{ try std.fmt.allocPrint(allocator, cham.red().fmt("Exceeded allocated memory: max [{}] bytes expected\n"), .{maxBytes}), cham.dim().fmt("try running a file to execute a bigger script.\n") });
                    },
                    std.io.AnyReader.Error.EndOfStream => {
                        print(cham.red().fmt("\nEOS, process killed.\n"), .{});
                    },
                    else => {
                        print(cham.red().fmt("Unexpected Error: {any}\n"), .{err});
                    },
                }
                std.process.exit(1);
            };

            const formatted = try std.fmt.allocPrint(allocator, "{?s}", .{input});

            if (utils.eql(".help", formatted, allocator) catch {
                print(cham.red().fmt("Out of memory \n"), .{});
                std.process.exit(1);
            }) {
                print(cham.magentaBright().fmt(".help"), .{});
                print(cham.whiteBright().fmt("    Shows you this command\n"), .{});
                print(cham.magentaBright().fmt(".clear"), .{});
                print(cham.whiteBright().fmt("   Clears entered commands\n"), .{});
                print(cham.magentaBright().fmt(".exit"), .{});
                print(cham.whiteBright().fmt("    Exit the program\n"), .{});
                print(cham.magentaBright().fmt(".load"), .{});
                print(cham.whiteBright().fmt("    Load CELES script from a file\n\n"), .{});
                print(cham.dim().blueBright().italic().fmt("Warning: This language is currently in it's alpha phase and might not be suitable for production\n"), .{});
            } else if (utils.eql(".exit", formatted, allocator) catch {
                print(cham.red().fmt("Out of memory \n"), .{});
                std.process.exit(1);
            }) {
                std.process.exit(0);
            } else if (utils.eql(".clear", formatted, allocator) catch {
                print(cham.red().fmt("Out of memory \n"), .{});
                std.process.exit(1);
            }) {
                _ = utils.clearConsole() catch print(cham.red().fmt("OS not supported\n"), .{});
                print(cham.italic().whiteBright().fmt("Welcome to {s} {s} {s}\n"), .{ CELES, SEMVER_CELES_VERSION, REPL });
                print(cham.cyanBright().fmt("Type \".help\" for more information.\n"), .{});
            } else if (utils.eql(".load", formatted, allocator) catch {
                print(cham.red().fmt("Out of memory \n"), .{});
                std.process.exit(1);
            }) {
                 print(cham.red().fmt("This command hasn\'t been fully implemented yet!\n"), .{});
            } else {
                print(cham.red().fmt("Failed executing unknown command \"{s}\"\n"), .{formatted});
            }
            print("> ", .{});
        }
    }
}
