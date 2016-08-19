DESTDIR := /usr/local
CFLAGS := -ggdb -I./include -I/usr/include -I/usr/local/include -DGPROF -pthread -O3 -Wall \
          -Wextra -fPIC -pedantic -std=gnu11
LDFLAGS := -g -L/usr/local/lib -pthread -lhttp_parser

UVBLOOP_BACKEND ?= epoll
ifeq ($(UVBLOOP_BACKEND),epoll)
    CFLAGS += -DEPOLL_BACKEND
    SOURCE := epoll_uvbloop.c
else
    CFLAGS += -DKQUEUE_BACKEND
    SOURCE := kqueue_uvbloop.c
endif

OUT := out
SOURCE += buffer.c http.c list.c pool.c server.c timers.c
OBJS := $(addprefix $(OUT)/,$(patsubst %.c,%.o,$(SOURCE)))

.PHONY: lmdb tm atom all
lmdb: uvb-server-lmdb
tm: uvb-server-tm
atom: uvb-server-atom
all: lmdb tm

$(OUT)/%.o: src/%.c Makefile
	$(CC) -c $(CFLAGS) -o $@ $<

$(OUT)/tm_counter.o: src/tm_counter.c Makefile
	$(CC) -c $(CFLAGS) -fgnu-tm -o $@ $<

uvb-server-lmdb: out/lmdb_counter.o $(OBJS) 
	$(CC) -o $@ $(OBJS) out/lmdb_counter.o $(LDFLAGS) -llmdb

uvb-server-tm: out/tm_counter.o $(OBJS) 
	$(CC) $(LDFLAGS) -fgnu-tm -o $@ $(OBJS) out/tm_counter.o

uvb-server-atom: out/atomic_counter.o $(OBJS) 
	$(CC) $(LDFLAGS) -latomic -o $@ $(OBJS) out/atomic_counter.o

counter-test-lmdb: out/counter_test.o out/buffer.o out/lmdb_counter.o
	$(CC) -o $@ out/counter_test.o out/buffer.o out/lmdb_counter.o $(LDFLAGS) -llmdb

counter-test-tm: out/counter_test.o out/buffer.o out/tm_counter.o
	$(CC) $(LDFLAGS) -fgnu-tm -o $@ out/counter_test.o out/buffer.o out/tm_counter.o

counter-test-atom: out/counter_test.o out/buffer.o out/atomic_counter.o
	$(CC) $(LDFLAGS) -latomic -o $@ out/counter_test.o out/buffer.o out/atomic_counter.o

.PHONY: install
install:
	install -D uvb-server $(DESTDIR)/bin/$(EXECUTABLE)

.PHONY: clean
clean:
	$(RM) -rf $(OUT) uvb-server-{lmdb,tm} counters.db names.db
	mkdir $(OUT)

.PHONY: uninstall
uninstall:
	$(RM) $(DESTDIR)/bin/$(EXECUTABLE)

