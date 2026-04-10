/*********************
 *********************
 * tty raw connection
 *********************
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <termios.h>
#include <unistd.h>

#include "tty.h"

const int Tty::DEF_MAXTERMS = 10;

Tty::Tty(const int max_terms)
{
    defaults = new termios[max_terms];
    tty_h    = new int[max_terms];
    maxterms = max_terms;
    for (int i=0; i<maxterms; i++)
        tty_h[i] = -1;
}

Tty::~Tty()
{
    for (int i=0; i<maxterms; i++)
        if (tty_h[i] != -1)
            do_close(i);
    if (defaults)
        delete [] defaults;
    defaults = 0;
    if (tty_h)
        delete [] tty_h;
    tty_h = 0;
    maxterms = 0;
}

bool Tty::setraw(termios& t, int speed)
{
    t.c_iflag |= (IGNBRK);
    t.c_iflag &= ~(INPCK | ISTRIP | INLCR | ICRNL | IUCLC | IXON | IXOFF);

    //t.c_oflag |= ();
    t.c_oflag &= ~(OPOST | OLCUC | XTABS | OCRNL | ONLCR);

    t.c_cflag &= ~(CSIZE | PARENB);
    t.c_cflag |= CS8;
    //t.c_cflag |= CRTSCTS; // Flow control - only if other side supports that

    t.c_lflag &= ~(ISIG | ICANON | XCASE | ECHO);

    t.c_cc[VMIN] = 1;
    t.c_cc[VTIME] = 0;
    if (speed)
    {
        switch(speed)
        {
#ifdef B1200
        case 1200:
            speed = B1200;
            break;
#endif
#ifdef B1800
        case 1800:
            speed = B1800;
            break;
#endif
#ifdef B2400
        case 2400:
            speed = B2400;
            break;
#endif
#ifdef B4800
        case 4800:
            speed = B4800;
            break;
#endif
#ifdef B9600
        case 9600:
            speed = B9600;
            break;
#endif
#ifdef B19200
        case 19200:
            speed = B19200;
            break;
#endif
#ifdef B38400
        case 38400:
            speed = B38400;
            break;
#endif
#ifdef B57600
        case 57600:
            speed = B57600;
            break;
#endif
#ifdef B115200
        case 115200:
            speed = B115200;
            break;
#endif
#ifdef B230400
        case 230400:
            speed = B230400;
            break;
#endif
#ifdef B307200
        case 307200:
            speed = B307200;
            break;
#endif
#ifdef B460800
        case 460800:
            speed = B460800;
            break;
#endif
        default:
            errno = EINVAL;
            return false;
        }

        if (cfsetospeed(&t, speed))
            return false;
        if (cfsetispeed(&t, speed))
            return false;
    }
    return true;
}

int Tty::open(const char *tty_port, const int speed, const bool reopen, const int tty_fd)
{
    termios sg;
    int     ind;

    for (ind=0; ind<maxterms; ind++)
        if (tty_h[ind] == -1)
            break;
    if (ind >= maxterms)
    {
        errno = EMFILE;
        return -1;
    }
    if (reopen)
        tty_h[ind] = tty_fd;
    else
    {
        if ((tty_h[ind] = ::open(tty_port, O_RDWR /*| O_NONBLOCK*/)) < 0)
            return -1;
    }
    if (!isatty(tty_h[ind]))
    {
        close(tty_h[ind]);
        tty_h[ind] = -1;
        return -1;
    }
    if (tcgetattr(tty_h[ind], &defaults[ind]) == -1)
    {
        close(tty_h[ind]);
        tty_h[ind] = -1;
        return -1;
    }
    memcpy(&sg, &defaults[ind], sizeof(termios));
    if (!setraw(sg, speed))
    {
        close(tty_h[ind]);
        tty_h[ind] = -1;
        return -1;
    }
    if (tcsetattr(tty_h[ind], TCSANOW, &sg) == -1)
    {
        close(tty_h[ind]);
        tty_h[ind] = -1;
        return -1;
    }
    return tty_h[ind];
}

void Tty::close(const int tid)
{
    for (int ind=0; ind<maxterms; ind++)
        if (tty_h[ind] == tid)
            do_close(ind);
}

void Tty::do_close(const int entry)
{
    if (tty_h[entry] < 0)
        return;
    if (isatty(tty_h[entry]))
        tcsetattr(tty_h[entry], TCSANOW, &defaults[entry]);
    ::close(tty_h[entry]);
    tty_h[entry] = -1;
}
