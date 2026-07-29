#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#include "constants.h"
#include "draw.h"
#include "io.h"
#include "snake.h"

int main() {
  srand(time(NULL));
  set_terminal_mode(START);
  draw_walls();

  struct timespec ts;
  ts.tv_sec = 0;
  ts.tv_nsec = 100000000; // 100 ms / .1 s

  // Two segments are created to start. Has benefit of avoiding
  // A segmentation fault in checking for head->next.
  // Body is just the second segment.
  struct Segment *head = malloc(sizeof(struct Segment));
  struct Segment *body = malloc(sizeof(struct Segment));

  head->x = WIDTH / 2;
  head->y = HEIGHT / 2;
  head->next = body;

  body->x = head->x;
  body->y = head->y + 1;
  body->next = NULL;

  struct Food *food = malloc(sizeof(struct Food));
  spawn_food(head, food);

  enum Direction direction = UP;

  while (true) {
    if (kbhit()) {
      handle_inputs(getchar(), &direction);
    }

    if (move(&head, direction, food)) {
      break;
    }

    draw_snake(head);
    fflush(stdout);

    nanosleep(&ts, NULL);
  }

  // Cleanup
  death(head);
  free(food);
  head = NULL;
  body = NULL;
  food = NULL;

  set_terminal_mode(STOP);

  return EXIT_SUCCESS;
}
