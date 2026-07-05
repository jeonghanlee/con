/*
 * Minimal UNIX Domain Socket echo server for con integration tests.
 *
 * Accepts any number of connections, forking one child per client; each child
 * echoes its own client's data back and exits on that client's EOF (#28).
 * The server puts itself in its own process group (setpgid), so a suite can
 * end the parent and every connection child with a single group signal -- the
 * multi-client suite's server-death case relies on this. Suites end the
 * server explicitly (stop_echo_server or a group kill); the parent no longer
 * exits after the first client.
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

    /* Own process group: one group signal reaches parent and children. A
     * no-op when a caller already made this process a group leader (setsid). */
    setpgid(0, 0);

    signal(SIGINT,  cleanup);
    signal(SIGTERM, cleanup);
    /* Connection children are fire-and-forget; reap them automatically. */
    signal(SIGCHLD, SIG_IGN);

    int srv = socket(AF_UNIX, SOCK_STREAM, 0);
    if (srv < 0) { perror("socket"); return 1; }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, sock_path, sizeof(addr.sun_path) - 1);
    unlink(sock_path);

    if (bind(srv, (struct sockaddr *)&addr, sizeof(addr)) < 0) { perror("bind"); return 1; }
    if (listen(srv, 8) < 0) { perror("listen"); return 1; }

    for (;;)
    {
        int cli = accept(srv, NULL, NULL);
        if (cli < 0) { perror("accept"); return 1; }

        pid_t pid = fork();
        if (pid < 0) { perror("fork"); close(cli); continue; }
        if (pid == 0)
        {
            /* Child: the parent alone owns the socket node. Reset the
             * inherited handlers so a group signal cannot make a child run
             * cleanup() and unlink the path the parent still listens on. */
            signal(SIGINT,  SIG_DFL);
            signal(SIGTERM, SIG_DFL);
            close(srv);

            char buf[4096];
            int n;
            while ((n = read(cli, buf, sizeof(buf))) > 0)
                write(cli, buf, n);
            _exit(0);
        }
        close(cli);
    }
}
