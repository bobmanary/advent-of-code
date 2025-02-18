#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <time.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/param.h>
#include <bits/time.h>

#define THREAD_COUNT ___THREAD_COUNT
#define OUTPUT_SIZE ___OUTPUT_SIZE
#define LOOP_WIDTH ___WIDTH

struct range {
  int64_t start;
  int64_t end;
};

int program(int64_t, int64_t*);
int child(int, int64_t, int64_t);
void watch_child_progress(int*, struct range*, int);

void timediff(struct timespec start, struct timespec end, struct timespec *elapsed) {
  if (end.tv_nsec - start.tv_nsec < 0)
  {
    elapsed->tv_sec = end.tv_sec - start.tv_sec - 1;
    elapsed->tv_nsec = 1000000000 + end.tv_nsec-start.tv_nsec;
  }
  else
  {
    elapsed->tv_sec = end.tv_sec - start.tv_sec;
    elapsed->tv_nsec = end.tv_nsec - start.tv_nsec;
  }
}

void bruteforce_part2() {
  int64_t search_start = 1LL << 45;
  int64_t search_end = (1LL << 48) - 1;

  int64_t search_space = search_end - search_start;
  int64_t search_per_thread = search_space / THREAD_COUNT;
  int fd_pair[2];
  int parent_fds[THREAD_COUNT];
  static const int parentsocket = 0;
  static const int childsocket = 1;
  pid_t pid;

  struct range ranges[THREAD_COUNT];
  for (int i=0; i<THREAD_COUNT; i++) {
    int64_t start = search_start + search_per_thread * i;
    int64_t end = search_start + search_per_thread * i + search_per_thread;
    if (LOOP_WIDTH > 1) {
      end = (end + LOOP_WIDTH) - (end % LOOP_WIDTH);
      start = start - start % LOOP_WIDTH;
    }
    ranges[i].start = start;
    ranges[i].end = end;
    //printf("start %li\nend   %li\n\n", start, end);
  }
  ranges[THREAD_COUNT - 1].end = search_end;

  for (int i=0; i<THREAD_COUNT; i++) {
    printf("start %li\nend   %li\n\n", ranges[i].start, ranges[i].end);
  }
  return;

  printf("Searching\n  start:        %li\n  end2:         %li\n  threads:      %i\n  # per thread: %li\n", search_start, search_end, THREAD_COUNT, search_per_thread);
  fflush(NULL);

  for (int i=0; i<THREAD_COUNT; i++) {
    socketpair(PF_LOCAL, SOCK_DGRAM, 0, fd_pair);
    pid = fork();
    if (pid == 0) {
      close(fd_pair[parentsocket]);
      child(fd_pair[childsocket], ranges[i].start, ranges[i].end);
      return;
    } else {
      parent_fds[i] = fd_pair[parentsocket];
      close(fd_pair[childsocket]);
    }
  }

  watch_child_progress(parent_fds, ranges, THREAD_COUNT);
}

int child(int socket, int64_t range_start, int64_t range_end) {
  pid_t pid = getpid();
  char message[200];
  int64_t goal[] = ___GOAL;

  // int64_t a = 0LL;
  // int64_t b = 0LL;
  // int64_t c = 0LL;
  // int64_t output[OUTPUT_SIZE];
  int found;

  for (int64_t i = range_end - LOOP_WIDTH; i>=range_start; i-=LOOP_WIDTH) {
    //memset(output, 0LL, sizeof(output));
    found = -1;



    // ___INNER_LOOP

    if (found >= 0) {
      snprintf(message, sizeof(message), "%li:1", i+found);
      int write_status = write(socket, message, strlen(message));
      return 0;
    } else {
      if ((i - range_start) % (536870912LL) == 0LL) {
        // send current status to parent
        snprintf(message, sizeof(message), "%li:0", i);
        write(socket, message, strlen(message));
      }
    }
  }

  // completed, did not find
  snprintf(message, sizeof(message), "%li:-1", range_end);
  write(socket, message, strlen(message));

  usleep(10000);
  return -1;
}

#define SEC_PER_DAY (60 * 60 * 24)

void format_elapsed_time(char *time_str, time_t total_seconds_elapsed) {
    int hours_elapsed = total_seconds_elapsed / 3600;
    int minutes_elapsed = (total_seconds_elapsed % 3600) / 60;
    int seconds_elapsed = total_seconds_elapsed % 60;
    sprintf(time_str, "%02i:%02i:%02i", hours_elapsed, minutes_elapsed, seconds_elapsed);
}

void update_local_status(int worker_num, int64_t start, int64_t end, int64_t latest_input, int status, struct timespec *start_time) {
  struct timespec now;
  struct timespec elapsed;
  clock_gettime(CLOCK_MONOTONIC, &now);
  timediff(*start_time, now, &elapsed);

  int64_t worker_completed = latest_input - start;
  int64_t total = end - start;
  double completion_percent = ((double)worker_completed / total) * 100;
  int64_t total_nsec = 1000000000LL * elapsed.tv_sec + elapsed.tv_nsec;
  double total_seconds = total_nsec / 1000000000.0d;
  double m_per_sec = (double)worker_completed / total_seconds / 1000000.0d;
  double avg_nsec_per_iteration = (double)total_nsec / worker_completed;
  char elapsed_str[100];
  format_elapsed_time(elapsed_str, elapsed.tv_sec);

  // print new lines
  // char *format = "worker %i: completed %li (%.3f\%) %.1fM/sec (%.1f ns)                ";
  // printf(format, worker_num, worker_completed, completion_percent, m_per_sec, avg_nsec_per_iteration);

  // rewrite existing lines
  char *format = "\e[%i;1Hworker %i: completed %li (%.3f\%) %.1fM/sec (%.1f ns)                ";
  printf(format, worker_num+8, worker_num, worker_completed, completion_percent, m_per_sec, avg_nsec_per_iteration);
  printf("\e[%i;1H  elapsed:      %s", 6, elapsed_str);
  printf("\e[%i;1H", THREAD_COUNT + 9);

  fflush(NULL);
}

void close_sockets_after(int first, int *sockets, int *closed, int count) {
  for (int i=first; i<count; i++) {
    if (closed[i] == 0) {
      close(sockets[i]);
      closed[i] = 1;
    }
  }
}

void reset_fdset(fd_set * set, int *socket_fds, int *closed, int count) {
  FD_ZERO(set);
  for (int i=0; i<count; i++) {
    if (closed[i] == 0) {
      FD_SET(socket_fds[i], set);
    }
  }
}

void watch_child_progress(int *sockets, struct range *ranges, int count) {
  char buf[1024];
  int closed[THREAD_COUNT] = {0};
  size_t msg_size;
  int select_status;
  fd_set watch_fds;
  int num_fds = 0;
  struct timespec start;
  clock_gettime(CLOCK_MONOTONIC, &start);
  FD_ZERO(&watch_fds);

  // set up initial status
  for (int i=0; i<THREAD_COUNT; i++) {
    num_fds = MAX(num_fds, sockets[i]);
    printf("\n");
  }
  for (int i=0; i<THREAD_COUNT; i++) {
    update_local_status(i, ranges[i].start, ranges[i].end, ranges[i].start, 0, &start);
  }

  while (1) {
    reset_fdset(&watch_fds, sockets, closed, count);
    select_status = select(num_fds+1, &watch_fds, NULL, NULL, NULL);
    if (select_status == -1) {
      if (errno == EINTR) { continue; }
      printf("select failed: errno %d\n", errno);
      exit(EXIT_FAILURE);
    }
    for (int i=0; i<count; i++) {
      if (FD_ISSET(sockets[i], &watch_fds)) {
        if (closed[i] == 0) {
          msg_size = read(sockets[i], buf, sizeof(buf));
          if (msg_size == 0) {
          } else if (msg_size < 0) {
            printf("socket read failed: errno %i\n", errno);
          } else {
            // handle message
            char *token;
            char *rest = buf;
            token = strtok_r(rest, ":", &rest);
            int64_t latest_input = strtoll(token, NULL, 10);
            token = strtok_r(rest, ":", &rest);
            int status = atoi(token);
            if (status == -1) {
              printf("closing %i", i);
              closed[i] = 1;
              close(sockets[i]);
            } else if (status == 1) {
              // printf("                       Worker %i found answer: %li\n", i, latest_input);
              printf("\e[%i;1H                       Worker %i found answer: %li\n", i + 8, i, latest_input);
              // closed[i] = 1;
              // close(sockets[i]);
              fflush(NULL);
              close_sockets_after(i, sockets, closed, count);
              return;
            }
            update_local_status(i, ranges[i].start, ranges[i].end, latest_input, status, &start);
          }
        }
      }
    }
  }
}

int main() {
  bruteforce_part2();
}
