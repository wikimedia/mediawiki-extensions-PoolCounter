#ifndef LOCKS_H
#define LOCKS_H

#include <stdint.h>
#include <sys/time.h>

/* This application uses several double linked lists.
 * They are circular lists, new items are added on the end (ie. on prev)
 * and popped from next.
 */
struct double_linked_list {
	struct double_linked_list* prev;
	struct double_linked_list* next;
};

struct hashtable_entry {
	struct double_linked_list hashtable_siblings;
	struct hashtable* parent_hashtable;
	uint32_t key_hash;
	char* key;
};

struct PoolCounter {
	struct hashtable_entry htentry;

	uint32_t count;
	int processing;

	struct double_linked_list working;
	struct double_linked_list for_them;
	struct double_linked_list for_anyone;
};

enum lock_state {
	UNLOCKED,    // Not yet locked or already unlocked
	WAITING,     // Waiting on ACQ4ME
	WAIT_ANY,    // Waiting on ACQ4ANY
	PROCESSING,  // Currently locked
};

struct locks {
	/*
	 * Siblings in whatever linked list this lives.  Either working, for_them
	 * or for_anyone.
	 */
	struct double_linked_list siblings;
	struct PoolCounter* parent;
	enum lock_state state;
	/*
	 * Instant where is started waiting/processing.
	 */
	struct timeval timeval;
	/**
	 * Pointer back to client_data needed when pulling the lock from one of the
	 * linked lists.
	 */
	void* client_data;
};

struct client_data;
void finish_lock(struct locks* l);
const char* process_line(struct client_data* cli_data, char* line, int line_len);
void remove_client_lock(struct locks* l, int wakeup_anyones);

void hashtable_init();
struct hashtable* hashtable_create(int hashpower);
void* hashtable_find(struct hashtable* ht, uint32_t hash_value, const char* key);
void hashtable_insert(struct hashtable* ht, struct hashtable_entry* htentry);
void hashtable_remove(struct hashtable* ht, struct hashtable_entry* htentry);
#endif
