#include "types.h"

#include "debug.h"

static struct RVALUE *pool, *pool_end;

static struct RHash escaped_index_hash;
static mrb_value escaped_index;

mrb_value gc_escape(mrb_state *mrb, mrb_value obj);

void gc_escape_allocate_new_pool() {
    pool = calloc(1024, sizeof(struct RVALUE));
    for (size_t i = 0; i < 1024 * sizeof(struct RVALUE); i++) {
        ((char *)pool)[i] = '\0';
    }
    pool_end = pool + 1024;
}

static iv_tbl *gc_escape_iv_tbl_clone(mrb_state *mrb, iv_tbl *tbl) {
    if (!tbl) return NULL;

    iv_tbl *clone = malloc(sizeof(iv_tbl));
    *clone = *tbl;

    clone->table = malloc(sizeof(struct iv_elem) * tbl->alloc);
    for (size_t i = 0; i < tbl->alloc; i++) {
        struct iv_elem *slot = &tbl->table[i];
        if (!slot->key || mrb_undef_p(slot->val)) continue;

        clone->table[i].key = slot->key;
        clone->table[i].val = gc_escape(mrb, slot->val);
    }

    return clone;
}

mrb_value gc_escape(mrb_state *mrb, mrb_value obj) {
    if (mrb_immediate_p(obj)) return obj;

    struct RVALUE *leaked = pool;
    mrb_value copy = api->mrb_obj_value(leaked);

    mrb_value key = mrb_nil_value();
    if (mrb_hash_p(obj) && (MRB_RHASH_DEFAULT_P(obj) || MRB_RHASH_PROCDEFAULT_P(obj))) {
        uint32_t hash = 54321;

        mrb_value ifnone = api->mrb_iv_get(mrb, obj, api->mrb_intern_lit(mrb, "ifnone"));
        hash ^= mrb_integer(api->mrb_funcall(mrb, ifnone, "hash", 0)) << 8;

        struct RHash *raw = RHASH(obj);
        hash_entry *source = MRB_FLAG_TEST(raw, MRB_HASH_HT) ? raw->ht->ea : raw->ea;
        for (uint32_t i = 0; i < raw->ea_capa; i++) {
            hash ^= mrb_integer(api->mrb_funcall(mrb, source[i].key, "hash", 0)) << (i % 16);
            hash ^= mrb_integer(api->mrb_funcall(mrb, source[i].val, "hash", 0)) << (i % 16);
        }

        key = api->mrb_int_value(mrb, hash);
    }

    mrb_value result = api->mrb_hash_fetch(mrb, escaped_index, (mrb_nil_p(key) ? obj : key), mrb_nil_value());
    if (!mrb_nil_p(result)) return result;

    pool += 1;
    if (pool >= pool_end) {
        gc_escape_allocate_new_pool();
    }

    struct RBasic *basic = mrb_basic_ptr(obj);

    switch (mrb_type(obj)) {
        case MRB_TT_FLOAT: {
            struct RFloat *raw = mrb_ptr(obj);
            leaked->as.floatv = *raw;
            api->mrb_hash_set(mrb, escaped_index, copy, copy);
            break;
        }
        case MRB_TT_STRING: {
            struct RString *raw = RSTRING(obj);

            if (RSTR_EMBED_P(raw)) {
                leaked->as.string = *raw;
            } else {
                leaked->as.basic = *basic;

                size_t len = RSTR_LEN(raw);
                if (RSTR_SHARED_P(raw)) {
                    leaked->as.string.as.heap.aux.shared->refcnt++;
                } else {
                    leaked->as.string.as.heap.ptr = api->mrb_malloc(mrb, len + 1);
                    leaked->as.string.as.heap.len = len;
                    leaked->as.string.as.heap.aux.capa = 0;
                    memcpy(leaked->as.string.as.heap.ptr, RSTR_PTR(raw), len + 1);
                    RSTR_SET_TYPE_FLAG(&leaked->as.string, NOFREE);
                }
            }

            break;
        }
        case MRB_TT_HASH: {
            struct RHash *raw = RHASH(obj);
            leaked->as.hash = *raw;
            leaked->as.hash.iv = gc_escape_iv_tbl_clone(mrb, raw->iv);
            leaked->as.hash.ea = NULL;
            leaked->as.hash.ht = NULL;

            uint32_t ea_capa = raw->ea_capa;
            if (ea_capa == 0) break;

            size_t ea_size = sizeof(struct hash_entry) * ea_capa;
            hash_entry *ea = api->mrb_malloc(mrb, ea_size);
            hash_entry *source = MRB_FLAG_TEST(raw, MRB_HASH_HT) ? raw->ht->ea : raw->ea;

            uint32_t i = 0;
            for (uint32_t i = 0; i < ea_capa; i++) {
                struct hash_entry entry = source[i];
                ea[i] = (struct hash_entry){
                    .key = gc_escape(mrb, entry.key),
                    .val = gc_escape(mrb, entry.val),
                };
            }

            if (MRB_FLAG_TEST(raw, MRB_HASH_HT)) {
                uint32_t ib_bits = (raw->flags & MRB_HASH_IB_BIT_MASK) >> MRB_HASH_IB_BIT_SHIFT;
                uint32_t ib_init_bit =
                    ((32 >> 2) | (32 >> 1)) <= 16 ? 6 :
                    ((16 >> 2) | (16 >> 1)) <= 16 ? 5 :
                    4;
                uint32_t ary_size = ib_init_bit == 4 ?
                    (((uint32_t)(1)) << ib_bits) * 2 / 32 * ib_bits / 2 :
                    (((uint32_t)(1)) << ib_bits) / 32 * ib_bits;
                size_t ht_size = sizeof(hash_table) + ((uint32_t)(sizeof(uint32_t) * ary_size));

                hash_table *ht = api->mrb_malloc(mrb, ht_size);
                memcpy(ht, raw->ht, ht_size);

                leaked->as.hash.ht = ht;
                leaked->as.hash.ht->ea = ea;
            } else {
                leaked->as.hash.ea = ea;
            }

            break;
        }
        default: {
            const char *name = api->mrb_class_name(mrb, basic->c);
            api->mrb_raisef(mrb, api->mrb_class_get(mrb, "RuntimeError"), "%s instances cannot be escaped", name);
        }
    }

    leaked->as.basic.gcnext = NULL;
    leaked->as.basic.color = 7; // RED
    MRB_SET_FROZEN_FLAG((struct RBasic *)leaked);
    api->mrb_hash_set(mrb, escaped_index, (mrb_nil_p(key) ? copy : key), copy);

    // inspect(obj);
    // inspect(api->mrb_funcall(mrb, obj, "hash", 0));
    // inspect(api->mrb_funcall(mrb, copy, "hash", 0));

    // switch (mrb_type(obj)) {
    //     case MRB_TT_FLOAT: {
    //         printf("orig: "); dump_float(mrb, obj);
    //         printf("copy: "); dump_float(mrb, copy);
    //         break;
    //     }
    //     case MRB_TT_STRING: {
    //         printf("orig: "); dump_string(mrb, obj);
    //         printf("copy: "); dump_string(mrb, copy);
    //         break;
    //     }
    //     case MRB_TT_HASH: {
    //         printf("orig: "); dump_hash(mrb, obj);
    //         printf("copy: "); dump_hash(mrb, copy);
    //         break;
    //     }
    //     default: {}
    // }

    return copy;
}

mrb_value gc_escape_m(mrb_state * mrb, mrb_value self) {
    const mrb_value obj;
    api->mrb_get_args(mrb, "o", &obj);

    api->mrb_gc_register(mrb, obj);
    mrb_value cloned = gc_escape(mrb, obj);
    api->mrb_gc_unregister(mrb, obj);

    return cloned;
}

void drb_register_c_extensions_with_api(mrb_state *mrb, struct drb_api_t *drb) {
    api = drb;

    gc_escape_allocate_new_pool();
    escaped_index_hash = (struct RHash){.c = mrb->hash_class, .tt = MRB_TT_HASH};
    escaped_index = mrb_obj_value(&escaped_index_hash);

    api->mrb_define_class_method(mrb, api->mrb_module_get(mrb, "GC"), "escape", gc_escape_m, MRB_ARGS_REQ(1));
    api->mrb_define_method(mrb, mrb->kernel_module, "ESCAPE", gc_escape_m, MRB_ARGS_REQ(1));
}
