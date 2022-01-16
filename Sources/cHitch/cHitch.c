
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

#define TOUPPER(x) ((x >= 'a' && x <= 'z') ? x - 0x20 : x)
#define TOLOWER(x) ((x >= 'A' && x <= 'Z') ? x + 0x20 : x)
#define WHITESPACE(c) (x == '\t' || x == '\n' || x == '\v' || x == '\f' || x == '\r' || x == ' ')

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
    long size = rhs_positions - lhs_positions;
    if (size <= 0) { return chitch_empty(); }
    if (c0->count == 0) { return chitch_empty(); }
    if (lhs_positions > c0->count || rhs_positions > c0->count) { return chitch_empty(); }
    return chitch_init_raw(c0->data + lhs_positions, size, size);
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
    int8_t * ptr = c0->data;
    int8_t * end = c0->data + c0->count;
    while (ptr < end) {
        *ptr = TOLOWER(*ptr);
        ptr++;
    }
}

void chitch_toupper(CHitch * c0) {
    int8_t * ptr = c0->data;
    int8_t * end = c0->data + c0->count;
    while (ptr < end) {
        *ptr = TOUPPER(*ptr);
        ptr++;
    }
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
    if (lhs == NULL && rhs == NULL) { return true; }
    if (lhs == NULL || rhs == NULL) { return false; }
    if (lhs_count != rhs_count) { return false; }
    if (lhs == rhs) { return true; }
    return memcmp(lhs, rhs, rhs_count) == 0;
}

bool chitch_contains_raw(const int8_t * haystack, long haystack_count, const int8_t * needle, long needle_count) {
    return chitch_firstof_raw(haystack, haystack_count, needle, needle_count) >= 0;
}

long chitch_firstof_raw(const int8_t * haystack, long haystack_count, const int8_t * needle, long needle_count) {
    if (needle_count == 0) { return 0; }
    if (needle == NULL && haystack == NULL) { return 0; }
    if (needle == NULL || haystack == NULL) { return -1; }
    if (needle_count > haystack_count) { return -1; }
    
    const int8_t * ptr = haystack;
    const int8_t * end = haystack + haystack_count - needle_count;
    const int8_t needle_start = needle[0];
    
    bool found = true;
    
    while (ptr < end) {
        if (*ptr == needle_start) {
            switch (needle_count) {
                case 1: return (ptr - haystack);
                case 2: if (ptr[1] == needle[1]) { return (ptr - haystack); } break;
                case 3: if (ptr[1] == needle[1] && ptr[2] == needle[2]) { return (ptr - haystack); } break;
                case 4: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3]) { return (ptr - haystack); } break;
                case 5: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4]) { return (ptr - haystack); } break;
                case 6: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5]) { return (ptr - haystack); } break;
                case 7: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6]) { return (ptr - haystack); } break;
                case 8: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7]) { return (ptr - haystack); } break;
                case 9: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7] && ptr[8] == needle[8]) { return (ptr - haystack); } break;
                case 10: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7] && ptr[8] == needle[8] && ptr[9] == needle[9]) { return (ptr - haystack); } break;
                default:
                    found = true;
                    for (int idx = 1; idx < needle_count; idx++) {
                        if (ptr[idx] != needle[idx]) {
                            found = false;
                            break;
                        }
                    }
                    if (found) {
                        return (ptr - haystack);
                    }
                    break;
            }
        }
        ptr++;
    }
    
    return -1;
}

long chitch_lastof_raw(const int8_t * haystack, long haystack_count, const int8_t * needle, long needle_count) {
    if (needle_count == 0) { return 0; }
    if (needle == NULL && haystack == NULL) { return 0; }
    if (needle == NULL || haystack == NULL) { return -1; }
    if (needle_count > haystack_count) { return -1; }
    
    const int8_t * start = haystack;
    const int8_t * end = haystack + haystack_count - needle_count;
    const int8_t * ptr = end;
    const int8_t needle_start = needle[0];
    
    bool found = true;
    
    while (ptr > start) {
        if (*ptr == needle_start) {
            switch (needle_count) {
                case 1: return (ptr - haystack);
                case 2: if (ptr[1] == needle[1]) { return (ptr - haystack); } break;
                case 3: if (ptr[1] == needle[1] && ptr[2] == needle[2]) { return (ptr - haystack); } break;
                case 4: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3]) { return (ptr - haystack); } break;
                case 5: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4]) { return (ptr - haystack); } break;
                case 6: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5]) { return (ptr - haystack); } break;
                case 7: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6]) { return (ptr - haystack); } break;
                case 8: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7]) { return (ptr - haystack); } break;
                case 9: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7] && ptr[8] == needle[8]) { return (ptr - haystack); } break;
                case 10: if (ptr[1] == needle[1] && ptr[2] == needle[2] && ptr[3] == needle[3] && ptr[4] == needle[4] && ptr[5] == needle[5] && ptr[6] == needle[6] && ptr[7] == needle[7] && ptr[8] == needle[8] && ptr[9] == needle[9]) { return (ptr - haystack); } break;
                default:
                    found = true;
                    for (int idx = 1; idx < needle_count; idx++) {
                        if (ptr[idx] != needle[idx]) {
                            found = false;
                            break;
                        }
                    }
                    if (found) {
                        return (ptr - haystack);
                    }
                    break;
            }
        }
        ptr--;
    }
    
    return -1;
}

long chitch_toepoch(CHitch * c0) {
    // Handles just this one date format. Timezone is always considered to be UTC
    // 4/30/2021 8:19:27 AM
    if (c0 == NULL || c0->count < 0) { return 0; }
    
    struct tm ti = {0};
    
    if (c0->data[c0->count-2] == 'A') {
        if (sscanf((const char *)c0->data, "%d/%d/%d %d:%d:%d",
                   &ti.tm_mon,
                   &ti.tm_mday,
                   &ti.tm_year,
                   &ti.tm_hour,
                   &ti.tm_min,
                   &ti.tm_sec) != 6) {
            return 0;
        }
        
        if (ti.tm_hour == 12) {
            ti.tm_hour = 0;
        }
        
    } else {
        if (sscanf((const char *)c0->data, "%d/%d/%d %d:%d:%d",
                   &ti.tm_mon,
                   &ti.tm_mday,
                   &ti.tm_year,
                   &ti.tm_hour,
                   &ti.tm_min,
                   &ti.tm_sec) != 6) {
            return 0;
        }
        
        if (ti.tm_hour == 12) {
            ti.tm_hour = 0;
        }
        
        ti.tm_hour += 12;
    }
    
    ti.tm_year -= 1900;
    ti.tm_mon -= 1;

    // struct tm to seconds since Unix epoch
    register long year;
    register time_t result;
    static const int cumdays[12] =
        { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };

    year = 1900 + ti.tm_year + ti.tm_mon / 12;
    result = (year - 1970) * 365 + cumdays[ti.tm_mon % 12];
    result += (year - 1968) / 4;
    result -= (year - 1900) / 100;
    result += (year - 1600) / 400;
    if ((year % 4) == 0 && ((year % 100) != 0 || (year % 400) == 0) &&
        (ti.tm_mon % 12) < 2)
        result--;
    result += ti.tm_mday - 1;
    result *= 24;
    result += ti.tm_hour;
    result *= 60;
    result += ti.tm_min;
    result *= 60;
    result += ti.tm_sec;
    if (ti.tm_isdst == 1)
        result -= 3600;
    return (result);
}



