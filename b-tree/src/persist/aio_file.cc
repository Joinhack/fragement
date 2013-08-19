#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <aio.h>
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include "aio_file.h"

using namespace ndb;

bool AIOFile::open() {
  #ifndef __APPLE__
  _fd = ::open(_filepath.c_str(), O_RDWR | O_DIRECT | O_CREAT, 0644);
  #else
  _fd = ::open(_filepath.c_str(), O_RDWR | O_CREAT, 0644);
  #endif
  if(_fd < 0) {
    return false;
  }
  _closed = false;
  return true;
}

struct AIORequest {
  struct aiocb aiocb;
  aio_cb_t cb;
  RequestType type;
  int fd;
  char *buf;
  size_t buf_len;
  size_t offset;
};

static void notify_function(union sigval sigval) {
  AIORequest *req = (AIORequest*) sigval.sival_ptr;
  AIOStatus aioStatus;
  aioStatus.success = false;
  ssize_t rs;
  if((rs = aio_error(&(req->aiocb))) == 0) {
    rs = aio_return(&(req->aiocb));
    aioStatus.rs = rs;
    
    if(rs < 0)
      aioStatus.success = false;
    else
      aioStatus.success = true;
  }
  req->cb(aioStatus);
  delete req;
}

static void aiocb_init(AIORequest *req) {
  memset(&req->aiocb, 0, sizeof(struct aiocb));
  req->aiocb.aio_fildes = req->fd;
  req->aiocb.aio_buf = req->buf;
  req->aiocb.aio_nbytes = req->buf_len;
  req->aiocb.aio_offset = req->offset;
  req->aiocb.aio_sigevent.sigev_notify = SIGEV_THREAD;
  req->aiocb.aio_sigevent.sigev_notify_function = notify_function;
  req->aiocb.aio_sigevent.sigev_notify_attributes = NULL;
  req->aiocb.aio_sigevent.sigev_value.sival_ptr = req;
}

void AIOFile::read(size_t offset, Buffer &buffer, aio_cb_t cb) {
  AIORequest *req = new AIORequest;
  req->fd = _fd;
  req->type = READ;
  req->offset = offset;
  req->buf = (char*)buffer.raw();
  req->buf_len = buffer.size();
  req->cb = cb;
  aiocb_init(req);

  while (true) {
    int rs = aio_read(&(req->aiocb));
    if (rs < 0) {
      if (errno == EAGAIN) {
        //retry.
        continue;
      }
      AIOStatus status;
      status.success = false;
      status.rs = rs;
      cb(status); // failed
    }
    return;
  }
}

void AIOFile::write(size_t offset, Buffer &buffer, aio_cb_t cb) {
  AIORequest *req = new AIORequest;
  req->fd = _fd;
  req->type = WRITE;
  req->offset = offset;
  req->buf = (char*)buffer.raw();
  req->buf_len = buffer.size();
  req->cb = cb;
  aiocb_init(req);

  while (true) {
    int rs = aio_write(&(req->aiocb));
    if (rs < 0) {
      if (errno == EAGAIN) {
        printf("posix aio_write busy, wait for a while\n");
        //retry.
        continue;
      }
      AIOStatus status;
      status.success = false;
      status.rs = rs;
      cb(status); // failed
    }
    return;
  }
}

bool AIOFile::truncate(size_t offset) {
  if(_closed)
    return false;
  int rs = ::ftruncate(_fd, offset);
  return rs == 0;
}

void AIOFile::remove() {
  if(!_closed)
    close();
  ::remove(_filepath.c_str());
}

void AIOFile::close() {
  if(!_closed)
    ::close(_fd);
  _fd = -1;
  _closed = true;
  return;
}

