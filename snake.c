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
