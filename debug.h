#include "types.h"

#define TO_BASE_N (sizeof(unsigned) * CHAR_BIT + 1)
#define BITS(x, n) bits((char[TO_BASE_N]){""}, (x), n)
char *bits(char buf[TO_BASE_N], unsigned i, int nbits) {
    char *s = &buf[TO_BASE_N - 1];
    *s = '\0';
    int idx = 0;
    while (idx < nbits) {
        idx++;
        s--;
        *s = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"[i % 2];
        i >>= 1;
    };
    return s;
}

static char *ttypes[] = {
    "MRB_TT_FALSE",
    "MRB_TT_TRUE",
    "MRB_TT_FLOAT",
    "MRB_TT_INTEGER",
    "MRB_TT_SYMBOL",
    "MRB_TT_UNDEF",
    "MRB_TT_CPTR",
    "MRB_TT_FREE",
    "MRB_TT_OBJECT",
    "MRB_TT_CLASS",
    "MRB_TT_MODULE",
    "MRB_TT_ICLASS",
    "MRB_TT_SCLASS",
    "MRB_TT_PROC",
    "MRB_TT_ARRAY",
    "MRB_TT_HASH",
    "MRB_TT_STRING",
    "MRB_TT_RANGE",
    "MRB_TT_EXCEPTION",
    "MRB_TT_ENV",
    "MRB_TT_DATA",
    "MRB_TT_FIBER",
    "MRB_TT_ISTRUCT",
    "MRB_TT_BREAK",
    "MRB_TT_MAXDEFINE"};

#define inspect(o) puts(api->mrb_str_to_cstr(mrb, api->mrb_inspect(mrb, o)))

static void dump_float(mrb_state *mrb, mrb_value x) {
    struct RFloat *obj = mrb_ptr(x);
    const char *cls = api->mrb_class_name(mrb, obj->c);
    printf("{ c: %s, gcnext: %p, tt: %s, color: %s, flags: %s, f: %f }\n",
           cls,
           obj->gcnext,
           ttypes[obj->tt],
           BITS(obj->color, 3),
           BITS(obj->flags, 32),
           obj->f);
}

static char *dump_buffer;
static char *dump_ivs(mrb_state *mrb, struct iv_tbl *tbl) {
    if (tbl == NULL) return "NULL";
    if (!dump_buffer) dump_buffer = malloc(1024);

    memset(dump_buffer, 0, 1024);
    dump_buffer[0] = '<';

    for (size_t i = 0; i < tbl->alloc; i++) {
        struct iv_elem *slot = &tbl->table[i];
        if (!slot->key) continue;
        sprintf(dump_buffer + strlen(dump_buffer), "@");
        strcpy(dump_buffer + strlen(dump_buffer), api->mrb_sym_name(mrb, slot->key));
        sprintf(dump_buffer + strlen(dump_buffer), "=");
        if (mrb_undef_p(slot->val)) {
            sprintf(dump_buffer + strlen(dump_buffer), "undef");
        } else {
            sprintf(dump_buffer + strlen(dump_buffer), "%s", api->mrb_str_to_cstr(mrb, api->mrb_inspect(mrb, slot->val)));
            if (i + 1 < tbl->alloc) {
                sprintf(dump_buffer + strlen(dump_buffer), ", ");
            }
        }
    }
    sprintf(dump_buffer + strlen(dump_buffer), ">");

    return dump_buffer;
}

static void dump_hash(mrb_state *mrb, mrb_value x) {
    struct RHash *obj = mrb_ptr(x);
    const char *cls = api->mrb_class_name(mrb, obj->c);
    printf("{ c: %s, gcnext: %p, tt: %s, color: %s, flags: %s, size: %d, ea_capa: %d, ea_n_used: %d, iv: %s, data: %p }\n",
           cls,
           obj->gcnext,
           ttypes[obj->tt],
           BITS(obj->color, 3),
           BITS(obj->flags, 32),
           obj->size,
           obj->ea_capa,
           obj->ea_n_used,
           dump_ivs(mrb, obj->iv),
           obj->ht);
}

static void dump_array(mrb_state *mrb, mrb_value x) {
    struct RArray *obj = mrb_ptr(x);
    const char *cls = api->mrb_class_name(mrb, obj->c);

    if (ARY_SHARED_P(obj)) {
        printf("{ c: %s, gcnext: %p, tt: %s, color: %s, flags: %s, len: %lld, shared: %p, ptr: %p }\n",
               cls,
               obj->gcnext,
               ttypes[obj->tt],
               BITS(obj->color, 3),
               BITS(obj->flags, 32),
               obj->as.heap.len,
               obj->as.heap.aux.shared,
               obj->as.heap.ptr);
    } else {
        printf("{ c: %s, gcnext: %p, tt: %s, color: %s, flags: %s, len: %lld, capa: %lld, ptr: %p }\n",
               cls,
               obj->gcnext,
               ttypes[obj->tt],
               BITS(obj->color, 3),
               BITS(obj->flags, 32),
               obj->as.heap.len,
               obj->as.heap.aux.capa,
               obj->as.heap.ptr);
    }
}
