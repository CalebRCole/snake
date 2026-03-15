#include <stdbool.h>
#include <stdlib.h>

#include "snake.h"

void move_snake(struct Snake *snake, int new_x, int new_y, bool ate) {
  struct Segment *new_head = malloc(sizeof(struct Segment));
  new_head->x = new_x;
  new_head->y = new_y;
  new_head->next = snake->head;
  snake->head = new_head;

  if (!ate) {
    struct Segment *body = snake->head;
    while (body->next->next != NULL) {
      body = body->next;
    }

    free(body->next);
    body->next = NULL;
  }
}

void handle_inputs(char input, enum Direction *old_dir) {
  enum Direction new_dir;
  bool valid = true;

  switch (input) {
  case 'a':
    new_dir = LEFT;
    break;
  case 's':
    new_dir = DOWN;
    break;
  case 'w':
    new_dir = UP;
    break;
  case 'd':
    new_dir = RIGHT;
    break;
  default:
    valid = 0;
    break;
  }

  // Opposite directions add to 3.
  // Only update if the sum of directions isn't 3
  // This prevents LEFT(0)+RIGHT(3) and DOWN(1)+UP(2)
  if (valid && (*old_dir + new_dir != 3)) {
    *old_dir = new_dir;
  }
}
