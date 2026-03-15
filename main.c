#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "constants.h"
#include "draw.h"
#include "io.h"
#include "snake.h"

int main() {
  srand(time(NULL));

  set_terminal_mode(START);

  draw_walls();

  // Two segments are created to start. Has benefit of avoiding
  // A segmentation fault in checking for head->next.
  // Body is just the second segment.
  struct Segment *head = malloc(sizeof(struct Segment));
  struct Segment *body = malloc(sizeof(struct Segment));

  head->x = WIDTH / 2;
  head->y = HEIGHT / 2;
  head->next = body;

  while (!close) {
    bool ate = false;

    input();
    logic();
    draw_movement(head, ate);
  }

  set_terminal_mode(STOP);

  return EXIT_SUCCESS;
}
