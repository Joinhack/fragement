#ifndef AIOFILE_H
#define AIOFILE_H

#include <string>
#include "buffer.h"


namespace ndb {

using namespace std;

struct AIOStatus {
  bool success;
  ssize_t rs;
};

typedef void (*aio_cb_t)(void *ctx, AIOStatus s);

enum RequestType {  
  READ,
  WRITE
};

class AIOFile {
public:
  AIOFile(const string &filepath):_filepath(filepath), _closed(true), _fd(-1) {}

  bool open();

  //async read
  void read(size_t offset, Buffer &buffer, aio_cb_t cb, void *ctx);

  //sync read
  AIOStatus read(size_t offset, Buffer &buffer);

  //async write
  void write(size_t offset, Buffer &buffer, aio_cb_t cb, void *ctx);

  //sync write
  AIOStatus write(size_t offset, Buffer &buffer);

  bool truncate(size_t offset);

  void close();

  void remove();

private:
  const string _filepath;
  bool _closed;
  int _fd;
};

}

#endif
