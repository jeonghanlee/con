#define _DEFAULT_SOURCE
#define _XOPEN_SOURCE 600

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

static volatile sig_atomic_t stop_requested = 0;

static void request_stop(int)
{
    stop_requested = 1;
}

static bool write_all(int fd, const char *data, size_t size)
{
    size_t written = 0;

    while (written < size)
    {
        ssize_t count = write(fd, data + written, size - written);
        if (count < 0)
        {
            if (errno == EINTR)
                continue;
            return false;
        }
        written += (size_t)count;
    }
    return true;
}

int main()
{
    int master_fd = posix_openpt(O_RDWR | O_NOCTTY);
    if (master_fd < 0)
    {
        perror("posix_openpt");
        return 1;
    }
    if (grantpt(master_fd) < 0 || unlockpt(master_fd) < 0)
    {
        perror("prepare PTY");
        close(master_fd);
        return 1;
    }

    const char *slave_path = ptsname(master_fd);
    if (!slave_path)
    {
        perror("ptsname");
        close(master_fd);
        return 1;
    }

    int slave_fd = open(slave_path, O_RDWR | O_NOCTTY);
    if (slave_fd < 0)
    {
        perror("open PTY slave");
        close(master_fd);
        return 1;
    }

    struct termios settings;
    if (tcgetattr(slave_fd, &settings) < 0)
    {
        perror("tcgetattr");
        close(slave_fd);
        close(master_fd);
        return 1;
    }
    cfmakeraw(&settings);
    if (tcsetattr(slave_fd, TCSANOW, &settings) < 0)
    {
        perror("tcsetattr");
        close(slave_fd);
        close(master_fd);
        return 1;
    }

    signal(SIGINT, request_stop);
    signal(SIGTERM, request_stop);

    printf("%s\n", slave_path);
    fflush(stdout);

    const char prefix[] = "SERIAL_PTY_ECHO:";
    char buffer[4096];
    struct pollfd pfd;
    pfd.fd = master_fd;
    pfd.events = POLLIN;

    while (!stop_requested)
    {
        pfd.revents = 0;
        int poll_status = poll(&pfd, 1, 100);
        if (poll_status < 0)
        {
            if (errno == EINTR)
                continue;
            perror("poll");
            close(slave_fd);
            close(master_fd);
            return 1;
        }
        if (poll_status == 0 || !(pfd.revents & POLLIN))
            continue;

        ssize_t count = read(master_fd, buffer, sizeof(buffer));
        if (count < 0)
        {
            if (errno == EINTR)
                continue;
            perror("read PTY master");
            close(slave_fd);
            close(master_fd);
            return 1;
        }
        if (count == 0)
            continue;
        if (!write_all(master_fd, prefix, sizeof(prefix) - 1)
            || !write_all(master_fd, buffer, (size_t)count))
        {
            perror("write PTY master");
            close(slave_fd);
            close(master_fd);
            return 1;
        }
    }

    close(slave_fd);
    close(master_fd);
    return 0;
}
