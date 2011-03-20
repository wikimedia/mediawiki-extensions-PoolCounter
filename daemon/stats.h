
#include <time.h>
#include <stdint.h>
#include <inttypes.h>

typedef int64_t count_t;
#define PRcount PRIi64
#define MAX_COUNT_LEN sizeof("−9223372036854775808")

struct stats {
	time_t start;
	
#define COMMAND(item) volatile count_t item;
#include "stats.list"
#undef COMMAND

};

extern struct stats stats;
const char* provide_stats(const char* type);

#define incr_stats(item) stats.item++
#define decr_stats(item) stats.item--
