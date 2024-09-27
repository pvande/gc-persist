#ifndef DRAGONRUBY_DRAGONRUBY_H
#include "dragonruby.h"

struct RVALUE {
    union {
        struct RBasic basic;
        struct RFloat floatv;
        struct RObject object;
        struct RString string;
        struct RArray array;
        struct RHash hash;
        struct RRange range;
    } as;
};

struct iv_elem {
    mrb_sym key;
    mrb_value val;
};

typedef struct iv_tbl {
    size_t size;
    size_t alloc;
    struct iv_elem *table;
} iv_tbl;

typedef struct hash_entry {
    mrb_value key;
    mrb_value val;
} hash_entry;

typedef struct hash_table {
    hash_entry *ea;
    uint32_t ib[];
} hash_table;

static drb_api_t *api;
#endif
