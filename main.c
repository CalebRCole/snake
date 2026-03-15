#include <stdio.h>
#include <stdlib.h>

#include "constants.h"
#include "draw.h"
#include "snake.h"

int main() {
  while (!close) {
    input();
    logic();
    drawing();
  }

  return EXIT_SUCCESS;
}
