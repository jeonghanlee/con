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

`/srv/librablm` is the nfs folder where the BLM can access as `PATH`.

```
source ../deviceconf/BLM/setEnvBLMCC.bash
make clean
make
sudo make install DESTDIR=/srv/liberablmOpt
```
