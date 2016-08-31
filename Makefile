SRCS     = src/nif/gb_markdown_info.cc \
	   src/nif/gb_markdown_analyzer.cc \
	   src/nif/gb_markdown_nif.cc

CXXFLAGS  = -g -O3 -ansi -pedantic -Wall -Wextra -Werror
CXXFLAGS += -Wno-unused-parameter -std=c++11 -fPIC

ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
ifeq ($(wildcard deps/hoedown),)
	HOEDOWN_PATH = ../hoedown
else
	HOEDOWN_PATH = deps/hoedown
endif

CXXFLAGS += -I$(ERLANG_PATH) -I$(HOEDOWN_PATH)/src -Isrc/nif/include

ifeq ($(shell uname),Darwin)
	LDFLAGS += -dynamiclib -undefined dynamic_lookup
endif

all: priv/greenbar_markdown.so

clean:
	@rm -f priv/greenbar_markdown.so

priv/greenbar_markdown.so: $(SRCS) Makefile
	$(MAKE) -C $(HOEDOWN_PATH) libhoedown.a
	$(CXX) $(CXXFLAGS) -shared $(LDFLAGS) -o $@ $(SRCS) $(HOEDOWN_PATH)/libhoedown.a
