#ifndef SNAKE_H
#define SNAKE_H

#include <stdbool.h>

enum Direction { LEFT, DOWN, UP, RIGHT };

struct Segment {
  int x;
  int y;
  struct Segment *next;
};

void handle_inputs(char input, enum Direction *old_direction);

bool move(struct Segment *head, enum Direction direction, bool ate);

void death(struct Segment *head);
#endif
