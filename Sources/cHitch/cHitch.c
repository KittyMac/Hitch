
#include <stdio.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#include "cHitch.h"
#include <time.h>
#include <math.h>

CHitch chitch_empty() {
    CHitch c = {0};
    return c;
}

CHitch chitch_init_capacity(long capacity) {
    CHitch c = {0};
    c.count = 0;
    c.capacity = capacity;
    c.data = malloc(capacity);
    return c;
}

CHitch chitch_init_raw(const int8_t * bytes, long capacity, long count) {
    CHitch c = {0};
    c.capacity = capacity;
    c.count = count;
    c.data = malloc(capacity);
    memcpy(c.data, bytes, count);
    return c;
}

CHitch chitch_init_cstring(const int8_t * bytes) {
    long count = strlen((const char *)bytes);
    return chitch_init_raw(bytes, count, count);
}

CHitch chitch_init_substring(CHitch * c0, long lhs_positions, long rhs_positions) {
    
}

void chitch_dealloc(CHitch * c0) {
    if (c0->data != NULL) {
        free(c0->data);
        c0->data = NULL;
    }
}

void chitch_realloc(CHitch * c0, long newCount) {
    c0->data = realloc(c0->data, newCount);
}

void chitch_resize(CHitch * c0, long newCount) {
    if (newCount > c0->capacity) {
        chitch_realloc(c0, newCount);
    }
    c0->count = newCount;
}

void chitch_tolower(CHitch * c0) {
    exit(127);
}

void chitch_toupper(CHitch * c0) {
    exit(127);
}

void chitch_trim(CHitch * c0) {
    exit(127);
}

void chitch_replace(CHitch * c0, CHitch * find, CHitch * replace, bool ignoreCase) {
    exit(127);
}

void chitch_concat(CHitch * c0, CHitch * c1) {
    exit(127);
}

void chitch_concat_raw(CHitch * c0, const int8_t * rhs, long rhs_count) {
    exit(127);
}

void chitch_concat_cstring(CHitch * c0, const int8_t * rhs) {
    exit(127);
}

void chitch_concat_char(CHitch * c0, const int8_t rhs) {
    exit(127);
}

void chitch_insert(CHitch * c0, long position, CHitch * c1) {
    exit(127);
}

void chitch_insert_raw(CHitch * c0, long position, const int8_t * rhs, long rhs_count) {
    exit(127);
}

void chitch_insert_cstring(CHitch * c0, long position, const int8_t * rhs) {
    exit(127);
}

void chitch_insert_char(CHitch * c0, long position, const int8_t rhs) {
    exit(127);
}

void chitch_insert_int(CHitch * c0, long position, const long rhs) {
    exit(127);
}

long chitch_cmp (CHitch * c0, CHitch * c1) {
    exit(127);
}

bool chitch_equal(CHitch * c0, CHitch * c1) {
    return chitch_equal_raw(c0->data, c0->count, c1->data, c1->count);
}

void chitch_copy_raw(const int8_t * lhs, const int8_t * rhs, long rhs_count) {
    memcpy((void *)lhs, rhs, rhs_count);
}

long chitch_cmp_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count) {
    exit(127);
}

bool chitch_equal_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count) {
    exit(127);
}

bool chitch_contains_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count) {
    exit(127);
}

long chitch_firstof_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count) {
    exit(127);
}

long chitch_lastof_raw(const int8_t * lhs, long lhs_count, const int8_t * rhs, long rhs_count) {
    exit(127);
}

long chitch_toepoch(CHitch * c0) {
    exit(127);
}



