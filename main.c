#include <stdio.h>
#include <stdlib.h>

#include "constants.h"
#include "draw.h"
#include "snake.h"

int main() {
  draw_walls();

  struct Snake *snake = malloc(sizeof(struct Snake));
  struct Segment *initial_segment = malloc(sizeof(struct Segment));

  snake->head = initial_segment;
  snake->length = 1;

  initial_segment->x = WIDTH / 2;
  initial_segment->y = HEIGHT / 2;

  while (!close) {
    input();
    logic();
    drawing();
  }

  return EXIT_SUCCESS;
}
