#pragma once
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/epoll.h>
#include "buffer.h"
#include "lmdb_counter.h"
#include "http.h"

#define MAXEVENTS 64
#define MAXREAD 512


typedef struct {
    const char *port;
    size_t nthreads;
    pthread_t *threads;

} server_t;

// Used to pass server info into the threads
typedef struct {
    const char *port;
    int listen_fd;
    int epoll_fd;
    void *data;
    uint64_t thread_id;
    lmdb_counter_t *counter;
} thread_data_t;


char *make_http_response(int status_code, const char *status, const char *content_type, const char* response);

int unblock_socket(int fd);

int make_server_socket(const char *port);

void free_connection(connection_t *session);
void init_connection(connection_t *session, int fd);
static inline bool epoll_error(struct epoll_event e);

void *epoll_loop(void *ptr);
server_t *new_server(const size_t nthreads, const char *addr, const char *port);
void server_wait(server_t *server);