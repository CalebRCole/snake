const std = @import("std");
const c = @import("c");

const stderr = std.Io.File.stderr();

const width = 30;
const height = 30;
const area = width * height;
const frame_rate = std.time.ms_per_s / 10;
const score_pos: Pos = .{ .x = width * 2 + 10, .y = height / 2 };

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const seed = std.Io.Timestamp.now(io, .real);
    var prng = std.Random.DefaultPrng.init(@intCast(seed.toMicroseconds()));
    const rand = prng.random();

    defer std.debug.print("Finished!\n", .{});

    const stdscr: *c.WINDOW = c.initscr() orelse {
        try stderr.writeStreamingAll(io, "ERROR: initscr failed to return a window pointer!\n");
        return error.NcursesError;
    };
    
    defer {
        call(io, "endwin", c.endwin, .{}) catch {
            stderr.writeStreamingAll(io, "ERROR: endwin returned value ERR!\n") catch {};
        };
    }

    try call(io, "cbreak", c.cbreak, .{});
    try call(io, "noecho", c.noecho, .{});
    try call(io, "keypad", c.keypad, .{ stdscr, true});
    try call(io, "nodelay", c.nodelay, .{ stdscr, true });
    try call(io, "curs_set", c.curs_set, .{ @backingInt(Visibility.invisible) });

    var grid: Grid = .{};
    var snake: RingBuffer = .{};
    
    try createWalls(&grid);
    try mvprintw(height / 2, width * 2 + 2, "Score = ");
    var score: usize = 0;
    
    var head: Pos = .{ .x = width / 2, .y = height / 2 };
    snake.push(head);

    try mvprintw(head.y, head.x * 2, "()");
    grid.set(head.x, head.y);

    var fruit: Pos = try generateFruit(rand, &grid);
    grid.set(fruit.x, fruit.y);
    
    var dir: Direction = .up;
    var score_buf: [area:0]u8 = undefined;

    _ = c.refresh();
    while (true) {
        const new_dir = Direction.fromKey(c.getch()) orelse dir;
        if (!dir.isOpposite(new_dir)) dir = new_dir;
        
        try call(io, "flushinp", c.flushinp, .{});
        
        var new_head = head;
        switch (dir) {
            .up => new_head.y -= 1,
            .down => new_head.y += 1,
            .left => new_head.x -= 1,
            .right => new_head.x += 1,
        }

        try mvprintw(head.y, head.x * 2, "<>");
        if (std.meta.eql(fruit, new_head)) {
            head = new_head;
            snake.push(new_head);
            
            score += 1;
            const foo = try std.mem.print(&score_buf, "{}", .{score});
            var bar: [area:0]u8 = undefined;
            @memcpy(bar[0..foo.len], foo);
            bar[foo.len] = 0;
            try mvprintw(score_pos.y, score_pos.x, &bar);
            
            fruit = try generateFruit(rand, &grid);
        } else if (grid.isOccupied(new_head.x, new_head.y)) {
            break;
        } else {
            const tail: Pos = snake.buffer[snake.tail];
            grid.unset(tail.x, tail.y);
            try mvprintw(tail.y, tail.x * 2, "  ");

            head = new_head;
            snake.pop();
            snake.push(new_head);
            grid.set(new_head.x, new_head.y);
        }
        try mvprintw(new_head.y, new_head.x * 2, "()");

        _ = c.refresh();
        try std.Io.sleep(io, .fromMilliseconds(frame_rate), .awake);
    }
}

const Pos = struct {
    x: u32,
    y: u32,
};

// Bitset that represents an occupied coordinate.
const Grid = struct {
    const Self = @This();
    bitset: std.StaticBitSet(area) = .empty,

    inline fn getIndex(x: usize, y: usize) usize {
        return y * width + x;
    }

    pub fn set(self: *Self, x: usize, y: usize) void {
        self.bitset.set(getIndex(x, y));
    }

    pub fn unset(self: *Self, x: usize, y: usize) void {
        self.bitset.unset(getIndex(x, y));
    }

    // Wrapper of 'bitset.isSet' to use xy coordinates.
    pub fn isOccupied(self: *Self, x: usize, y: usize) bool {
        return self.bitset.isSet(getIndex(x, y));
    }
};

// Ring buffer that represents the snake.
const RingBuffer = struct {
    const Self = @This();
    buffer: [area]Pos = @splat(.{ .x = 0, .y = 0 }),
    head: usize = 0,
    tail: usize = 0,
    len: usize = 0,

    pub fn push(self: *Self, pos: Pos) void {
        self.buffer[self.head] = pos;
        self.head = (self.head + 1) % self.buffer.len;
        self.len += 1;
    }

    pub fn pop(self: *Self) void {
        self.tail = (self.tail + 1) % self.buffer.len;
        self.len -= 1;
    }    
};

const Visibility = enum(c_int) {
    invisible,
    visible,
    very_visible,
};

const Direction = enum(u2) {
    up,
    left,
    down,
    right,

    pub fn fromKey(key: c_int) ?Direction {
        return switch (key) {
            'w', 'W', c.KEY_UP => .up,
            'a', 'A', c.KEY_LEFT => .left,
            's', 'S', c.KEY_DOWN => .down,
            'd', 'D', c.KEY_RIGHT => .right,
            else => null,
        };
    }

    pub fn isOpposite(self: Direction, other: Direction) bool {
        return switch (self) {
            .up => other == .down,
            .down => other == .up,
            .left => other == .right,
            .right => other == .left,
        };
    }
};


// Helper to use ncurses functions a possible ERR return value returning
// explicit Zig errors rather than having to check each function directly.
// This should only be used for functions that perform side-effects rather than returning values.
fn call(io: std.Io, func_name: []const u8, comptime func: anytype, args: std.meta.ArgsTuple(@TypeOf(func))) !void {
    const return_value: c_int = @call(.auto, func, args);
    if (return_value == c.ERR) {
        var buf: [4096]u8 = undefined;
        const message = try std.mem.print(&buf, "ERROR: {s} returned value ERR!\n", .{func_name});
        try stderr.writeStreamingAll(io, message);
        return error.NcursesError;
    }
}

// In terminal prints the boundary walls with the '#' character.
// User must set terminal settings before calling function.
fn createWalls(grid: *Grid) !void {
    for (0..width) |x| {
        for (0..height) |y| {
            if (x == width - 1 or x == 0 or y == height - 1 or y == 0) {
                try mvprintw(@intCast(y), @intCast(x * 2), "##");
                grid.set(x,y);
            }
        }
    }
}

// Safety-checked wrapper around mvprintw.
// The original variadic function is not supported by std.meta.ArgsTuple.
// This version provides a simple interface.
fn mvprintw(y: u32, x: u32, msg: []const u8) !void {
    const status = c.mvprintw(@intCast(y), @intCast(x), msg.ptr);
    if (status == c.ERR) return error.MvprintwFailed;
}

fn generateFruit(rand: std.Random, grid: *Grid) !Pos { 
    return while (true) {
        const fruit: Pos = .{
            .x = rand.intRangeAtMost(u32, 1, width - 2),
            .y = rand.intRangeAtMost(u32, 1, height - 2),
        };

        if (!grid.isOccupied(fruit.x, fruit.y)) {
            try mvprintw(fruit.y, fruit.x * 2, "[]");
            break fruit;
        }
    };
}
