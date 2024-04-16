const std = @import("std");
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});
const main = @import("main.zig").main;

const Chameleon = @import("deps/chameleon/chameleon.zig").Chameleon;

pub fn handleSigInt(n: c_int) callconv(.C) void {
    _ = n;

    comptime var cham = Chameleon.init(.Auto);
    std.debug.print(cham.dim().fmt("\n(hint: use .exit or CTRL+D to quit)"), .{});

    std.process.exit(0);
}

pub fn eql(cmd: []const u8, formatted: []const u8, alloc: std.mem.Allocator) !bool {
    const cmd_win = try std.fmt.allocPrint(alloc, "\n{s}", .{cmd});
    const equal = std.mem.eql(u8, formatted, cmd_win);
    const equal2 = std.mem.eql(u8, formatted, cmd);
    if (equal) {
        return true;
    } else if (equal2) {
        return true;
    } else return false;
}

pub fn getDelimiter() u8 {
    switch (os()) {
        .windows => {
            return '\r';
        },
        .linux => {
            return '\n';
        },
        else => return '\n',
    }
}

pub const OS = enum { linux, windows, unsupported };

pub fn os() OS {
    const win32 = @hasDecl(c, "__WIN32__");
    const win32x = @hasDecl(c, "__NT__");
    const win = @hasDecl(c, "WIN32");
    const winy = @hasDecl(c, "_WIN32");

    const linux = @hasDecl(c, "__linux__");

    if (win or win32x or win32 or winy) {
        return OS.windows;
    } else if (linux) {
        return OS.linux;
    } else return OS.unsupported;
}

pub fn clearConsole() anyerror!void {
    {
        const win32 = @hasDecl(c, "__WIN32__");
        const win32x = @hasDecl(c, "__NT__");
        const win = @hasDecl(c, "WIN32");
        const winy = @hasDecl(c, "_WIN32");

        const linux = @hasDecl(c, "__linux__");

        if (win32 or win32x or win or winy) {
            _ = c.system("cls");
        } else if (linux) {
            _ = c.system("clear");
        } else return error.Unsupported;
    }
}
