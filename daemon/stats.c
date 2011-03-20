#include <stdio.h>
#include <string.h>
#include "stats.h"


struct stats stats;

#define COMMAND(item) + sizeof(#item) + 2 + MAX_COUNT_LEN
static char stats_buffer[
	sizeof("Uptime: 100000 days, 23h 59m 59s") + 2
	#include "stats.list"
];
#undef COMMAND

const char* provide_stats(const char* type)
{
	int seconds = time(NULL) - stats.start;
	int minutes = seconds / 60;
	seconds %= 60;
	int hours = minutes / 60;
	minutes %= 60;
	unsigned int days = hours / 24;
	
	int n;
	n = sprintf( stats_buffer, "uptime: %u days, %dh %dm %ds\n", days, hours, minutes, seconds );
	
	if ( !strcasecmp( type, "FULL" ) ) {
		#define COMMAND(item) n += sprintf( stats_buffer + n, #item ": %" PRcount "\n", stats.item );
		#include "stats.list"
		#undef COMMAND
		strcpy( stats_buffer + n, "\n" );
	} else if ( strcasecmp( type, "UPTIME" ) ) {
		#define COMMAND(item) if ( !strcasecmp( type, #item ) ) sprintf( stats_buffer, #item ": %" PRcount "\n", stats.item ); else
		#include "stats.list"
		#undef COMMAND
		
		strcpy( stats_buffer, "ERROR WRONG_STAT" );
	}
	return stats_buffer;
}
