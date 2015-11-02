#ifndef _AOI_H
#define _AOI_H

//#include <stdint.h>
#include <stddef.h>

#ifdef _WIN32
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef short int16_t;
#else
#include <inttypes.h>
#endif

typedef int16_t position_t;

typedef void * (*AoiAlloc)(void *ud, void * ptr, size_t sz);
typedef void (AoiCallback)(void *ud, uint32_t watcher, uint32_t marker);

struct aoi_space;

struct aoi_space * AoiCreate(AoiAlloc alloc, void *ud);
struct aoi_space * AoiNew();
void AoiRelease(struct aoi_space *);

bool IsOutOfAoi(position_t pos1[2], position_t pos2[2]);


// w(atcher) m(arker) d(rop)
void AoiUpdate(struct aoi_space * space , uint32_t id, const char * mode , position_t pos[2]);
void AoiMessage(struct aoi_space *space, AoiCallback cb, void *ud);

#endif
