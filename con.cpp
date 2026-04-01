/*********************
 * Console utility
 *********************
 *
 */

#include <arpa/inet.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <memory.h>
#include <netdb.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>
#include <vector>

#include "tty.h"

#define PERR(args...) do { fprintf(stderr, args); finish(1); } while(0)
#define RERR(args...) do { fprintf(stderr, args); return;    } while(0)

Tty             *tty = 0;
int             tty1 = -1;
char            *tty1_name = 0;
const char      *tty2_name = "/dev/tty";
unsigned char   exitChr = '\001';
bool            echo_flag = false;
bool            hexa_flag = false;
bool            hexa_ascii_flag = false;
int             hexa_inline = 16;
int             hexa_ascii_inline = 8;
FILE            *log_file = NULL;

void usage(const char *s)
{
    const char *msg =
        "Usage:\n"
        "\t%s [SWITCHES] {tty_device | path_to_local_socket | [host]:port}\n"
        "\n"
        "The tool can be used in a few different modes:\n"
        "\n"
        "1. Communicaton program to serial line (like minicom):\n"
        "       %s [-t] [-b BAUDRATE] TERM_DEVICE\n"
        "   Example:\n"
        "       %s -b 115200 /dev/ttyUSB0\n"
        "       %s -x ctrl/b /dev/ttyS0\n"
        "\n"
        "2. Communicaton program to TCP socket in a client mode:\n"
        "       %s -c ADDR:PORT\n"
        "   Example:\n"
        "       %s -c www.something.org:80\n"
        "       %s -c 192.168.2.100:8080\n"
        "\n"
        "3. Communicaton program to TCP socket in a server mode):\n"
        "       %s -s :PORT\n"
        "   Example:\n"
        "       %s -s :8080\n"
        "\n"
        "4. Communicaton program to UNIX socket in a client mode:\n"
        "       %s -c SOCKET_PATH\n"
        "   Example:\n"
        "       %s -c /tmp/my_named_socket\n"
        "\n"
        "5. Communicaton program to UNIX socket in a server mode:\n"
        "       %s -s SOCKET_PATH\n"
        "   Example:\n"
        "       %s -s /tmp/my_named_socket\n"
        "\n"
        "SWITCHES may be:\n"
        "\t-h[elp]             - Print help message.\n"
        "\t-e[cho]             - Echo keyboard input locally.\n"
        "\t-l[og] FILENAME     - Log everything to specified file, file be overwritten\n"
        "\t-a[ppend] FILENAME  - Appends all logs to specified file\n"
        "\t-n[ocolor]          - Filter out colors and CRNL sequences in a log file\n"
        "\t-X                  - Output as hexa bytes\n"
        "\t-Y                  - Output as hexa and ascii\n"
        "\t-x[exit] KEY        - Exit connection key. May be in integer as 0x01 or 001\n"
        "\t                      or in a \"control-a\", \"cntrl/a\" or \"ctrl/a\" form\n"
        "\t                      Default is \"cntrl/a\".\n"
        "\t-q                  - Be quiet\n"
        "\n"
        "Switches specific for tty_device:\n"
        "\t-t[erm]             - Work as serial communicaton program. The is a default\n"
        "\t                      mode. Note that \"-b\" switch assumes \"-t\"\n"
        "\t-b[aud] <baud_rate> - Set the baud rate for target connection.\n"
        "\n"
        "Switches specific for socket connection:\n"
        "\t-s[erver]           - Accept connection to socket as server.\n"
        "\t-c[lient]           - Connection to socket as client.\n"
        ;
    fprintf(stderr, msg, s, s, s, s,    s, s, s, s,    s, s, s, s,    s);
    exit (1);
}

void finish(int stat = 0)
{
    fprintf(stderr, "\r\n");
    if (tty)
    {
        delete tty;
        tty = 0;
    }
    if (tty1 >= 0)
    {
        close(tty1);
        tty1 = -1;
    }
    if (tty1_name)
    {
        free(tty1_name);
        tty1_name = 0;
    }
    if (log_file)
    {
        fclose(log_file);
        log_file = NULL;
    }
    exit (stat);
}
extern "C" void finish_int(int)
{
    finish(1);
}

int readn(int fd, void *ptr, int nbytes)
{
    int     nread;

    do
        nread = read(fd, ptr, nbytes);
    while (nread < 0 && (errno == EINTR || errno == EAGAIN));
    return nread;
}

int writen(int fd, const void *ptr, int nbytes)
{
    int     nwritten;

    do
        nwritten = write(fd, ptr, nbytes);
    while (nwritten < 0 && (errno == EINTR || errno == EAGAIN));
    return nwritten;
}

enum Pstate { REGULAR, COLOR, CRNL };
static Pstate log_pstate = REGULAR;
static int    cr_count = 0;

/*
 * Write data to the log file efficiently.
 * If color filtering is enabled, it buffers the filtered characters
 * into a single chunk to minimize fwrite() lock/unlock overhead.
 */
void write_log(const unsigned char *buf, const int buf_cnt, bool filter_colors)
{
    if (!log_file)
        return;

    if (filter_colors)
    {
        // Use a vector as a dynamic buffer to accumulate filtered data.
        // Reserving capacity upfront prevents costly memory reallocations.
        std::vector<unsigned char> out_buf;
        out_buf.reserve(buf_cnt);

        for (int i = 0; i < buf_cnt; i++)
        {
            switch(log_pstate)
            {
            case REGULAR:
                if (buf[i] == '\033')
                    log_pstate = COLOR;
                else if (buf[i] == '\r')
                {
                    log_pstate = CRNL;
                    cr_count++;
                }
                else
                    out_buf.push_back(buf[i]);
                break;
            case COLOR:
                if (buf[i] == 'm')
                    log_pstate = REGULAR;
                break;
            case CRNL:
                if (buf[i] == '\r')
                    cr_count++;
                else if (buf[i] == '\n')
                {
                    out_buf.push_back(buf[i]);
                    cr_count = 0;
                }
                else
                {
                    for (int j = 0; j < cr_count; j++)
                        out_buf.push_back('\r');
                    out_buf.push_back(buf[i]);
                    cr_count = 0;
                }
                log_pstate = REGULAR;
                break;
            }
        }
        if (!out_buf.empty()) {
            fwrite(out_buf.data(), 1, out_buf.size(), log_file);
        }
    }
    else
    {
        fwrite(buf, buf_cnt, 1, log_file);
    }
}

void con_core(int cli_fd, const char *cli_name, int term_fd, const char *term_name, bool filter_colors)
{
    const int            MAXBUF = 8192;
    static unsigned char buf[MAXBUF];
    static int           term_cnt = 0;
    fd_set               rds;
    fd_set               except_ds;
    int                  num = (cli_fd > term_fd ? cli_fd : term_fd) + 1;
    for (;;)
    {
        FD_ZERO(&rds);
        FD_ZERO(&except_ds);
        FD_SET(cli_fd, &rds);
        FD_SET(term_fd, &rds);
        FD_SET(cli_fd, &except_ds);
        FD_SET(term_fd, &except_ds);

        if (select(num, &rds, 0, &except_ds, 0) < 0)
            RERR("select failure: %s\n", strerror(errno));

        if (FD_ISSET(cli_fd, &except_ds))
            RERR("\r\n\"%s\" error\n", cli_name);
        if (FD_ISSET(term_fd, &except_ds))
            RERR("\r\n\"%s\" error\n", term_name);

        if (FD_ISSET(cli_fd, &rds))
        {
            // From client to terminal
            int buf_cnt = readn(cli_fd, buf, MAXBUF);
            if (buf_cnt < 0)
                RERR("\r\n\"%s\" read error: %s\n", cli_name, strerror(errno));
            if (buf_cnt == 0)
                RERR("\r\n\"%s\" EOF\n", cli_name);
            if (hexa_ascii_flag)
            {
                for (int i=0; i<buf_cnt; i++)
                {
                    char xbuf[16];
                    sprintf(xbuf, "0x%02x [%c]   ", buf[i]&0xff, buf[i] >= ' ' && buf[i] <= '~' ? buf[i] : '.');
                    if (writen(term_fd, xbuf, strlen(xbuf)) != (int)strlen(xbuf))
                        RERR("\r\n\"%s\" write error: %s\n", term_name, strerror(errno));
                    term_cnt++;
                    if (term_cnt == hexa_ascii_inline)
                    {
                        if (writen(term_fd, "\r\n", 2) != 2)
                            RERR("\r\n\"%s\" write error: %s\n", term_name, strerror(errno));
                        term_cnt = 0;
                    }
                }
            }
            else if (hexa_flag)
            {
                for (int i=0; i<buf_cnt; i++)
                {
                    char xbuf[8];
                    sprintf(xbuf, "0x%02x ", buf[i]&0xff);
                    if (writen(term_fd, xbuf, strlen(xbuf)) != (int)strlen(xbuf))
                        RERR("\r\n\"%s\" write error: %s\n", term_name, strerror(errno));
                    term_cnt++;
                    if (term_cnt == hexa_inline)
                    {
                        if (writen(term_fd, "\r\n", 2) != 2)
                            RERR("\r\n\"%s\" write error: %s\n", term_name, strerror(errno));
                        term_cnt = 0;
                    }
                }
            }
            else
            {
                if (writen(term_fd, buf, buf_cnt) != buf_cnt)
                    RERR("\r\n\"%s\" write error: %s\n", term_name, strerror(errno));
            }
            if (log_file)
                write_log(buf, buf_cnt, filter_colors);
        }
        if (FD_ISSET(term_fd, &rds))
        {
            // From terminal to client
            int buf_cnt = readn(term_fd, buf, MAXBUF);
            if (buf_cnt < 0)
                RERR("\r\n\"%s\" read error: %s\n", term_name, strerror(errno));
            if (buf_cnt == 0)
                RERR("\r\n\"%s\" EOF\n", term_name);
            if (buf_cnt == 1  &&  *buf == exitChr)
                break;
            if (echo_flag  &&  writen(term_fd, buf, buf_cnt) != buf_cnt)
                RERR("\r\n\"%s\" write error: %s\n", term_name, strerror(errno));
            if (writen(cli_fd, buf, buf_cnt) != buf_cnt)
                RERR("\r\n\"%s\" write error: %s\n", cli_name, strerror(errno));
            if (log_file)
                write_log(buf, buf_cnt, filter_colors);
       }
    }
}

int main(int ac, char *av[])
{
    int                  TargetBaud = 0, nparams=0;
    bool                 tty_flag=false, socket_flag=false, cli_flag=false, srv_flag=false, quiet_flag=false;
    bool                 filter_colors = false;
    char                 *TargetCon = 0;

    /* Command line parsing. */
    if (ac < 2)
        usage(av[0]);
    for (int i=1; i<ac; i++)
    {
        switch (*av[i])
        {
        case '-':
            ++av[i];
            if (!strcmp(av[i], "e")  ||  !strcmp(av[i], "echo"))
            {
                echo_flag = true;
            }
            else if (!strcmp(av[i], "b")  ||  !strcmp(av[i], "baud"))
            {
                if (++i >= ac)
                    PERR("After switch \"%s\" baud rate is expected.\n",av[--i]);
                char *end;
                TargetBaud = (int)strtol(av[i], &end, 0);
                if (*end)
                    PERR("Invalid baud rate: \"%s\" -- ?\n", end);
                tty_flag = true;
            }
            else if (!strcmp(av[i], "l")  ||  !strcmp(av[i], "log"))
            {
                if (++i >= ac)
                    PERR("After switch \"%s\" baud rate is expected.\n",av[--i]);
                if (log_file)
                    PERR("Log file have to be specified only once\n");
                log_file = fopen(av[i], "w");
                if (!log_file)
                    PERR("File \"%s\" open error: %s\n", av[i], strerror(errno));
            }
            else if (!strcmp(av[i], "a")  ||  !strcmp(av[i], "append"))
            {
                time_t    t;
                struct tm *tmp;
                char      outstr[200];

                if (++i >= ac)
                    PERR("After switch \"%s\" baud rate is expected.\n",av[--i]);
                if (log_file)
                    PERR("Log file have to be specified only once\n");
                log_file = fopen(av[i], "a");
                if (!log_file)
                    PERR("File \"%s\" open error: %s\n", av[i], strerror(errno));
                fprintf(log_file, "\n\n\n*****     New CON session");

                t = time(NULL);
                tmp = localtime(&t);
                if (tmp &&  strftime(outstr, sizeof(outstr)-1, "%a, %d %b %y %T %z", tmp))
                    fprintf(log_file, ", started at %s     *****\n\n\n", outstr);
                else
                    fprintf(log_file, "     *****\n\n\n");
            }
            else if (!strcmp(av[i], "n")  ||  !strcmp(av[i], "nocolor"))
            {
                filter_colors = true;
            }
            else if (!strcmp(av[i], "t")  ||  !strcmp(av[i], "term"))
            {
                tty_flag = true;
            }
            else if (!strcmp(av[i], "q")  ||  !strcmp(av[i], "quiet"))
            {
                quiet_flag = true;
            }
            else if (!strcmp(av[i], "X")  ||  !strcmp(av[i], "hexa"))
            {
                hexa_flag = true;
            }
            else if (!strcmp(av[i], "Y")  ||  !strcmp(av[i], "hexa_ascii"))
            {
                hexa_ascii_flag = true;
            }
            else if (!strcmp(av[i], "x")  ||  !strcmp(av[i], "exit"))
            {
                if (++i >= ac)
                    PERR("After switch \"%s\" quit character is expected.\n",av[--i]);
                char *end;
                exitChr = (unsigned char)strtol(av[i], &end, 0);
                if (*end)
                {
                    char *p = strchr(av[i], '/');
                    if (!p)
                        p = strchr(av[i], '-');
                    if (!p)
                        PERR("No delimiter ('-' or '/') found in \"KEY\" specification.\n");

                    *p++ = 0;
                    if (!strcasecmp(av[i], "control")
                        || !strcasecmp(av[i], "cntrl")
                        || !strcasecmp(av[i], "ctrl"))
                    {
                    }
                    else
                    {
                        fprintf(stderr, "No modificator found in \"KEY\" specification.\n");
                        fprintf(stderr, "Can be \"control\", \"cntrl\" or \"ctrl\"\n");
                        finish(1);
                    }

                    if (strlen(p) != 1)
                    {
                        fprintf(stderr, "Should be one character after modificator in \"KEY\" specification.\n");
                        fprintf(stderr, "Can be \"control\", \"cntrl\" or \"ctrl\"\n");
                        finish(1);
                    }

                    if (*p >= 0x40 && *p <= 0x60)
                        exitChr = *p - 0x40;
                    else if (*p > 0x60)
                        exitChr = *p - 0x60;
                    else
                    {
                        fprintf(stderr, "Invalid character after modificator in \"KEY\" specification.\n");
                        fprintf(stderr, "Can be \"control\", \"cntrl\" or \"ctrl\"\n");
                        finish(1);
                    }
                }
            }
            else if (!strcmp(av[i], "s")  ||  !strcmp(av[i], "server"))
            {
                srv_flag = true;
                socket_flag = true;
            }
            else if (!strcmp(av[i], "c")  ||  !strcmp(av[i], "client"))
            {
                cli_flag = true;
                socket_flag = true;
            }
            else if (!strcmp(av[i], "h")  ||  !strcmp(av[i], "help"))
            {
                usage(av[0]);
            }
            else
                PERR("Invalid switch \"%s\".\n", av[i]);
            break;
        case '?':
            usage(av[0]);
            break;
        default:
            TargetCon = av[i];
            nparams++;
        }
    }

    if (nparams != 1)
        PERR("Invalid number of parameters.\n");
    if ((socket_flag && tty_flag)  ||  (srv_flag && cli_flag))
        PERR("Mutually exclusive flags are specified.\n");

    // tty or socket ?
    if (!socket_flag && !tty_flag)
    {
        if (strchr(TargetCon, ':'))
            // Contains ':' - most probably socket
            socket_flag = true;
        else
            // Otherwise - most probably tty
            tty_flag = true;
    }

    // server or client ?
    if (socket_flag  &&  (!srv_flag && !cli_flag))
    {
        if (*TargetCon == ':')
            // Starts with ':' - most probably server
            srv_flag = true;
        else if (strchr(TargetCon, ':'))
            // Contains ':' - most probably client
            srv_flag = true;
        else
            PERR("\'%s\" is ambiguous - server or client flag must be specified\n", TargetCon);
    }
    //fprintf(stderr, "socket_flag:%d, tty_flag:%d, srv_flag:%d, cli_flag:%d\n", socket_flag, tty_flag, srv_flag, cli_flag);

    signal(SIGINT,  finish_int);
    signal(SIGQUIT, finish_int);
    signal(SIGTERM, finish_int);
    signal(SIGPIPE, finish_int);
    tty = new Tty();

    // Open second connection, always to /dev/tty
    int tty2 = tty->open(tty2_name);
    if (tty2 == -1)
        PERR("Can't open /dev/tty: %s\n", strerror(errno));

    // Open first connection
    if (socket_flag)
    {
        if (srv_flag)
        {
            int        one=1;
            const int  name_l = sizeof(((struct hostent*)0)->h_name) + 1;
            char       name[name_l];
            name[name_l-1] = 0;

            char *p = strchr(TargetCon, ':');
            if (!p)
            {
                /*
                 * UNIX socket server
                 */

                struct sockaddr_un  serv_addr;
                int                 servlen;
                const int           addr_l = sizeof(((struct sockaddr_un*)0)->sun_path) + 1;
                char                addr[addr_l];
                addr[addr_l-1] = 0;

                // Open a TCP socket (an Internet stream socket).
                if ((tty1 = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
                    PERR("socket (AF_UNIX): %s", strerror(errno));

                // Reuse address
                if (setsockopt(tty1, SOL_SOCKET, SO_REUSEADDR, (char *) &one, sizeof(one)) < 0)
                    PERR("setsockopt (SO_REUSEADDR): %s", strerror(errno));

                // Bind our local address so that the client can send to us.
                memset((char *) &serv_addr, 0, sizeof(serv_addr));
                serv_addr.sun_family = AF_UNIX;
                strncpy(serv_addr.sun_path, TargetCon, sizeof(serv_addr.sun_path)-1);
                servlen = strlen(serv_addr.sun_path) + sizeof(serv_addr.sun_family);
                unlink(serv_addr.sun_path);
                if (bind(tty1, (struct sockaddr *)&serv_addr, servlen) < 0)
                    PERR("bind: %s", strerror(errno));

                // Get ready to accept connection
                if (listen(tty1, 1) < 0)
                    PERR("listen: %s", strerror(errno));

                size_t name_len = strlen(TargetCon) + 32;
                tty1_name = (char *)malloc(name_len);
                snprintf(tty1_name, name_len, "Unix domain server %s", TargetCon);
                if (!quiet_flag)
                    fprintf(stderr, "\r\n%s wating for connection, use Cntrl/%c to exit\r\n", tty1_name, exitChr+0x40);
                for (;;)
                {
                    fd_set  rds;

                    FD_ZERO(&rds);
                    FD_SET(tty1, &rds);
                    FD_SET(tty2, &rds);
                    if (select((tty1 > tty2 ? tty1 : tty2) + 1, &rds, 0, 0, 0) < 0)
                        PERR("select failure: %s\n", strerror(errno));
                    if (FD_ISSET(tty1, &rds))
                    {
                        struct sockaddr_un  cli_unix_addr;
                        int                 clilen = sizeof(cli_unix_addr);

                        cli_unix_addr.sun_path[0] = 0;
                        int new_sock = accept(tty1, (struct sockaddr *)&cli_unix_addr, (socklen_t *)&clilen);
                        if (new_sock < 0)
                            PERR("accept: %s", strerror(errno));

                        if (strlen(cli_unix_addr.sun_path))
                            strncpy(addr, cli_unix_addr.sun_path, addr_l-1);
                        else
                            strcpy(addr, "unkonown client");

                        if (!quiet_flag)
                            fprintf(stderr, "Connection accepted from %s, use Cntrl/%c to exit\r\n", addr, exitChr+0x40);
                        con_core(new_sock, tty1_name, tty2, tty2_name, filter_colors);
                        close(new_sock);
                        if (!quiet_flag)
                            fprintf(stderr, "\r\n\r\n%s wating for connection, use Cntrl/%c to exit\r\n", tty1_name, exitChr+0x40);
                    }
                    if (FD_ISSET(tty2, &rds))
                    {
                        unsigned char ch;
                        int buf_cnt = read(tty2, &ch, 1);
                        if (buf_cnt < 0)
                            PERR("\r\n\"%s\" read error: %s\n", tty2_name, strerror(errno));
                        if (buf_cnt == 0)
                            PERR("\r\n\"%s\" EOF\n", tty2_name);
                        if (ch == exitChr)
                            finish(0);
                    }
                }
            }
            else
            {
                /*
                 * TCP socket server
                 */
                char      *end;

                TargetCon = p + 1;
                int port = (int)strtol(TargetCon, &end, 0);
                if (*end)
                    PERR("Invalid port value: \"%s\" -- ?\n", end);

                struct sockaddr_in  serv_addr;
                struct hostent      *hent;

                // Open a TCP socket (an Internet stream socket).
                if ((tty1 = socket(AF_INET, SOCK_STREAM, 0)) < 0)
                    PERR("socket (AF_INET): %s", strerror(errno));

                // Reuse address
                if (setsockopt(tty1, SOL_SOCKET, SO_REUSEADDR, (char *) &one, sizeof(one)) < 0)
                    PERR("setsockopt (SO_REUSEADDR): %s", strerror(errno));

                // Bind our local address so that the client can send to us.
                memset((char *) &serv_addr, 0, sizeof(serv_addr));
                serv_addr.sin_family      = AF_INET;
                serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
                serv_addr.sin_port        = htons(port);
                if (bind(tty1, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
                    PERR("bind: %s", strerror(errno));

                // Get ready to accept connection
                if (listen(tty1, 1) < 0)
                    PERR("listen: %s", strerror(errno));

                tty1_name = (char*)malloc(32);
                snprintf(tty1_name, 32, "TCP server :%d", port);
                if (!quiet_flag)
                    fprintf(stderr, "\r\n%s wating for connection, use Cntrl/%c to exit\r\n", tty1_name, exitChr+0x40);
                for (;;)
                {
                    fd_set  rds;

                    FD_ZERO(&rds);
                    FD_SET(tty1, &rds);
                    FD_SET(tty2, &rds);
                    if (select((tty1 > tty2 ? tty1 : tty2) + 1, &rds, 0, 0, 0) < 0)
                        PERR("select failure: %s\n", strerror(errno));
                    if (FD_ISSET(tty1, &rds))
                    {
                        struct sockaddr_in  cli_inet_addr;
                        int                 clilen = sizeof(cli_inet_addr);
                        const int           addr_l = 16;  // Max inet_ntoa()
                        char                addr[addr_l];
                        addr[addr_l-1] = 0;

                        int new_sock = accept(tty1, (struct sockaddr *)&cli_inet_addr, (socklen_t *)&clilen);
                        if (new_sock < 0)
                            PERR("accept: %s", strerror(errno));

                        // Determine the client host name
                        hent = gethostbyaddr((char *)&cli_inet_addr.sin_addr,
                                             sizeof(cli_inet_addr.sin_addr), AF_INET);
                        if (hent)
                            strncpy(name, hent->h_name, name_l-1);
                        else
                            strncpy(name, "???", name_l-1);

                        strncpy(addr, inet_ntoa(cli_inet_addr.sin_addr), addr_l-1);
                        if (!quiet_flag)
                            fprintf(stderr,"Connection accepted from %s (%s), use Cntrl/%c to exit\r\n", name, addr, exitChr+0x40);
                        con_core(new_sock, tty1_name, tty2, tty2_name, filter_colors);
                        close(new_sock);
                        if (!quiet_flag)
                            fprintf(stderr, "\r\n\r\n%s wating for connection, use Cntrl/%c to exit\r\n", tty1_name, exitChr+0x40);
                    }
                    if (FD_ISSET(tty2, &rds))
                    {
                        unsigned char ch;
                        int buf_cnt = read(tty2, &ch, 1);
                        if (buf_cnt < 0)
                            PERR("\r\n\"%s\" read error: %s\n", tty2_name, strerror(errno));
                        if (buf_cnt == 0)
                            PERR("\r\n\"%s\" EOF\n", tty2_name);
                        if (ch == exitChr)
                            finish(0);
                    }
                }
            }
        }
        else if (cli_flag)
        {
            char *p = strchr(TargetCon, ':');
            if (!p)
            {
                /*
                 * UNIX local socket client
                 */

                struct sockaddr_un  serv_addr;
                int                 servlen;

                // Fill the "serv_addr" structure
                memset((char *) &serv_addr, 0, sizeof(serv_addr));
                serv_addr.sun_family      = AF_UNIX;
                strncpy(serv_addr.sun_path, TargetCon, sizeof(serv_addr.sun_path)-1);
                servlen = strlen(serv_addr.sun_path) + sizeof(serv_addr.sun_family);

                // Open a UNIX socket
                if ( (tty1 = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
                    PERR("socket (AF_UNIX): %s", strerror(errno));
                tty1_name = strdup(TargetCon);

                // Connect to the server.
                if (connect(tty1, (struct sockaddr *) &serv_addr, servlen) < 0)
                    PERR("connect: %s", strerror(errno));

            }
            else
            {
                /*
                 * TCP socket client
                 */

                *p = '\0';
                char *end;
                int port = (int)strtol(p+1, &end, 0);
                if (*end)
                    PERR("Invalid port value: \"%s\" -- ?\n", end);
                struct sockaddr_in  serv_addr;
                struct hostent      *hent;

                // Try to determinate server IP address
                if ((hent = gethostbyname(TargetCon)) == NULL)
                    PERR("gethostbyname(%s): %s\n", TargetCon, hstrerror(h_errno));

                // Fill the "serv_addr" structure
                memset((char *) &serv_addr, 0, sizeof(serv_addr));
                serv_addr.sin_family      = AF_INET;
                memcpy(&serv_addr.sin_addr, (*(hent->h_addr_list)), sizeof(struct in_addr));
                serv_addr.sin_port        = htons(port);

                // Open a TCP socket (an Internet stream socket).
                if ( (tty1 = socket(AF_INET, SOCK_STREAM, 0)) < 0)
                    PERR("socket (AF_INET): %s", strerror(errno));

                // Connect to the server.
                if (connect(tty1, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
                    PERR("connect: %s", strerror(errno));

                tty1_name = (char*)malloc(strlen(TargetCon) + 32);
                snprintf(tty1_name, strlen(TargetCon) + 32, "%s:%d", TargetCon, port);
            }
        }
        else
            PERR("Internal error #1\n");

    }
    else if (tty_flag)
    {
        tty1_name = strdup(TargetCon);
        tty1 = tty->open(TargetCon, TargetBaud);
        if (tty1 < 0)
            PERR("Can't open tty device %s: %s\n", TargetCon, strerror(errno));

        if (!quiet_flag)
            fprintf(stderr, "Connected to %s, use Cntrl/%c to exit\r\n", tty1_name, exitChr+0x40);
    }
    else
        PERR("Internal error #2\n");

    con_core(tty1, tty1_name, tty2, tty2_name, filter_colors);
    finish();
}
