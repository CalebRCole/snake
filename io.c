#include <stdio.h>
#include <sys/select.h>
#include <termios.h>
#include <unistd.h>

void set_terminal_mode(int start) {
  // Static values have process long lifetimes and live in the global memory
  // space, meaning they are not uninitialized and are reused across calls.
  static struct termios oldt, newt;
  if (start) {
    //  Get current settings.
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;

    //  Disable buffered I/O (ICANON) and echoing (ECHO).
    newt.c_lflag &= ~(ICANON | ECHO);

    //  Apply settings immediately.
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
  } else {
    //  Restore original settings.
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
  }
}

int kbhit() {
  // Zero timeout: check and return instantly
  struct timeval tv = {0L, 0L};
  fd_set fds;
  FD_ZERO(&fds);
  FD_SET(STDIN_FILENO, &fds);

  // Select returns > 0 if a key is waiting.
  return select(STDIN_FILENO + 1, &fds, NULL, NULL, &tv);
}
