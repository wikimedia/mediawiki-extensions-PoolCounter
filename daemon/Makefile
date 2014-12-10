CC=gcc
DEFINES=-DENDIAN_BIG=0 -DENDIAN_LITTLE=1 -DHAVE_ACCEPT4=1
CFLAGS=-Wall -Werror $(DEFINES) $(DEBUG_FLAGS)
DEBUG_FLAGS=-DNDEBUG
OBJS=main.o client_data.o locks.o hash.o stats.o
LINK=-levent -lm
HEADERS=prototypes.h client_data.h stats.h stats.list
DESTDIR ?=

poolcounterd: $(OBJS)
	$(CC) $^ $(LINK) -o $@

debug: DEBUG_FLAGS=-DDEBUG -g
debug: poolcounterd

%.o: %.c $(HEADERS)
	$(CC) -c $(CFLAGS) $< -o $@

prototypes.h: main.c
	sed -n 's/\/\* prototype \*\//;/p' $^ > $@

clean:
	rm -f *.o prototypes.h

install:
	install -d $(DESTDIR)/usr/bin/
	install poolcounterd $(DESTDIR)/usr/bin/

test: clean debug
	./poolcounterd & echo $$! > .pid
	cd tests; bundle exec cucumber; SUC=$$?; cd ..; kill `cat .pid` && rm .pid ; exit $$SUC
