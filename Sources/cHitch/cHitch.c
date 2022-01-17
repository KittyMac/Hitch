
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

#define DIGIT(x) (x >= '0' && x <= '9')
#define TOUPPER(x) ((x >= 'a' && x <= 'z') ? x - 0x20 : x)
#define TOLOWER(x) ((x >= 'A' && x <= 'Z') ? x + 0x20 : x)
#define WHITESPACE(x) (x == '\t' || x == '\n' || x == '\r' || x == ' ')

static inline int memcasecmp(const void * ptr1, const void * ptr2, size_t count, bool ignoreCase) {
    if (ignoreCase) {
        return strncasecmp(ptr1, ptr2, count);
    }
    return memcmp(ptr1, ptr2, count);
}

// Ensure chitch is not empty and is of a minimum capacity
#define CHITCH_SANITY(C,MINSIZE)                                                                             \
if (C->data == 0) { C->capacity = (MINSIZE); C->data = malloc(C->capacity + 1); }                            \
if (C->capacity < MINSIZE) { C->capacity = (MINSIZE); C->data = realloc(C->data, C->capacity + 1); }         \

uint8_t * chitch_to_uint8(const int8_t * ptr) {
    return (uint8_t *)ptr;
}

int8_t * chitch_to_int8(const uint8_t * ptr) {
    return (int8_t *)ptr;
}

CHitch chitch_empty() {
    CHitch c = {0};
    return c;
}

CHitch chitch_init_capacity(long capacity) {
    CHitch c = {0};
    c.count = 0;
    c.capacity = capacity;
    c.data = malloc(capacity + 1);
    return c;
}

CHitch chitch_init_raw(const uint8_t * bytes, long count, long capacity) {
    CHitch c = {0};
    c.capacity = capacity;
    c.count = count;
    c.data = malloc(capacity + 1);
    memmove(c.data, bytes, count);
    return c;
}

CHitch chitch_init_cstring(const uint8_t * bytes) {
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
    c0->capacity = newCount;
    c0->data = realloc(c0->data, c0->capacity + 1);
    if (c0->count > c0->capacity) {
        c0->count = c0->capacity;
    }
}

void chitch_resize(CHitch * c0, long newCount) {
    if (newCount > c0->capacity) {
        chitch_realloc(c0, newCount + 1);
    } else {
        c0->count = newCount;
    }
}

void chitch_tolower(CHitch * c0) {
    uint8_t * ptr = c0->data;
    uint8_t * end = c0->data + c0->count;
    while (ptr < end) {
        *ptr = TOLOWER(*ptr);
        ptr++;
    }
}

void chitch_toupper(CHitch * c0) {
    uint8_t * ptr = c0->data;
    uint8_t * end = c0->data + c0->count;
    while (ptr < end) {
        *ptr = TOUPPER(*ptr);
        ptr++;
    }
}

void chitch_trim(CHitch * c0) {
    uint8_t * start = c0->data;
    uint8_t * end = c0->data + c0->count - 1;
    
    uint8_t c = *start;
    while (start < end && WHITESPACE(c)) {
        start++;
        c = *start;
    }
    
    c = *end;
    while (end > start && WHITESPACE(c)) {
        end--;
        c = *end;
    }
    
    c0->count = end - start + 1;
    if (start == c0->data) {
        return;
    }
    memmove(c0->data, start, c0->count);
}

void chitch_replace(CHitch * c0, CHitch * find, CHitch * replace, bool ignoreCase) {
    long c0_count = c0->count;
    long find_count = find->count;
    long replace_count = replace->count;
        
    const uint8_t find_start_lower = TOLOWER(find->data[0]);
    const uint8_t find_start_upper = TOUPPER(find->data[0]);
    
    // Expansion: our array is going to need to grow before we can perform the replacement
    if (replace_count > find_count) {
        // Figure out how big out final array needs to be, then resize c0
        long num_occurences = 0;
        long nextOffset = 0;
        while (true) {
            nextOffset = chitch_firstof_raw_offset(c0->data, nextOffset, c0_count, find->data, find_count);
            if (nextOffset < 0) {
                break;
            }
            nextOffset += find_count;
            num_occurences++;
        }
        
        long capacity_required = c0_count + (replace_count - find_count) * num_occurences;
        
        CHITCH_SANITY(c0, capacity_required);
        
        // work our way from back to front, copying and replacing as we go
        uint8_t * start = c0->data;
        uint8_t * old_end = c0->data + c0_count;
        uint8_t * new_end = c0->data + capacity_required;
        
        uint8_t * old_ptr_a = old_end;
        uint8_t * old_ptr_b = old_end;
        uint8_t * new_ptr = new_end;
                
        long fix_count = 0;
        
        while (old_ptr_a >= start) {
            // is this the thing we need to replace?
            if ((*old_ptr_a == find_start_lower || *old_ptr_a == find_start_upper) &&
                old_ptr_a + find_count <= old_end &&
                memcasecmp(old_ptr_a, find->data, find_count, ignoreCase) == 0) {
                fix_count = old_ptr_b - (old_ptr_a + find_count);
                if (fix_count > 0) {
                    memmove(new_ptr - fix_count, (old_ptr_a + find_count), fix_count);
                    new_ptr -= fix_count;
                }
                
                new_ptr -= replace_count;
                memmove(new_ptr, replace->data, replace_count);
                old_ptr_b = old_ptr_a;
            }
            
            old_ptr_a--;
        }
        
        // final copy
        fix_count = old_ptr_b - (old_ptr_a + find_count);
        if (fix_count > 0) {
            memmove((old_ptr_a + find_count), new_ptr - fix_count, fix_count);
        }
        
        c0->count = capacity_required;
    } else {
        // Our array can stay the same size as we perform the replacement. Since we can go front to
        // back we don't need to know the number of occurrences a priori.
        
        // work our way from back to front, copying and replacing as we go
        uint8_t * start = c0->data;
        uint8_t * old_end = c0->data + c0_count;
        
        uint8_t * old_ptr = start;
        uint8_t * new_ptr = start;
                
        while (old_ptr <= old_end) {
            // is this the thing we need to replace?
            if ((*old_ptr == find_start_lower || *old_ptr == find_start_upper) &&
                old_ptr + find_count <= old_end &&
                memcasecmp(old_ptr, find->data, find_count, ignoreCase) == 0) {
                old_ptr += find_count;
                
                memmove(new_ptr, replace->data, replace_count);
                new_ptr += replace_count;
            } else {
                *new_ptr = *old_ptr;
                new_ptr++;
                old_ptr++;
            }
        }
                
        c0->count = (new_ptr - start) - 1;
    }
}

void chitch_concat(CHitch * c0, CHitch * c1) {
    long c1_count = c1->count;
    if (c1_count <= 0) { return; }
    CHITCH_SANITY(c0, c0->count + c1_count);
    memmove(c0->data + c0->count, c1->data, c1_count);
    c0->count += c1_count;
}

void chitch_concat_raw(CHitch * c0, const uint8_t * rhs, long rhs_count) {
    if (rhs_count <= 0) { return; }
    CHITCH_SANITY(c0, c0->count + rhs_count);
    memmove(c0->data + c0->count, rhs, rhs_count);
    c0->count += rhs_count;
}

void chitch_concat_cstring(CHitch * c0, const uint8_t * rhs) {
    chitch_concat_raw(c0, rhs, strlen((const char *)rhs));
}

void chitch_concat_char(CHitch * c0, const uint8_t rhs) {
    CHITCH_SANITY(c0, c0->count);
    c0->data[c0->count] = rhs;
    c0->count++;
}

void chitch_concat_raw_precision(CHitch * c0, const uint8_t * rhs, long rhs_count, long precision) {
    if (rhs_count <= 0) { return; }
    CHITCH_SANITY(c0, c0->count + rhs_count);
    
    // treat each '.' found with digits on boths sides as if it were a double, include only precision number of decimal places
    uint8_t * ptr = c0->data + c0->count;
    const uint8_t * end = rhs + rhs_count;
    
    *(ptr++) = *(rhs++);
    
    while (rhs < end) {
        if (*rhs == '.' && DIGIT(rhs[-1]) && DIGIT(rhs[1])) {
            *(ptr++) = *(rhs++);
            
            // copy over the precisions
            long precisionCount = precision;
            while (rhs < end && precisionCount > 0) {
                precisionCount--;
                
                if (DIGIT(*rhs) == false) {
                    break;
                }
                *(ptr++) = *(rhs++);
            }
            
            // skip any more digits
            while (precisionCount == 0 && rhs < end && DIGIT(*rhs)) {
                rhs++;
            }
            
        } else {
            *(ptr++) = *(rhs++);
        }
    }
    
    c0->count = ptr - c0->data;
}

void chitch_insert(CHitch * c0, long position, CHitch * c1) {
    return chitch_insert_raw(c0, position, c1->data, c1->count);
}

void chitch_insert_raw(CHitch * c0, long position, const uint8_t * rhs, long rhs_count) {
    if (position < 0) { position = 0; }
    if (position >= c0->count) {
        return chitch_concat_raw(c0, rhs, rhs_count);
    }
    
    CHITCH_SANITY(c0, c0->count + rhs_count);
    
    // Start at end and copy back until old count + rhs_count to make room
    // for simultaneous copy operation
    uint8_t * ptr = c0->data + c0->count;
    uint8_t * start = c0->data + position;
    while (ptr >= start) {
        ptr[rhs_count] = *ptr;
        ptr--;
    }
    
    // simulataneous insert and copy
    const uint8_t * src_ptr = rhs;
    uint8_t * dst_ptr = c0->data + position;
    uint8_t * end = dst_ptr + rhs_count;
    while (dst_ptr < end) {
        *dst_ptr = *src_ptr;
        dst_ptr++;
        src_ptr++;
    }
    
    c0->count += rhs_count;
}

void chitch_insert_cstring(CHitch * c0, long position, const uint8_t * rhs) {
    return chitch_insert_raw(c0, position, rhs, strlen((const char *)rhs));
}

void chitch_insert_char(CHitch * c0, long position, const uint8_t rhs) {
    return chitch_insert_raw(c0, position, &rhs, 1);
}

void chitch_insert_int(CHitch * c0, long position, long rhs) {
    switch(rhs) {
        case 0: return chitch_insert_char(c0, position, '0');
        case 1: return chitch_insert_char(c0, position, '1');
        case 2: return chitch_insert_char(c0, position, '2');
        case 3: return chitch_insert_char(c0, position, '3');
        case 4: return chitch_insert_char(c0, position, '4');
        case 5: return chitch_insert_char(c0, position, '5');
        case 6: return chitch_insert_char(c0, position, '6');
        case 7: return chitch_insert_char(c0, position, '7');
        case 8: return chitch_insert_char(c0, position, '8');
        case 9: return chitch_insert_char(c0, position, '9');
    }
    
    uint8_t s[128] = {0};
    uint8_t * end = s + sizeof(s) - 1;
    uint8_t * ptr = end;
    int len = 0;
    
    if (rhs >= 0 && rhs <= 9) {
        *(ptr--) = '0' + rhs;
        len = 1;
    } else {
        int neg = (rhs < 0);
        if (neg) {
            rhs = -rhs;
        }
        
        while (ptr > s && rhs > 0) {
            *(ptr--) = '0' + (rhs % 10);
            rhs /= 10;
        }
        
        if (neg) {
            *(ptr--) = '-';
        }
        
        len = (end - ptr);
    }
    
    return chitch_insert_raw(c0, position, ptr+1, len);
}

long chitch_cmp (CHitch * c0, CHitch * c1) {
    return chitch_cmp_raw(c0->data, c0->count, c1->data, c1->count);
}

bool chitch_equal(CHitch * c0, CHitch * c1) {
    return chitch_equal_raw(c0->data, c0->count, c1->data, c1->count);
}

void chitch_copy_raw(const uint8_t * lhs, const uint8_t * rhs, long rhs_count) {
    memmove((void *)lhs, rhs, rhs_count);
}

long chitch_cmp_raw(const uint8_t * lhs, long lhs_count, const uint8_t * rhs, long rhs_count) {
    if (lhs_count < rhs_count) {
        return strncmp((const char *)lhs, (const char *)rhs, lhs_count);
    }
    return strncmp((const char *)lhs, (const char *)rhs, rhs_count);
}

bool chitch_equal_raw(const uint8_t * lhs, long lhs_count, const uint8_t * rhs, long rhs_count) {
    if (lhs == NULL && rhs == NULL) { return true; }
    if (lhs == NULL || rhs == NULL) { return false; }
    if (lhs_count != rhs_count) { return false; }
    if (lhs == rhs) { return true; }
    return memcmp(lhs, rhs, rhs_count) == 0;
}

bool chitch_equal_caseless_raw(const uint8_t * lhs, long lhs_count, const uint8_t * rhs, long rhs_count) {
    if (lhs == NULL && rhs == NULL) { return true; }
    if (lhs == NULL || rhs == NULL) { return false; }
    if (lhs_count != rhs_count) { return false; }
    if (lhs == rhs) { return true; }
    return strncasecmp((const char *)lhs, (const char *)rhs, rhs_count) == 0;
}

bool chitch_contains_raw(const uint8_t * haystack, long haystack_count, const uint8_t * needle, long needle_count) {
    return chitch_firstof_raw(haystack, haystack_count, needle, needle_count) >= 0;
}

long chitch_firstof_raw_offset(const uint8_t * haystack, long haystack_offset, long haystack_count, const uint8_t * needle, long needle_count) {
    haystack_count -= haystack_offset;
    haystack += haystack_offset;
    long result = chitch_firstof_raw(haystack, haystack_count, needle, needle_count);
    if (result < 0) {
        return result;
    }
    return result + haystack_offset;
}

long chitch_firstof_raw(const uint8_t * haystack, long haystack_count, const uint8_t * needle, long needle_count) {
    if (haystack_count < 0) { return -1; }
    if (needle_count == 0) { return 0; }
    if (needle == NULL && haystack == NULL) { return 0; }
    if (needle == NULL || haystack == NULL) { return -1; }
    if (needle_count > haystack_count) { return -1; }
    
    const uint8_t * ptr = haystack;
    const uint8_t * end = haystack + haystack_count - needle_count;
    const uint8_t needle_start = needle[0];
    
    bool found = true;
    
    while (ptr <= end) {
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

long chitch_lastof_raw(const uint8_t * haystack, long haystack_count, const uint8_t * needle, long needle_count) {
    if (needle_count == 0) { return 0; }
    if (needle == NULL && haystack == NULL) { return 0; }
    if (needle == NULL || haystack == NULL) { return -1; }
    if (needle_count > haystack_count) { return -1; }
    
    const uint8_t * start = haystack;
    const uint8_t * end = haystack + haystack_count - needle_count;
    const uint8_t * ptr = end;
    const uint8_t needle_start = needle[0];
    
    bool found = true;
    
    while (ptr >= start) {
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
        c0->data[c0->count] = 0;
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
        c0->data[c0->count] = 0;
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



