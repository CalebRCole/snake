const std = @import("std");
const c = @cImport({
    @cInclude("curses.h");
});

const width = 30;
const height = 30;
const frame_rate = 10;
const ms_frame_rate = std.time.ms_per_s / frame_rate;

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

const Pos = struct {
    x: u8,
    y: u8,
};

const RingBuffer = struct {
    data: [width * height]Pos = undefined,
    head: usize = 0,
    tail: usize = 0,
    len: usize = 0,

    pub fn push(self: *RingBuffer, pos: Pos) void {
        self.head = (self.head + 1) % self.data.len;
        self.data[self.head] = pos;
        self.len += 1;
    }

    pub fn pop(self: *RingBuffer) void {
        self.tail = (self.tail + 1) % self.data.len;
        self.len -= 1;
    }
};

const GridMatrix = struct {
    bitset: std.StaticBitSet(width * height) = std.StaticBitSet(width * height).initEmpty(),

    inline fn getIndex(x: usize, y: usize) usize {
        return y * width + x;
    }

    pub fn set(self: *GridMatrix, x: usize, y: usize) void {
        self.bitset.set(getIndex(x, y));
    }

    pub fn unset(self: *GridMatrix, x: usize, y: usize) void {
        self.bitset.unset(getIndex(x, y));
    }

    pub fn occupied(self: *GridMatrix, x: usize, y: usize) bool {
        return self.bitset.isSet(getIndex(x, y));
    }
};

pub fn main(init: std.process.Init) !void {
    // Setup
    var score: u32 = 0;
    defer std.debug.print("Game Over!\nYour score was: {d}!\n", .{score});
    
    const io = init.io;

    const seed = std.Io.Timestamp.now(io, std.Io.Clock.real);
    var prng = std.Random.DefaultPrng.init(@intCast(seed.nanoseconds));
    const rand = prng.random();

    if (!c.isendwin()) _ = c.endwin();
    
    _ = c.initscr();
    defer _ = c.endwin();

    _ = c.cbreak();
    _ = c.noecho();
    _ = c.keypad(c.stdscr, true);
    _ = c.nodelay(c.stdscr, true); // getch() is non-blocking
    _ = c.curs_set(0); // Hide cursor (0 = invisible, 1 = normal, 2 = high visibility)

    const snake: Pos = .{ .x = width / 2, .y = height / 2 };
    const neck: Pos = .{ .x = width / 2 - 1, .y = height / 2 };
    var buffer = RingBuffer{};
    buffer.push(neck);
    buffer.push(snake);
    buffer.tail = 1;

    try mvprintw(snake.y, snake.x, "()", .{});
    try mvprintw(neck.y, neck.x, "<>", .{});

    var grid = GridMatrix{};
    grid.set(snake.x, snake.y);
    grid.set(neck.x, neck.y);

    var dirty_direction: ?Direction = .right;
    var sanitized_direction: Direction = .right;

    var food = Pos{
        .x = rand.intRangeAtMost(u8, 1, width - 2),
        .y = rand.intRangeAtMost(u8, 1, height - 2),
    };
    try mvprintw(food.y, food.x, "[]", .{});

    // Sets the walls and score text
    for (0..width) |x| {
        for (0..height) |y| {
            if (x == width - 1 or x == 0 or y == height - 1 or y == 0) {
                try mvprintw(y, x, "##", .{});
                grid.set(x, y);
            }
        }
    }

    try mvprintw(height / 2, width + 2, "Score = {d}", .{score});

    // Logic
    while (true) {
        const input = c.getch();
        if (input != c.ERR and Direction.fromKey(input) != null) dirty_direction = Direction.fromKey(input);
        if (dirty_direction.? != sanitized_direction and !dirty_direction.?.isOpposite(sanitized_direction)) sanitized_direction = dirty_direction.?;
        _ = c.flushinp();

        if (move(sanitized_direction, &buffer, &grid, food) catch |err| {
	    if (food.x == 0 and food.y == 0) return err else break;
        }) {
            food = spawnFood(rand, &grid);
            score += 1;

            try mvprintw(food.y, food.x, "[]", .{});
            try mvprintw(height / 2, width + 2, "Score = {d}", .{score});
        }

        _ = c.refresh();
        try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(ms_frame_rate), std.Io.Clock.awake);
    }
}

// Sanitizes ncurses' mvprintw, turning any integer into a c_int as well as
// doubling x, giving a 1:1 aspect ratio during rendering.
// 'msg' is printed while 'args' are for Zig string formatting.
pub fn mvprintw(y: anytype, x: anytype, comptime msg: []const u8, args: anytype) !void {
    const c_y: c_int = @intCast(y);
    const c_x: c_int = @intCast(2 * x);

    var buffer: [64]u8 = undefined;
    const formatted = try std.fmt.bufPrintZ(&buffer, msg, args);

    const status = c.mvprintw(c_y, c_x, formatted.ptr);
    if (status == c.ERR) return error.MvPrintWFailed;
}

// Returns boolean based on if food was eaten.
pub fn move(dir: Direction, buffer: *RingBuffer, grid: *GridMatrix, food: Pos) !bool {
    const old_head = buffer.data[buffer.head];
    try mvprintw(old_head.y, old_head.x, "<>", .{});

    const new_head: Pos = switch (dir) {
        .up => .{ .x = old_head.x, .y = old_head.y - 1 },
        .down => .{ .x = old_head.x, .y = old_head.y + 1 },
        .left => .{ .x = old_head.x - 1, .y = old_head.y },
        .right => .{ .x = old_head.x + 1, .y = old_head.y },
    };

    try mvprintw(new_head.y, new_head.x, "()", .{});

    if (new_head.x == food.x and new_head.y == food.y) {
	if (grid.occupied(new_head.x, new_head.y)) return error.GameOver;
	
	buffer.push(new_head);
	grid.set(new_head.x, new_head.y);
        return true;
    } else {
        const tail = buffer.data[buffer.tail];
        try mvprintw(tail.y, tail.x, "  ", .{});
        grid.unset(tail.x, tail.y);
        buffer.pop();

	if (grid.occupied(new_head.x, new_head.y)) return error.GameOver;

	buffer.push(new_head);
	grid.set(new_head.x, new_head.y);

        return false;
    }
}

pub fn spawnFood(rand: std.Random, grid: *GridMatrix) Pos {
    while (true) {
	const food = Pos{
	    .x = rand.intRangeAtMost(u8, 1, width - 2),
            .y = rand.intRangeAtMost(u8, 1, height - 2),
	};
	if (!grid.occupied(food.x, food.y)) return food;
    }
}
