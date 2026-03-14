#include <stdio.h>

#include "constants.h"
#include "draw.h"
#include "snake.h"

void goto_xy(int x, int y) { printf("\033[%d;%dH", y + 1, x + 1); }

void draw_walls(int x, int y) {
  // Sets cursor to top left and turns off blinking
  printf("\033[H\033[?25l");

  for (int y = 0; y < HEIGHT; y++) {
    for (int x = 0; x < WIDTH; x++) {
      if (x == 0 || x == WIDTH - 1 || y == 0 || y == HEIGHT - 1) {
        // Walls
        printf("#");
      } else {
        printf(" ");
      }
    }
    printf("\n");
  }
}

void draw_snake(struct Snake *snake) {
  struct Segment *current = snake->head;

  // Prints for head of snake
  goto_xy(current->x, current->y);
  printf("@");

  current = current->next;
  while (current != NULL) {
    goto_xy(current->x, current->y);
    printf("o");
    current = current->next;
  }
}
