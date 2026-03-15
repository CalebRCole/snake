#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "constants.h"
#include "draw.h"
#include "snake.h"

void spawn_food(struct Segment *head, struct Food *food) {
  bool valid = false;

  while (!valid) {
    food->x = (rand() % (WIDTH - 2)) + 1;
    food->y = (rand() % (HEIGHT - 2)) + 1;

    valid = true;
    struct Segment *current = head;
    while (current != NULL) {
      if (current->x == food->x && current->y == food->y) {
        valid = false; // Collision! Need to try again.
        break;
      }
      current = current->next;
    }
  }

  goto_xy(food->x * 2, food->y);
  printf("$$");
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

bool move(struct Segment **head, enum Direction direction, struct Food *food) {
  struct Segment *head_ref = *head;
  struct Segment *new_head = malloc(sizeof(struct Segment));
  new_head->x = head_ref->x;
  new_head->y = head_ref->y;

  switch (direction) {
  case LEFT:
    new_head->x--;
    break;
  case RIGHT:
    new_head->x++;
    break;
  case UP:
    new_head->y--;
    break;
  case DOWN:
    new_head->y++;
    break;
  }

  if (new_head->x <= 0 || new_head->x >= WIDTH - 1 || new_head->y <= 0 ||
      new_head->y >= HEIGHT - 1) {
    return DEAD;
  }

  struct Segment *current = head_ref;
  while (current != NULL) {
    if (new_head->x == current->x && new_head->y == current->y) {
      free(new_head);
      return DEAD;
    }

    current = current->next;
  }

  new_head->next = head_ref;
  *head = new_head;

  if (new_head->x == food->x && new_head->y == food->y) {
    spawn_food(new_head, food);
  } else {
    struct Segment *penult = new_head;

    while (penult->next != NULL && penult->next->next != NULL) {
      penult = penult->next;
    }

    goto_xy(penult->next->x * 2, penult->next->y);
    printf("  ");

    free(penult->next);
    penult->next = NULL;
  }

  return ALIVE;
}

void death(struct Segment *head) {
  struct Segment *temp;
  while (head != NULL) {
    temp = head->next;
    free(head);
    head = temp;
  }
}
