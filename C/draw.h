#ifndef DRAW_H
#define DRAW_H

#include "snake.h"

void goto_xy(int x, int y);

void draw_walls();

void draw_snake(struct Segment *head);

#endif
