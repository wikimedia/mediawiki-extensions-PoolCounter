typedef unsigned char u_char; /* needed by event.h */
#include <stddef.h>
#include <event.h>
#include "locks.h"

#define MAX_LOCKS_PER_CLIENT 4

struct client_data {
	struct event ev;
	int fd;
	size_t used_buffer;
	char buffer[1024];

	int next_lock;
	struct locks client_locks[MAX_LOCKS_PER_CLIENT];
};

struct client_data* new_client_data();
void free_client_data(struct client_data* cli_data);
struct locks* init_next_lock(struct client_data* cli_data, struct PoolCounter* parent, enum lock_state state);
int read_client_line(int fd, struct client_data* cli_data, char** line);
int recover_client_buffer(struct client_data* cli_data, int len, char** line);
void process_timeout(struct client_data* cli_data);
void send_client(struct client_data* cli_data, const char* msg);

#define PORT 7531
#define BACKLOG 20
