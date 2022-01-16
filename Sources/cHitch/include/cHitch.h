#ifndef __CHITCH__
#define __CHITCH__

#include <stdarg.h>
#include <string.h>
#include <limits.h>
#include <ctype.h>
#include <stdbool.h>

typedef struct {
    long capacity;
    long count;
    int8_t * data;
}CHitch;

CHitch chitch_empty();

extern CHitch chitch_init_capacity(long capacity);
extern CHitch chitch_init_raw(const int8_t * bytes, long capacity, long count);
extern CHitch chitch_init_cstring(const int8_t * bytes);

extern CHitch chitch_init_substring(CHitch * c0, long lhs_positions, long rhs_positions);

extern void chitch_dealloc(CHitch * c0);

extern void chitch_resize(CHitch * c0, long newCount);

extern void chitch_tolower(CHitch * c0);
extern void chitch_toupper(CHitch * c0);
extern void chitch_trim(CHitch * c0);

extern void chitch_replace(CHitch * c0, CHitch * find, CHitch * replace, bool ignoreCase);

extern void chitch_concat(CHitch * c0, CHitch * c1);
extern void chitch_concat_raw(CHitch * c0, const int8_t * rhs, long rhs_count);
extern void chitch_concat_cstring(CHitch * c0, const int8_t * rhs);
extern void chitch_concat_char(CHitch * c0, const int8_t rhs);

extern void chitch_insert(CHitch * c0, long position, CHitch * c1);
extern void chitch_insert_raw(CHitch * c0, long position, const int8_t * rhs, long rhs_count);
extern void chitch_insert_cstring(CHitch * c0, long position, const int8_t * rhs);
extern void chitch_insert_char(CHitch * c0, long position, const int8_t rhs);
extern void chitch_insert_int(CHitch * c0, long position, const long rhs);

extern long chitch_cmp (CHitch * c0, CHitch * c1);
extern bool chitch_equal(CHitch * c0, CHitch * c1);

extern long chitch_cmp_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count);
extern bool chitch_equal_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count);
extern bool chitch_contains_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count);
extern long chitch_firstof_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count);
extern long chitch_lastof_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count);

extern long chitch_toepoch(CHitch * c0);

#endif
