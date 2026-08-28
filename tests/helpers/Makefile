TRGS = echo_server serial_pty

CXX ?= g++
CXXFLAGS += -Wall -O2

all: $(TRGS)

echo_server: echo_server.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

serial_pty: serial_pty.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

clean:
	$(RM) $(TRGS)

.PHONY: all clean
