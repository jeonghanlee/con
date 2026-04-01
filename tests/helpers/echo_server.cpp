/*
 * Minimal UNIX Domain Socket echo server for con integration tests.
 * Accepts a single connection, echoes all received data back, and exits on EOF.
 */

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <signal.h>

static const char *sock_path = NULL;

static void cleanup(int sig)
{
    if (sock_path)
        unlink(sock_path);
    _exit(sig ? 1 : 0);
}

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        fprintf(stderr, "Usage: %s <socket_path>\n", argv[0]);
        return 1;
    }

    sock_path = argv[1];

    signal(SIGINT,  cleanup);
    signal(SIGTERM, cleanup);

    int srv = socket(AF_UNIX, SOCK_STREAM, 0);
    if (srv < 0) { perror("socket"); return 1; }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, sock_path, sizeof(addr.sun_path) - 1);
    unlink(sock_path);

    if (bind(srv, (struct sockaddr *)&addr, sizeof(addr)) < 0) { perror("bind"); return 1; }
    if (listen(srv, 1) < 0) { perror("listen"); return 1; }

    int cli = accept(srv, NULL, NULL);
    if (cli < 0) { perror("accept"); return 1; }

    char buf[4096];
    int n;
    while ((n = read(cli, buf, sizeof(buf))) > 0)
        write(cli, buf, n);

    close(cli);
    close(srv);
    unlink(sock_path);
    return 0;
}
