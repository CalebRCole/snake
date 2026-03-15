#ifndef DRAW_H
#define DRAW_H

#include "snake.h"

void goto_xy(int x, int y);

void draw_walls();

void draw_snake(struct Segment *head);

void erase_tail(struct Segment *head, bool ate);

void draw_movement(struct Segment *head, bool ate);

#endif
