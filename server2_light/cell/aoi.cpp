/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：aoi
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.14
// 模块描述：aoi 范围相关封装
//----------------------------------------------------------------*/

#include <stdio.h>
//#include <stdint.h>
#include <string.h>
//#include <stdbool.h>
#include <assert.h>
#include <stdlib.h>
#include "aoi.h"


//#define AOI_RADIS 1000
//#define PRE_ALLOC 16
//#define AOI_RADIS2 (AOI_RADIS * AOI_RADIS)

enum
{
    /*AOI_RADIS = 450,*/
    AOI_RADIS = 4500,
    PRE_ALLOC = 16,

    AOI_RADIS2 = AOI_RADIS * AOI_RADIS,
    LEAVE_AOI_RADIS2 = AOI_RADIS2 * 4,

    MODE_WATCHER = 1,
    MODE_MARKER = 2,
    MODE_MOVE = 4,
    MODE_DROP = 8,
};

const uint32_t INVALID_ID = ~0;

#define DIST2(p1,p2) ((p1[0] - p2[0]) * (p1[0] - p2[0]) + (p1[1] - p2[1]) * (p1[1] - p2[1]) )
//#define MODE_WATCHER 1
//#define MODE_MARKER 2
//#define MODE_MOVE 4
//#define MODE_DROP 8

bool IsOutOfAoi(position_t pos1[2], position_t pos2[2])
{
    return DIST2(pos1, pos2) > LEAVE_AOI_RADIS2;
}

struct object
{
    int ref;
    uint32_t id;
    int version;
    int mode;
    position_t last[2];
    position_t position[2];
};

struct object_set
{
    int cap;
    int number;
    struct object ** slot;
};

struct pair_list
{
    struct pair_list * next;
    struct object * watcher;
    struct object * marker;
    int watcher_version;
    int marker_version;
};

struct map_slot
{
    uint32_t id;
    struct object * obj;
    int next;
};

struct map
{
    int size;
    int lastfree;
    struct map_slot * slot;
};

struct aoi_space
{
    AoiAlloc alloc;
    void * alloc_ud;
    struct map * object;
    struct object_set * watcher_static;
    struct object_set * marker_static;
    struct object_set * watcher_move;
    struct object_set * marker_move;
    struct pair_list * hot;
};

// 创建一个新的object 对象。设置引用计数为 1
static struct object * NewObject(struct aoi_space * space, uint32_t id)
{
    struct object * obj = (object*)space->alloc(space->alloc_ud, NULL, sizeof(*obj));
    obj->ref = 1;
    obj->id = id;
    obj->version = 0;
    obj->mode = 0;
    obj->position[0] = 0;
    obj->position[1] = 0;
    obj->last[0] = 0;
    obj->last[1] = 0;
    return obj;
}

static inline struct map_slot * MainPosition(struct map *m , uint32_t id)
{
    uint32_t hash = id & (m->size-1);
    return &m->slot[hash];
}

static void rehash(struct aoi_space * space, struct map *m);

static void MapInsert(struct aoi_space * space , struct map * m, uint32_t id , struct object *obj)
{
        struct map_slot *s = MainPosition(m,id);
        if (s->id == INVALID_ID) {
            s->id = id;
            s->obj = obj;
            return;
        }
        if (MainPosition(m, s->id) != s)
        {
            struct map_slot * last = MainPosition(m,s->id);
            while (last->next != s - m->slot)
            {
                assert(last->next >= 0);
                last = &m->slot[last->next];
            }
            uint32_t temp_id = s->id;
            struct object * temp_obj = s->obj;
            last->next = s->next;
            s->id = id;
            s->obj = obj;
            s->next = -1;
            if (temp_obj)
            {
                MapInsert(space, m, temp_id, temp_obj);
            }
            return;
        }
        while (m->lastfree >= 0)
        {
            struct map_slot * temp = &m->slot[m->lastfree--];
            if (temp->id == INVALID_ID)
            {
                temp->id = id;
                temp->obj = obj;
                temp->next = s->next;
                s->next = (int)(temp - m->slot);
                return;
            }
        }
        rehash(space,m);
        MapInsert(space, m, id , obj);
}

static void rehash(struct aoi_space * space, struct map *m)
{
        struct map_slot * old_slot = m->slot;
        int old_size = m->size;
        m->size = 2 * old_size;
        m->lastfree = m->size - 1;
        m->slot = (map_slot*)space->alloc(space->alloc_ud, NULL, m->size * sizeof(struct map_slot));
        int i;
        for (i=0;i<m->size;i++) {
            struct map_slot * s = &m->slot[i];
            s->id = INVALID_ID;
            s->obj = NULL;
            s->next = -1;
        }
        for (i=0;i<old_size;i++) {
            struct map_slot * s = &old_slot[i];
            if (s->obj) {
                MapInsert(space, m, s->id, s->obj);
            }
        }
        space->alloc(space->alloc_ud, old_slot, old_size * sizeof(struct map_slot));
}

// 在 map 中查找 id 对应的对象。 如果不存在， 则插入，存在则返回
// 空间不够时，增加一倍的空间大小，将 object 复制到新的 map中， 消除旧的map
// map 为静态链表。
static struct object * MapQuery(struct aoi_space *space, struct map * m, uint32_t id)
{
        struct map_slot *s = MainPosition(m, id);
        for (;;) {
            if (s->id == id) {
                if (s->obj == NULL) {
                    s->obj = NewObject(space, id);
                }
                return s->obj;
            }
            if (s->next < 0) {
                break;
            }
            s=&m->slot[s->next];
        }
        struct object * obj = NewObject(space, id);
        MapInsert(space, m , id , obj);
        return obj;
}

// 遍历map, 对每个object 执行 函数指针 func
static void MapForeach(struct map * m , void (*func)(void *ud, struct object *obj), void *ud)
{
    int i;
    for(i=0; i<m->size; i++)
    {
        if(m->slot[i].obj)
        {
            func(ud, m->slot[i].obj);
        }
    }
}

// 遍历map。 删除 指定id的对象，并返回该对象指针。
static struct object * MapDrop(struct map *m, uint32_t id)
{
    uint32_t hash = id & (m->size-1);
    struct map_slot *s = &m->slot[hash];
    for(;;)
    {
        if(s->id == id)
        {
            struct object * obj = s->obj;
            s->obj = NULL;
            return obj;
        }
        if(s->next < 0)
        {
            return NULL;
        }
        s=&m->slot[s->next];
    }
}

// 释放 m_slot 以及m的 内存。 m_slot 是一个 object 数组
static void MapDelete(struct aoi_space *space, struct map * m)
{
    space->alloc(space->alloc_ud, m->slot, m->size * sizeof(struct map_slot));
    space->alloc(space->alloc_ud, m , sizeof(*m));
}

// 创建一个 map， 其slot 为一个 object 构成的数组， object 均指向 null
static struct map * MapNew(struct aoi_space *space)
{
    int i;
    struct map * m = (map*)space->alloc(space->alloc_ud, NULL, sizeof(*m));
    m->size = PRE_ALLOC;
    m->lastfree = PRE_ALLOC - 1;
    m->slot = (map_slot*)space->alloc(space->alloc_ud, NULL, m->size * sizeof(struct map_slot));
    for(i=0; i<m->size; i++)
    {
        struct map_slot * s = &m->slot[i];
        s->id = INVALID_ID;
        s->obj = NULL;
        s->next = -1;
    }
    return m;
}

// obj 引用计数加一
inline static void GrabObject(struct object *obj)
{
    ++obj->ref;
}

// 释放 object 内存， s 为 aoi_space 指针
static void DeleteObject(void *s, struct object * obj)
{
    struct aoi_space * space = (aoi_space*)s;
    space->alloc(space->alloc_ud, obj, sizeof(*obj));
}

// object 引用计数加一， 等于0时， 从 对应的 space 中删除， 并释放 obj 内存
inline static void DropObject(struct aoi_space * space, struct object *obj)
{
    --obj->ref;
    if(obj->ref <=0)
    {
        MapDrop(space->object, obj->id);
        DeleteObject(space, obj);
    }
}

// 创建 object_set 对象， 其中 set->slot 为一个 object 数组
static struct object_set * SetNew(struct aoi_space * space)
{
    struct object_set * set = (object_set*)space->alloc(space->alloc_ud, NULL, sizeof(*set));
    set->cap = PRE_ALLOC;
    set->number = 0;
    set->slot = (object**)space->alloc(space->alloc_ud, NULL, set->cap * sizeof(struct object *));
    return set;
}

// 创建 aoi_space ， 初始化各属性
struct aoi_space * AoiCreate(AoiAlloc alloc, void *ud)
{
    struct aoi_space *space = (aoi_space*)alloc(ud, NULL, sizeof(*space));
    space->alloc = alloc;
    space->alloc_ud = ud;
    space->object = MapNew(space);
    space->watcher_static = SetNew(space);
    space->marker_static = SetNew(space);
    space->watcher_move = SetNew(space);
    space->marker_move = SetNew(space);
    space->hot = NULL;
    return space;
}

// 删除 space 指向的 hot 链表。 释放内存
static void DeletePairList(struct aoi_space * space)
{
    struct pair_list * p = space->hot;
    while(p)
    {
        struct pair_list * next = p->next;
        space->alloc(space->alloc_ud, p, sizeof(*p));
        p = next;
    }
}

// 删除 set 以及 set->slot 。释放内存
static void DeleteSet(struct aoi_space *space, struct object_set * set)
{
    if(set->slot)
    {
        space->alloc(space->alloc_ud, set->slot, sizeof(struct object *) * set->cap);
    }
    space->alloc(space->alloc_ud, set, sizeof(*set));
}

void AoiRelease(struct aoi_space *space)
{
    MapForeach(space->object, DeleteObject, space);
    MapDelete(space, space->object);
    DeletePairList(space);
    DeleteSet(space,space->watcher_static);
    DeleteSet(space,space->marker_static);
    DeleteSet(space,space->watcher_move);
    DeleteSet(space,space->marker_move);
    space->alloc(space->alloc_ud, space, sizeof(*space));
}

inline static void CopyPosition(position_t des[2], position_t src[2])
{
    des[0] = src[0];
    des[1] = src[1];
}

// 设置 object 的 模式， 并返回是否有变化
// object->mode ，按位，表示 观察者， 或者被观察者。 可以同时是观察者或者被观察者。
static bool ChangeMode(struct object * obj, bool set_watcher, bool set_marker)
{
    bool change = false;
    if(obj->mode == 0)
    {
        if(set_watcher)
        {
            obj->mode = MODE_WATCHER;
        }
        if(set_marker)
        {
            obj->mode |= MODE_MARKER;
        }
        return true;
    }
    if(set_watcher)
    {
        if(!(obj->mode & MODE_WATCHER))
        {
            obj->mode |= MODE_WATCHER;
            change = true;
        }
    }
    else
    {
        if(obj->mode & MODE_WATCHER)
        {
            obj->mode &= ~MODE_WATCHER;
            change = true;
        }
    }
    if(set_marker)
    {
        if(!(obj->mode & MODE_MARKER))
        {
            obj->mode |= MODE_MARKER;
            change = true;
        }
    }
    else
    {
        if(obj->mode & MODE_MARKER)
        {
            obj->mode &= ~MODE_MARKER;
            change = true;
        }
    }
    return change;
}

inline static bool IsNear(position_t p1[2], position_t p2[2])
{
    return DIST2(p1,p2) < AOI_RADIS2 * 0.25f ;
}

inline static int dist2(struct object *p1, struct object *p2)
{
    int d = DIST2(p1->position,p2->position);
    return d;
}

void AoiUpdate(struct aoi_space * space , uint32_t id, const char * modestring , position_t pos[2])
{
    struct object * obj = MapQuery(space, space->object,id);
    int i;
    bool set_watcher = false;
    bool set_marker = false;

    for(i=0; modestring[i]; ++i)
    {
        char m = modestring[i];
        switch(m)
        {
            case 'w':
                set_watcher = true;
                break;
            case 'm':
                set_marker = true;
                break;
            case 'd':
                if (!(obj->mode & MODE_DROP))
                {
                    obj->mode = MODE_DROP;
                    DropObject(space, obj);
                }
                return;
        }
    }
    //obj->mode &= ~MODE_DROP;

    if (obj->mode & MODE_DROP)
    {
        obj->mode &= ~MODE_DROP;
        GrabObject(obj);
    }

    bool changed = ChangeMode(obj, set_watcher, set_marker);

    CopyPosition(obj->position, pos);
    if(changed || !IsNear(pos, obj->last))
    {
        // new object or change object mode
        // or position changed
        CopyPosition(obj->last , pos);
        obj->mode |= MODE_MOVE;
        ++obj->version;
    }
}

static void DropPair(struct aoi_space * space, struct pair_list *p)
{
    DropObject(space, p->watcher);
    DropObject(space, p->marker);
    space->alloc(space->alloc_ud, p, sizeof(*p));
}

static void FlushPair(struct aoi_space * space, AoiCallback cb, void *ud)
{
    struct pair_list **last = &(space->hot);
    struct pair_list *p = *last;
    while(p)
    {
        struct pair_list *next = p->next;
        if(p->watcher->version != p->watcher_version || p->marker->version != p->marker_version ||
                (p->watcher->mode & MODE_DROP) || (p->marker->mode & MODE_DROP) )
        {
            DropPair(space, p);
            *last = next;
        }
        else
        {
            int distance2 = dist2(p->watcher , p->marker);
            if(distance2 > AOI_RADIS2 * 4)
            {
                DropPair(space, p);
                *last = next;
            }
            else if(distance2 < AOI_RADIS2)
            {
                cb(ud, p->watcher->id, p->marker->id);
                DropPair(space, p);
                *last = next;
            }
            else
            {
                last = &(p->next);
            }
        }
        p=next;
    }
}

static void SetPushback(struct aoi_space * space, struct object_set * set, struct object *obj)
{
    if(set->number >= set->cap)
    {
        int cap = set->cap * 2;
        void * tmp =  set->slot;
        set->slot = (object**)space->alloc(space->alloc_ud, NULL, cap * sizeof(struct object *));
        memcpy(set->slot, tmp ,  set->cap * sizeof(struct object *));
        space->alloc(space->alloc_ud, tmp, set->cap * sizeof(struct object *));
        set->cap = cap;
    }
    set->slot[set->number] = obj;
    ++set->number;
}

static void SetPush(void * s, struct object * obj)
{
    struct aoi_space * space = (aoi_space*)s;
    int mode = obj->mode;
    if(mode & MODE_WATCHER)
    {
        if(mode & MODE_MOVE)
        {
            SetPushback(space, space->watcher_move , obj);
            obj->mode &= ~MODE_MOVE;
        }
        else
        {
            SetPushback(space, space->watcher_static , obj);
        }
    }
    if(mode & MODE_MARKER)
    {
        if(mode & MODE_MOVE)
        {
            SetPushback(space, space->marker_move , obj);
            obj->mode &= ~MODE_MOVE;
        }
        else
        {
            SetPushback(space, space->marker_static , obj);
        }
    }
}

static void GenPair(struct aoi_space * space, struct object * watcher, struct object * marker,
                    AoiCallback cb, void *ud)
{
    if(watcher == marker)
    {
        return;
    }
    int distance2 = dist2(watcher, marker);
    if(distance2 < AOI_RADIS2)
    {
        cb(ud, watcher->id, marker->id);
        return;
    }
    if(distance2 > AOI_RADIS2 * 4)
    {
        return;
    }
    struct pair_list * p = (pair_list*)space->alloc(space->alloc_ud, NULL, sizeof(*p));
    p->watcher = watcher;
    GrabObject(watcher);
    p->marker = marker;
    GrabObject(marker);
    p->watcher_version = watcher->version;
    p->marker_version = marker->version;
    p->next = space->hot;
    space->hot = p;
}

static void GenPairList(struct aoi_space *space, struct object_set * watcher, struct object_set * marker,
                        AoiCallback cb, void *ud)
{
    int i,j;
    for(i = 0; i < watcher->number; i++)
    {
        for(j = 0; j < marker->number; j++)
        {
            GenPair(space, watcher->slot[i], marker->slot[j],cb,ud);
        }
    }
}

void AoiMessage(struct aoi_space *space, AoiCallback cb, void *ud)
{
    FlushPair(space,  cb, ud);
    space->watcher_static->number = 0;
    space->watcher_move->number = 0;
    space->marker_static->number = 0;
    space->marker_move->number = 0;
    MapForeach(space->object, SetPush , space);
    GenPairList(space, space->watcher_static, space->marker_move, cb, ud);
    GenPairList(space, space->watcher_move, space->marker_static, cb, ud);
    GenPairList(space, space->watcher_move, space->marker_move, cb, ud);
}

static void * DefaultAlloc(void * ud, void *ptr, size_t sz)
{
    if(ptr == NULL)
    {
        void *p = malloc(sz);
        return p;
    }
    free(ptr);
    return NULL;
}

struct aoi_space * AoiNew()
{
    return AoiCreate(DefaultAlloc, NULL);
}
