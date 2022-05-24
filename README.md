# con with GNUmakefile

The different Makefile I need for an old cross compiler, because the old embedded system doesn't have the amazing tree.

```bash
make
make clean
make distclean
make install
make uninstall
```
## Specific Example for BLM

`/srv/librablmOpt` is the nfs folder where the BLM can access as `PATH`.


```
source ../deviceconf/BLM/setEnvBLMCC.bash
make clean
make
sudo make install DESTDIR=/srv/liberablmOpt
```

## How to

The latest `procServ` supports a UNIX domain socket. This application can connect (attach) to the socket very quickly such as

```bash
con -c /tmp/unix-domain-socket
```

To detach, `ctrl-a`.  The commands (`CTRL-t`, `CTRL-x`) of `procServ` works well, however, `CTRL-r` doesn't work. The exit of the connection is `CTRL-a` by default.



