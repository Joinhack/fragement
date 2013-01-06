#ifndef CIO_H
#define CIO_H

int cio_set_noblock(int fd);

int cio_set_block(int fd);

int cio_write(int fd, char *ptr, size_t len);

int cio_read(int fd, char *ptr, size_t len);

#endif /*end define common io**/
