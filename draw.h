#ifndef DRAW_H
#define DRAW_H

#include "snake.h"

void goto_xy(int x, int y);

void draw_walls(int x, int y);

void draw_snake(struct Snake *snake);

#endif
