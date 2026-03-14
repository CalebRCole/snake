#ifndef SNAKE_H
#define SNAKE_H

#include <stdbool.h>

enum Direction { LEFT, DOWN, UP, RIGHT };

struct Segment {
  int x;
  int y;
  struct Segment *next;
};

struct Snake {
  struct Segment *head;
  int length;
};

void move_snake(struct Snake *snake, int new_x, int new_y, bool ate);

#endif
