TRG = echo_server
SRC = echo_server.cpp

CXX ?= g++
CXXFLAGS += -Wall -O2

all: $(TRG)

$(TRG): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $<

clean:
	$(RM) $(TRG)

.PHONY: all clean
