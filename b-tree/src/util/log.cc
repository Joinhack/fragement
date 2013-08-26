#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <sys/time.h>
#include "log.h"
#include "sys/posix_sys.h"

using namespace ndb;

static const char* level_array[] = {
  "TRACE",
  "DEBUG",
  "INFO",
  "WARN",
  "ERR"
};

//default use stdout
static int logfd = 1;

//define use mutex for log lock.

static int top_level = LEVEL_TRACE;
static Mutex mutex;

void log_init(int fd) {
  logfd = fd;
}

void set_top_level(int level) {
  top_level = level;
}

static int now(char *buf, size_t len) {
  struct timeval now;
  time_t current_tv;
  char tbuf[128] = {0};
  gettimeofday(&now, NULL);
  current_tv = now.tv_sec;
  strftime(tbuf, sizeof(tbuf),"[%m/%d %H:%M:%S.",localtime(&current_tv));
  strcat(tbuf, "%ld] ");
  return snprintf(buf, len, tbuf, now.tv_usec/1000);
}

static int log_write(int fd, char *ptr, size_t len) {
  int count = 0;
  int wn = 0;
  while(count < len ) {
    wn = write(fd, ptr, len - count);
    if(wn == 0) return count;
    if(wn == -1) return -1;
    ptr += wn;
    count += wn;
  }
  return count;
}

void log_print(int level, const char *fmt, ...) {
  if(level < top_level)
    return;
  int len = 1024, off, rs;
  char *buf = NULL, tbuf[128];
  va_list arg_list;
  off = now(tbuf, sizeof(tbuf));
  while(true) { 
    if(buf)
      delete []buf;
    buf = new char[len];
    va_start(arg_list, fmt);
    rs = vsnprintf(buf + off, len - off - 2, fmt, arg_list);
    va_end(arg_list);
    if(rs > 0 && rs <= len - off - 2) {
      buf[rs + off] = '\n';
      buf[rs + off + 1] = 0;
      break;
    }
    len *= 2;
  }
  memcpy(buf, tbuf, off);
  ScopeLock lock(mutex);
  log_write(logfd, buf, rs + off + 2);
  delete []buf;
}
