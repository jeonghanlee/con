# $Copyright: $
# Copyright (c) 1996 - 2022 by Steve Baker
# All Rights reserved
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Author  : Jeong Han Lee
# email   : jeonghan.lee@gmail.com
# Date    : 2022.05.08
#
# 2022-05-08 : Rewritten Makefile for Cross Compiler of Linux

TOP:=$(CURDIR)


DESTDIR?=$(TOP)
BINDIR?= $(PREFIX)bin

TRG1 = con
TRG2 = send_rs232

INCDIR:=$(TOP)
SRCDIR:=$(TOP)

VPATH = $(INCDIR) $(SRCDIR)
CXXFLAGS += -I $(INCDIR)

SRCS1  = con.cpp tty.cpp
SRCS2  = send_rs232.cpp tty.cpp str_utils.cpp

OBJS1=$(addsuffix .o,$(basename $(SRCS1)))
OBJS2=$(addsuffix .o,$(basename $(SRCS2)))

CXXFLAGS += -O5 -Wall -fno-exceptions -W -Werror
CXXFLAGS += -Wno-psabi

#------------------------------------------------------------

all: $(TRG1) $(TRG2) 

$(TRG1): $(OBJS1)
	$(LINK.cc) $^ -o $@

$(TRG2): $(OBJS2)
	$(LINK.cc) $^ -o $@

%.o: %.cpp
	$(COMPILE.cc) $(OUTPUT_OPTION) $<

clean:
	$(RM) -r $(TRG1) $(TRG2) $(OBJS1) $(OBJS2)

install:
	install -DT -m 755 $(TRG1) $(DESTDIR)/$(BINDIR)/$(TRG1)
	install -DT -m 755 $(TRG2) $(DESTDIR)/$(BINDIR)/$(TRG2)

distclean: clean

uninstall:
	$(RM) -v $(DESTDIR)/$(BINDIR)/$(TRG1)
	$(RM) -v $(DESTDIR)/$(BINDIR)/$(TRG2)

PRINT.%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)

