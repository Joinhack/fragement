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

//pthread mutex
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

//lock in scope. release lock when exit the scope
class ScopeLock {
public:
  ScopeLock(Mutex &mutex):_mutex(mutex) {
    _mutex.lock();
  }
  ~ScopeLock() {
    _mutex.unlock(); 
  }
private:
  Mutex _mutex;
};

//pthread cond
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

class RWLock {
public:
  RWLock();

  bool rdlock();

  bool tryrdlock();

  bool unlock();

  bool wrlock();

  bool trywrlock();

  ~RWLock();
private:
  pthread_rwlock_t _rwlock;
};

};

#endif
