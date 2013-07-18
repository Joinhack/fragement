#ifndef SETTING_H
#define SETTING_H

typedef struct setting {

  void* (*malloc)(size_t size);

  void (*free)(void *m);

} setting;

void set_setting(setting *s);

setting *get_setting();

#endif

