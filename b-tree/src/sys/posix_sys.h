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

  pthread_mutex_t _mutex;
};

class Cond {
public:
  Cond();
  
  bool wait();

  bool wait(long t);

  bool notify();

  Cond(Mutex *);

  ~Cond();

  Mutex *_mutex;
  //if mutex object is create by Cond, free it.
  bool _isCreateMutex;
  pthread_cond_t _cond;
};

};

#endif
