const std = @import("std");

const nc = @cImport({
    @cInclude("curses.h");
});

pub fn mvprintw(y: anytype, x: anytype, comptime msg: []const u8, args: anytype) !void {
    const c_y: c_int = @intCast(y);
    const c_x: c_int = @intCast(2 * x);

    var buffer: [64]u8 = undefined;
    const formatted = try std.fmt.bufPrintZ(&buffer, msg, args);

    const status = nc.mvprintw(c_y, c_x, formatted.ptr);
    if (status == nc.ERR) return error.MvPrintWFailed;
}

const Direction = enum(u2) {
    left,
    down,
    up,
    right,

    pub fn fromKey(key: c_int) ?Direction {
        return switch (key) {
            'w', 'W', nc.KEY_UP => .up,
            'a', 'A', nc.KEY_LEFT => .left,
            's', 'S', nc.KEY_DOWN => .down,
            'd', 'D', nc.KEY_RIGHT => .right,
            else => null,
        };
    }
};

const width = 30;
const height = 30;
var score: u32 = 0;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    var prng = std.Random.DefaultPrng.init(255);
    const rand = prng.random();

    _ = nc.initscr();
    defer _ = nc.endwin();

    _ = nc.cbreak();
    _ = nc.noecho();
    _ = nc.keypad(nc.stdscr, true);
    _ = nc.nodelay(nc.stdscr, true); // getch() is non-blocking
    _ = nc.curs_set(0); // Hide cursor (0 = invisible, 1 = normal, 2 = high visibility)

    for (0..width) |x| {
        for (0..height) |y| {
            if (x == width - 1 or x == 0 or y == height - 1 or y == 0) {
                try mvprintw(y, x, "##", .{});
            }
        }
    }
    _ = nc.refresh();

    var snake: Head = .init(width / 2, height / 2);
    var neck: Segment = .{ .x = snake.x - 1, .y = snake.y };
    
    var body = std.DoublyLinkedList{ .first = &snake.node };
    body.insertAfter(&snake.node, &neck.node);

    var food = .{
        .x = rand.intRangeAtMost(u8, 1, width - 2),
        .y = rand.intRangeAtMost(u8, 1, height - 2),
    };
    try mvprintw(food.y, food.x, "[]", .{});

    var dir: ?Direction = .fromKey('d');
    while (true) {
        // Movement
        const input = nc.getch();
        if (input == 'p' or input == 'P') break;
        if (input != nc.ERR and Direction.fromKey(input) != null) dir = Direction.fromKey(input);
        _ = nc.flushinp();

        const old_x = snake.x;
        const old_y = snake.y;

        // Move returns true if we collided, meaning death.
        if (snake.move(dir.?)) {
            try mvprintw(height / 2 + 2, width + 2, "Game Over!", .{});
            _ = nc.refresh();

            try std.Io.sleep(io, std.Io.Duration.fromSeconds(3), std.Io.Clock.awake);
            break;
        }

        // Logic
        try mvprintw(height / 2, width + 2, "Score = {d}", .{score});
        try mvprintw(snake.y, snake.x, "()", .{});

        if (snake.x == food.x and snake.y == food.y) {
            score += 1;
            food.x = rand.intRangeAtMost(u8, 1, width - 2);
            food.y = rand.intRangeAtMost(u8, 1, height - 2);

            const segment = try arena.create(Segment);
            segment.x = old_x;
            segment.y = old_y;
	    body.insertAfter(&snake.node, &segment.node);

            try mvprintw(food.y, food.x, "[]", .{});
            try mvprintw(segment.y, segment.x, "<>", .{});
        } else {
            const last_node = body.pop();
            const last_segment: *Segment = @fieldParentPtr("node", last_node.?);
            try mvprintw(last_segment.y, last_segment.x, "  ", .{});

	    last_segment.x = old_x;
	    last_segment.y = old_y;
            body.insertAfter(&snake.node, &last_segment.node);

	    try mvprintw(last_segment.y, last_segment.x, "<>", .{});
        }

        _ = nc.refresh();

        try std.Io.sleep(io, std.Io.Duration.fromMilliseconds(100), std.Io.Clock.awake);
    }
}

const Head = struct {
    node: std.DoublyLinkedList.Node = .{},
    x: u8,
    y: u8,

    pub fn init(x: u8, y: u8) Head {
        return Head{
            .x = x,
            .y = y,
        };
    }

    pub fn move(self: *Head, d: Direction) bool {
        switch (d) {
            .up => if (self.y > 1) {
                self.y -= 1;
                return false;
            } else return true,

            .down => if (self.y < height - 2) {
                self.y += 1;
                return false;
            } else return true,

            .left => if (self.x > 1) {
                self.x -= 1;
                return false;
            } else return true,

            .right => if (self.x < width - 2) {
                self.x += 1;
                return false;
            } else return true,
        }
    }
};

const Segment = struct {
    node: std.DoublyLinkedList.Node = .{},
    x: u8,
    y: u8,
};
