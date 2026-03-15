#include <stdio.h>

#include "constants.h"
#include "draw.h"
#include "snake.h"

// ANSI terminal escape codes are 1-indexed.
void goto_xy(int x, int y) { printf("\033[%d;%dH", y + 1, x + 1); }

void draw_walls() {
  // Sets cursor to top left and turns off blinking.
  // Should only be used when starting the game.
  printf("\033[H\033[?25l");

  for (int y = 0; y < HEIGHT; y++) {
    for (int x = 0; x < WIDTH; x++) {
      if (x == 0 || x == WIDTH - 1 || y == 0 || y == HEIGHT - 1) {
        // Prints walls.
        printf("#");
      } else {
        printf(" ");
      }
    }
    printf("\n");
  }
}

void draw_snake(struct Segment *head) {
  // Prints head.
  goto_xy(head->x, head->y);
  printf("@");

  // Changes old head to body segment.
  goto_xy(head->next->x, head->next->y);
  printf("o");
}
