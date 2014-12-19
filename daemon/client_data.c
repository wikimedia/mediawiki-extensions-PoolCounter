#include <stddef.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <malloc.h>
#include <assert.h>
#include "client_data.h"
#include "locks.h"
#include "stats.h"

struct client_data* new_client_data(int fd) {
	struct client_data* cli_data;
	cli_data = malloc( sizeof( *cli_data ) );
	cli_data->used_buffer = 0;
	cli_data->next_lock = 0;
	cli_data->fd = fd;
	int i;
	for ( i = 0; i < MAX_LOCKS_PER_CLIENT; i++ ) {
		cli_data->client_locks[i].state = UNLOCKED;
	}
	return cli_data;
}

int all_unlocked(struct client_data* cli_data) {
	int i;
	for ( i = 0; i < MAX_LOCKS_PER_CLIENT; i++ ) {
		if ( cli_data->client_locks[i].state != UNLOCKED ) {
			fprintf( stderr, "%d lock still locked after free_client_data.  next_lock is %d.  State is %d.\n",
				i, cli_data->next_lock, cli_data->client_locks[i].state );
			return 0;
		}
	}
	return 1;
}

void free_client_data(struct client_data* cli_data) {
	int i;
	// Release locks backwards because that feels better.
	for ( i = cli_data->next_lock - 1; i >= 0 ; i-- ) {
		finish_lock( cli_data->client_locks + i );
	}

	assert( all_unlocked( cli_data ) );
	free( cli_data );
}

/**
 * Initialize and return a pointer to the next available lock in the client or
 * NULL if there aren't any more available locks.
 */
struct locks* init_next_lock(struct client_data* cli_data, struct PoolCounter* parent, enum lock_state state) {
	if ( cli_data->next_lock >= MAX_LOCKS_PER_CLIENT ) {
		return NULL;
	}
	struct locks* l = cli_data->client_locks + cli_data->next_lock;
	l->state = state;
	l->parent = parent;
	l->client_data = cli_data;
	cli_data->next_lock++;
	return l;
}

/**
 * Read data from the client
 * If we filled a line, return the line length, and point to it in *line.
 * If a line is not available, *line will point to NULL.
 * Return -1 or -2 if the socket was closed (gracefully / erroneusly)
 * Line separator is \n.
 * Returned lines end in \0 with \n stripped.
 * Incomplete lines are not returned on close.
 */
int read_client_line(int fd, struct client_data* cli_data, char** line) {
	int n, i;
	*line = NULL;
	n = recv( fd, cli_data->buffer + cli_data->used_buffer, sizeof( cli_data->buffer ) - cli_data->used_buffer, 0 );
	if ( n == 0 ) {
		return -1;
	}
	if ( n == -1 ) {
		if (errno == EAGAIN) {
			/* This shouldn't happen... */
			return 0;
		} else {
			return -2;
		}
	}
	
	for ( i=cli_data->used_buffer; i < cli_data->used_buffer+n; i++ ) {
		if ( cli_data->buffer[i] == '\n' ) {
			cli_data->buffer[i] = '\0';
			*line = cli_data->buffer;
			return i;
		}
	}

	/* Wait for the rest of the line */
	event_add( &cli_data->ev, NULL );
	return 0;
}

/* Recover the space from the buffer which has been read, return another line if available */
int recover_client_buffer(struct client_data* cli_data, int len, char** line) {
	int i;
	*line = 0;
	if ( len >= cli_data->used_buffer ) {
		/* This is a query-response protocol. This should be *always* the case */
		cli_data->used_buffer = 0;
		return 0;
	}

	/* Nonetheless handle the other case */
	memmove(cli_data->buffer, cli_data->buffer + len, cli_data->used_buffer - len);
	cli_data->used_buffer -= len;
	
	for ( i=0; i < cli_data->used_buffer; i++ ) {
		if ( cli_data->buffer[i] == '\n' ) {
			cli_data->buffer[i] = '\0';
			*line = cli_data->buffer;
			return i;
		}
	}

	return 0;
}

/* Sends the message msg to the other side, or nothing if msg is NULL
 * Since the message are short, we optimistically consider that they
 * will always fit and never block (note O_NONBLOCK is set).
 */
void send_client(struct client_data* cli_data, const char* msg) {
	if ( !msg ) return;
	
	size_t len = strlen(msg);

	if ( send( cli_data->fd, msg, len, 0) != len ) {
		perror( "Something failed sending message" );
		incr_stats( failed_sends );
	}
	/* Wait for answer */
	event_add( &cli_data->ev, NULL );
}

void process_timeout(struct client_data* cli_data) {
	/*
	 * Note that you can't cancel a timeout so we just have to be careful and
	 * only do timeout things when the lock looks like its timed out.
	 */
	if ( cli_data->next_lock <= 0 ) {
		return;
	}
	struct locks* l = cli_data->client_locks + cli_data->next_lock - 1;
	if ( ( l->state == WAIT_ANY ) || ( l->state == WAITING ) ) {
		// Ignore any timeouts for locks not waiting - those are just left over
		// because its expensive to cancel them.
		cli_data->next_lock--;
		struct timeval now = { 0 };
		time_stats( l, wasted_timeout_time );
		send_client( cli_data, "TIMEOUT\n" );
		decr_stats( waiting_workers );
		remove_client_lock( l, 0 );
	}
}
