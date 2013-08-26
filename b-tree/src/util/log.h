#ifndef LOG_H
#define LOG_H

enum LOG_LEVEL {
  LEVEL_TRACE=0,
  LEVEL_DEBUG,
  LEVEL_INFO,
  LEVEL_WARN,
  LEVEL_ERR
};

void log_init(int fd);

void log_print(int level, const char *fmt, ...);

#define LOG_ERROR(fmt, ...) log_print(LEVEL_ERR, fmt, ##__VA_ARGS__)

#define LOG_INFO(fmt, ...) log_print(LEVEL_INFO, fmt, ##__VA_ARGS__)

#define LOG_WARN(fmt, ...) log_print(LEVEL_WARN, fmt, ##__VA_ARGS__)

#define LOG_DEBUG(fmt, ...) log_print(LEVEL_DEBUG, fmt, ##__VA_ARGS__)

#define LOG_TRACE(fmt, ...) log_print(LEVEL_TRACE, fmt, ##__VA_ARGS__)

#endif
