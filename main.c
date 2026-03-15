#include <stdio.h>
#include <stdlib.h>

#include "constants.h"
#include "draw.h"
#include "snake.h"

int main() {
  draw_walls();

  // Two segments are created to start. Has benefit of avoiding
  // a segmentation fault in checking for snake->head->next.
  struct Snake *snake = malloc(sizeof(struct Snake));
  struct Segment *initial_segment = malloc(sizeof(struct Segment));
  struct Segment *second_segment = malloc(sizeof(struct Segment));

  snake->head = initial_segment;
  snake->length = 1;

  initial_segment->x = WIDTH / 2;
  initial_segment->y = HEIGHT / 2;
  initial_segment->next = second_segment;

  while (!close) {
    bool ate = false;

    input();
    logic();
    draw_movement(snake, ate);
  }

  return EXIT_SUCCESS;
}
