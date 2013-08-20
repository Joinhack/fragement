#ifndef POSIX_SYS_H
#define POSIX_SYS_H

#include <assert.h>
#include <pthread.h>
#include <sys/time.h>

namespace ndb {

inline static struct timeval now() {
  struct timeval t;
  ::gettimeofday(&t, NULL);
  return t;
}


class Mutex {
public:
  Mutex();

  bool lock();

  bool trylock();

  bool unlock();

  ~Mutex();

private:
  friend class Cond;

  pthread_mutex_t _mutex;
};

class Cond {
public:
  Cond();
  
  bool wait();

  bool wait(long t);

  bool notify();

  Cond(Mutex &mutex);

  ~Cond();

private:
  Mutex &_mutex;

  pthread_cond_t _cond;
};

};

#endif
